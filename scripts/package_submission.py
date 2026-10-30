"""Package the runnable atlas and rebuild sources without development history."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parents[1]
required = [
    'app.R', 'README.md', 'config/app.json', 'data/smp_cache.rds',
    'data/smp_original.rds', 'data/landcover/summary.csv.gz',
    'data/landcover/classes.csv', 'data/landcover/epochs.csv',
    'data/landcover/manifest.json', 'tableau/Victoria_Landscape_Change.twb',
    'tableau/Victoria_Landscape_Change.twbx', 'tableau/data/landcover.csv',
    'tableau/data/manifest.json', 'tableau/README.md', 'docs/SOURCE_NOTES.md',
    'docs/R_PACKAGE_VERSIONS.csv',
]
for name in required:
    if not (ROOT / name).is_file():
        raise SystemExit(f'Missing {name}; prepare the local data/workbook first.')

files = {ROOT / name for name in required}
for name in ['R', 'www', 'scripts', 'tests', 'data/landcover']:
    files.update(p for p in (ROOT / name).rglob('*')
                 if p.is_file() and not any(part.startswith('.') or part == '__pycache__'
                                            for part in p.relative_to(ROOT).parts)
                 and p.suffix not in {'.twbr', '.log', '.png', '.pyc'})
files = sorted(files)
manifest = {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in files}
out = ROOT / 'dist' / 'Victoria_Landscape_Atlas.zip'
out.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, 'Victoria_Landscape_Atlas/' + path.relative_to(ROOT).as_posix())
    archive.writestr('Victoria_Landscape_Atlas/PACKAGE_SHA256.json', json.dumps(manifest, indent=2))
print(f'{out} ({len(files)} files, {out.stat().st_size:,} bytes)')
