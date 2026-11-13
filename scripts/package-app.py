#!/usr/bin/env python3
"""Create a UTF-8 ZIP while preserving the executable modes in the app bundle."""
import hashlib
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parent.parent
bundle = root / 'dist' / '六本豆.app'
archive = root / 'dist' / '六本豆-v1.5.0-macOS-arm64.zip'
if not (bundle / 'Contents' / 'MacOS' / 'Liubendou').is_file():
    raise SystemExit('Build 六本豆.app before packaging.')
with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    z.write(bundle, bundle.name + '/')
    for entry in sorted(bundle.rglob('*')):
        if entry.is_symlink():
            raise SystemExit(f'Unexpected symbolic link in app bundle: {entry}')
        z.write(entry, entry.relative_to(bundle.parent).as_posix())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert all(entry.flag_bits & 0x800 for entry in z.infolist()), 'Missing UTF-8 filename flags'
    assert '六本豆.app/Contents/Info.plist' in z.namelist()
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_name(archive.name + '.sha256').write_text(
    f'{digest}  {archive.name}\n', encoding='utf-8')
print(f'Packaged {archive.name}, SHA-256 {digest}')
