#!/usr/bin/env python3
"""
Regression runner: RTL (GHDL) vs golden ISS.

    python3 sw/run_regression.py                 # directed programs + 200 random
    python3 sw/run_regression.py --random 1000   # more random programs
    python3 sw/run_regression.py --keep          # keep per-test traces in build/tests

For every program:
  1. assemble (sw/mips_asm.py)              -> .imem.hex / .dmem.hex
  2. run the golden ISS (sw/mips_iss.py)    -> expected registers + memory
  3. simulate tb_mips in GHDL               -> self-checking PASS / FAIL + trace.csv
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

from mips_asm import assemble, write_outputs          # noqa: E402
from mips_iss import ISS, write_expected              # noqa: E402
from random_program import gen                        # noqa: E402

BUILD = os.path.join(ROOT, 'build')
GHDL = ['ghdl']
STD = ['--std=08', f'--workdir={BUILD}']


def compile_rtl():
    os.makedirs(BUILD, exist_ok=True)
    files = open(os.path.join(ROOT, 'scripts', 'files.txt')).read().split()
    for f in files:
        subprocess.run(GHDL + ['-a'] + STD + [os.path.join(ROOT, f)], check=True,
                       capture_output=True, text=True)
    subprocess.run(GHDL + ['-e'] + STD + ['tb_mips'], check=True, cwd=BUILD,
                   capture_output=True, text=True)


def run_one(name, src, outdir):
    os.makedirs(outdir, exist_ok=True)
    stem = os.path.join(outdir, name)
    res = assemble(src)
    write_outputs(res, stem)
    open(stem + '.s', 'w').write(src)
    iss = ISS([w for _, w, _ in res['text']], res['data'])
    iss.run(20000)
    if not iss.halted:
        return dict(name=name, status='SKIP', why='ISS did not halt')
    write_expected(iss, stem + '.expect')
    cmd = GHDL + ['-r'] + STD + ['tb_mips', '--ieee-asserts=disable',
                                 f'-gIMEM_FILE={stem}.imem.hex', f'-gDMEM_FILE={stem}.dmem.hex',
                                 f'-gEXPECT_FILE={stem}.expect', f'-gTRACE_FILE={stem}.trace.csv',
                                 '-gMAX_CYCLES=100000']
    p = subprocess.run(cmd, cwd=BUILD, capture_output=True, text=True)
    out = p.stdout + p.stderr
    m = re.search(r'TB_RESULT PASS cycles=(\d+) instructions=(\d+)', out)
    if m:
        cyc, ins = int(m.group(1)), int(m.group(2))
        trace = open(stem + '.trace.csv').read().splitlines()[1:-3]   # drop halt drain
        stalls = sum(1 for l in trace if l.split(',')[11] == '1')
        flushes = sum(1 for l in trace if l.split(',')[12] == '1')
        return dict(name=name, status='PASS', cycles=cyc, instructions=ins,
                    cpi=round(cyc / ins, 3), stalls=stalls, flushes=flushes)
    errs = [l for l in out.splitlines() if 'MISMATCH' in l or 'FAIL' in l]
    return dict(name=name, status='FAIL', why='\n'.join(errs[:10]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--random', type=int, default=200)
    ap.add_argument('--seed', type=int, default=1000)
    ap.add_argument('--length', type=int, default=40)
    ap.add_argument('--json', help='write summary JSON here')
    a = ap.parse_args()

    print('compiling RTL ...')
    compile_rtl()
    results = []
    tests = os.path.join(BUILD, 'tests')
    for path in sorted(glob.glob(os.path.join(ROOT, 'sw', 'programs', '*.s'))):
        name = os.path.splitext(os.path.basename(path))[0]
        r = run_one(name, open(path).read(), tests)
        results.append(r)
        print(f"  {r['status']:4}  {name:24} "
              + (f"instr={r['instructions']:4} cycles={r['cycles']:4} CPI={r['cpi']:.3f} "
                 f"stalls={r['stalls']} flushes={r['flushes']}" if r['status'] == 'PASS' else r.get('why', '')))
    for i in range(a.random):
        seed = a.seed + i
        r = run_one(f'rand_{seed}', gen(seed, a.length), os.path.join(tests, 'random'))
        results.append(r)
        if r['status'] != 'PASS':
            print(f"  {r['status']:4}  rand_{seed}  {r.get('why', '')}")
    rnd = [r for r in results if r['name'].startswith('rand_') and r['status'] == 'PASS']
    npass = sum(r['status'] == 'PASS' for r in results)
    nfail = sum(r['status'] == 'FAIL' for r in results)
    print(f'\n{npass} passed, {nfail} failed, {len(results) - npass - nfail} skipped')
    if rnd:
        ins = sum(r['instructions'] for r in rnd)
        cyc = sum(r['cycles'] for r in rnd)
        print(f'random programs: {len(rnd)} runs, {ins} instructions, {cyc} cycles, '
              f'aggregate CPI {cyc / ins:.3f}, stalls {sum(r["stalls"] for r in rnd)}, '
              f'flushes {sum(r["flushes"] for r in rnd)}')
    if a.json:
        json.dump(results, open(a.json, 'w'), indent=1)
    sys.exit(1 if nfail else 0)


if __name__ == '__main__':
    main()
