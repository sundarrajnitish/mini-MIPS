#!/usr/bin/env python3
"""
Mutation testing: "does the regression actually catch bugs?"

Each mutant injects one realistic design bug into a copy of the RTL (several
of them are exactly the bugs found in v11). The mutant is killed if at least
one program in the regression (directed + constrained-random) fails the
golden-model comparison. A surviving mutant would reveal a hole in the tests.

    python3 sw/mutation_test.py [--random 150]
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
import run_regression as rr                      # noqa: E402
from random_program import gen                  # noqa: E402

MUTANTS = [
    ('no_exmem_fwd', 'EX/MEM -> EX forwarding removed', 'rtl/3_execute/forwarding_unit.vhd',
     'return FWD_EX_MEM;', 'return FWD_NONE;'),
    ('no_memwb_fwd', 'MEM/WB -> EX forwarding removed', 'rtl/3_execute/forwarding_unit.vhd',
     'return FWD_MEM_WB;', 'return FWD_NONE;'),
    ('fwd_priority', 'MEM/WB given priority over EX/MEM (stale value wins)', 'rtl/3_execute/forwarding_unit.vhd',
     "if m_we = '1' and m_d /= REG_ZERO and m_d = src then\n      return FWD_EX_MEM;\n    elsif w_we = '1' and w_d /= REG_ZERO and w_d = src then\n      return FWD_MEM_WB;",
     "if w_we = '1' and w_d /= REG_ZERO and w_d = src then\n      return FWD_MEM_WB;\n    elsif m_we = '1' and m_d /= REG_ZERO and m_d = src then\n      return FWD_EX_MEM;"),
    ('fwd_r0', 'forwarding does not exclude $0 (v11 bug)', 'rtl/3_execute/forwarding_unit.vhd',
     "if m_we = '1' and m_d /= REG_ZERO and m_d = src then", "if m_we = '1' and m_d = src then"),
    ('fwd_no_regwrite', 'forwarding ignores RegWrite (v11 bug)', 'rtl/3_execute/forwarding_unit.vhd',
     "elsif w_we = '1' and w_d /= REG_ZERO and w_d = src then", "elsif w_d /= REG_ZERO and w_d = src then"),
    ('id_fwd_load', 'ID forwarding also forwards a load address', 'rtl/3_execute/forwarding_unit.vhd',
     "if m_we = '1' and m_rd = '0' and", "if m_we = '1' and"),
    ('no_id_fwd', 'MUX E / MUX F never forward', 'rtl/mips_cpu.vhd',
     "id_rs_val <= ex_mem.alu_result when fwd_e = '1' else rf_rd1;", "id_rs_val <= rf_rd1;"),
    ('imm_overridden', 'forwarding MUX placed after ALUSrc MUX (v11 ordering)', 'rtl/mips_cpu.vhd',
     "alu_b <= id_ex.imm when id_ex.ctrl.alu_src = '1' else rt_fwd;",
     "alu_b <= rt_fwd when (fwd_b /= FWD_NONE or id_ex.ctrl.alu_src = '0') else id_ex.imm;"),
    ('store_not_fwd', 'SB store data taken before forwarding (v11 bug)', 'rtl/mips_cpu.vhd',
     "store_data => rt_fwd,", "store_data => id_ex.rt_val,"),
    ('no_load_use', 'load-use interlock removed', 'rtl/2_decode/hazard_unit.vhd',
     "load_use   := ex_mem_read = '1' and", "load_use   := false and"),
    ('no_branch_stall_ex', 'no stall when BEQ/JR operand is still in EX', 'rtl/2_decode/hazard_unit.vhd',
     "((ex_reg_write = '1' and reads", "((false and reads"),
    ('no_branch_stall_mem', 'no second stall when BEQ/JR operand comes from a load', 'rtl/2_decode/hazard_unit.vhd',
     "(mem_mem_read = '1' and reads", "(false and reads"),
    ('no_if_flush', 'wrong-path instruction not flushed', 'rtl/mips_cpu.vhd',
     "write => pc_write, flush => if_flush,", "write => pc_write, flush => '0',"),
    ('no_rf_bypass', 'register file without write-through bypass', 'rtl/2_decode/register_file.vhd',
     "elsif we_i = '1' and wa_i = ra then", "elsif false then"),
    ('r0_writable', '$0 not hard-wired to zero (v11 bug)', 'rtl/2_decode/register_file.vhd',
     "if ra = REG_ZERO then\n      return ZERO_WORD;\n    elsif", "if false then\n      return ZERO_WORD;\n    elsif"),
    ('branch_no_shift', 'branch offset not shifted left by 2 (v11 bug)', 'rtl/2_decode/branch_unit.vhd',
     "shift_left(resize(signed(imm16), 32), 2)", "resize(signed(imm16), 32)"),
    ('sb_full_word', 'SB always writes byte lane 0 (v11 bug)', 'rtl/4_memory/data_memory.vhd',
     "lane := to_integer(unsigned(addr(1 downto 0)));", "lane := 0;"),
    ('andi_sext', 'ANDI sign-extends its immediate', 'rtl/2_decode/control_unit.vhd',
     "c.ext_zero  := '1';", "c.ext_zero  := '0';"),
    ('wb_wrong_data', 'MEM/WB latches store data instead of loaded data (v11 bug)', 'rtl/mips_cpu.vhd',
     "read_data => dmem_rdata,\n", "read_data => ex_mem.store_data,\n"),
    ('dest_always_rd', 'destination is always rd (v11 EX/MEM bug)', 'rtl/mips_cpu.vhd',
     "ex_dest <= id_ex.rd when id_ex.ctrl.reg_dst = '1' else id_ex.rt;", "ex_dest <= id_ex.rd;"),
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--random', type=int, default=150)
    ap.add_argument('--json')
    a = ap.parse_args()
    work = os.path.join(ROOT, 'build', 'mutants')
    shutil.rmtree(work, ignore_errors=True)
    progs = [(os.path.splitext(os.path.basename(p))[0], open(p).read())
             for p in sorted(__import__('glob').glob(os.path.join(ROOT, 'sw', 'programs', '*.s')))]
    progs += [(f'rand_{s}', gen(s, 40)) for s in range(9000, 9000 + a.random)]
    results = []
    for name, desc, rel, old, new in MUTANTS:
        mroot = os.path.join(work, name)
        shutil.copytree(os.path.join(ROOT, 'rtl'), os.path.join(mroot, 'rtl'))
        shutil.copytree(os.path.join(ROOT, 'tb'), os.path.join(mroot, 'tb'))
        shutil.copytree(os.path.join(ROOT, 'scripts'), os.path.join(mroot, 'scripts'))
        p = os.path.join(mroot, rel)
        s = open(p).read()
        if s.count(old) < 1:
            print(f'  !! mutant {name}: pattern not found'); sys.exit(2)
        open(p, 'w').write(s.replace(old, new, 1))
        rr.ROOT, rr.BUILD = mroot, os.path.join(mroot, 'build')
        rr.STD = ['--std=08', f'--workdir={rr.BUILD}']
        rr.compile_rtl()
        killer = None
        for pname, src in progs:
            r = rr.run_one(pname, src, os.path.join(rr.BUILD, 't'))
            if r['status'] == 'FAIL':
                killer = pname
                break
        results.append(dict(mutant=name, description=desc, killed=bool(killer), killed_by=killer))
        print(f"  {'KILLED  ' if killer else 'SURVIVED'} {name:20} {desc:58} {('by ' + killer) if killer else ''}")
    k = sum(r['killed'] for r in results)
    print(f'\nmutation score: {k}/{len(results)}')
    if a.json:
        json.dump(results, open(a.json, 'w'), indent=1)
    shutil.rmtree(work, ignore_errors=True)


if __name__ == '__main__':
    main()
