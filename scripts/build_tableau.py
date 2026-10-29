"""Build the local Tableau workbook from a native-validated XML scaffold.
Native Desktop opening/rendering remains a separate required validation step.
"""
from pathlib import Path
from copy import deepcopy
import csv, json, uuid, zipfile, argparse, xml.etree.ElementTree as E
parser=argparse.ArgumentParser();parser.add_argument('--output-name',default='Victoria_Landscape_Change');args=parser.parse_args()
if Path(args.output_name).name != args.output_name: raise ValueError('Use a simple output basename')
ROOT=Path(__file__).resolve().parents[1]
T=ROOT/'tableau'
base=E.parse(ROOT/'scripts/tableau_scaffold.twb').getroot()
manifest=json.loads((T/'data/manifest.json').read_text())
classes=list(csv.DictReader((ROOT/'data/landcover/classes.csv').open()))
epochs=list(csv.DictReader((ROOT/'data/landcover/epochs.csv').open()))
units=['unit'+str(i) for i in range(1,1054)]
S='federated.landcover'; C='textscan.landcover'; OBJ='landcover.csv_2020'
fields={k:('integer' if k in ['epoch_start','epoch_end','class_code'] else 'real' if k in ['area_ha','share_pct','valid_area_ha','coverage_pct','unclassified_area_ha','nodata_area_ha'] else 'string') for k in next(csv.reader((T/'data/landcover.csv').open()))}
params={
 'DataRelease':('Data release',manifest['release'],None),
 'FocusArea':('Main area','unit668',units),
 'FocusView':('Chart 1: what should the bars show?','All cover types',['All cover types','Selected cover type']),
 'Compare1':('Additional area 1 (optional)','unit375',['']+units),
 'Compare2':('Additional area 2 (optional)','',['']+units),
 'Compare3':('Additional area 3 (optional)','',['']+units),
 'LandClass':('Cover type','Treed native vegetation',[r['class_label'] for r in classes]),
 'StartEpoch':('Earlier period',epochs[0]['epoch_label'],[r['epoch_label'] for r in epochs[:-1]]),
 'EndEpoch':('Later period',epochs[-1]['epoch_label'],[r['epoch_label'] for r in epochs[1:]])}
