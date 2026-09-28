#!/usr/bin/env python3
"""
Constrained-random program generator for mini-MIPS v12.

The generator deliberately draws operands from a small register pool so that
almost every instruction depends on one of the previous 1-3 instructions --
this is what exercises forwarding, load-use stalls and branch-operand stalls.
Programs always terminate: branches/jumps only go forward, and loops are
emitted from a bounded count-down template.
"""
import random

POOL = [1, 2, 3, 4, 5, 6]      # hazard-dense operand pool
JR_REG = 7                      # reserved for JR targets
LOOP_REG = 8                    # reserved loop counter


def rreg(rng, zero_ok=True):
    if zero_ok and rng.random() < 0.08:
        return 0
    return rng.choice(POOL)


def gen(seed, length=40):
    rng = random.Random(seed)
    lines = ['        .data']
    words = [rng.choice([0, 1, 2, 3, 0xFFFFFFFF]) if rng.random() < 0.5 else rng.getrandbits(32)
             for _ in range(16)]
    lines.append('        .word ' + ', '.join(f'0x{w:08x}' for w in words))
    lines.append('        .text')
    def small_or_big():
        # small values make BEQ outcomes ~50/50 instead of almost never taken
        return rng.choice([0, 1, 2, 3, -1]) if rng.random() < 0.5 else rng.randint(-32767, 32768)

    for r in POOL:
        lines.append(f'        li   ${r}, {small_or_big()}')

    label_id = 0
    pending = []                # (label, remaining instructions before placement)
    body = 0
    in_loop = False
    prev_d = 1

    def new_label():
        nonlocal label_id
        label_id += 1
        return f'L{label_id}'

    def emit(s):
        nonlocal body
        lines.append('        ' + s)
        body += 1
        for p in pending:
            p[1] -= 1
        while pending and pending[0][1] <= 0:
            lines.append(pending.pop(0)[0] + ':')

    while body < length:
        k = rng.random()
        d, s, t = rreg(rng), rreg(rng), rreg(rng)
        if k < 0.30:
            op = rng.choice(['add', 'nor', 'xor'])
            emit(f'{op}  ${d}, ${s}, ${t}')
        elif k < 0.38:
            emit(f'sll  ${d}, ${t}, {rng.randint(0, 31)}')
        elif k < 0.46:
            mask = rng.choice([1, 3, 0xFF]) if rng.random() < 0.5 else rng.randint(0, 0xFFFF)
            emit(f'andi ${d}, ${s}, {mask}')
        elif k < 0.54:
            imm = rng.choice([0, 1, -1]) if rng.random() < 0.4 else rng.randint(-32768, 32767)
            emit(f'subui ${d}, ${s}, {imm}')
        elif k < 0.66:
            base = 0 if rng.random() < 0.6 else s
            off = rng.randrange(0, 64, 4) if base == 0 else rng.randint(-64, 64) & ~3
            emit(f'lw   ${d}, {off}(${base})')
        elif k < 0.76:
            base = 0 if rng.random() < 0.6 else s
            off = rng.randrange(0, 64) if base == 0 else rng.randint(-64, 64)
            emit(f'sb   ${t}, {off}(${base})')
        elif k < 0.86 and not pending:
            if rng.random() < 0.5:
                s = prev_d          # branch right after its producer (ALU or load)
            L = new_label()
            pending.append([L, rng.randint(1, 4)])
            emit(f'beq  ${s}, ${t}, {L}')
        elif k < 0.90 and not pending:
            L = new_label()
            pending.append([L, rng.randint(1, 3)])
            emit(f'j    {L}')
        elif k < 0.94 and not pending:
            L = new_label()
            emit(f'la   ${JR_REG}, {L}')
            pending.append([L, rng.randint(1, 3)])
            emit(f'jr   ${JR_REG}')
        elif not pending and not in_loop and body < length - 8:
            # bounded count-down loop with a data-dependent body
            n = rng.randint(1, 4)
            top, out = new_label(), new_label()
            emit(f'li   ${LOOP_REG}, {n}')
            lines.append(f'{top}:')
            emit(f'add  ${d}, ${s}, ${t}')
            emit(f'sb   ${d}, {rng.randrange(0, 64)}($0)')
            emit(f'subui ${LOOP_REG}, ${LOOP_REG}, 1')
            emit(f'beq  ${LOOP_REG}, $0, {out}')
            emit(f'j    {top}')
            lines.append(f'{out}:')
        if k < 0.66 and d:
            prev_d = d              # last ALU/load destination
    for p in pending:
        lines.append(p[0] + ':')
    lines.append('        halt')
    return '\n'.join(lines) + '\n'


if __name__ == '__main__':
    import sys
    print(gen(int(sys.argv[1]) if len(sys.argv) > 1 else 1))
