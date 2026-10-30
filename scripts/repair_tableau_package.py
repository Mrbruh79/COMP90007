"""Restore the frozen CSV connection in a workbook saved with an extract."""
from pathlib import Path, PurePosixPath
import argparse
import hashlib
import json
import os
import shutil
import tempfile
import xml.etree.ElementTree as E
import zipfile

ROOT = Path(__file__).resolve().parents[1]
CSV = ROOT / 'tableau/data/landcover.csv'


def validate_sources(workbook):
    manifest = json.loads((ROOT / 'tableau/data/manifest.json').read_text())
    with zipfile.ZipFile(workbook) as archive:
        names = archive.namelist()
        twbs = [n for n in names if n.endswith('.twb')]
        if len(twbs) != 1 or archive.testzip() is not None:
            raise ValueError('The package must contain one readable workbook.')
        root = E.fromstring(archive.read(twbs[0]))
        release = root.find("datasources/datasource[@name='Parameters']/column[@caption='Data release']")
        if release is None or json.loads(release.get('value')) != manifest['release']:
            raise ValueError('The workbook identifies a different data release.')
        connections = root.findall(".//connection[@class='textscan']")
        if not connections or any(c.get('filename') != 'landcover.csv' for c in connections):
            raise ValueError('The authoring package must retain its landcover.csv source.')
        for connection in connections:
            directory = connection.get('directory', '').replace('\\', '/')
            target = PurePosixPath(twbs[0]).parent / directory / connection.get('filename', '')
            if target.is_absolute() or ':' in directory or '..' in target.parts or target.as_posix() not in names:
                raise ValueError('CSV source is missing or points outside the package. Run scripts/repair_tableau_package.py.')
            if hashlib.md5(archive.read(target.as_posix())).hexdigest() != manifest['chart_input_md5']:
                raise ValueError('The packaged CSV differs from the frozen land cover release.')
        for connection in root.findall(".//connection[@class='hyper']"):
            target = PurePosixPath(twbs[0]).parent / connection.get('dbname', '').replace('\\', '/')
            if target.is_absolute() or ':' in str(target) or '..' in target.parts or target.as_posix() not in names:
                raise ValueError('The extract is missing or points outside the package.')


def repair(source, output):
    source, output = Path(source), Path(output)
    with zipfile.ZipFile(source) as archive:
        contents = {name: archive.read(name) for name in archive.namelist()}
    twbs = [name for name in contents if name.endswith('.twb')]
    if len(twbs) != 1:
        raise ValueError('Expected one workbook in the package.')
    root = E.fromstring(contents[twbs[0]])
    connections = root.findall(".//connection[@class='textscan']")
    if not connections or any(c.get('filename') != 'landcover.csv' for c in connections):
        raise ValueError('This repair only supports the atlas landcover.csv connection.')
    release = root.find("datasources/datasource[@name='Parameters']/column[@caption='Data release']")
    expected = json.loads((ROOT / 'tableau/data/manifest.json').read_text())['release']
    if release is None or json.loads(release.get('value')) != expected:
        raise ValueError('The workbook uses a different data release; no files were changed.')
    for connection in connections:
        connection.set('directory', 'Data/Source')
    contents = {name: data for name, data in contents.items()
                if PurePosixPath(name).name != 'landcover.csv'}
    contents[twbs[0]] = E.tostring(root, encoding='utf-8', xml_declaration=True)
    contents['Data/Source/landcover.csv'] = CSV.read_bytes()
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(dir=output.parent, suffix='.twbx', delete=False) as f:
        temporary = Path(f.name)
    try:
        with zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED) as archive:
            for name, data in contents.items():
                archive.writestr(name, data)
        validate_sources(temporary)
        if source.resolve() == output.resolve():
            backup = Path(tempfile.mkdtemp(prefix='Victoria_workbook_backup_')) / source.name
            shutil.copy2(source, backup)
            print('Original saved to', backup)
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=ROOT / 'tableau/Victoria_Landscape_Change.twbx')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    repair(args.input, args.output)
    print('Repaired and checked', args.output)
