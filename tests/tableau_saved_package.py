"""Exercise the missing-source case after an extract-only native save."""
from pathlib import Path
import hashlib
import sys
import tempfile
import xml.etree.ElementTree as E
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from repair_tableau_package import repair, validate_sources

with tempfile.TemporaryDirectory() as folder:
    source = Path(folder) / 'Extract_only.twbx'
    output = Path(folder) / 'Repaired.twbx'
    root = E.parse(ROOT / 'tableau/Victoria_Landscape_Change.twb').getroot()
    root.find(".//connection[@class='textscan']").set('directory', 'C:/Temp/TableauTemp/expired')
    ds = root.find("datasources/datasource[@name='federated.landcover']")
    E.SubElement(E.SubElement(ds, 'extract'), 'connection', {'class':'hyper', 'dbname':'Data/Existing.hyper'})
    # Archive preservation fixture; this placeholder is not a renderable Hyper database.
    extract = b'existing extract bytes preserved by the archive repair'
    with zipfile.ZipFile(source, 'w') as z:
        z.writestr('Atlas.twb', E.tostring(root))
        z.writestr('Data/Existing.hyper', extract)
    before = hashlib.sha256(source.read_bytes()).hexdigest()
    try:
        validate_sources(source)
        raise AssertionError('The broken source was accepted')
    except ValueError as error:
        assert 'CSV source' in str(error)
    repair(source, output)
    validate_sources(output)
    assert hashlib.sha256(source.read_bytes()).hexdigest() == before
    with zipfile.ZipFile(output) as z:
        assert z.read('Data/Existing.hyper') == extract
        assert z.read('Data/Source/landcover.csv') == (ROOT / 'tableau/data/landcover.csv').read_bytes()
        repaired = E.fromstring(z.read('Atlas.twb'))
        assert E.tostring(repaired.find('dashboards')) == E.tostring(root.find('dashboards'))
        assert E.tostring(repaired.find('worksheets')) == E.tostring(root.find('worksheets'))
print('PASS extract-only save rejected; CSV repaired; source, extract bytes, sheets and layout preserved')
