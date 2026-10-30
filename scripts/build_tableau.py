"""Build the local Tableau workbook from a native validated XML scaffold.
Native Desktop opening/rendering remains a separate required validation step.
"""
from pathlib import Path
from copy import deepcopy
import csv, json, uuid, zipfile, argparse, textwrap, xml.etree.ElementTree as E
parser=argparse.ArgumentParser();parser.add_argument('--output-name',default='Victoria_Landscape_Change');args=parser.parse_args()
if Path(args.output_name).name != args.output_name: raise ValueError('Use a simple output basename')
ROOT=Path(__file__).resolve().parents[1]
T=ROOT/'tableau'
base=E.parse(ROOT/'scripts/tableau_scaffold.twb').getroot()
manifest=json.loads((T/'data/manifest.json').read_text())
chart_path=T/'data/landcover.csv'
chart_bytes=chart_path.read_bytes().replace(b'\r\n',b'\n')
import hashlib
import re
def display_text(value):
 value=re.sub(r'(\d{4})[-\u2013\u2014](\d{4})',r'\1 to \2',value)
 return ' '.join(re.sub(r'[-\u2013\u2014]',' ',value).split())
if hashlib.md5(chart_bytes).hexdigest()!=manifest['chart_input_md5']:raise ValueError('Unexpected Tableau data release')
chart_path.write_bytes(chart_bytes)
classes=list(csv.DictReader((ROOT/'data/landcover/classes.csv').open()))
epochs=list(csv.DictReader((ROOT/'data/landcover/epochs.csv').open()))
units=['unit'+str(i) for i in range(1,1054)]
S='federated.landcover'; C='textscan.landcover'; OBJ='landcover.csv_2020'
fields={k:('integer' if k in ['epoch_start','epoch_end','class_code'] else 'real' if k in ['area_ha','share_pct','valid_area_ha','coverage_pct','unclassified_area_ha','nodata_area_ha'] else 'string') for k in next(csv.reader((T/'data/landcover.csv').open()))}
params={
 'TrendMode':('Trend measure','Cover share (%)',['Cover share (%)','Baseline change (pp)']),
 'DataRelease':('Data release',manifest['release'],None),
 'FocusArea':('Main area','unit668',units),
 'FocusView':('Composition view','Grouped overview',['Grouped overview','All cover types','Selected cover type']),
 'Compare1':('Additional area 1 (optional)','unit375',['']+units),
 'Compare2':('Additional area 2 (optional)','',['']+units),
 'Compare3':('Additional area 3 (optional)','',['']+units),
 'LandClass':('Cover type','Treed native vegetation',[r['class_label'] for r in classes]),
 'StartEpoch':('Earlier period',epochs[0]['epoch_label'],[r['epoch_label'] for r in epochs[:-1]]),
 'EndEpoch':('Later period',epochs[-1]['epoch_label'],[r['epoch_label'] for r in epochs[1:]])}
