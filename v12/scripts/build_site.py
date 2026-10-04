#!/usr/bin/env python3
"""Builds the GitHub Pages site (../docs) from web/ + sw/programs + regression results."""
import glob, json, os, re, shutil, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOCS = os.path.join(os.path.dirname(ROOT), 'docs') if len(sys.argv) < 2 else sys.argv[1]
A = os.path.join(DOCS, 'assets')
os.makedirs(A, exist_ok=True)

shutil.copy(os.path.join(ROOT, 'web', 'index.html'), os.path.join(DOCS, 'index.html'))
for f in ('style.css', 'app.js', 'mips-core.js'):
    shutil.copy(os.path.join(ROOT, 'web', f), os.path.join(A, f))
open(os.path.join(DOCS, '.nojekyll'), 'w').close()

progs = []
for p in sorted(glob.glob(os.path.join(ROOT, 'sw', 'programs', '*.s'))):
    src = open(p).read()
    first = src.splitlines()[0].lstrip('# ').strip()
    m = re.match(r'(\d+)\s*-\s*([^:]+)(?::\s*(.*))?', first)
    num, title, desc = (m.group(1), m.group(2).strip(), (m.group(3) or '').strip()) if m else ('', first, '')
    progs.append(dict(id=os.path.splitext(os.path.basename(p))[0], title=f'{num} · {title}', desc=desc, src=src))
open(os.path.join(A, 'programs.js'), 'w').write('window.PROGRAMS = ' + json.dumps(progs, indent=1) + ';\n')

vj = os.path.join(ROOT, 'web', 'verification.json')
open(os.path.join(A, 'verification.js'), 'w').write('window.VERIF = ' + open(vj).read() + ';\n')
print('site written to', DOCS)
