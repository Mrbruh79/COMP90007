"""Build a local handoff with the frozen cache; no downloads or installations."""
from pathlib import Path
import hashlib, json, zipfile
ROOT = Path(__file__).resolve().parents[1]
required = ['app.R', 'data/smp_cache.rds', 'data/landcover/summary.csv.gz', 'data/smp_original.rds', 'tableau/Victoria_Landscape_Change.twbx']
for name in required:
    if not (ROOT / name).is_file():
        raise SystemExit(f'Missing {name}; prepare the local data/workbook first.')
files = []
for name in ['app.R', 'README.md', 'R', 'www', 'config', 'scripts', 'tests', 'docs', 'tableau', 'data/landcover', 'data/smp_original.rds', 'data/smp_cache.rds']:
    path = ROOT / name
    for item in (path.rglob('*') if path.is_dir() else [path]):
        if item.is_file() and not item.name.startswith('.') and item.suffix not in ['.twbr', '.log', '.png']:
            files.append(item)
files = sorted(set(files))
manifest = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
out = ROOT / 'dist' / 'Victoria_Landscape_Atlas.zip'
out.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, 'Victoria_Landscape_Atlas/' + str(path.relative_to(ROOT)))
    archive.writestr('Victoria_Landscape_Atlas/PACKAGE_SHA256.json', json.dumps(manifest, indent=2))
print(f'{out} ({len(files)} files, {out.stat().st_size:,} bytes)')