calcs={
 'AreaSeries':('string','(IF [microID] = [Parameters].[FocusArea] THEN "Main | " ELSEIF [microID] = [Parameters].[Compare1] THEN "Pin 1 | " ELSEIF [microID] = [Parameters].[Compare2] THEN "Pin 2 | " ELSE "Pin 3 | " END) + [unit_label]'),
 'EpochDisplay':('string','LEFT([epoch_label],4) + "/" + RIGHT([epoch_label],2)'),
 'FocusMatch':('boolean','[microID] = [Parameters].[FocusArea]'),
 'FocusViewMatch':('boolean','[Parameters].[FocusView] <> "Selected cover type" OR [class_label] = [Parameters].[LandClass]'),
 'DisplayClass':('string','IF [Parameters].[FocusView] <> "Grouped overview" THEN TRIM(REPLACE([class_label]," - "," ")) ELSE CASE [class_code] WHEN 1 THEN "Developed / disturbed" WHEN 2 THEN "Developed / disturbed" WHEN 3 THEN "Developed / disturbed" WHEN 4 THEN "Agriculture" WHEN 5 THEN "Agriculture" WHEN 8 THEN "Agriculture" WHEN 7 THEN "Plantations / exotic trees" WHEN 15 THEN "Plantations / exotic trees" WHEN 6 THEN "Plantations / exotic trees" WHEN 14 THEN "Natural low cover" WHEN 17 THEN "Open water" WHEN 9 THEN "Wetland vegetation" WHEN 16 THEN "Wetland vegetation" WHEN 18 THEN "Wetland vegetation" WHEN 19 THEN "Wetland vegetation" ELSE "Other native vegetation" END END'),
 'ChangeLabel':('string','STR(ROUND(SUM([EarlierShare]),1)) + "% to " + STR(ROUND(SUM([LaterShare]),1)) + "%   |   " + IF ROUND(SUM([ChangePP]),1) > 0 THEN "+" ELSE "" END + STR(ROUND(SUM([ChangePP]),1)) + " pp"'),
 'EarlierShare':('real','IF [epoch_label] = [Parameters].[StartEpoch] THEN [share_pct] END'),
 'LaterShare':('real','IF [epoch_label] = [Parameters].[EndEpoch] THEN [share_pct] END'),
 'ChangePP':('real','IF [epoch_label] = [Parameters].[EndEpoch] THEN [share_pct] ELSEIF [epoch_label] = [Parameters].[StartEpoch] THEN -[share_pct] END'),
 'TrendValue':('real','IF [Parameters].[TrendMode] = "Cover share (%)" THEN [share_pct] ELSE [share_pct] - { FIXED [microID], [class_label] : MIN(IF [epoch_label] = "1985-1990" THEN [share_pct] END) } END'),
 'CompareMatch':('boolean','[microID] = [Parameters].[FocusArea] OR [microID] = [Parameters].[Compare1] OR [microID] = [Parameters].[Compare2] OR [microID] = [Parameters].[Compare3]'),
 'ClassMatch':('boolean','[class_label] = [Parameters].[LandClass]'),
 'EndpointMatch':('boolean','INT(LEFT([Parameters].[StartEpoch],4)) < INT(LEFT([Parameters].[EndEpoch],4)) AND ([epoch_label] = [Parameters].[StartEpoch] OR [epoch_label] = [Parameters].[EndEpoch])'),
 'IntervalRole':('string','IF [epoch_label] = [Parameters].[StartEpoch] THEN "Earlier period" ELSEIF [epoch_label] = [Parameters].[EndEpoch] THEN "Later period" ELSE "Other period" END')}
def sub(parent,tag,text=None,**attrs):
 e=E.SubElement(parent,tag,attrs)
 if text is not None:e.text=text
 return e
def sid(parent):sub(parent,'simple-id',uuid='{'+str(uuid.uuid4()).upper()+'}')
def parameter(key, members=True):
 caption,value,values=params[key]
 c=E.Element('column',{'caption':caption,'datatype':'string','name':f'[{key}]','param-domain-type':'list' if values is not None else 'any','role':'measure','type':'nominal','value':json.dumps(value)})
 sub(c,'calculation',**{'class':'tableau','formula':json.dumps(value)})
 if members and values is not None:
  m=sub(c,'members')
  for v in values:
   attrs={'value':json.dumps(v)}
   if key in ['LandClass','StartEpoch','EndEpoch']:attrs['alias']=display_text(v)
   sub(m,'member',**attrs)
 return c
def column(key):
 dtype=fields.get(key,calcs.get(key,('string',))[0]);numeric=dtype in ['real','integer']
 e=E.Element('column',{'caption':{'AreaSeries':'Area','share_pct':'Cover (%)','unit_label':'Area','epoch_label':'Historical period','class_label':'Cover type','microID':'Area ID','EpochDisplay':'Period','DisplayClass':'Cover group / class','ChangePP':'Change (percentage points)','EarlierShare':'Earlier cover (%)','LaterShare':'Later cover (%)','TrendValue':'Cover share (%) / baseline change (pp)','IntervalRole':'Period being compared','area_ha':'Land covered (hectares)','coverage_pct':'Area with classified data (%)','unclassified_area_ha':'Unclassified land (hectares)','nodata_area_ha':'Missing data (hectares)'}.get(key,key.replace('_',' ').capitalize()),'datatype':dtype,'name':f'[{key}]','role':'measure' if numeric else 'dimension','type':'quantitative' if numeric else 'nominal'})
 if key in ['EarlierShare','LaterShare']:e.set('default-format','0.0"%"')
 if key=='ChangePP':e.set('default-format','+0.0" pp";-0.0" pp";0.0" pp"')
 if key in ['area_ha','valid_area_ha','unclassified_area_ha','nodata_area_ha']:e.set('default-format','#,##0.0')
 if key=='ChangeLabel':e.set('role','measure')
 if key in calcs:sub(e,'calculation',**{'class':'tableau','formula':calcs[key][1]})
 return e
