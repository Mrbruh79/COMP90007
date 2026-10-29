"""Workbook structure/data checks; native rendering is a separate validation."""
import csv,gzip,hashlib,json,zipfile,xml.etree.ElementTree as E
from pathlib import Path
root=Path(__file__).resolve().parents[1]
t=root/'tableau';m=json.loads((t/'data/manifest.json').read_text())
assert hashlib.md5((t/'data/landcover.csv').read_bytes()).hexdigest()==m['chart_input_md5']
with (t/'data/landcover.csv').open() as f: rows=list(csv.DictReader(f))
assert len(rows)==140049
assert len({(r['microID'],r['epoch_id'],r['class_code']) for r in rows})==len(rows)
r=E.parse(t/'Victoria_Landscape_Change.twb').getroot()
assert [d.attrib['name'] for d in r.findall('dashboards/dashboard')]==['LandscapeChange']
assert len(r.findall('worksheets/worksheet'))==3
parameters=r.find('datasources/datasource')
assert {c.attrib['caption'] for c in parameters.findall('column')}=={'Data release','Focus area','Compare area 1','Compare area 2','Compare area 3','Land-cover class','Start epoch','End epoch'}
assert m['release'] in parameters.find("column[@caption='Data release']").attrib['value']
for ws in r.findall('worksheets/worksheet'):
 assert ws.find("table/style/style-rule[@element='axis']/encoding").attrib['max']=='100.0'
text=E.tostring(r,encoding='unicode')
assert not any(s in text for s in ['Biodiversity_2037','target_ha','activity.csv','ProgressOverview'])
with zipfile.ZipFile(t/'Victoria_Landscape_Change.twbx') as z:
 assert z.testzip() is None
 contents=z.namelist();csvs=[n for n in contents if n.endswith('.csv')];twbs=[n for n in contents if n.endswith('.twb')]
 assert len(csvs)==len(twbs)==1
 assert hashlib.md5(z.read(csvs[0])).hexdigest()==m['chart_input_md5']
 packaged=E.fromstring(z.read(twbs[0]));assert packaged.find('dashboards/dashboard').attrib['name']=='LandscapeChange'
for unit in ['unit668','unit375','unit925']:
 x=[r for r in rows if r['microID']==unit and r['class_label']=='Water']
 assert len(x)==7
# Reconcile the Tableau table against independently saved runtime summaries, all rows.
with gzip.open(root/'data/landcover/summary.csv.gz','rt') as f: runtime={(r['microID'],r['epoch_id'],r['class_code']):r for r in csv.DictReader(f)}
assert all(abs(float(r['area_ha'])-float(runtime[(r['microID'],r['epoch_id'],r['class_code'])]['area_ha']))<1e-8 for r in rows)
print('PASS Tableau keys, 140049 row reconciliation, parameters, fixed scales, new dashboard identity and packaged CSV integrity')
