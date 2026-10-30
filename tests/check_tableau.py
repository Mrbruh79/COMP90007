"""Workbook structure/data checks; native rendering is a separate validation."""
import argparse,csv,gzip,hashlib,json,zipfile,xml.etree.ElementTree as E
import re
from collections import defaultdict
from pathlib import Path
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--workbook-name',default='Victoria_Landscape_Change');args=parser.parse_args()
assert Path(args.workbook_name).name==args.workbook_name
t=root/'tableau';m=json.loads((t/'data/manifest.json').read_text())
assert hashlib.md5((t/'data/landcover.csv').read_bytes()).hexdigest()==m['chart_input_md5']
with (t/'data/landcover.csv').open() as f: rows=list(csv.DictReader(f))
assert len(rows)==140049
assert len({(r['microID'],r['epoch_id'],r['class_code']) for r in rows})==len(rows)
r=E.parse(t/(args.workbook_name+'.twb')).getroot()
for connection in r.findall(".//connection[@class='textscan']"):
 assert (t/connection.attrib['directory']/connection.attrib['filename']).is_file()
assert [d.attrib['name'] for d in r.findall('dashboards/dashboard')]==['LandscapeChange']
assert {w.attrib['name'] for w in r.findall('worksheets/worksheet')}=={'T01_Composition','T02_ClassTrajectories','T04_NetChange'}
parameters=r.find('datasources/datasource')
assert {c.attrib['caption'] for c in parameters.findall('column')}=={'Trend measure','Data release','Main area','Additional area 1 (optional)','Additional area 2 (optional)','Additional area 3 (optional)','Cover type','Earlier period','Later period','Composition view'}
assert m['release'] in parameters.find("column[@caption='Data release']").attrib['value']
mode=parameters.find("column[@caption='Composition view']")
assert json.loads(mode.attrib['value'])=='Grouped overview'
assert {json.loads(x.attrib['value']) for x in mode.findall('members/member')}=={'Grouped overview','All cover types','Selected cover type'}
for ws in r.findall('worksheets/worksheet'):
 axes=ws.findall("table/style/style-rule[@element='axis']/encoding")
 if ws.attrib['name']=='T01_Composition':
  assert not any(e.attrib.get('max')=='100.0' and e.attrib.get('range-type')=='fixed' for e in axes)
  filters=ws.findall('table/view/filter')
  assert any('FocusMatch' in f.attrib['column'] for f in filters)
  assert any('FocusViewMatch' in f.attrib['column'] for f in filters)
 elif ws.attrib['name']=='T03_EndpointComparison':
  assert any(e.attrib.get('max')=='100.0' and e.attrib.get('min')=='0.0' for e in axes)
assert any(z.attrib.get('param')=='[Parameters].[FocusView]' for z in r.findall('dashboards/dashboard/zones//zone'))
calc=r.find("datasources/datasource[@name='federated.landcover']/column[@name='[FocusViewMatch]']/calculation")
assert calc is not None and 'Selected cover type' in calc.attrib['formula'] and '[Parameters].[LandClass]' in calc.attrib['formula']
text=E.tostring(r,encoding='unicode')
assert not any(s in text for s in ['Biodiversity_2037','target_ha','activity.csv','ProgressOverview'])
with zipfile.ZipFile(t/(args.workbook_name+'.twbx')) as z:
 assert z.testzip() is None
 contents=z.namelist();csvs=[n for n in contents if n.endswith('.csv')];twbs=[n for n in contents if n.endswith('.twb')]
 assert len(csvs)==len(twbs)==1
 assert hashlib.md5(z.read(csvs[0])).hexdigest()==m['chart_input_md5']
 packaged=E.fromstring(z.read(twbs[0]))
 for connection in packaged.findall(".//connection[@class='textscan']"):
  assert (Path(twbs[0]).parent/connection.attrib['directory']/connection.attrib['filename']).as_posix() in contents
 assert packaged.find('dashboards/dashboard').attrib['name']=='LandscapeChange'
for unit in ['unit668','unit375','unit925']:
 x=[r for r in rows if r['microID']==unit and r['class_label']=='Water']
 assert len(x)==7
# Reconcile the Tableau table against independently saved runtime summaries, all rows.
with gzip.open(root/'data/landcover/summary.csv.gz','rt') as f: runtime={(r['microID'],r['epoch_id'],r['class_code']):r for r in csv.DictReader(f)}
assert all(abs(float(r['area_ha'])-float(runtime[(r['microID'],r['epoch_id'],r['class_code'])]['area_ha']))<1e-8 for r in rows)
# The focused composition retains 19 classes, while a selected type retains all seven periods.
focused=[x for x in rows if x['microID']=='unit668']
assert len(focused)==7*19
small=[x for x in focused if x['class_label']=='Built environment']
assert len(small)==7 and 0<max(float(x['share_pct']) for x in small)<.001
assert all(abs(sum(float(x['share_pct']) for x in focused if x['epoch_id']==epoch)-100)<1e-7 for epoch in {x['epoch_id'] for x in focused})
# Every source class maps once into a display group; grouping conserves composition.
source=r.find("datasources/datasource[@name='federated.landcover']")
formula=source.find("column[@name='[DisplayClass]']/calculation").attrib['formula']
mapping={int(code):label for code,label in re.findall(r'WHEN (\d+) THEN "([^"]+)"',formula)}
for code in range(1,20):mapping.setdefault(code,'Other native vegetation')
assert len(set(mapping.values()))==7 and set(mapping)==set(range(1,20))
totals=defaultdict(float)
for row in focused:totals[(row['epoch_id'],mapping[int(row['class_code'])])]+=float(row['share_pct'])
for epoch in {x['epoch_id'] for x in focused}:assert abs(sum(v for (e,g),v in totals.items() if e==epoch)-100)<1e-7
for ws in r.findall('worksheets/worksheet'):
 for key in ['coverage_pct','unclassified_area_ha','nodata_area_ha']:
  assert ws.find(f"table/view/datasource-dependencies/column-instance[@column='[{key}]'][@derivation='Min']") is not None
assert 'FIXED [microID], [class_label]' in source.find("column[@name='[TrendValue]']/calculation").attrib['formula']
annual={x['epoch_id']:float(x['share_pct']) for x in focused if x['class_label']=='Treed native vegetation'}
assert abs((annual['2015_2019']-annual['1985_1990'])-.695)<.01
assert source.find("column[@name='[ChangePP]']/calculation") is not None
print('PASS Tableau data/package, seven-group closure, per-area coverage aggregation, baseline-change reference and three-chart structure')