def numeric(key):return fields.get(key,calcs.get(key,('',))[0]) in ['real','integer']
def derivation(key):return 'User' if key=='ChangeLabel' else 'Min' if key in ['coverage_pct','valid_area_ha','unclassified_area_ha','nodata_area_ha'] else 'Sum' if numeric(key) else 'None'
def inst(key):return f'[{'usr' if derivation(key)=='User' else derivation(key).lower()}:{key}:{"qk" if numeric(key) else "nk"}]'
def ref(key):return f'[{S}].'+inst(key)
root=E.Element('workbook',base.attrib)
for tag in ['document-format-change-manifest','preferences']:root.append(deepcopy(base.find(tag)))
for tag in ['DatagraphCoreV1','DatagraphNodeAxisTitle','DatagraphNodeSingleValueFieldV1']:
 sub(root.find('document-format-change-manifest'),tag)
dss=sub(root,'datasources');pds=sub(dss,'datasource',hasconnection='false',inline='true',name='Parameters',version='18.1');sub(pds,'aliases',enabled='yes')
for key in params:pds.append(parameter(key))
ds=sub(dss,'datasource',caption='Victoria land cover by SMP summary area',inline='true',name=S,version='18.1')
conn=sub(ds,'connection',**{'class':'federated'});ncs=sub(conn,'named-connections');nc=sub(ncs,'named-connection',caption='landcover',name=C)
sub(nc,'connection',**{'class':'textscan','directory':'data','filename':'landcover.csv','password':'','server':''})
relation=E.Element('relation',{'connection':C,'name':'landcover.csv','table':'[landcover#csv]','type':'table'})
cols=sub(relation,'columns',**{'character-set':'UTF-8','header':'yes','locale':'en_AU','separator':','})
for i,(key,dtype) in enumerate(fields.items()):sub(cols,'column',datatype=dtype,name=key,ordinal=str(i))
conn.append(deepcopy(relation))
# Native metadata record scaffold, with field types/positions rewritten for the new input.
oldrecords=base.find('datasources')[1].find('connection/metadata-records');records=sub(conn,'metadata-records')
cap=deepcopy(oldrecords[0]);cap.find('parent-name').text='[landcover.csv]';records.append(cap)
oldcol=oldrecords.find("metadata-record[@class='column']")
for i,(key,dtype) in enumerate(fields.items()):
 rec=deepcopy(oldcol)
 values={'remote-name':key,'remote-type':str({'string':129,'integer':20,'real':5}[dtype]),'local-name':f'[{key}]','parent-name':'[landcover.csv]','remote-alias':key,'ordinal':str(i),'local-type':dtype,'aggregation':'Sum' if dtype in ['integer','real'] else 'Count'}
 for tag,val in values.items():
  node=rec.find(tag)
  if node is not None:node.text=val
 records.append(rec)
sub(ds,'aliases',enabled='yes')
for k in list(calcs)+list(fields):ds.append(column(k))
for k in ['class_label','DisplayClass','AreaSeries']:
 sub(ds,'column-instance',column=f'[{k}]',derivation='None',name=inst(k),pivot='key',type='nominal')
