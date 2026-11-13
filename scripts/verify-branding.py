#!/usr/bin/env python3
"""Validate the packaged app's identity, copy and update destination."""
import plistlib
import re
import sys
from pathlib import Path

bundle = Path(sys.argv[1])
contents = bundle / 'Contents'
info = plistlib.loads((contents / 'Info.plist').read_bytes())
assert info['CFBundleDisplayName'] == '六本豆', info
assert info['CFBundleName'] == '六本豆', info
assert info['CFBundleIdentifier'] == 'com.liubendou.browser', info
assert info['CFBundleExecutable'] == 'Liubendou', info
assert (contents / 'MacOS' / info['CFBundleExecutable']).is_file()
assert (contents / 'Resources' / 'AppIcon.icns').stat().st_size > 0
for lang in ['zh-Hans', 'en']:
    path = contents / 'Resources' / f'{lang}.lproj' / 'Localizable.strings'
    text = path.read_text(encoding='utf-8')
    assert '关于 六本豆' in text, lang
    assert not re.search(r'\bSafarier\b', text), lang
binary = (contents / 'MacOS' / 'Liubendou').read_bytes()
assert b'https://api.github.com/repos/liubendou/liubendou-browser/releases/latest' in binary
assert b'https://api.github.com/repos/Cd1s/safarier/releases/latest' not in binary
assert (contents / 'Resources' / 'ThirdParty' / 'NOTICE.md').is_file()
print('Verified 六本豆 identity, Chinese/English branding, icon, update destination and notices.')
