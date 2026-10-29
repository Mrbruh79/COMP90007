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
 'FocusArea':('Focus area','unit668',units),
 'Compare1':('Compare area 1','unit375',['']+units),
 'Compare2':('Compare area 2','',['']+units),
 'Compare3':('Compare area 3','',['']+units),
 'LandClass':('Land-cover class','Treed native vegetation',[r['class_label'] for r in classes]),
 'StartEpoch':('Start epoch',epochs[0]['epoch_label'],[r['epoch_label'] for r in epochs[:-1]]),
 'EndEpoch':('End epoch',epochs[-1]['epoch_label'],[r['epoch_label'] for r in epochs[1:]])}
calcs={
 'FocusMatch':('boolean','[microID] = [Parameters].[FocusArea]'),
 'CompareMatch':('boolean','[microID] = [Parameters].[FocusArea] OR [microID] = [Parameters].[Compare1] OR [microID] = [Parameters].[Compare2] OR [microID] = [Parameters].[Compare3]'),
 'ClassMatch':('boolean','[class_label] = [Parameters].[LandClass]'),
 'EndpointMatch':('boolean','INT(LEFT([Parameters].[StartEpoch],4)) < INT(LEFT([Parameters].[EndEpoch],4)) AND ([epoch_label] = [Parameters].[StartEpoch] OR [epoch_label] = [Parameters].[EndEpoch])'),
 'IntervalRole':('string','IF [epoch_label] = [Parameters].[StartEpoch] THEN "Start epoch" ELSEIF [epoch_label] = [Parameters].[EndEpoch] THEN "End epoch" ELSE "Intermediate epoch" END')}
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
 e=E.Element('column',{'caption':{'share_pct':'Share of classified area (%)','unit_label':'Summary area','epoch_label':'Historical epoch','area_ha':'Projected grid hectares','coverage_pct':'Classified coverage (%)'}.get(key,key.replace('_',' ').capitalize()),'datatype':dtype,'name':f'[{key}]','role':'measure' if numeric else 'dimension','type':'quantitative' if numeric else 'nominal'})
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
def sheet(name,title,filters,mark,rows,cols,colour,lod=()):
 w=sub(worksheets,'worksheet',name=name);fmt=sub(sub(sub(w,'layout-options'),'title'),'formatted-text');sub(fmt,'run',title,bold='true',fontsize='12')
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
 style=sub(table,'style');axis=sub(style,'style-rule',element='axis');sub(axis,'encoding',attr='space',**{'class':'0','field':ref('share_pct'),'field-type':'quantitative','max':'100.0','min':'0.0','range-type':'fixed','scope':'rows' if rows==ref('share_pct') else 'cols','type':'space'})
 if colour=='class_label':
  rule=sub(style,'style-rule',element='mark');ce=sub(rule,'encoding',attr='color',field=ref('class_label'),type='palette')
  for row,col in zip(classes,colours):sub(sub(ce,'map',to=col),'bucket',json.dumps(row['class_label']))
 pane=sub(sub(table,'panes'),'pane',**{'selection-relaxation-option':'selection-relaxation-allow'});sub(sub(pane,'view'),'breakdown',value='auto');sub(pane,'mark',**{'class':mark});enc=sub(pane,'encodings');sub(enc,'color',column=ref(colour))
 for k in lod:sub(enc,'lod',column=ref(k))
 for k in ['area_ha','coverage_pct','unclassified_area_ha','nodata_area_ha']:sub(enc,'tooltip',column=ref(k))
 sub(table,'rows',rows);sub(table,'cols',cols);sid(w);return w
sheet('T01_Composition','Focused area | composition across seven historical epochs (%)',['FocusMatch'],'Bar',ref('share_pct'),ref('epoch_label'),'class_label',['class_label','microID'])
sheet('T02_ClassTrajectories','Selected class | share by focused and comparison area (%)',['CompareMatch','ClassMatch'],'Line',ref('share_pct'),ref('epoch_label'),'unit_label',['microID','class_label'])
sheet('T03_EndpointComparison','Selected class | start and end epochs (%)',['CompareMatch','ClassMatch','EndpointMatch'],'Circle',ref('unit_label'),ref('share_pct'),'IntervalRole',['epoch_label','microID','class_label'])
dash=sub(sub(root,'dashboards'),'dashboard',**{'enable-sort-zone-taborder':'true','name':'LandscapeChange'});sub(dash,'style');sub(dash,'size',maxheight='1200',maxwidth='1200',minheight='1200',minwidth='1200');sub(sub(dash,'datasources'),'datasource',name='Parameters');dep=sub(dash,'datasource-dependencies',datasource='Parameters')
for k in params:dep.append(parameter(k))
z=sub(sub(dash,'zones'),'zone',h='100000',id='1',**{'type-v2':'layout-basic','w':'100000','x':'0','y':'0'})
header=sub(z,'zone',h='9000',id='2',**{'type-v2':'text','w':'98000','x':'1000','y':'700'});fmt=sub(header,'formatted-text');sub(fmt,'run','Victoria | conservation priorities and historical land cover\n',bold='true',fontsize='16');sub(fmt,'run','Source: State of Victoria / DEECA, Victorian Land Cover Time Series (2020), CC BY 4.0. Seven multi-year epochs; first file labels 1985-1990. Shares use classified area only. Units overlap and must not be summed. Land cover is not habitat condition or evidence of management outcomes.',fontsize='10')
for i,k in enumerate(['FocusArea','LandClass','StartEpoch','EndEpoch']):sub(z,'zone',h='6000',id=str(10+i),**{'type-v2':'paramctrl','param':f'[Parameters].[{k}]','w':'24000','x':str(1000+24500*i),'y':'10000'})
for i,k in enumerate(['Compare1','Compare2','Compare3']):sub(z,'zone',h='5000',id=str(14+i),**{'type-v2':'paramctrl','param':f'[Parameters].[{k}]','w':'32000','x':str(1000+33000*i),'y':'16000'})
for i,(name,x,y,w,h) in enumerate([('T01_Composition',1000,23000,69000,38000),('T02_ClassTrajectories',1000,63000,59000,30000),('T03_EndpointComparison',61000,63000,38000,30000)]):
 zone=sub(z,'zone',h=str(h),id=str(20+i),name=name,w=str(w),x=str(x),y=str(y));zs=sub(zone,'zone-style');sub(zs,'format',attr='border-style',value='none');sub(zs,'format',attr='margin',value='4')
sub(z,'zone',h='38000',id='40',name='T01_Composition',w='28000',x='71000',y='23000',**{'type-v2':'color','param':ref('class_label')})
sub(z,'zone',h='3500',id='41',name='T02_ClassTrajectories',w='59000',x='1000',y='95000',**{'type-v2':'color','param':ref('unit_label')})
sub(z,'zone',h='3500',id='42',name='T03_EndpointComparison',w='38000',x='61000',y='95000',**{'type-v2':'color','param':ref('IntervalRole')})
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