sub(ds,'layout',**{'dim-ordering':'alphabetic','measure-ordering':'alphabetic','show-structure':'true'})
style=sub(ds,'style');sr=sub(style,'style-rule',element='mark');enc=sub(sr,'encoding',attr='color',field=inst('class_label'),type='palette')
colours=['#555b54','#8a9087','#a58c78','#c6be85','#c6a352','#7d8f51','#876b4f','#879d6e','#5a8974','#9db56b','#6d995b','#285f47','#759779','#ccc2a8','#9f7b63','#6b9f91','#658da5','#8ab8ad','#3b807d']
group_colours={'Developed / disturbed':'#797d80','Agriculture':'#c3a45b','Plantations / exotic trees':'#90765c','Natural low cover':'#d5cdb4','Open water':'#4f86a0','Wetland vegetation':'#80ada0','Other native vegetation':'#285f47'}
for row,colour in zip(classes,colours):sub(sub(enc,'map',to=colour),'bucket',json.dumps(row['class_label']))
enc=sub(sr,'encoding',attr='color',field=inst('DisplayClass'),type='palette')
for label,colour in [(display_text(r['class_label']),c) for r,c in zip(classes,colours)]+list(group_colours.items()):sub(sub(enc,'map',to=colour),'bucket',json.dumps(label))
enc=sub(sr,'encoding',attr='color',field=inst('AreaSeries'),type='palette')
# Assign by comparison slot, matching the local R history chart for every unit.
for prefix,colour in [('Main | ','#285f47'),('Pin 1 | ','#b47737'),('Pin 2 | ','#6c7896'),('Pin 3 | ','#9b6670')]:
 for i in range(1,1054):sub(sub(enc,'map',to=colour),'bucket',json.dumps(prefix+f'Unit {i}'))
pdep=sub(ds,'datasource-dependencies',datasource='Parameters')
for k in params:pdep.append(parameter(k,False))
og=sub(ds,'object-graph');obj=sub(sub(og,'objects'),'object',caption='landcover.csv',id=OBJ);sub(obj,'properties',context='').append(deepcopy(relation))
worksheets=sub(root,'worksheets')
def sheet(name,title,filters,mark,rows,cols,colour,lod=(),fixed_axis=True):
 w=sub(worksheets,'worksheet',name=name);fmt=sub(sub(sub(w,'layout-options'),'title'),'formatted-text');sub(fmt,'run',title,bold='true',fontsize='13',fontname='Segoe UI',fontcolor='#203c32')
 table=sub(w,'table');view=sub(table,'view');sources=sub(view,'datasources');sub(sources,'datasource',caption='Victoria land cover by SMP summary area',name=S);sub(sources,'datasource',name='Parameters')
 dep=sub(view,'datasource-dependencies',datasource='Parameters')
 for k in params:dep.append(parameter(k,False))
 dep=sub(view,'datasource-dependencies',datasource=S)
 for k in list(calcs)+list(fields):dep.append(column(k))
 for k in list(calcs)+list(fields):sub(dep,'column-instance',column=f'[{k}]',derivation=derivation(k),name=inst(k),pivot='key',type='quantitative' if numeric(k) else 'nominal')
 for k in filters:
  f=sub(view,'filter',**{'class':'categorical','column':ref(k)});sub(f,'groupfilter',function='member',level=inst(k),member='true')
 slices=sub(view,'slices')
 for k in filters:sub(slices,'column',ref(k))
 sub(view,'aggregation',value='true')
 style=sub(table,'style')
 for element in ['gridline','zeroline']:
  rule=sub(style,'style-rule',element=element)
  sub(rule,'format',attr='line-visibility',value='on')
  sub(rule,'format',attr='color',value='#dedfd8' if element=='gridline' else '#89988d')
  sub(rule,'format',attr='line-pattern',value='solid')
 if fixed_axis:
  axis=sub(style,'style-rule',element='axis');sub(axis,'encoding',attr='space',**{'class':'0','field':ref('share_pct'),'field-type':'quantitative','max':'100.0','min':'0.0','range-type':'fixed','scope':'rows' if rows==ref('share_pct') else 'cols','type':'space'})
 # A bar view's automatic axis includes zero and fits the displayed class values.
 pane=sub(sub(table,'panes'),'pane',**{'selection-relaxation-option':'selection-relaxation-allow'});sub(sub(pane,'view'),'breakdown',value='auto');sub(pane,'mark',**{'class':mark});enc=sub(pane,'encodings');sub(enc,'color',column=ref(colour))
 for k in lod:sub(enc,'lod',column=ref(k))
 for k in ['area_ha','coverage_pct','unclassified_area_ha','nodata_area_ha']:sub(enc,'tooltip',column=ref(k))
 rule=sub(style,'style-rule',element='worksheet');sub(rule,'format',attr='font-family',value='Segoe UI');sub(rule,'format',attr='font-size',value='11')
 sub(rule,'format',attr='background-color',value='#f7f6f1')
 if name=='T03_EndpointComparison':
  sub(enc,'path',column=ref('epoch_label'))
  sub(enc,'text',column=ref('share_pct'))
 if name in ['T03_EndpointComparison','T04_NetChange']:
  rule=sub(style,'style-rule',element='mark');sub(rule,'format',attr='mark-labels-show',value='true')
 if name=='T04_NetChange':
  axis=sub(style,'style-rule',element='axis')
  sub(axis,'encoding',attr='space',**{'class':'0','field':ref('ChangePP'),'field-type':'quantitative','max':'100.0','min':'-100.0','major-origin':'0.0','major-spacing':'50.0','minor-show':'false','range-type':'fixed','scope':'cols','type':'space'})
  for k in ['EarlierShare','LaterShare','ChangePP']:sub(enc,'tooltip',column=ref(k))
  sub(enc,'text',column=ref('ChangeLabel'))
  # A single row aggregates exactly the two scoped endpoint records.
  tip=sub(sub(pane,'customized-tooltip'),'formatted-text')
  for label,k in [('Area','unit_label'),('Earlier cover','EarlierShare'),('Later cover','LaterShare'),('Change (percentage points)','ChangePP')]:sub(tip,'run',label+': <'+ref(k)+'>\n',fontsize='11')
  rule=sub(sub(pane,'style'),'style-rule',element='mark');sub(rule,'format',attr='size',value='1.8350828886032104')
 if name=='T02_ClassTrajectories':
  axis=sub(style,'style-rule',element='axis');sub(axis,'format',attr='title',**{'class':'0','field':ref('TrendValue'),'scope':'rows','value':'Cover share (%)'})
  sub(enc,'text',column=ref('unit_label'))
  rule=sub(sub(pane,'style'),'style-rule',element='mark')
  for attr,value in [('mark-labels-show','true'),('mark-labels-mode','line-ends'),('mark-labels-line-first','false'),('mark-labels-cull','true')]:sub(rule,'format',attr=attr,value=value)
 sub(table,'rows',rows);sub(table,'cols',cols);sid(w);return w
