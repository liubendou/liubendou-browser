#!/usr/bin/env python3
"""Reuse the exact proxy helpers from the verified v1.5.0 ARM64 release."""
import hashlib
import io
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
URL = 'https://github.com/Cd1s/safarier/releases/download/v1.5.0/Safarier-v1.5.0-macOS-arm64.zip'
SHA256 = '8d1d85483cd2960f4c01d0cf9b35e51e23a62ab50319ed89ed8dddad97a47560'


def main():
    request = urllib.request.Request(URL, headers={'User-Agent': 'Liubendou-Build'})
    with urllib.request.urlopen(request, timeout=180) as response:
        archive = response.read()
    if hashlib.sha256(archive).hexdigest() != SHA256:
        raise SystemExit('The upstream archive SHA-256 does not match the pinned release.')
    with zipfile.ZipFile(io.BytesIO(archive)) as bundle:
        for helper, notices in [('sing-box', ['LICENSE', 'COPYING', 'SOURCE']),
                                ('mieru', ['LICENSE', 'SOURCE'])]:
            target = ROOT / '.build' / helper
            target.mkdir(parents=True, exist_ok=True)
            binary = target / helper
            binary.write_bytes(bundle.read(f'Safarier.app/Contents/Helpers/{helper}'))
            binary.chmod(0o755)
            for notice in notices:
                name = f'Safarier.app/Contents/Resources/ThirdParty/{helper}/{notice}'
                (target / notice).write_bytes(bundle.read(name))
            print(f'Prepared verified {helper} (arm64) and its license notices.')


if __name__ == '__main__':
    main()
