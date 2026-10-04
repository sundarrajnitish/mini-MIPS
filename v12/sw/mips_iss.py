#!/usr/bin/env python3
"""
mini-MIPS golden reference model (instruction-set simulator).

Executes one instruction at a time with no notion of a pipeline. The RTL must
end in exactly the same architectural state (registers + data memory) as this
model for every program -- that is the definition of "correct" used by the
verification flow.

    python3 mips_iss.py prog.s            # prints final state
    python3 mips_iss.py prog.s -e exp.txt # writes the expected-state file for tb_mips
"""
import sys
from mips_asm import assemble, disasm, IMEM_WORDS, DMEM_WORDS, AsmError

M32 = 0xFFFFFFFF


def sext16(x):
    return (x | 0xFFFF0000) if x & 0x8000 else x


class ISS:
    def __init__(self, imem, dmem_words):
        self.imem = list(imem) + [0] * (IMEM_WORDS - len(imem))
        self.mem = [0] * DMEM_WORDS
        for i, w in enumerate(dmem_words):
            self.mem[i] = w
        self.r = [0] * 32
        self.pc = 0
        self.retired = 0
        self.halted = False

    def step(self):
        pc = self.pc
        w = self.imem[(pc >> 2) % IMEM_WORDS]
        op, rs, rt, rd = (w >> 26) & 63, (w >> 21) & 31, (w >> 16) & 31, (w >> 11) & 31
        sh, fn, imm = (w >> 6) & 31, w & 63, w & 0xFFFF
        a, b = self.r[rs], self.r[rt]
        npc = (pc + 4) & M32
        wr = None
        if op == 0:
            if fn == 0b100000:
                wr = (rd, (a + b) & M32)
            elif fn == 0b100111:
                wr = (rd, ~(a | b) & M32)
            elif fn == 0b100110:
                wr = (rd, a ^ b)
            elif fn == 0b000000:
                wr = (rd, (b << sh) & M32)
            elif fn == 0b001000:
                npc = a
        elif op == 0b001100:
            wr = (rt, a & imm)
        elif op == 0b011001:
            wr = (rt, (a - sext16(imm)) & M32)
        elif op == 0b100011:
            addr = (a + sext16(imm)) & M32
            wr = (rt, self.mem[(addr >> 2) % DMEM_WORDS])
        elif op == 0b101000:
            addr = (a + sext16(imm)) & M32
            i, lane = (addr >> 2) % DMEM_WORDS, addr & 3
            self.mem[i] = (self.mem[i] & ~(0xFF << (8 * lane)) & M32) | ((b & 0xFF) << (8 * lane))
        elif op == 0b000100:
            if a == b:
                npc = (pc + 4 + (sext16(imm) << 2)) & M32
        elif op == 0b000010:
            npc = ((pc + 4) & 0xF0000000) | ((w & 0x3FFFFFF) << 2)
            if npc == pc:
                self.halted = True
        if wr and wr[0] != 0:
            self.r[wr[0]] = wr[1]
        self.pc = npc
        self.retired += 1

    def run(self, max_steps=100000):
        while not self.halted and self.retired < max_steps:
            self.step()
        return self.halted


def run_source(src, max_steps=100000):
    res = assemble(src)
    iss = ISS([w for _, w, _ in res['text']], res['data'])
    iss.run(max_steps)
    return iss, res


def write_expected(iss, path):
    with open(path, 'w') as f:
        for i in range(32):
            f.write(f'R {i} {iss.r[i]:08x}\n')
        for i, w in enumerate(iss.mem):
            if w:
                f.write(f'M {i} {w:08x}\n')
        f.write(f'I {iss.retired}\n')


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('-e', '--expect')
    ap.add_argument('--max', type=int, default=100000)
    a = ap.parse_args()
    try:
        iss, _ = run_source(open(a.src).read(), a.max)
    except AsmError as e:
        sys.exit(f'error: {e}')
    if a.expect:
        write_expected(iss, a.expect)
    print(f'halted={iss.halted} retired={iss.retired}')
    for i in range(0, 32, 4):
        print('  '.join(f'${j:<2}={iss.r[j]:08x}' for j in range(i, i + 4)))
    nz = [(i, w) for i, w in enumerate(iss.mem) if w]
    for i, w in nz[:32]:
        print(f'mem[0x{4 * i:03x}] = {w:08x}')
