#!/usr/bin/env python3
"""
mini-MIPS assembler / disassembler.

Usage:
    python3 mips_asm.py prog.s [-o prog]      -> prog.imem.hex, prog.dmem.hex, prog.lst

Syntax
    labels          loop:
    comments        # ...   ; ...   // ...
    registers       $0..$31, r0..r31, R0..R31, $zero $at $v0-1 $a0-3 $t0-9 $s0-7 $k0-1 $gp $sp $fp $ra
    sections        .text (default, starts at 0x0) / .data (starts at 0x0 of data memory)
    data            .word v1, v2, ...     .space nbytes

Instructions (11)
    add  rd, rs, rt        nor rd, rs, rt        xor rd, rs, rt
    sll  rd, rt, shamt     jr  rs
    andi rt, rs, imm16u    subui rt, rs, imm16s
    lw   rt, off(rs)       sb  rt, off(rs)
    beq  rs, rt, label     j   label

Pseudo-instructions
    nop                    -> sll $0, $0, 0
    li   rt, imm           -> subui rt, $0, -imm        (-32767 .. 32768)
    la   rt, label         -> li rt, address-of-label
    move rd, rs            -> add rd, rs, $0
    b    label             -> beq $0, $0, label
    halt                   -> j .      (jump-to-self; the testbench stops here)
"""
import re
import sys

OPC = {'rtype': 0b000000, 'j': 0b000010, 'beq': 0b000100, 'andi': 0b001100,
       'subui': 0b011001, 'lw': 0b100011, 'sb': 0b101000}
FUN = {'sll': 0b000000, 'jr': 0b001000, 'add': 0b100000, 'xor': 0b100110, 'nor': 0b100111}

ABI = ['zero', 'at', 'v0', 'v1', 'a0', 'a1', 'a2', 'a3',
       't0', 't1', 't2', 't3', 't4', 't5', 't6', 't7',
       's0', 's1', 's2', 's3', 's4', 's5', 's6', 's7',
       't8', 't9', 'k0', 'k1', 'gp', 'sp', 'fp', 'ra']

IMEM_WORDS = 256
DMEM_WORDS = 1024


class AsmError(Exception):
    pass


def reg(tok):
    t = tok.strip().lower()
    if t.startswith('$'):
        t = t[1:]
        if t.isdigit():
            n = int(t)
        elif t in ABI:
            n = ABI.index(t)
        else:
            raise AsmError(f"bad register '{tok}'")
    elif t.startswith('r') and t[1:].isdigit():
        n = int(t[1:])
    else:
        raise AsmError(f"bad register '{tok}'")
    if not 0 <= n <= 31:
        raise AsmError(f"register out of range '{tok}'")
    return n


def num(tok):
    t = tok.strip().lower().replace('_', '')
    try:
        return int(t, 0)
    except ValueError:
        raise AsmError(f"bad number '{tok}'")


def strip_comment(line):
    for c in ('#', ';', '//'):
        i = line.find(c)
        if i >= 0:
            line = line[:i]
    return line.strip()


def split_ops(s):
    return [x.strip() for x in s.split(',')] if s.strip() else []


def expand(mn, ops):
    """Pseudo-instruction expansion -> list of (mnemonic, operands)."""
    if mn == 'nop':
        return [('sll', ['$0', '$0', '0'])]
    if mn == 'move':
        return [('add', [ops[0], ops[1], '$0'])]
    if mn == 'b':
        return [('beq', ['$0', '$0', ops[0]])]
    if mn == 'halt':
        return [('j', ['.'])]
    if mn == 'li':
        return [('li', ops)]
    if mn == 'la':
        return [('la', ops)]
    return [(mn, ops)]