calcs={
 'FocusMatch':('boolean','[microID] = [Parameters].[FocusArea]'),
 'FocusViewMatch':('boolean','[Parameters].[FocusView] = "All cover types" OR [class_label] = [Parameters].[LandClass]'),
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
  for v in values:sub(m,'member',value=json.dumps(v))
 return c
def column(key):
 dtype=fields.get(key,calcs.get(key,('string',))[0]);numeric=dtype in ['real','integer']
 e=E.Element('column',{'caption':{'share_pct':'Land covered (%)','unit_label':'Area','epoch_label':'Historical period','class_label':'Cover type','microID':'Area ID','IntervalRole':'Period being compared','area_ha':'Land covered (hectares)','coverage_pct':'Area with classified data (%)','unclassified_area_ha':'Unclassified land (hectares)','nodata_area_ha':'Missing data (hectares)'}.get(key,key.replace('_',' ').capitalize()),'datatype':dtype,'name':f'[{key}]','role':'measure' if numeric else 'dimension','type':'quantitative' if numeric else 'nominal'})
 if key in calcs:sub(e,'calculation',**{'class':'tableau','formula':calcs[key][1]})
 return e
def inst(key):return f'[{"sum" if fields.get(key) in ["real","integer"] else "none"}:{key}:{"qk" if fields.get(key) in ["real","integer"] else "nk"}]'
def ref(key):return f'[{S}].'+inst(key)
root=E.Element('workbook',base.attrib)
for tag in ['document-format-change-manifest','preferences']:root.append(deepcopy(base.find(tag)))
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
sub(ds,'layout',**{'dim-ordering':'alphabetic','measure-ordering':'alphabetic','show-structure':'true'})
style=sub(ds,'style');sr=sub(style,'style-rule',element='mark');enc=sub(sr,'encoding',attr='color',field=inst('class_label'),type='palette')
colours=['#555b54','#8a9087','#a58c78','#c6be85','#c6a352','#7d8f51','#876b4f','#879d6e','#5a8974','#9db56b','#6d995b','#285f47','#759779','#ccc2a8','#9f7b63','#6b9f91','#658da5','#8ab8ad','#3b807d']
for row,colour in zip(classes,colours):sub(sub(enc,'map',to=colour),'bucket',json.dumps(row['class_label']))
pdep=sub(ds,'datasource-dependencies',datasource='Parameters')
for k in params:pdep.append(parameter(k,False))
og=sub(ds,'object-graph');obj=sub(sub(og,'objects'),'object',caption='landcover.csv',id=OBJ);sub(obj,'properties',context='').append(deepcopy(relation))
worksheets=sub(root,'worksheets')
def sheet(name,title,filters,mark,rows,cols,colour,lod=(),fixed_axis=True):
 w=sub(worksheets,'worksheet',name=name);fmt=sub(sub(sub(w,'layout-options'),'title'),'formatted-text');sub(fmt,'run',title,bold='true',fontsize='14',fontcolor='#193f36')
 table=sub(w,'table');view=sub(table,'view');sources=sub(view,'datasources');sub(sources,'datasource',caption='Victoria land cover by SMP summary area',name=S);sub(sources,'datasource',name='Parameters')
 dep=sub(view,'datasource-dependencies',datasource='Parameters')
 for k in params:dep.append(parameter(k,False))
 dep=sub(view,'datasource-dependencies',datasource=S)
 for k in list(calcs)+list(fields):dep.append(column(k))
 for k in list(calcs)+list(fields):sub(dep,'column-instance',column=f'[{k}]',derivation='Sum' if fields.get(k) in ['real','integer'] else 'None',name=inst(k),pivot='key',type='quantitative' if fields.get(k) in ['real','integer'] else 'nominal')
 for k in filters:
  f=sub(view,'filter',**{'class':'categorical','column':ref(k)});sub(f,'groupfilter',function='member',level=inst(k),member='true')
 slices=sub(view,'slices')
 for k in filters:sub(slices,'column',ref(k))
 sub(view,'aggregation',value='true')
 style=sub(table,'style')
 if fixed_axis:
  axis=sub(style,'style-rule',element='axis');sub(axis,'encoding',attr='space',**{'class':'0','field':ref('share_pct'),'field-type':'quantitative','max':'100.0','min':'0.0','range-type':'fixed','scope':'rows' if rows==ref('share_pct') else 'cols','type':'space'})
 # A bar view's automatic axis includes zero and fits the displayed class values.
 if colour=='class_label':
  rule=sub(style,'style-rule',element='mark');ce=sub(rule,'encoding',attr='color',field=ref('class_label'),type='palette')
  for row,col in zip(classes,colours):sub(sub(ce,'map',to=col),'bucket',json.dumps(row['class_label']))
 pane=sub(sub(table,'panes'),'pane',**{'selection-relaxation-option':'selection-relaxation-allow'});sub(sub(pane,'view'),'breakdown',value='auto');sub(pane,'mark',**{'class':mark});enc=sub(pane,'encodings');sub(enc,'color',column=ref(colour))
 for k in lod:sub(enc,'lod',column=ref(k))
 for k in ['area_ha','coverage_pct','unclassified_area_ha','nodata_area_ha']:sub(enc,'tooltip',column=ref(k))
 sub(table,'rows',rows);sub(table,'cols',cols);sid(w);return w
sheet('T01_Composition','1. What covers the main area?',['FocusMatch','FocusViewMatch'],'Bar',ref('share_pct'),ref('epoch_label'),'class_label',['class_label','microID'],fixed_axis=False)
sheet('T02_ClassTrajectories','2. How did the chosen cover type change over time?',['CompareMatch','ClassMatch'],'Line',ref('share_pct'),ref('epoch_label'),'unit_label',['microID','class_label'])
sheet('T03_EndpointComparison','3. Did the chosen cover type increase or decrease?',['CompareMatch','ClassMatch','EndpointMatch'],'Circle',ref('unit_label'),ref('share_pct'),'IntervalRole',['epoch_label','microID','class_label'])
# Pixel-based dashboard grid: controls at left, three reading tasks at right.
WIDTH,HEIGHT=1400,1660
dash=sub(sub(root,'dashboards'),'dashboard',**{'enable-sort-zone-taborder':'true','name':'LandscapeChange'})
sub(dash,'style');sub(dash,'size',maxheight=str(HEIGHT),maxwidth=str(WIDTH),minheight=str(HEIGHT),minwidth=str(WIDTH))
sub(sub(dash,'datasources'),'datasource',name='Parameters');dep=sub(dash,'datasource-dependencies',datasource='Parameters')
for k in params:dep.append(parameter(k))
z=sub(sub(dash,'zones'),'zone',h='100000',id='1',**{'type-v2':'layout-basic','w':'100000','x':'0','y':'0'})
def zone(id,x,y,w,h,kind=None,**attrs):
 if kind:attrs['type-v2']=kind
 return sub(z,'zone',id=str(id),x=str(round(x/WIDTH*100000)),y=str(round(y/HEIGHT*100000)),w=str(round(w/WIDTH*100000)),h=str(round(h/HEIGHT*100000)),**attrs)
def paint(n,bg='#ffffff',margin=8):
 st=sub(n,'zone-style')
 for k,v in [('background-color',bg),('border-style','none'),('border-width','0'),('margin',str(margin))]:sub(st,'format',attr=k,value=v)
 return n
def textzone(id,x,y,w,h,title='',body='',bg='#ffffff',ink='#193f36',size=16):
 n=zone(id,x,y,w,h,'text');fmt=sub(n,'formatted-text')
 if title:sub(fmt,'run',title+('\n' if body else ''),bold='true',fontsize=str(size),fontcolor=ink)
 if body:sub(fmt,'run',body,fontsize='11',fontcolor=('#e2eee8' if bg=='#193f36' else '#495d56'))
 return paint(n,bg,12)
# Background panels are placed first so all controls and charts remain foreground.
textzone(90,0,0,1400,1660,bg='#eef2ef')
textzone(91,24,154,278,1020,bg='#e2ebe5')
textzone(92,322,154,1054,600)
textzone(93,322,774,1054,400)
textzone(94,322,1194,1054,310)
textzone(95,24,1194,278,310,bg='#e2ebe5')
textzone(2,0,0,1400,130,'VICTORIA  /  LANDSCAPE CHANGE',
 'See what covers an area, follow its history, and compare it with other areas.\nSeven mapped periods  |  1985–1990 to 2015–2019  |  19 cover types',bg='#193f36',ink='#ffffff',size=25)
textzone(3,40,170,246,76,'Choose your areas','Area + cover type.',bg='#e2ebe5')
def control(id,key,x,y,w=246):
 paint(zone(id,x,y,w,64,'paramctrl',param=f'[Parameters].[{key}]',mode='compact'),'#ffffff',8)
control(10,'FocusArea',40,252)
control(11,'LandClass',40,330)
textzone(8,40,414,246,78,'Add comparisons','Leave unused slots blank.',bg='#e2ebe5',size=14)
for i,k in enumerate(['Compare1','Compare2','Compare3']):control(14+i,k,40,502+78*i)
textzone(9,40,760,246,170,'What does the % mean?',
 '40% = 40 of every 100 classified hectares.\n\nunit668 is an area ID, not a rank.',bg='#e2ebe5',size=14)
textzone(18,40,956,246,180,'Small categories',
 'Chart 1: choose Selected cover type to enlarge small values.\n\nCheck its adjusted scale. Charts 2 and 3 stay at 0–100%.',bg='#e2ebe5',size=14)
control(17,'FocusView',342,172,380)
textzone(4,742,172,610,94,'Read the bars',
 'One bar per period. Colours identify cover types. All cover types totals 100%; Selected cover type uses an adjusted scale.',size=14)
textzone(5,342,794,1008,70,'',
 'READ THE LINES  •  Each colour identifies an area. A rising line means the selected cover type occupies a larger share of classified land. All seven periods are shown.',size=16)
textzone(6,342,1214,1008,70,'',
 'READ THE DOTS  •  Each row is an area. Later dot to the right = increase; to the left = decrease. Overlapping dots mean equal or very close values.',size=16)
textzone(19,40,1210,246,80,'Chart 3 periods','Earlier and later maps.',bg='#e2ebe5',size=14)
control(12,'StartEpoch',40,1290)
control(13,'EndEpoch',40,1368)
textzone(23,40,1444,246,48,body='Choose the earlier period first.',bg='#e2ebe5')
for i,(name,x,y,w,h) in enumerate([('T01_Composition',342,282,652,450),('T02_ClassTrajectories',342,874,820,276),('T03_EndpointComparison',342,1294,820,188)]):
 paint(zone(20+i,x,y,w,h,name=name))
for id,name,key,x,y,w,h in [(40,'T01_Composition','class_label',1006,282,346,450),(41,'T02_ClassTrajectories','unit_label',1178,874,174,276),(42,'T03_EndpointComparison','IntervalRole',1178,1294,174,188)]:
 paint(zone(id,x,y,w,h,'color',name=name,param=ref(key)))
textzone(7,24,1524,1352,120,'About the data',
 'Percentages exclude missing and unclassified land; hover for hectares and data coverage. A change from 30% to 35% is +5 percentage points. Areas may overlap: do not add their hectares.\nSource: State of Victoria / DEECA, Victorian Land Cover Time Series (2020), CC BY 4.0. Multi-year maps, not annual measurements. First file: 1985–1990 (catalogue: 1987–1990). Historical cover does not measure habitat health or prove that management worked.',bg='#eef2ef',size=13)
sid(dash)
windows=sub(root,'windows',**{'source-height':'30'})
for name in ['T01_Composition','T02_ClassTrajectories','T03_EndpointComparison']:
 win=deepcopy(base.find('windows/window'));win.set('name',name)
 for node in win.findall('simple-id'):win.remove(node)
 sid(win);windows.append(win)
win=sub(windows,'window',**{'class':'dashboard','maximized':'true','name':'LandscapeChange'});vps=sub(win,'viewpoints')
for name in ['T01_Composition','T02_ClassTrajectories','T03_EndpointComparison']:sub(sub(vps,'viewpoint',name=name),'zoom',type='entire-view')
sub(win,'active',id='-1');sid(win)
E.indent(root,space='  ')
path=T/(args.output_name+'.twb');E.ElementTree(root).write(path,encoding='utf-8',xml_declaration=True)
with zipfile.ZipFile(T/(args.output_name+'.twbx'),'w',zipfile.ZIP_DEFLATED) as z:
 z.write(path,path.name);z.write(T/'data/landcover.csv','data/landcover.csv')
print('Built',path)