sheet('T01_Composition','Composition of the selected area',['FocusMatch','FocusViewMatch'],'Bar',ref('share_pct'),ref('EpochDisplay'),'DisplayClass',['microID'],fixed_axis=False)
sheet('T02_ClassTrajectories','Selected cover through time',['CompareMatch','ClassMatch'],'Line',ref('TrendValue'),ref('EpochDisplay'),'AreaSeries',['microID','class_label','unit_label'],fixed_axis=False)
sheet('T04_NetChange','Change between selected periods',['CompareMatch','ClassMatch','EndpointMatch'],'Circle',ref('AreaSeries'),ref('ChangePP'),'AreaSeries',['microID','class_label'],fixed_axis=False)
# Shiny owns area/class/date selection. Tableau retains presentation controls.
WIDTH,HEIGHT=1180,1240

dash=sub(sub(root,'dashboards'),'dashboard',**{'enable-sort-zone-taborder':'true','name':'LandscapeChange'})
sub(dash,'style');sub(dash,'size',maxheight=str(HEIGHT),maxwidth=str(WIDTH),minheight=str(HEIGHT),minwidth=str(WIDTH))
sub(sub(dash,'datasources'),'datasource',name='Parameters');dep=sub(dash,'datasource-dependencies',datasource='Parameters')
for k in params:dep.append(parameter(k))
z=sub(sub(dash,'zones'),'zone',h='100000',id='1',**{'type-v2':'layout-basic','w':'100000','x':'0','y':'0'})
def zone(id,x,y,w,h,kind=None,**attrs):
 if kind:attrs['type-v2']=kind
 if kind=='color':attrs['leg-item-layout']='vert'
 return sub(z,'zone',id=str(id),x=str(round(x/WIDTH*100000)),y=str(round(y/HEIGHT*100000)),w=str(round(w/WIDTH*100000)),h=str(round(h/HEIGHT*100000)),**attrs)
def paint(n,bg='#f7f6f1',margin=4):
 st=sub(n,'zone-style')
 for k,v in [('background-color',bg),('border-style','none'),('border-width','0'),('margin',str(margin)),('font-family','Segoe UI'),('font-size','11'),('color','#203c32')]:sub(st,'format',attr=k,value=v)
 return n
def textzone(id,x,y,w,h,text,size=11,bold=False,bg='#f7f6f1',ink='#203c32'):
 n=zone(id,x,y,w,h,'text');fmt=sub(n,'formatted-text')
 sub(fmt,'run',text,fontsize=str(size),bold='true' if bold else 'false',fontname='Georgia' if size>=18 else 'Segoe UI',fontcolor=ink)
 return paint(n,bg,6)