def assemble(src):
    """Two-pass assembler. Returns dict(text=[(addr, word, srcline)], data=[words], labels)."""
    lines = src.splitlines()
    labels = {}
    items = []          # (section, addr, mn, ops, lineno, text)
    section = 'text'
    pc = {'text': 0, 'data': 0}
    data = {}
    for no, raw in enumerate(lines, 1):
        line = strip_comment(raw)
        while True:
            m = re.match(r'^([A-Za-z_.][\w.]*)\s*:\s*(.*)$', line)
            if not m:
                break
            name = m.group(1)
            if name in labels:
                raise AsmError(f"line {no}: duplicate label '{name}'")
            labels[name] = pc[section]
            line = m.group(2).strip()
        if not line:
            continue
        parts = line.split(None, 1)
        mn = parts[0].lower()
        ops = split_ops(parts[1]) if len(parts) > 1 else []
        if mn == '.text':
            section = 'text'; continue
        if mn == '.data':
            section = 'data'; continue
        if mn == '.word':
            if section != 'data':
                raise AsmError(f"line {no}: .word only allowed in .data")
            for o in ops:
                items.append(('data', pc['data'], '.word', [o], no, raw.strip()))
                pc['data'] += 4
            continue
        if mn == '.space':
            n = num(ops[0])
            if n % 4:
                raise AsmError(f"line {no}: .space must be a multiple of 4")
            pc[section] += n
            continue
        if section != 'text':
            raise AsmError(f"line {no}: instruction in .data section")
        for (m2, o2) in expand(mn, ops):
            items.append(('text', pc['text'], m2, o2, no, raw.strip()))
            pc['text'] += 4

    def value(tok, no):
        t = tok.strip()
        if t in labels:
            return labels[t]
        return num(t)

    text = []
    for sec, addr, mn, ops, no, raw in items:
        try:
            if sec == 'data':
                data[addr // 4] = value(ops[0], no) & 0xFFFFFFFF
                continue
            w = encode(mn, ops, addr, labels)
        except AsmError as e:
            raise AsmError(f"line {no}: {e}  -> '{raw}'")
        except (IndexError, ValueError):
            raise AsmError(f"line {no}: wrong operands -> '{raw}'")
        text.append((addr, w, raw))
    if len(text) > IMEM_WORDS:
        raise AsmError("program larger than instruction memory")
    dwords = [0] * (max(data) + 1 if data else 0)
    for k, v in data.items():
        dwords[k] = v
    return {'text': text, 'data': dwords, 'labels': labels}


def encode(mn, ops, addr, labels):
    def val(t):
        t = t.strip()
        if t == '.':
            return addr
        if t in labels:
            return labels[t]
        return num(t)

    def need(n):
        if len(ops) != n:
            raise AsmError(f"'{mn}' expects {n} operands")

    if mn in ('add', 'nor', 'xor'):
        need(3)
        rd, rs, rt = reg(ops[0]), reg(ops[1]), reg(ops[2])
        return (rs << 21) | (rt << 16) | (rd << 11) | FUN[mn]
    if mn == 'sll':
        need(3)
        rd, rt, sh = reg(ops[0]), reg(ops[1]), val(ops[2])
        if not 0 <= sh <= 31:
            raise AsmError("shamt must be 0..31")
        return (rt << 16) | (rd << 11) | (sh << 6) | FUN['sll']
    if mn == 'jr':
        need(1)
        return (reg(ops[0]) << 21) | FUN['jr']
    if mn in ('andi', 'subui'):
        need(3)
        rt, rs, imm = reg(ops[0]), reg(ops[1]), val(ops[2])
        if mn == 'andi' and not 0 <= imm <= 0xFFFF:
            raise AsmError("andi immediate must be 0..65535 (zero-extended)")
        if mn == 'subui' and not -32768 <= imm <= 32767:
            raise AsmError("subui immediate must be -32768..32767 (sign-extended)")
        return (OPC[mn] << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)
    if mn in ('li', 'la'):
        need(2)
        rt, imm = reg(ops[0]), val(ops[1])
        if not -32767 <= imm <= 32768:
            raise AsmError("li immediate must be -32767..32768")
        return (OPC['subui'] << 26) | (0 << 21) | (rt << 16) | ((-imm) & 0xFFFF)
    if mn in ('lw', 'sb'):
        need(2)
        rt = reg(ops[0])
        m = re.match(r'^(.*)\((.*)\)$', ops[1].strip())
        if not m:
            raise AsmError("expected offset(base)")
        off = val(m.group(1)) if m.group(1).strip() else 0
        rs = reg(m.group(2))
        if not -32768 <= off <= 32767:
            raise AsmError("offset out of range")
        return (OPC[mn] << 26) | (rs << 21) | (rt << 16) | (off & 0xFFFF)
    if mn == 'beq':
        need(3)
        rs, rt = reg(ops[0]), reg(ops[1])
        t = ops[2].strip()
        if t in labels or t == '.':
            off = (val(t) - (addr + 4)) >> 2
        else:
            off = num(t)                        # raw word offset
        if not -32768 <= off <= 32767:
            raise AsmError("branch out of range")
        return (OPC['beq'] << 26) | (rs << 21) | (rt << 16) | (off & 0xFFFF)
    if mn == 'j':
        need(1)
        tgt = val(ops[0])
        if tgt & 3:
            raise AsmError("jump target not word aligned")
        return (OPC['j'] << 26) | ((tgt >> 2) & 0x3FFFFFF)
    raise AsmError(f"unknown instruction '{mn}'")


def sext16(x):
    return x - 0x10000 if x & 0x8000 else x


def disasm(w, addr=None):
    op = (w >> 26) & 0x3F
    rs = (w >> 21) & 31
    rt = (w >> 16) & 31
    rd = (w >> 11) & 31
    sh = (w >> 6) & 31
    fn = w & 0x3F
    imm = w & 0xFFFF
    if w == 0:
        return 'nop'
    if op == 0:
        if fn == FUN['sll']:
            return f'sll ${rd}, ${rt}, {sh}'
        if fn == FUN['jr']:
            return f'jr ${rs}'
        for k in ('add', 'xor', 'nor'):
            if fn == FUN[k]:
                return f'{k} ${rd}, ${rs}, ${rt}'
        return f'.word 0x{w:08x}  (unsupported funct)'
    if op == OPC['andi']:
        return f'andi ${rt}, ${rs}, {imm}'
    if op == OPC['subui']:
        return f'subui ${rt}, ${rs}, {sext16(imm)}'
    if op == OPC['lw']:
        return f'lw ${rt}, {sext16(imm)}(${rs})'
    if op == OPC['sb']:
        return f'sb ${rt}, {sext16(imm)}(${rs})'
    if op == OPC['beq']:
        if addr is not None:
            return f'beq ${rs}, ${rt}, 0x{(addr + 4 + (sext16(imm) << 2)) & 0xFFFFFFFF:x}'
        return f'beq ${rs}, ${rt}, {sext16(imm)}'
    if op == OPC['j']:
        base = ((addr + 4) & 0xF0000000) if addr is not None else 0
        return f'j 0x{base | ((w & 0x3FFFFFF) << 2):x}'
    return f'.word 0x{w:08x}  (unsupported opcode)'


def write_outputs(res, stem):
    with open(stem + '.imem.hex', 'w') as f:
        for addr, w, raw in res['text']:
            f.write(f'{w:08x}  // 0x{addr:03x}: {disasm(w, addr)}\n')
    with open(stem + '.dmem.hex', 'w') as f:
        for w in res['data']:
            f.write(f'{w:08x}\n')
    with open(stem + '.lst', 'w') as f:
        for addr, w, raw in res['text']:
            f.write(f'0x{addr:04x}  {w:08x}  {disasm(w, addr):28s} | {raw}\n')


if __name__ == '__main__':
    import argparse
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('src')
    ap.add_argument('-o', '--out', help='output stem (default: source name without .s)')
    a = ap.parse_args()
    try:
        r = assemble(open(a.src).read())
    except AsmError as e:
        sys.exit(f'error: {e}')
    stem = a.out or re.sub(r'\.s$|\.asm$', '', a.src)
    write_outputs(r, stem)
    print(f'{len(r["text"])} instructions, {len(r["data"])} data words -> {stem}.imem.hex / .dmem.hex / .lst')
