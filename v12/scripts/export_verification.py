#!/usr/bin/env python3
"""Collects build/regression.json + build/mutation.json into web/verification.json (read by the site)."""
import json, os
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
B = lambda f: os.path.join(ROOT, 'build', f)
reg = json.load(open(B('regression.json')))
mut = json.load(open(B('mutation.json')))
rnd = [r for r in reg if r['name'].startswith('rand_')]
alu = 0
if os.path.exists(B('alu.log')):
    import re
    m = re.search(r'checks=(\d+)', open(B('alu.log')).read())
    alu = int(m.group(1)) if m else 0
js = {'programs': 0, 'cycles': 0}
if os.path.exists(B('jscheck.log')):
    import re
    m = re.search(r'(\d+) programs cycle-exact \((\d+) cycles', open(B('jscheck.log')).read())
    if m:
        js = {'programs': int(m.group(1)), 'cycles': int(m.group(2))}
out = dict(
    directed=[r for r in reg if not r['name'].startswith('rand_')],
    random=dict(n=len(rnd), instructions=sum(r['instructions'] for r in rnd), cycles=sum(r['cycles'] for r in rnd),
                stalls=sum(r['stalls'] for r in rnd), flushes=sum(r['flushes'] for r in rnd),
                cpi=[r['cpi'] for r in rnd]),
    mutation=mut, alu_checks=alu, js_cycles=js['cycles'], js_programs=js['programs'])
json.dump(out, open(os.path.join(ROOT, 'web', 'verification.json'), 'w'))
print('web/verification.json updated')