def parametertext(id,x,y,w,h,parts,size=11,bold=False):
 n=zone(id,x,y,w,h,'text');fmt=sub(n,'formatted-text')
 for kind,value in parts:
  run=sub(fmt,'run',fontsize=str(size),bold='true' if bold else 'false',fontname='Georgia' if size>=18 else 'Segoe UI',fontcolor='#203c32')
  if kind=='text':run.text=value
  else:run.text=f'<[Parameters].[{value}]>'
 return paint(n,margin=6)
def control(id,key,x,y,w):
 return paint(zone(id,x,y,w,64,'paramctrl',param=f'[Parameters].[{key}]',mode='compact'),margin=3)
textzone(90,0,0,WIDTH,HEIGHT,'')
parametertext(2,12,8,1156,44,[('param','LandClass')],22,True)
textzone(3,12,54,1156,30,'Historical land cover | Victoria | seven periods from 1985 to 2019',11)
textzone(4,12,118,724,34,'01   Selected cover through time',14,True)
control(18,'TrendMode',820,96,342)
paint(zone(21,18,166,930,300,name='T02_ClassTrajectories',**{'show-title':'false'}),margin=6)
paint(zone(41,966,166,196,300,'color',name='T02_ClassTrajectories',param=ref('AreaSeries')),margin=6)
textzone(5,12,476,1156,30,'Baseline change is measured from each area\'s first period. All seven periods stay visible.',10,ink='#5b675e')
parametertext(6,12,534,724,34,[('text','02   Land cover composition | '),('param','FocusArea')],14,True)
control(14,'FocusView',820,512,342)
paint(zone(20,18,584,806,254,name='T01_Composition',**{'show-title':'false'}),margin=6)
paint(zone(40,842,584,320,254,'color',name='T01_Composition',param=ref('DisplayClass')),margin=6)
parametertext(7,12,864,1156,34,[('text','03   Change between '),('param','StartEpoch'),('text',' and '),('param','EndEpoch')],14,True)
textzone(8,12,900,1156,30,'Later minus earlier, in percentage points. Fixed -100 to +100 scale; hover for both endpoint percentages.',10,ink='#5b675e')
paint(zone(23,18,938,1144,230,name='T04_NetChange',**{'show-title':'false'}),margin=6)
textzone(9,12,1184,1156,28,'Source: DEECA, Victorian Land Cover Time Series (2020), CC BY 4.0. Shares exclude missing and unclassified land.',9,ink='#5b675e')
textzone(19,12,1210,1156,28,'Areas overlap; do not add hectares. Land cover change does not measure habitat quality. Definitions and limitations are in Sources & methods.',9,ink='#5b675e')
sid(dash)
windows=sub(root,'windows',**{'source-height':'30'})
for name in ['T01_Composition','T02_ClassTrajectories','T04_NetChange']:
 win=deepcopy(base.find('windows/window'));win.set('name',name)
 for node in win.findall('simple-id'):win.remove(node)
 sid(win);windows.append(win)
win=sub(windows,'window',**{'class':'dashboard','maximized':'true','name':'LandscapeChange'});vps=sub(win,'viewpoints')
for name in ['T01_Composition','T02_ClassTrajectories','T04_NetChange']:sub(sub(vps,'viewpoint',name=name),'zoom',type='entire-view')
sub(win,'active',id='-1');sid(win)
# Native Tableau 2026.2 dynamic-axis graph, tied to this build's worksheet UUID.
graph=E.parse(ROOT/'scripts/tableau_axis_title.xml').getroot()
graph.find('.//axis-title-node').set('sheet-identifier',worksheets.find("worksheet[@name='T02_ClassTrajectories']/simple-id").attrib['uuid'])
root.append(graph)
E.indent(root,space='  ')
path=T/(args.output_name+'.twb');E.ElementTree(root).write(path,encoding='utf-8',xml_declaration=True)
with zipfile.ZipFile(T/(args.output_name+'.twbx'),'w',zipfile.ZIP_DEFLATED) as z:
 z.write(path,path.name);z.write(T/'data/landcover.csv','data/landcover.csv')
print('Built',path)
