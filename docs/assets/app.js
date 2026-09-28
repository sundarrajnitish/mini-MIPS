/* mini-MIPS Pipeline Lab — UI
 * Depends on: mips-core.js (window.MiniMIPS), programs.js (window.PROGRAMS),
 * verification.js (window.VERIF).
 */
(function () {
  'use strict';
  const M = window.MiniMIPS;
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
  const SVGNS = 'http://www.w3.org/2000/svg';
  const hex = (x, n = 8) => '0x' + (x >>> 0).toString(16).toUpperCase().padStart(n, '0');
  const hexs = (x) => '0x' + (x >>> 0).toString(16).toUpperCase();
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const signed = (x) => x | 0;
  const REGN = (r) => `$${r}`;
  const colorOf = (pc) => `var(--i${(pc >>> 2) % 6})`;
  const STAGES = ['IF', 'ID', 'EX', 'MEM', 'WB'];
  const STAGE_NAMES = { IF: 'Instruction Fetch', ID: 'Instruction Decode', EX: 'Execute', MEM: 'Memory', WB: 'Write Back' };

  /* ================================================================== */
  /* Simulation state                                                     */
  /* ================================================================== */
  const S = {
    presetId: null, src: '', prog: null, pipe: null, snaps: [], cur: 0,
    srcByPc: new Map(), playing: null, radix: 'hex', selUnit: null, lastWrite: null,
  };

  function cleanSrc(raw) {
    let s = raw.replace(/(#|;|\/\/).*$/, '').trim();
    s = s.replace(/^([A-Za-z_.][\w.]*\s*:\s*)+/, '').trim();
    return s.replace(/\s+/g, ' ').replace(/ ,/g, ',');
  }

  function loadProgram(src, presetId) {
    const prog = M.assemble(src);          // may throw
    bubbleKeys.clear();
    S.src = src; S.prog = prog; S.presetId = presetId || null;
    S.srcByPc = new Map(prog.text.map((t) => [t.addr, { word: t.word, src: cleanSrc(t.src), label: labelAt(prog, t.addr) }]));
    S.pipe = new M.Pipeline(prog);
    S.snaps = [];
    S.cur = 0;
    stepSim();
    renderAll();
  }

  function labelAt(prog, addr) {
    const ls = Object.entries(prog.labels).filter(([, a]) => a === addr).map(([l]) => l);
    return ls.join(', ');
  }

  function stepSim() {
    if (S.pipe.done) return false;
    const snap = S.pipe.step();
    if (!snap) return false;
    snap.regsAfter = Array.from(S.pipe.regs);
    snap.memAfter = S.pipe.mem.slice(0, 64);
    snap.stats = Object.assign({}, S.pipe.stats, { retired: S.pipe.retired });
    noteBubble(snap);
    S.snaps.push(snap);
    S.cur = S.snaps.length;
    return true;
  }

  function gotoCycle(n) {
    n = Math.max(1, n);
    if (n <= S.snaps.length) { S.cur = n; renderAll(); return; }
    while (S.snaps.length < n && stepSim()) { /* advance */ }
    S.cur = S.snaps.length;
    renderAll();
  }

  const snapNow = () => S.snaps[S.cur - 1];
  const instrAt = (pc) => S.srcByPc.get(pc) || { word: S.pipe.imem[(pc >>> 2) & 255], src: M.disasm(S.pipe.imem[(pc >>> 2) & 255], pc), label: '' };
  const txt = (pc) => instrAt(pc).src;

  /* ================================================================== */
  /* Datapath SVG                                                         */
  /* ================================================================== */
  const DP = { wires: {}, units: {}, vals: {}, pregs: {}, stageIns: {}, dots: [] };

  function el(tag, attrs, parent) {
    const e = document.createElementNS(SVGNS, tag);
    for (const k in attrs) e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  }
  function text(parent, x, y, s, cls, anchor = 'middle', extra = {}) {
    const t = el('text', Object.assign({ x, y, class: cls, 'text-anchor': anchor }, extra), parent);
    t.textContent = s;
    return t;
  }

  const UNIT_INFO = {
    pc: ['Program Counter', 'IF', 'A 32-bit register holding the address of the instruction being fetched. It loads the next-PC value on every rising edge, except during a stall, when the hazard unit clears PCWrite so the same instruction is fetched again.'],
    imem: ['Instruction Memory', 'IF', '256-word ROM with asynchronous read, loaded from a hex file when the design elaborates. Words that were never written read as 0x00000000, which is SLL $0,$0,0 (a NOP).'],
    add4: ['PC + 4 adder', 'IF', 'Computes the address of the next sequential instruction. The result goes into IF/ID for BEQ targets, and it is also the default input of the branch MUX.'],
    bmux: ['Branch MUX', 'IF', 'First next-PC multiplexer. It selects the branch target when a BEQ in ID is taken, and PC+4 otherwise.'],
    jmux: ['Jump MUX', 'IF', 'Second next-PC multiplexer. It passes the branch-MUX output through, or selects the J target (in 1) or the JR target taken from the forwarded rs value (in 2).'],
    hazard: ['Hazard Detection Unit', 'ID', 'Watches the instruction in ID and the ones in EX and MEM. It stalls on a load-use hazard, and on a BEQ or JR whose operand is not ready yet. A stall freezes the PC and IF/ID and sends a bubble into ID/EX. When a BEQ is taken or a J/JR executes, it redirects the PC and flushes the one wrong-path instruction in IF/ID.'],
    ctrl: ['Control Unit', 'ID', 'Purely combinational decoder of opcode and funct. It produces RegWrite, MemtoReg, MemRead, MemWrite, RegDst, ALUSrc, ALUOp and Branch/Jump/JumpReg. It also produces ExtOp and flags saying whether rs and rt are read, which the hazard unit uses.'],
    cmux: ['Control MUX (bubble)', 'ID', 'On a stall, this sends all-zero control, a NOP, into ID/EX instead of the real control word. The stalled instruction waits in ID and tries again next cycle.'],
    rf: ['Register File', 'ID', '32 × 32-bit registers, two asynchronous read ports and one write port. $0 always reads 0. A write-through bypass returns the value WB is writing in this same cycle, which is the RTL version of "write in the first half, read in the second half".'],
    muxe: ['MUX E (ID forwarding, rs)', 'ID', 'Forwards the EX/MEM ALU result into ID when it writes rs. This is what lets a BEQ or JR use a value computed just one instruction earlier after a single stall. Load results are never forwarded here, because EX/MEM only holds their address.'],
    muxf: ['MUX F (ID forwarding, rt)', 'ID', 'Same as MUX E, for rt.'],
    cmp: ['Equality comparator', 'ID', 'BEQ is resolved in ID by comparing the two forwarded operands. Doing it here instead of in MEM brings the taken-branch penalty down from 3 slots to 1.'],
    se: ['Sign / zero extend', 'ID', 'Widens the 16-bit immediate to 32 bits. ANDI zero-extends, as MIPS logical immediates do. SUBUI, LW, SB and BEQ sign-extend.'],
    badd: ['Branch target adder', 'ID', 'PC+4 + (sign-extended offset << 2). The offset counts words, so it is shifted left by 2 to make a byte offset.'],
    jcalc: ['Jump address', 'ID', 'J target = { PC+4[31:28], target26, "00" }.'],
    muxc: ['MUX C (EX forwarding, operand A)', 'EX', 'Picks ALU operand A. The choices are the value read in ID (0), the value being written back from MEM/WB (1), or the ALU result in EX/MEM (2). The newest producer wins.'],
    muxd: ['MUX D (EX forwarding, rt)', 'EX', 'Same as MUX C, for rt. Its output feeds MUX A and is also the SB store data. It sits before MUX A, so forwarding can never overwrite an immediate. v11 had that order the other way round.'],
    muxa: ['MUX A (ALUSrc)', 'EX', 'Selects the forwarded rt value (0) or the extended immediate (1) as ALU operand B.'],
    muxb: ['MUX B (RegDst)', 'EX', 'Selects the destination register: rd for R-type, rt for ANDI, SUBUI and LW.'],
    alu: ['ALU', 'EX', 'Combinational: ADD, SUB, AND, XOR, NOR, and SLL (operand B shifted by shamt). Arithmetic wraps modulo 2³² with no overflow trap.'],
    fwd: ['Forwarding Unit', 'EX', 'Compares the source registers of the instructions in EX (for MUX C/D) and ID (for MUX E/F) with the destinations of the instructions in MEM and WB. Only producers with RegWrite=1 and dest ≠ $0 count.'],
    dmem: ['Data Memory', 'MEM', '1024 words (4 KiB), byte-addressed, little-endian. LW reads the aligned word asynchronously. SB writes byte lane addr[1:0] on the rising edge.'],
    wbmux: ['Write-back MUX', 'WB', 'MemtoReg = 1 selects the loaded word, otherwise the ALU result. Its output goes to the register file write port and back to MUX C/D as the MEM/WB forwarding source.'],
    ifid: ['IF/ID register', 'IF', 'Holds PC, PC+4 and the instruction word. Write is disabled on a stall. On a taken branch or a jump it is cleared (flushed).'],
    idex: ['ID/EX register', 'ID', 'Holds the control word, both operand values, the immediate, shamt, and the rs/rt/rd numbers. A stall loads a bubble.'],
    exmem: ['EX/MEM register', 'EX', 'Holds the WB+M control, the ALU result (or memory address), the store data and the destination register.'],
    memwb: ['MEM/WB register', 'MEM', 'Holds the WB control, the loaded word, the ALU result and the destination register.'],
  };

  function buildDatapath() {
    const svg = $('#datapath');
    svg.innerHTML = '';
    const defs = el('defs', {}, svg);
    const mk = el('marker', { id: 'dpArr', viewBox: '0 0 10 10', refX: 9, refY: 5, markerWidth: 6, markerHeight: 6, orient: 'auto-start-reverse' }, defs);
    el('path', { d: 'M0,0 L10,5 L0,10 z', fill: 'context-stroke' }, mk);

    // stage bands
    const bands = [['IF', 0, 300], ['ID', 300, 750], ['EX', 750, 1080], ['MEM', 1080, 1290], ['WB', 1290, 1480]];
    const gB = el('g', {}, svg);
    bands.forEach(([n, x0, x1], i) => {
      el('rect', { x: x0, y: 0, width: x1 - x0, height: 770, class: 'stage-bg', style: `--c: ${i % 2 ? 'var(--ink-2)' : 'transparent'}` }, gB);
      text(gB, (x0 + x1) / 2, 22, n, 'stage-title');
      DP.stageIns[n] = text(gB, (x0 + x1) / 2, 42, '', 'stage-ins');
    });

    const gW = el('g', {}, svg);
    const gU = el('g', {}, svg);
    const gV = el('g', {}, svg);

    const W = (id, pts, cls = '', arrow = true) => {
      const d = 'M' + pts.map((p) => p.join(',')).join(' L');
      const p = el('path', { d, class: 'wire ' + cls, 'data-id': id }, gW);
      if (arrow) p.setAttribute('marker-end', 'url(#dpArr)');
      (DP.wires[id] = DP.wires[id] || []).push(p);
      return p;
    };
    const dot = (x, y, ids) => { const c = el('circle', { cx: x, cy: y, r: 3, class: 'dot' }, gW); DP.dots.push([c, ids]); };
    const unitG = (id) => { const g = el('g', { class: 'unit', 'data-unit': id }, gU); DP.units[id] = g; return g; };
    const box = (id, x, y, w, h, label, sub) => {
      const g = unitG(id);
      el('rect', { x, y, width: w, height: h, rx: 6 }, g);
      const lines = label.split('\n');
      lines.forEach((l, i) => text(g, x + w / 2, y + h / 2 + 4 - (lines.length - 1) * 7 + i * 14 - (sub ? 6 : 0), l, 'lbl'));
      if (sub) text(g, x + w / 2, y + h / 2 + 14 + (lines.length - 1) * 7, sub, 'lbl2');
      return g;
    };
    const mux = (id, x, y, w, h, label, pins) => {
      const g = unitG(id);
      const r = w / 2;
      el('path', { d: `M${x},${y + r} A${r},${r} 0 0 1 ${x + w},${y + r} L${x + w},${y + h - r} A${r},${r} 0 0 1 ${x},${y + h - r} Z` }, g);
      text(g, x + w / 2, y + h / 2 + 4, label, 'lbl', 'middle', { style: 'font-size:11px' });
      (pins || []).forEach(([py, s]) => text(g, x + 3, py + 3, s, 'pin', 'start'));
      return g;
    };
    const val = (id, x, y, anchor = 'middle') => { DP.vals[id] = text(gV, x, y, '', 'val', anchor); };
    const preg = (id, x, label) => {
      const g = el('g', { class: 'preg unit', 'data-unit': id }, gU);
      el('rect', { x, y: 130, width: 16, height: 570, rx: 3 }, g);
      text(g, x + 8, 415, label, '', 'middle', { transform: `rotate(-90 ${x + 8} 415)` });
      DP.pregs[id] = g; DP.units[id] = g;
    };
    const pin = (x, y, s, a = 'start') => text(gV, x, y, s, 'pin', a);

    /* ---------- pipeline registers ---------- */
    preg('ifid', 292, 'IF / ID');
    preg('idex', 742, 'ID / EX');
    preg('exmem', 1072, 'EX / MEM');
    preg('memwb', 1282, 'MEM / WB');

    /* ---------- IF ---------- */
    mux('bmux', 20, 375, 20, 70, '', [[392, '0'], [428, '1']]);
    mux('jmux', 80, 365, 22, 90, '', [[382, '0'], [410, '1'], [438, '2']]);
    box('pc', 122, 380, 40, 60, 'PC');
    box('imem', 185, 335, 95, 150, 'Instruction\nmemory');
    const a4 = unitG('add4');
    el('path', { d: 'M190,528 L240,543 L240,583 L190,598 L190,572 L198,563 L190,554 Z' }, a4);
    text(a4, 222, 568, '+4', 'lbl');

    W('pc4_bmux', [[260, 563], [260, 625], [4, 625], [4, 392], [20, 392]]);
    W('bmux_jmux', [[40, 410], [50, 410], [50, 382], [80, 382]]);
    W('jmux_pc', [[102, 410], [122, 410]]);
    W('pc_imem', [[162, 410], [185, 410]]);
    W('pc_add', [[172, 410], [172, 563], [190, 563]]);
    dot(172, 410, ['pc_add']);
    W('imem_ifid', [[280, 400], [292, 400]]);
    W('add_ifid', [[240, 563], [292, 563]]);
    dot(260, 563, ['pc4_bmux']);
    W('bt_lane', [[670, 490], [685, 490], [685, 78], [10, 78], [10, 428], [20, 428]]);
    W('jt_lane', [[510, 647], [715, 647], [715, 90], [64, 90], [64, 410], [80, 410]]);
    W('jr_lane', [[700, 360], [700, 102], [72, 102], [72, 438], [80, 438]]);
    dot(700, 360, ['jr_lane']);
    W('haz_pc', [[340, 140], [340, 114], [142, 114], [142, 380]], 'ctl');
    W('haz_ifid', [[360, 140], [360, 122], [300, 122], [300, 130]], 'ctl');
    pin(146, 128, 'PCWrite');
    pin(304, 118, 'Write / Flush', 'start');
    pin(14, 72, 'branch target');
    pin(120, 86, 'jump target');
    pin(120, 98, 'JR target (rs)');
    pin(246, 557, 'PC+4');
    pin(282, 395, 'instr', 'end');
    val('pc', 142, 372);
    val('nextpc', 142, 458);
    val('instr', 232, 500);
    val('pc4', 216, 612);

    /* ---------- ID ---------- */
    box('hazard', 330, 140, 150, 50, 'Hazard\ndetection');
    box('ctrl', 520, 140, 100, 50, 'Control');
    mux('cmux', 665, 142, 20, 46, '', [[152, '1'], [176, '0']]);
    box('rf', 380, 320, 140, 170, 'Register\nfile');
    ['RR1 rs', 'RR2 rt', 'WR', 'WD'].forEach((s, i) => pin(384, [350, 390, 430, 465][i] + 3, s));
    pin(516, 363, 'RD1', 'end'); pin(516, 433, 'RD2', 'end');
    mux('muxe', 560, 335, 20, 50, 'E', [[348, ''], [372, '']]);
    mux('muxf', 560, 405, 20, 50, 'F', [[418, ''], [442, '']]);
    const cmp = unitG('cmp');
    el('circle', { cx: 640, cy: 395, r: 15 }, cmp);
    text(cmp, 640, 400, '=', 'lbl', 'middle', { style: 'font-size:15px' });
    const se = unitG('se');
    el('ellipse', { cx: 450, cy: 540, rx: 40, ry: 17 }, se);
    text(se, 450, 544, 'Extend', 'lbl2');
    box('badd', 600, 470, 70, 40, '<<2  +', '');
    box('jcalc', 400, 630, 110, 34, '<<2 ∥ PC[31:28]');

    W('ifid_ctrl', [[308, 225], [570, 225], [570, 190]]);
    W('ctrl_cmux', [[620, 152], [665, 152]]);
    W('cmux_idex', [[685, 165], [742, 165]]);
    W('haz_cmux', [[455, 190], [455, 205], [675, 205], [675, 188]], 'ctl');
    W('ifid_rs', [[308, 350], [380, 350]]);
    W('ifid_rt', [[308, 390], [380, 390]]);
    W('rs_idex', [[340, 350], [340, 575], [742, 575]]);
    W('rt_idex', [[350, 390], [350, 590], [742, 590]]);
    dot(340, 350, ['rs_idex']); dot(350, 390, ['rt_idex']);
    W('rd_idex', [[308, 608], [742, 608]]);
    W('ifid_imm', [[308, 540], [410, 540]]);
    W('se_idex', [[490, 540], [742, 540]]);
    W('se_badd', [[560, 540], [560, 500], [600, 500]]);
    dot(560, 540, ['se_badd']);
    W('pc4_badd', [[308, 680], [585, 680], [585, 482], [600, 482]]);
    W('ifid_tgt', [[308, 647], [400, 647]]);
    W('rd1_e', [[520, 360], [540, 360], [540, 348], [560, 348]]);
    W('rd2_f', [[520, 430], [540, 430], [540, 418], [560, 418]]);
    W('e_idex', [[580, 360], [742, 360]]);
    W('f_idex', [[580, 430], [742, 430]]);
    W('e_cmp', [[610, 360], [610, 389], [625, 389]]);
    W('f_cmp', [[618, 430], [618, 401], [625, 401]]);
    dot(610, 360, ['e_cmp']); dot(618, 430, ['f_cmp']);
    W('cmp_haz', [[640, 380], [640, 215], [440, 215], [440, 190]], 'ctl');
    pin(312, 220, 'opcode, funct');
    pin(312, 345, 'rs'); pin(312, 385, 'rt'); pin(312, 604, 'rd'); pin(312, 535, 'imm16'); pin(312, 642, 'target26'); pin(312, 675, 'PC+4');
    pin(736, 354, 'rs', 'end'); pin(736, 424, 'rt', 'end'); pin(733, 536, 'imm32', 'end');
    pin(733, 571, 'rs', 'end'); pin(733, 586, 'rt', 'end'); pin(733, 604, 'rd', 'end');
    pin(733, 161, 'WB M EX', 'end');
    pin(645, 229, 'Equal');
    val('rd1', 655, 352); val('rd2', 655, 422);
    val('imm', 450, 568); val('eq', 668, 399, 'start'); val('bt', 635, 462); val('jt', 455, 690);

    /* ---------- EX ---------- */
    mux('muxc', 800, 335, 22, 74, 'C', [[348, '0'], [372, '1'], [396, '2']]);
    mux('muxd', 800, 420, 22, 74, 'D', [[433, '0'], [457, '1'], [481, '2']]);
    mux('muxa', 860, 445, 20, 50, 'A', [[457, '0'], [483, '1']]);
    mux('muxb', 940, 578, 20, 40, 'B', [[590, '0'], [608, '1']]);
    const alu = unitG('alu');
    el('path', { d: 'M910,330 L975,372 L975,458 L910,500 L910,432 L925,415 L910,398 Z' }, alu);
    text(alu, 950, 419, 'ALU', 'lbl');
    DP.aluOp = text(alu, 950, 436, '', 'lbl2');
    box('fwd', 805, 640, 150, 40, 'Forwarding unit');

    W('idex_c', [[758, 360], [780, 360], [780, 348], [800, 348]]);
    W('idex_d', [[758, 430], [785, 430], [785, 433], [800, 433]]);
    W('c_alu', [[822, 372], [910, 372]]);
    W('d_a', [[822, 457], [860, 457]]);
    W('idex_imm', [[758, 540], [845, 540], [845, 483], [860, 483]]);
    W('a_alu', [[880, 470], [910, 470]]);
    W('alu_exmem', [[975, 415], [1072, 415]]);
    W('d_store', [[838, 457], [838, 520], [1072, 520]]);
    dot(838, 457, ['d_store']);
    W('idex_rt_b', [[758, 590], [940, 590]]);
    W('idex_rd_b', [[758, 608], [940, 608]]);
    W('b_exmem', [[960, 598], [1072, 598]]);
    W('rs_fwd', [[758, 575], [870, 575], [870, 640]], '', true);
    W('rt_fwd', [[885, 590], [885, 640]], '', true);
    dot(885, 590, ['rt_fwd']);
    W('fwd_seld', [[811, 640], [811, 494]], 'ctl fwdsel');
    W('fwd_selc', [[830, 640], [830, 415], [811, 415], [811, 409]], 'ctl fwdsel');
    W('fwd_selef', [[805, 668], [572, 668], [572, 455]], 'ctl fwdsel');
    // forwarding buses
    W('fb_exmem', [[1105, 415], [1105, 710], [790, 710]], 'fwd', false);
    W('fb_exmem_c', [[790, 710], [790, 396], [800, 396]], 'fwd');
    W('fb_exmem_d', [[790, 481], [800, 481]], 'fwd');
    W('fb_exmem_id', [[790, 710], [548, 710], [548, 442]], 'fwd', false);
    W('fb_exmem_e', [[548, 442], [548, 372], [560, 372]], 'fwd');
    W('fb_exmem_f', [[548, 442], [560, 442]], 'fwd');
    W('fb_wb', [[775, 740], [775, 457]], 'fwd', false);
    W('fb_wb_c', [[775, 457], [775, 372], [800, 372]], 'fwd');
    W('fb_wb_d', [[775, 457], [800, 457]], 'fwd');
    W('exmem_fwd', [[1100, 598], [1100, 660], [955, 660]], 'ctl', true);
    W('memwb_fwd', [[1310, 598], [1310, 672], [955, 672]], 'ctl', true);
    pin(1064, 411, 'ALU result', 'end'); pin(1064, 516, 'store data', 'end'); pin(1064, 594, 'dest', 'end');
    pin(880, 702, 'EX/MEM.ALUResult  →  C/D/E/F', 'middle');
    pin(778, 752, 'WB value → C/D', 'start');
    val('alua', 862, 364); val('alub', 893, 510); val('aluo', 1022, 434); val('dest', 1012, 620); val('fwdv', 700, 725);

    /* ---------- MEM ---------- */
    box('dmem', 1135, 360, 110, 140, 'Data\nmemory');
    pin(1139, 418, 'addr'); pin(1139, 473, 'wdata'); pin(1241, 434, 'rdata', 'end');
    W('exmem_addr', [[1088, 415], [1135, 415]]);
    W('exmem_alu_memwb', [[1118, 415], [1118, 335], [1282, 335]]);
    dot(1118, 415, ['exmem_alu_memwb']); dot(1105, 415, ['fb_exmem']);
    W('exmem_wd', [[1088, 520], [1120, 520], [1120, 470], [1135, 470]]);
    W('dmem_memwb', [[1245, 430], [1282, 430]]);
    W('exmem_dest', [[1088, 598], [1282, 598]]);
    dot(1100, 598, ['exmem_fwd']);
    val('maddr', 1190, 525); val('mdata', 1190, 545);

    /* ---------- WB ---------- */
    mux('wbmux', 1340, 318, 24, 92, '', [[340, '0'], [390, '1']]);
    W('memwb_alu_mux', [[1298, 335], [1320, 335], [1320, 340], [1340, 340]]);
    W('memwb_rd_mux', [[1298, 430], [1320, 430], [1320, 390], [1340, 390]]);
    W('wb_out', [[1364, 364], [1400, 364], [1400, 740], [775, 740]], '', false);
    W('wb_rf_data', [[775, 740], [362, 740], [362, 465], [380, 465]]);
    dot(775, 740, ['fb_wb']);
    W('memwb_dest', [[1298, 598], [1420, 598], [1420, 752], [370, 752], [370, 430], [380, 430]]);
    dot(1310, 598, ['memwb_fwd']);
    pin(1304, 330, 'ALU result'); pin(1304, 425, 'read data'); pin(1304, 594, 'dest');
    pin(1404, 450, 'write data', 'start'); pin(1424, 470, 'write reg', 'start');
    val('wbv', 1440, 356); val('wbd', 1440, 378);

    // unit click/hover
    $$('.unit', svg).forEach((g) => {
      g.addEventListener('click', () => { S.selUnit = S.selUnit === g.dataset.unit ? null : g.dataset.unit; renderInspector(); renderDatapathSel(); });
      g.addEventListener('mousemove', (e) => { const u = UNIT_INFO[g.dataset.unit]; if (u) showTip(e, `<b>${u[0]}</b><br>click for details`); });
      g.addEventListener('mouseleave', hideTip);
    });
  }

  function renderDatapathSel() {
    Object.entries(DP.units).forEach(([id, g]) => g.classList.toggle('sel', id === S.selUnit));
  }

  function renderDatapath(s) {
    // reset
    Object.values(DP.wires).flat().forEach((p) => { p.classList.remove('on', 'flush'); p.style.removeProperty('--wc'); });
    Object.values(DP.units).forEach((g) => { g.classList.remove('on', 'fwd', 'alert', 'flushing', 'hold', 'flushq'); g.style.removeProperty('--wc'); });
    Object.values(DP.vals).forEach((t) => { t.textContent = ''; t.classList.remove('fwdv'); });
    if (!s) return;
    const on = (ids, color) => ids.forEach((id) => (DP.wires[id] || []).forEach((p) => { p.classList.add('on'); if (color) p.style.setProperty('--wc', color); }));
    const uon = (ids, color) => ids.forEach((id) => { const g = DP.units[id]; if (g) { g.classList.add('on'); g.style.setProperty('--wc', color); } });
    const V = (id, str, fwd) => { if (DP.vals[id]) { DP.vals[id].textContent = str; DP.vals[id].classList.toggle('fwdv', !!fwd); } };

    const cIF = colorOf(s.pc);
    const idV = s.ifid.valid, exV = s.idex.valid, memV = s.exmem.valid, wbV = s.memwb.valid;
    const cID = colorOf(s.ifid.pc), cEX = colorOf(s.idex.pc), cMEM = colorOf(s.exmem.pc), cWB = colorOf(s.memwb.pc);

    // stage instruction labels
    const lab = (n, v, pc, fallback) => { const t = DP.stageIns[n]; t.textContent = v ? txt(pc) : fallback; t.style.fill = v ? colorOf(pc) : 'var(--muted)'; };
    lab('IF', 1, s.pc); lab('ID', idV, s.ifid.pc, 'bubble'); lab('EX', exV, s.idex.pc, 'bubble'); lab('MEM', memV, s.exmem.pc, 'bubble'); lab('WB', wbV, s.memwb.pc, 'bubble');

    /* IF */
    on(['pc_imem', 'pc_add', 'imem_ifid', 'add_ifid'], cIF);
    uon(['pc', 'imem', 'add4'], cIF);
    const cSel = s.pcSel ? cID : cIF;
    if (s.pcSel === 0) { on(['pc4_bmux', 'bmux_jmux', 'jmux_pc'], cIF); uon(['bmux', 'jmux'], cIF); }
    if (s.pcSel === 1) { on(['bt_lane', 'bmux_jmux', 'jmux_pc', 'se_badd', 'pc4_badd'], cSel); uon(['bmux', 'jmux', 'badd'], cSel); }
    if (s.pcSel === 2) { on(['jt_lane', 'jmux_pc', 'ifid_tgt'], cSel); uon(['jmux', 'jcalc'], cSel); }
    if (s.pcSel === 3) { on(['jr_lane', 'jmux_pc'], cSel); uon(['jmux'], cSel); }
    V('pc', hex(s.pc)); V('instr', hex(s.instr)); V('pc4', hex(s.pc4));
    V('nextpc', s.stall ? 'PC hold' : 'next ' + hexs(s.nextPc));
    if (s.stall) {
      on(['haz_pc', 'haz_ifid', 'haz_cmux']);
      DP.units.hazard.classList.add('alert'); DP.units.pc.classList.add('alert');
      DP.pregs.ifid.classList.add('hold'); DP.units.cmux.classList.add('alert');
    }
    if (s.flush) {
      (DP.wires.haz_ifid || []).forEach((p) => p.classList.add('on', 'flush'));
      DP.units.hazard.classList.add('flushing'); DP.pregs.ifid.classList.add('flushq');
    }

    /* ID */
    const d = s.id, c = d.ctrl;
    if (idV) {
      on(['ifid_ctrl', 'ctrl_cmux', 'cmux_idex'], cID); uon(['ctrl', 'cmux'], cID);
      if (c.usesRs || c.jumpReg) { on(['ifid_rs', 'rd1_e', 'e_idex', 'rs_idex'], cID); uon(['rf', 'muxe'], cID); }
      if (c.usesRt) { on(['ifid_rt', 'rd2_f', 'f_idex', 'rt_idex'], cID); uon(['rf', 'muxf'], cID); }
      if (!c.usesRt && c.regWrite) on(['rt_idex'], cID);
      if (c.regDst) on(['rd_idex'], cID);
      if (c.aluSrc) { on(['ifid_imm', 'se_idex'], cID); uon(['se'], cID); }
      if (c.branch) { on(['e_cmp', 'f_cmp', 'cmp_haz', 'ifid_imm', 'se_badd', 'pc4_badd'], cID); uon(['cmp', 'badd', 'se'], cID); }
      if (c.jump) { on(['ifid_tgt'], cID); uon(['jcalc'], cID); }
      if (c.jumpReg) on(['jr_lane'], cID);
      if (c.usesRs || c.jumpReg) V('rd1', `$${d.f.rs} = ${hexs(d.rsVal)}`, d.fwdE);
      if (c.usesRt) V('rd2', `$${d.f.rt} = ${hexs(d.rtVal)}`, d.fwdF);
      if (c.aluSrc || c.branch) V('imm', hexs(d.imm));
      if (c.branch) { V('eq', d.equal ? 'equal' : '≠'); V('bt', hexs(s.branchTarget)); }
      if (c.jump) V('jt', hexs(s.jumpTarget));
      if (d.fwdE || d.fwdF) {
        on(['fb_exmem', 'fb_exmem_id'].concat(d.fwdE ? ['fb_exmem_e'] : [], d.fwdF ? ['fb_exmem_f'] : []));
        if (d.fwdE) DP.units.muxe.classList.add('fwd');
        if (d.fwdF) DP.units.muxf.classList.add('fwd');
        on(['fwd_selef']); DP.units.fwd.classList.add('fwd');
      }
    }

    /* EX */
    const x = s.ex, ic = s.idex.ctrl;
    if (exV) {
      uon(['alu', 'muxb'], cEX);
      on(['alu_exmem'], cEX);
      DP.aluOp.textContent = M.ALU_NAME[ic.aluOp] || '';
      const consumes = ic.regWrite || ic.memWrite;          // BEQ/J/JR ignore the ALU in EX
      const usesA = ic.usesRs && consumes, usesB = ic.usesRt && consumes;
      if (usesA) { on([x.fwdA ? null : 'idex_c', 'c_alu'].filter(Boolean), cEX); uon(['muxc'], cEX); }
      if (usesB) { on([x.fwdB ? null : 'idex_d', 'd_a'].filter(Boolean), cEX); uon(['muxd'], cEX); }
      if (ic.aluSrc) { on(['idex_imm', 'a_alu'], cEX); uon(['muxa'], cEX); } else if (usesB) { on(['a_alu'], cEX); uon(['muxa'], cEX); }
      if (ic.memWrite) on(['d_store'], cEX);
      if (ic.regWrite) { on([ic.regDst ? 'idex_rd_b' : 'idex_rt_b', 'b_exmem'], cEX); V('dest', `dest $${x.exDest}`); }
      on(['rs_fwd', 'rt_fwd']); uon(['fwd'], 'var(--line)');
      if (usesA) V('alua', hexs(x.aluA), x.fwdA);
      if (usesB || ic.aluSrc) V('alub', hexs(x.aluB), x.fwdB && !ic.aluSrc);
      V('aluo', hexs(x.aluOut));
      if (x.fwdA === 2 && usesA) { on(['fb_exmem', 'fb_exmem_c']); DP.units.muxc.classList.add('fwd'); }
      if (x.fwdA === 1 && usesA) { on(['wb_out', 'fb_wb', 'fb_wb_c']); DP.units.muxc.classList.add('fwd'); }
      if (x.fwdB === 2 && usesB) { on(['fb_exmem', 'fb_exmem_d']); DP.units.muxd.classList.add('fwd'); }
      if (x.fwdB === 1 && usesB) { on(['wb_out', 'fb_wb', 'fb_wb_d']); DP.units.muxd.classList.add('fwd'); }
      if ((x.fwdA && usesA) || (x.fwdB && usesB)) {
        DP.units.fwd.classList.add('fwd');
        on([(x.fwdA && usesA) ? 'fwd_selc' : null, (x.fwdB && usesB) ? 'fwd_seld' : null].filter(Boolean));
        on([x.fwdA === 2 || x.fwdB === 2 ? 'exmem_fwd' : null, x.fwdA === 1 || x.fwdB === 1 ? 'memwb_fwd' : null].filter(Boolean));
      }
    } else DP.aluOp.textContent = '';

    /* MEM */
    const em = s.exmem;
    if (memV) {
      on(['exmem_alu_memwb'], cMEM);
      if (em.regWrite) on(['exmem_dest'], cMEM);
      if (em.memRead || em.memWrite) { on(['exmem_addr'], cMEM); uon(['dmem'], cMEM); V('maddr', 'addr ' + hexs(em.alu)); }
      if (em.memRead) { on(['dmem_memwb'], cMEM); V('mdata', 'read ' + hexs(s.mem.readData)); }
      if (em.memWrite) { on(['exmem_wd'], cMEM); V('mdata', 'byte ' + hexs(em.storeData & 0xFF) + ' → lane ' + (em.alu & 3)); }
    }

    /* WB */
    const mw = s.memwb;
    if (wbV && mw.regWrite) {
      on([mw.memToReg ? 'memwb_rd_mux' : 'memwb_alu_mux'], cWB);
      uon(['wbmux'], cWB);
      if (s.wb.we) { on(['wb_out', 'wb_rf_data', 'memwb_dest'], cWB); uon(['rf'], s.ifid.valid ? cID : cWB); V('wbv', hexs(s.wb.data)); V('wbd', '→ $' + mw.dest); }
    }

    // dots follow their wire
    DP.dots.forEach(([cEl, ids]) => {
      const w = (DP.wires[ids[0]] || [])[0];
      const onw = w && w.classList.contains('on');
      cEl.classList.toggle('on', !!onw);
      if (onw) cEl.style.setProperty('--wc', w.classList.contains('fwd') ? 'var(--fwd)' : (w.style.getPropertyValue('--wc') || 'var(--ink)'));
    });
    renderDatapathSel();
  }

  /* ================================================================== */
  /* Per-cycle narrative                                                  */
  /* ================================================================== */
  function narrative(s) {
    const ev = [];
    const I = (pc) => `<code style="color:${colorOf(pc)}">${esc(txt(pc))}</code>`;
    const d = s.id, c = d.ctrl, x = s.ex;
    // IF
    if (s.stall) ev.push(['IF', `${I(s.pc)} is fetched again because <b>PCWrite = 0</b>. The PC and IF/ID keep their values this cycle.`, 'stall']);
    else if (s.flush) ev.push(['IF', `${I(s.pc)} was fetched from ${hexs(s.pc)}, but it is on the wrong path. IF/ID will be <b>flushed</b> at the clock edge.`, 'flush']);
    else ev.push(['IF', `Fetch ${I(s.pc)} from ${hexs(s.pc)}. Next PC = ${hexs(s.nextPc)}${s.pcSel ? ' (redirected)' : ' (PC+4)'}.`]);
    // ID
    if (s.ifid.valid) {
      const pc = s.ifid.pc;
      const reads = [];
      if (c.usesRs || c.jumpReg) reads.push(`$${d.f.rs} = ${hexs(d.rsVal)}${d.fwdE ? ' <i>(MUX E, forwarded from EX/MEM)</i>' : d.rfBypass1 ? ' <i>(register-file bypass from WB)</i>' : ''}`);
      if (c.usesRt) reads.push(`$${d.f.rt} = ${hexs(d.rtVal)}${d.fwdF ? ' <i>(MUX F, forwarded from EX/MEM)</i>' : d.rfBypass2 ? ' <i>(register-file bypass from WB)</i>' : ''}`);
      let t = `Decode ${I(pc)}${reads.length ? ': read ' + reads.join(', ') : ''}.`;
      if (d.fwdE || d.fwdF) ev.push(['ID', t, 'fwd']); else ev.push(['ID', t]);
      if (d.loadUse) ev.push(['Hazard', `<b>Load-use hazard.</b> ${I(s.idex.pc)} in EX loads $${x.exDest}, which ${I(pc)} needs, and the data only exists after MEM. <b>Stall 1 cycle</b>: the PC and IF/ID hold, and a bubble goes into ID/EX. Next cycle the loaded word will be forwarded from MEM/WB.`, 'stall']);
      else if (d.branchHazEx) ev.push(['Hazard', `<b>Branch operand not ready.</b> ${I(pc)} compares in ID, but $${x.exDest} is still being computed by ${I(s.idex.pc)} in EX. <b>Stall 1 cycle</b>, then MUX E/F forwards it from EX/MEM.`, 'stall']);
      else if (d.branchHazMem) ev.push(['Hazard', `<b>Branch operand from a load.</b> ${I(s.exmem.pc)} in MEM is loading $${s.exmem.dest}, which ${I(pc)} needs in ID. <b>Stall again</b>. Next cycle the register-file bypass supplies it.`, 'stall']);
      if (!s.stall) {
        if (c.branch) {
          if (d.equal) ev.push(['Branch', `BEQ: ${hexs(d.rsVal)} = ${hexs(d.rtVal)}, so the branch is <b>taken</b>. PC ← PC+4 + (${signed(M.sext16(d.f.imm))} << 2) = ${hexs(s.branchTarget)}. The instruction fetched this cycle is flushed (1-cycle penalty).`, 'flush']);
          else ev.push(['Branch', `BEQ: ${hexs(d.rsVal)} ≠ ${hexs(d.rtVal)}, so the branch is <b>not taken</b>. Predict-not-taken was right, so there is no penalty.`]);
        }
        if (c.jump) ev.push(['Jump', s.halted ? `<b>halt</b> (j .): jumps to itself. The pipeline drains for 3 more cycles.` : `J resolved in ID: PC ← ${hexs(s.jumpTarget)}. The next sequential instruction is flushed.`, 'flush']);
        if (c.jumpReg) ev.push(['Jump', `JR: PC ← $${d.f.rs} = ${hexs(d.rsVal)}${d.fwdE ? ' (forwarded)' : ''}. The instruction fetched this cycle is flushed.`, 'flush']);
      }
    } else ev.push(['ID', `<span class="muted">Bubble. ${s.cycle === 1 ? 'The pipeline is still filling.' : 'The slot was flushed last cycle.'}</span>`]);
    // EX
    if (s.idex.valid) {
      const ic = s.idex.ctrl, pc = s.idex.pc;
      const src = (sel) => (sel === 2 ? ' <i>(MUX C/D ← EX/MEM)</i>' : sel === 1 ? ' <i>(MUX C/D ← MEM/WB)</i>' : '');
      const parts = [];
      if (ic.usesRs) parts.push(`A = ${hexs(x.aluA)}${src(x.fwdA)}`);
      if (ic.aluSrc) parts.push(`B = imm ${hexs(x.aluB)}`); else if (ic.usesRt) parts.push(`B = ${hexs(x.aluB)}${src(x.fwdB)}`);
      if (ic.aluOp === M.ALU.SLL) parts.push(`shamt = ${s.idex.shamt}`);
      let what = ic.memRead || ic.memWrite ? 'address' : 'result';
      if (ic.branch || ic.jump || ic.jumpReg) ev.push(['EX', `${I(pc)} was already resolved in ID, so the ALU output is not used.`]);
      else ev.push(['EX', `${I(pc)}: ALU ${M.ALU_NAME[ic.aluOp]} ${parts.join(', ')} → ${what} ${hexs(x.aluOut)}.${ic.memWrite ? ` Store data = ${hexs(x.rtFwd)}${src(x.fwdB)}.` : ''}`,
        ((x.fwdA && ic.usesRs) || (x.fwdB && ic.usesRt)) ? 'fwd' : '']);
    } else ev.push(['EX', `<span class="muted">Bubble${s.idex.uid < -1 ? ' inserted by last cycle\'s stall (all control signals 0)' : ''}.</span>`]);
    // MEM
    if (s.exmem.valid) {
      const em = s.exmem, pc = em.pc;
      if (em.memRead) ev.push(['MEM', `${I(pc)}: read mem[${hexs(em.alu & ~3)}] = ${hexs(s.mem.readData)}.`]);
      else if (em.memWrite) ev.push(['MEM', `${I(pc)}: store byte ${hexs(em.storeData & 0xFF)} to ${hexs(em.alu)} (word ${hexs(em.alu & ~3)}, lane ${em.alu & 3}). It is written at the clock edge.`]);
      else ev.push(['MEM', `${I(pc)} does not access memory; the ALU result passes through.`]);
    } else ev.push(['MEM', '<span class="muted">Bubble.</span>']);
    // WB
    if (s.memwb.valid) {
      const pc = s.memwb.pc;
      if (s.wb.we) ev.push(['WB', `${I(pc)}: $${s.memwb.dest} ← ${hexs(s.wb.data)} (${s.memwb.memToReg ? 'loaded word' : 'ALU result'}). The register file bypass also hands this value to ID in the same cycle.`]);
      else ev.push(['WB', `${I(pc)} retires with no register write.`]);
    } else ev.push(['WB', '<span class="muted">Bubble.</span>']);
    return ev;
  }

  function renderInspector() {
    const s = snapNow();
    const body = $('#inspBody');
    if (S.selUnit && UNIT_INFO[S.selUnit]) {
      const [name, stage, desc] = UNIT_INFO[S.selUnit];
      $('#inspTitle').innerHTML = `${esc(name)} <button class="x" id="inspClose">✕ close</button>`;
      body.innerHTML = `<p class="small muted">${stage} stage</p><p>${esc(desc)}</p>${unitLive(S.selUnit, s)}`;
      $('#inspClose').onclick = () => { S.selUnit = null; renderInspector(); renderDatapathSel(); };
      return;
    }
    $('#inspTitle').textContent = s ? `Cycle ${s.cycle}${s.done ? ', finished' : ''}` : 'This cycle';
    if (!s) { body.innerHTML = ''; return; }
    body.innerHTML = '<ul class="events">' + narrative(s).map(([st, h, k]) =>
      `<li class="${k || ''}" style="--c:${stageColor(s, st)}"><span class="s">${st}</span>${h}</li>`).join('') + '</ul>' +
      (s.done ? `<p class="small" style="margin-top:12px"><b class="pass">Program complete.</b> ${s.stats.retired} instructions retired in ${s.cycle} cycles.</p>` : '');
  }

  function stageColor(s, st) {
    const m = { IF: s.pc, ID: s.ifid.valid && s.ifid.pc, EX: s.idex.valid && s.idex.pc, MEM: s.exmem.valid && s.exmem.pc, WB: s.memwb.valid && s.memwb.pc };
    if (!(st in m)) return 'var(--line)';
    return (st === 'IF' || m[st] !== false) ? colorOf(m[st] || 0) : 'var(--line)';
  }

  function unitLive(u, s) {
    if (!s) return '';
    const kv = (o) => '<dl class="kv">' + Object.entries(o).map(([k, v]) => `<dt>${k}</dt><dd>${v}</dd>`).join('') + '</dl>';
    const d = s.id, x = s.ex, c = d.ctrl;
    switch (u) {
      case 'pc': return kv({ PC: hex(s.pc), PCWrite: s.stall ? '0 (stall)' : '1', next: hex(s.nextPc) });
      case 'imem': return kv({ address: hex(s.pc), word: hex(s.instr), decoded: esc(M.disasm(s.instr, s.pc)) });
      case 'bmux': case 'jmux': return kv({ select: ['PC+4', 'branch target', 'jump target', 'JR target'][s.pcSel], output: hex(s.nextPc) });
      case 'hazard': return kv({ 'load-use': d.loadUse ? 'YES' : 'no', 'branch/JR vs EX': d.branchHazEx ? 'YES' : 'no', 'branch/JR vs MEM load': d.branchHazMem ? 'YES' : 'no', stall: s.stall, 'IF.Flush': s.flush, 'PC select': ['PC+4', 'branch', 'J', 'JR'][s.pcSel] });
      case 'ctrl': case 'cmux': return kv(Object.fromEntries(Object.entries(c).map(([k, v]) => [k, k === 'aluOp' ? M.ALU_NAME[v] : v]))) + (s.stall ? '<p class="small">Stall: the control MUX sends zeros instead.</p>' : '');
      case 'rf': return kv({ [`read $${d.f.rs}`]: hex(d.rd1), [`read $${d.f.rt}`]: hex(d.rd2), write: s.wb.we ? `$${s.memwb.dest} ← ${hex(s.wb.data)}` : 'none', bypass: (d.rfBypass1 || d.rfBypass2) ? 'active' : 'no' });
      case 'muxe': case 'muxf': return kv({ 'E select': d.fwdE ? 'EX/MEM' : 'register file', 'F select': d.fwdF ? 'EX/MEM' : 'register file', 'rs value': hex(d.rsVal), 'rt value': hex(d.rtVal) });
      case 'cmp': return kv({ A: hex(d.rsVal), B: hex(d.rtVal), equal: d.equal });
      case 'se': return kv({ imm16: hex(d.f.imm, 4), mode: c.extZero ? 'zero-extend' : 'sign-extend', imm32: hex(d.imm) });
      case 'badd': return kv({ 'PC+4': hex(s.ifid.pc4), offset: signed(M.sext16(d.f.imm)) + ' words', target: hex(s.branchTarget) });
      case 'jcalc': return kv({ target26: hex(d.f.target, 7), 'J target': hex(s.jumpTarget) });
      case 'muxc': case 'muxd': case 'fwd': return kv({ ForwardA: ['0: ID/EX', '1: MEM/WB', '2: EX/MEM'][x.fwdA], ForwardB: ['0: ID/EX', '1: MEM/WB', '2: EX/MEM'][x.fwdB], 'ID/EX.rs': '$' + s.idex.rs, 'ID/EX.rt': '$' + s.idex.rt, 'EX/MEM.dest': s.exmem.regWrite ? '$' + s.exmem.dest : '-', 'MEM/WB.dest': s.memwb.regWrite ? '$' + s.memwb.dest : '-', 'ID fwd E/F': `${d.fwdE}/${d.fwdF}` });
      case 'muxa': return kv({ ALUSrc: s.idex.ctrl.aluSrc, 'operand B': hex(x.aluB) });
      case 'muxb': return kv({ RegDst: s.idex.ctrl.regDst, dest: '$' + x.exDest });
      case 'alu': return kv({ op: M.ALU_NAME[s.idex.ctrl.aluOp], A: hex(x.aluA), B: hex(x.aluB), shamt: s.idex.shamt, result: hex(x.aluOut) });
      case 'dmem': return kv({ address: hex(s.mem.addr), 'word index': s.mem.idx, 'read data': hex(s.mem.readData), MemWrite: s.exmem.memWrite, 'write byte': s.exmem.memWrite ? hex(s.exmem.storeData & 0xFF, 2) : '-' });
      case 'wbmux': return kv({ MemtoReg: s.memwb.memToReg, value: hex(s.wb.data), RegWrite: s.memwb.regWrite, dest: '$' + s.memwb.dest });
      default: return '';
    }
  }

  /* ================================================================== */
  /* Stage strip, listing, timing, panels                                 */
  /* ================================================================== */
  function renderStageStrip(s) {
    const cells = STAGES.map((st) => {
      let valid, pc, ev = '', tag = '';
      if (st === 'IF') { valid = true; pc = s.pc; if (s.stall) tag = '<span class="tag stall">hold</span>'; if (s.flush) tag = '<span class="tag flush">squash</span>'; ev = hexs(pc); }
      if (st === 'ID') { valid = s.ifid.valid; pc = s.ifid.pc; if (s.stall) tag = '<span class="tag stall">stall</span>'; if (s.id.fwdE || s.id.fwdF) tag += ' <span class="tag fwd">fwd</span>'; ev = valid ? decodeEv(s) : ''; }
      if (st === 'EX') { valid = s.idex.valid; pc = s.idex.pc; const ic = s.idex.ctrl, cons = ic.regWrite || ic.memWrite; if (valid && cons && ((s.ex.fwdA && ic.usesRs) || (s.ex.fwdB && ic.usesRt))) tag = '<span class="tag fwd">fwd</span>'; ev = valid ? (cons ? `→ ${hexs(s.ex.aluOut)}` : 'ALU unused') : ''; }
      if (st === 'MEM') { valid = s.exmem.valid; pc = s.exmem.pc; ev = valid ? (s.exmem.memRead ? `load ${hexs(s.mem.readData)}` : s.exmem.memWrite ? `store byte` : 'pass-through') : ''; }
      if (st === 'WB') { valid = s.memwb.valid; pc = s.memwb.pc; ev = valid ? (s.wb.we ? `$${s.memwb.dest} ← ${hexs(s.wb.data)}` : 'no write') : ''; }
      const bub = !valid;
      return `<div class="st ${bub ? 'bubble' : ''}" style="--c:${bub ? 'var(--line)' : colorOf(pc)}"><div class="nm"><span>${st}</span><span>${tag}</span></div>
        <div class="ins">${bub ? 'bubble' : esc(txt(pc))}</div><div class="ev">${esc(ev)}</div></div>`;
    });
    $('#stageStrip').innerHTML = cells.join('');
  }
  function decodeEv(s) {
    const c = s.id.ctrl;
    if (s.stall) return 'waiting for operand';
    if (c.branch) return s.id.equal ? `taken → ${hexs(s.branchTarget)}` : 'not taken';
    if (c.jump) return `jump → ${hexs(s.jumpTarget)}`;
    if (c.jumpReg) return `jr → ${hexs(s.id.rsVal)}`;
    return 'read registers';
  }

  function renderListing(s) {
    const where = {};
    const add = (pc, st) => { (where[pc] = where[pc] || []).push(st); };
    add(s.pc, 'IF');
    if (s.ifid.valid) add(s.ifid.pc, 'ID');
    if (s.idex.valid) add(s.idex.pc, 'EX');
    if (s.exmem.valid) add(s.exmem.pc, 'MEM');
    if (s.memwb.valid) add(s.memwb.pc, 'WB');
    $('#listing').innerHTML = S.prog.text.map((t) => {
      const e = S.srcByPc.get(t.addr);
      const b = (where[t.addr] || []).map((st) => `<span class="badge">${st}</span>`).join('');
      return `<div class="ln ${b ? 'active' : ''}" style="--c:${colorOf(t.addr)}"><span class="a">${hexs(t.addr)}</span>
        <span class="src" title="${esc(M.disasm(t.word, t.addr))} · ${hex(t.word)}">${e.label ? `<span class="muted">${esc(e.label)}:</span> ` : ''}${esc(e.src)}</span><span class="badges">${b}</span></div>`;
    }).join('');
  }

  function renderTiming() {
    const snaps = S.snaps;
    const rows = new Map();            // uid -> {key, pc, cells: {cycle: text}, type}
    const getRow = (uid, pc, key, type) => { if (!rows.has(uid)) rows.set(uid, { uid, pc, key, type, cells: {} }); return rows.get(uid); };
    let prevOcc = {};
    snaps.forEach((s, i) => {
      const cyc = i + 1;
      const occ = {};
      occ.IF = s.ifUid;
      if (s.ifid.valid) occ.ID = s.ifid.uid;
      if (s.idex.valid || s.idex.uid < -1) occ.EX = s.idex.uid;
      if (s.exmem.valid || s.exmem.uid < -1) occ.MEM = s.exmem.uid;
      if (s.memwb.valid || s.memwb.uid < -1) occ.WB = s.memwb.uid;
      STAGES.forEach((st) => {
        const uid = occ[st];
        if (uid === undefined || uid === -1) return;
        let pc, type = 'ins';
        if (uid < -1) type = 'bub';
        if (st === 'IF') pc = s.pc; else if (st === 'ID') pc = s.ifid.pc; else if (st === 'EX') pc = s.idex.pc; else if (st === 'MEM') pc = s.exmem.pc; else pc = s.memwb.pc;
        const r = getRow(uid, pc, type === 'bub' ? (bubbleKeys.get(uid) ?? 0) : uid, type);
        const stalled = prevOcc[st] === uid;
        r.cells[cyc] = { t: type === 'bub' ? 'nop' : st, st: stalled && type !== 'bub' };
      });
      if (s.squashedUid !== undefined) {
        const r = rows.get(s.squashedUid);
        if (r) { r.type = 'sq'; r.cells[cyc + 1] = { t: '✕', sq: true }; }
      }
      prevOcc = occ;
    });
    const list = Array.from(rows.values()).sort((a, b) => a.key - b.key);
    const n = snaps.length;
    const cur = S.cur;
    let h = '<thead><tr><th class="rowh">instruction</th>';
    for (let c = 1; c <= n; c++) h += `<th data-c="${c}" class="${c === cur ? 'cur' : ''}">${c}</th>`;
    h += '</tr></thead><tbody>';
    for (const r of list) {
      const col = r.type === 'bub' ? 'var(--line)' : colorOf(r.pc);
      const name = r.type === 'bub' ? 'bubble (stall)' : `${hexs(r.pc).padEnd(6)} ${txt(r.pc)}`;
      h += `<tr class="${r.type === 'bub' ? 'bubrow' : r.type === 'sq' ? 'sqrow' : ''}" style="--c:${col}"><th class="rowh" title="${esc(name)}">${esc(name)}</th>`;
      for (let c = 1; c <= n; c++) {
        const cell = r.cells[c];
        const cc = c === cur ? ' curcol' : '';
        if (!cell) h += `<td class="${cc}"></td>`;
        else if (cell.sq) h += `<td class="sq${cc}" title="squashed">✕</td>`;
        else h += `<td class="cell${cell.st ? ' st' : ''}${r.type === 'bub' ? ' bub' : ''}${cc}" title="${cell.st ? 'stalled in ' + cell.t : cell.t}">${cell.t}</td>`;
      }
      h += '</tr>';
    }
    h += '</tbody>';
    const tbl = $('#timing');
    tbl.innerHTML = h;
    $$('thead th[data-c]', tbl).forEach((th) => th.addEventListener('click', () => { stopPlay(); gotoCycle(+th.dataset.c); }));
    // keep current column in view
    const sc = $('#timingScroll');
    const th = $(`thead th[data-c="${cur}"]`, tbl);
    if (th) {
      const left = th.offsetLeft - 200;
      if (left < sc.scrollLeft || th.offsetLeft + 40 > sc.scrollLeft + sc.clientWidth) sc.scrollLeft = Math.max(0, left - 80);
    }
    const s = snapNow();
    if (s) {
      const idRow = $$('tbody tr', tbl)[list.findIndex((r) => r.uid === s.ifUid)];
      if (idRow) {
        const top = idRow.offsetTop;
        if (top > sc.scrollTop + sc.clientHeight - 30 || top < sc.scrollTop + 24) sc.scrollTop = Math.max(0, top - sc.clientHeight + 60);
      }
    }
  }
  // bubble uid -> sort key (just above the instruction it was stalled for)
  const bubbleKeys = new Map();
  function noteBubble(s) { if (s.bubbleUid !== undefined) bubbleKeys.set(s.bubbleUid, s.ifid.uid - 0.5); }

  function renderStats(s) {
    const st = s.stats;
    const cpi = st.retired ? (s.cycle / st.retired) : 0;
    $('#stats').innerHTML = `
      <div class="s"><div class="v">${s.cycle}</div><div class="l">clock cycles</div></div>
      <div class="s"><div class="v">${st.retired}</div><div class="l">instructions retired</div></div>
      <div class="s"><div class="v">${st.retired ? cpi.toFixed(2) : '–'}</div><div class="l">CPI so far (ideal 1.0)</div></div>
      <div class="s"><div class="v">${st.stalls}</div><div class="l">stall cycles · ${st.loadUse} load-use, ${st.branchStall} branch/JR</div></div>
      <div class="s"><div class="v">${st.flushes}</div><div class="l">flushed slots (taken BEQ / J / JR)</div></div>
      <div class="s"><div class="v">${st.fwdEx + st.fwdId}</div><div class="l">forwards · ${st.fwdEx} into EX, ${st.fwdId} into ID</div></div>
      <div class="s full">${s.done ? `<span class="done">✓ Finished.</span> All instructions before the halt have written back.` : `<span class="muted">Running. Press Step or → to advance one clock.</span>`}</div>`;
  }

  function bits(o, keys) {
    return '<div class="ctl">' + keys.map(([k, l]) => `<span class="bit ${o[k] ? 'one' : ''}">${l}=${k === 'aluOp' ? M.ALU_NAME[o[k]] : (o[k] ? 1 : 0)}</span>`).join('') + '</div>';
  }
  function renderPregs(s) {
    const kv = (o) => '<dl class="kv">' + Object.entries(o).map(([k, v]) => `<dt>${k}</dt><dd>${v}</dd>`).join('') + '</dl>';
    const head = (n, v, pc) => `<h4><span>${n}</span><span class="muted pi">${v ? esc(txt(pc)) : 'bubble'}</span></h4>`;
    const col = (v, pc) => (v ? colorOf(pc) : 'var(--line)') + (v ? '' : ';opacity:.6');
    const a = s.ifid, b = s.idex, c = s.exmem, d = s.memwb;
    $('#pregs').innerHTML =
      `<div class="preg-card" style="--c:${col(a.valid, a.pc)}">${head('IF/ID', a.valid, a.pc)}${kv({ PC: hex(a.pc), 'PC+4': hex(a.pc4), instr: hex(a.instr) })}</div>` +
      `<div class="preg-card" style="--c:${col(b.valid, b.pc)}">${head('ID/EX', b.valid, b.pc)}${kv({ 'rs val': hex(b.rsVal), 'rt val': hex(b.rtVal), imm: hex(b.imm), 'rs rt rd': `$${b.rs} $${b.rt} $${b.rd}`, shamt: b.shamt })}` +
      bits(b.ctrl, [['regWrite', 'RegWr'], ['memToReg', 'MemToReg'], ['memRead', 'MemRd'], ['memWrite', 'MemWr'], ['regDst', 'RegDst'], ['aluSrc', 'ALUSrc'], ['aluOp', 'ALUOp']]) + '</div>' +
      `<div class="preg-card" style="--c:${col(c.valid, c.pc)}">${head('EX/MEM', c.valid, c.pc)}${kv({ 'ALU result': hex(c.alu), 'store data': hex(c.storeData), dest: '$' + c.dest })}` +
      bits(c, [['regWrite', 'RegWr'], ['memToReg', 'MemToReg'], ['memRead', 'MemRd'], ['memWrite', 'MemWr']]) + '</div>' +
      `<div class="preg-card" style="--c:${col(d.valid, d.pc)}">${head('MEM/WB', d.valid, d.pc)}${kv({ 'read data': hex(d.readData), 'ALU result': hex(d.alu), dest: '$' + d.dest })}` +
      bits(d, [['regWrite', 'RegWr'], ['memToReg', 'MemToReg']]) + '</div>';
  }

  function fmtVal(v) { return S.radix === 'hex' ? hex(v) : String(v | 0); }
  function renderRegs(s) {
    const w = s.wb.we ? s.memwb.dest : -1;
    const reads = new Set();
    if (s.ifid.valid) { if (s.id.ctrl.usesRs || s.id.ctrl.jumpReg) reads.add(s.id.f.rs); if (s.id.ctrl.usesRt) reads.add(s.id.f.rt); }
    let h = '';
    for (let i = 0; i < 32; i++) {
      h += `<div class="r ${i === w ? 'w' : ''} ${reads.has(i) && i ? 'rd' : ''}" title="${i === w ? 'written at the end of this cycle' : reads.has(i) ? 'read by ID this cycle' : ''}"><span class="n">$${i} ${M.ABI[i]}</span><span>${fmtVal(s.regsAfter[i])}</span></div>`;
    }
    $('#regs').innerHTML = h;
  }
  function renderMem(s) {
    const wIdx = s.exmem.valid && s.exmem.memWrite ? s.mem.idx : -1;
    const rIdx = s.exmem.valid && s.exmem.memRead ? s.mem.idx : -1;
    let h = '';
    for (let i = 0; i < 32; i++) {
      const v = s.memAfter[i];
      let vs = hex(v);
      if (i === wIdx) {
        const lane = s.exmem.alu & 3;
        const hx = (v >>> 0).toString(16).toUpperCase().padStart(8, '0');
        const pos = 6 - lane * 2;
        vs = '0x' + hx.slice(0, pos) + '<b>' + hx.slice(pos, pos + 2) + '</b>' + hx.slice(pos + 2);
      }
      h += `<div class="m ${i === wIdx ? 'w' : ''} ${i === rIdx ? 'rd' : ''}"><span class="n">${hex(i * 4, 3)}</span><span class="by">${vs}</span></div>`;
    }
    $('#mem').innerHTML = h;
  }

  function renderAll() {
    const s = snapNow();
    $('#cycleNo').textContent = s ? s.cycle : 0;
    $('#btnBack').disabled = S.cur <= 1;
    $('#btnStep').disabled = !!(s && s.done && S.cur === S.snaps.length);
    $('#btnEnd').disabled = $('#btnStep').disabled;
    if (!s) return;
    renderDatapath(s);
    renderStageStrip(s);
    renderInspector();
    renderListing(s);
    renderTiming();
    renderStats(s);
    renderPregs(s);
    renderRegs(s);
    renderMem(s);
  }

  /* ================================================================== */
  /* Controls                                                             */
  /* ================================================================== */
  function doStep() {
    if (S.cur < S.snaps.length) { S.cur++; renderAll(); return true; }
    const ok = stepSim();
    renderAll();
    return ok;
  }
  function stopPlay() { if (S.playing) { clearInterval(S.playing); S.playing = null; $('#btnPlay').textContent = '▶ Run'; } }
  function togglePlay() {
    if (S.playing) { stopPlay(); return; }
    $('#btnPlay').textContent = '❚❚ Pause';
    const tick = () => { const s = snapNow(); if ((s && s.done && S.cur === S.snaps.length) || !doStep()) stopPlay(); };
    const ms = () => Math.round(1400 / Math.pow(1.45, +$('#speed').value - 1));
    S.playing = setInterval(tick, ms());
    $('#speed').oninput = () => { if (S.playing) { clearInterval(S.playing); S.playing = setInterval(tick, ms()); } };
  }
  function runToEnd() {
    stopPlay();
    while (stepSim()) { /* run */ }
    S.cur = S.snaps.length;
    renderAll();
  }
  function resetSim() { stopPlay(); S.cur = Math.min(1, S.snaps.length); renderAll(); }
  function back() { stopPlay(); if (S.cur > 1) { S.cur--; renderAll(); } }

  function loadPreset(id, cycle) {
    const p = window.PROGRAMS.find((x) => x.id === id) || window.PROGRAMS[0];
    stopPlay();
    bubbleKeys.clear();
    $('#presetSel').value = p.id;
    $('#editor').value = p.src;
    loadProgram(p.src, p.id);
    if (cycle) { while (S.snaps.length < cycle && stepSim()) { /* advance */ } S.cur = Math.min(cycle, S.snaps.length); renderAll(); }
    setAsmMsg(`${p.title}: ${S.prog.text.length} instructions, ${S.prog.data.length} data words.`, 'ok');
  }

  function showMe(programId, pred) {
    loadPreset(programId);
    let c = 1;
    while (c <= 5000) {
      if (c > S.snaps.length && !stepSim()) break;
      if (pred(S.snaps[c - 1])) break;
      c++;
    }
    S.cur = Math.min(c, S.snaps.length);
    renderAll();
    document.getElementById('sim').scrollIntoView({ behavior: 'smooth' });
  }

  function setAsmMsg(m, cls) { const e = $('#asmMsg'); e.textContent = m; e.className = 'asm-msg ' + (cls || ''); }

  function initControls() {
    const sel = $('#presetSel');
    sel.innerHTML = window.PROGRAMS.map((p) => `<option value="${p.id}">${esc(p.title)}</option>`).join('') + '<option value="__custom" disabled>Custom (edited)</option>';
    sel.onchange = () => loadPreset(sel.value);
    $('#btnStep').onclick = () => { stopPlay(); doStep(); };
    $('#btnBack').onclick = back;
    $('#btnReset').onclick = resetSim;
    $('#btnPlay').onclick = togglePlay;
    $('#btnEnd').onclick = runToEnd;
    $('#btnEdit').onclick = () => { const p = $('#editorPanel'); p.hidden = !p.hidden; $('#btnEdit').textContent = p.hidden ? '✎ Edit program' : '✕ Close editor'; };
    $('#btnAssemble').onclick = () => {
      try {
        stopPlay(); bubbleKeys.clear();
        loadProgram($('#editor').value, null);
        $('#presetSel').value = '__custom';
        setAsmMsg(`✓ Assembled ${S.prog.text.length} instructions, ${S.prog.data.length} data words. Loaded.`, 'ok');
      } catch (e) { setAsmMsg('✗ ' + e.message, 'err'); }
    };
    $$('#radix button').forEach((b) => b.onclick = () => { S.radix = b.dataset.r; $$('#radix button').forEach((x) => x.classList.toggle('on', x === b)); renderAll(); });
    document.addEventListener('keydown', (e) => {
      if (e.target.closest('textarea, input, select')) return;
      if (e.key === 'ArrowRight' || e.key === ' ') { if (isSimVisible()) { e.preventDefault(); stopPlay(); doStep(); } }
      else if (e.key === 'ArrowLeft') { if (isSimVisible()) { e.preventDefault(); back(); } }
      else if (e.key === 'p' || e.key === 'P') togglePlay();
      else if (e.key === 'r' || e.key === 'R') resetSim();
      else if (e.key === 'e' || e.key === 'E') runToEnd();
    });
  }
  function isSimVisible() { const r = $('#sim').getBoundingClientRect(); return r.top < innerHeight && r.bottom > 0; }

  /* ================================================================== */
  /* Tooltip + theme                                                      */
  /* ================================================================== */
  function showTip(e, html) {
    const t = $('#tip'); t.innerHTML = html; t.hidden = false;
    const w = t.offsetWidth, h = t.offsetHeight;
    let x = e.clientX + 14, y = e.clientY + 14;
    if (x + w > innerWidth - 8) x = e.clientX - w - 14;
    if (y + h > innerHeight - 8) y = e.clientY - h - 14;
    t.style.left = x + 'px'; t.style.top = y + 'px';
  }
  function hideTip() { $('#tip').hidden = true; }
  function initTheme() {
    let saved = null;
    try { saved = localStorage.getItem('mm-theme'); } catch (e) { /* storage unavailable */ }
    if (saved) document.documentElement.setAttribute('data-theme', saved);
    $('#themeBtn').onclick = () => {
      const curDark = document.documentElement.getAttribute('data-theme') === 'dark' ||
        (!document.documentElement.getAttribute('data-theme') && matchMedia('(prefers-color-scheme: dark)').matches);
      const next = curDark ? 'light' : 'dark';
      document.documentElement.setAttribute('data-theme', next);
      try { localStorage.setItem('mm-theme', next); } catch (e) { /* ignore */ }
    };
  }

  /* ================================================================== */
  /* Learn section                                                        */
  /* ================================================================== */
  function initLearn() {
    const stages = [
      ['IF', 'Instruction Fetch', 'Read the instruction at PC and compute PC+4. Pick the next PC from four sources: PC+4, the branch target, the J target, or the JR register.', ['PC register (write-enable for stalls)', 'Instruction memory (async ROM)', 'Branch MUX → Jump MUX']],
      ['ID', 'Decode & resolve', 'Decode the instruction, read two registers, and extend the immediate. BEQ, J and JR are resolved here, so only one slot is lost when control flow changes.', ['Control unit, hazard unit', 'Register file with WB bypass', 'MUX E/F forwarding, comparator, target adders']],
      ['EX', 'Execute', 'The ALU computes a result or a memory address. Operands pass through the forwarding muxes first, so the ALU always sees the newest values.', ['MUX C/D (forwarding), MUX A (ALUSrc)', 'ALU: ADD SUB AND XOR NOR SLL', 'MUX B chooses rt or rd']],
      ['MEM', 'Memory access', 'LW reads a word from data memory. SB writes one byte lane. Every other instruction passes its ALU result straight through.', ['4 KiB data memory, little-endian', 'Async read, sync byte write']],
      ['WB', 'Write back', 'The result is written to the register file: either the loaded word or the ALU result, chosen by MemtoReg. The same value is forwarded to EX.', ['Write-back MUX', 'Register file write port']],
    ];
    $('#stageCards').innerHTML = stages.map(([k, n, p, list], i) => `<div class="card stage-card" style="--c:var(--i${i})"><div class="k">${k}</div><h3>${n}</h3><p>${p}</p><ul>${list.map((x) => `<li>${x}</li>`).join('')}</ul></div>`).join('');

    const hz = [
      { kind: 'Data hazard · RAW', col: 'var(--fwd)', title: 'Back-to-back ALU dependence', text: 'The second instruction needs a result that is still in the pipeline. The value exists at the end of EX, so it is forwarded from EX/MEM straight into the ALU input and no time is lost.', code: 'add $3, $1, $2\nsb  $3, 0($0)   # $3 via MUX D ← EX/MEM', cost: '0 cycles', prog: '00_tour', pred: (s) => s.idex.valid && s.ex.fwdB === 2 && s.idex.ctrl.memWrite },
      { kind: 'Data hazard · RAW', col: 'var(--fwd)', title: 'Dependence two instructions apart', text: 'The producer has reached WB. MUX C/D take the write-back value. An instruction three apart gets the value from the register file bypass instead.', code: 'li  $1, 7\nli  $2, 3\nadd $3, $1, $2  # $1 via MUX C ← MEM/WB', cost: '0 cycles', prog: '00_tour', pred: (s) => s.idex.valid && s.ex.fwdA === 1 },
      { kind: 'Load-use hazard', col: 'var(--stall)', title: 'Using a value right after LW', text: 'The loaded word only exists after MEM, which is too late for the next instruction\'s EX. The hazard unit stalls once, and then the word is forwarded from MEM/WB.', code: 'lw  $4, 0($0)\nxor $5, $4, $1  # stall 1, then MEM/WB fwd', cost: '1 stall', prog: '00_tour', pred: (s) => s.id.loadUse },
      { kind: 'Branch data hazard', col: 'var(--stall)', title: 'BEQ/JR needs a value still in EX', text: 'Branches compare in ID, one stage earlier than ALU instructions read their operands. If the producer is in EX, stall one cycle, then MUX E/F forwards from EX/MEM.', code: 'xor $5, $4, $1\nbeq $5, $0, skip # stall 1, MUX E ← EX/MEM', cost: '1 stall', prog: '00_tour', pred: (s) => s.id.branchHazEx },
      { kind: 'Branch data hazard', col: 'var(--stall)', title: 'BEQ right after LW', text: 'The load has to finish MEM before its value exists. That means two stalls; after them the register-file bypass hands the word to the comparator.', code: 'lw  $3, 0($0)\nbeq $3, $1, t1b  # stall 2', cost: '2 stalls', prog: '03_control', pred: (s) => s.id.branchHazMem },
      { kind: 'Control hazard', col: 'var(--flush)', title: 'Taken branch, J, JR', text: 'Fetch assumes "not taken" and keeps going. When ID resolves a taken BEQ or any jump, the one wrong-path instruction in IF is flushed and the PC is redirected.', code: 'beq $3, $4, skip # taken\nli  $6, 99       # ✕ flushed', cost: '1 slot', prog: '00_tour', pred: (s) => s.flush && s.pcSel === 1 },
    ];
    $('#hazardCards').innerHTML = hz.map((h, i) => `<div class="card hz"><span class="kind" style="color:${h.col}">${h.kind}</span><h3>${h.title}</h3><p>${h.text}</p><pre>${esc(h.code)}</pre>
      <div class="cost"><span>penalty: ${h.cost}</span><button class="btn" data-hz="${i}">Show me ▶</button></div></div>`).join('') +
      `<p class="small muted" style="grid-column:1/-1;margin:0">Structural hazards cannot happen here. Instruction and data memories are separate, and the register file has two read ports plus a write port whose value is bypassed to the readers.</p>`;
    $$('[data-hz]').forEach((b) => b.onclick = () => { const h = hz[+b.dataset.hz]; showMe(h.prog, h.pred); });

    // control table
    const rows = [['add', 0, 32], ['nor', 0, 39], ['xor', 0, 38], ['sll', 0, 0], ['jr', 0, 8], ['andi', 12, 0], ['subui', 25, 0], ['lw', 35, 0], ['sb', 40, 0], ['beq', 4, 0], ['j', 2, 0]];
    const cols = [['regWrite', 'RegWrite'], ['memToReg', 'MemtoReg'], ['memRead', 'MemRead'], ['memWrite', 'MemWrite'], ['regDst', 'RegDst'], ['aluSrc', 'ALUSrc'], ['aluOp', 'ALUOp'], ['branch', 'Branch'], ['jump', 'Jump'], ['jumpReg', 'JumpReg'], ['extZero', 'ZeroExt'], ['usesRs', 'reads rs'], ['usesRt', 'reads rt']];
    $('#ctrlTable').innerHTML = '<thead><tr><th>Instr</th>' + cols.map((c) => `<th>${c[1]}</th>`).join('') + '</tr></thead><tbody>' +
      rows.map(([n, op, fn]) => { const c = M.control(op, fn); return `<tr><td>${n.toUpperCase()}</td>` + cols.map(([k]) => k === 'aluOp' ? `<td>${(c.regWrite || c.memRead || c.memWrite || c.branch) ? M.ALU_NAME[c[k]] : '–'}</td>` : `<td class="${c[k] ? 'one' : 'zero'}">${c[k]}</td>`).join('') + '</tr>'; }).join('') + '</tbody>';
  }

  /* ================================================================== */
  /* ISA                                                                  */
  /* ================================================================== */
  const ISA = [
    ['ADD', 'R', 'add rd, rs, rt', '000000', '100000', 'rd ← rs + rt'],
    ['NOR', 'R', 'nor rd, rs, rt', '000000', '100111', 'rd ← ~(rs | rt)'],
    ['XOR', 'R', 'xor rd, rs, rt', '000000', '100110', 'rd ← rs ^ rt'],
    ['SLL', 'R', 'sll rd, rt, shamt', '000000', '000000', 'rd ← rt << shamt'],
    ['JR', 'R', 'jr rs', '000000', '001000', 'PC ← rs'],
    ['ANDI', 'I', 'andi rt, rs, imm', '001100', '–', 'rt ← rs & zext(imm)'],
    ['SUBUI', 'I', 'subui rt, rs, imm', '011001', '–', 'rt ← rs − sext(imm)  (li rt, k ≡ subui rt, $0, −k)'],
    ['LW', 'I', 'lw rt, off(rs)', '100011', '–', 'rt ← MEM32[rs + sext(off)]'],
    ['SB', 'I', 'sb rt, off(rs)', '101000', '–', 'MEM8[rs + sext(off)] ← rt[7:0]'],
    ['BEQ', 'I', 'beq rs, rt, label', '000100', '–', 'if rs = rt: PC ← PC+4 + sext(off)<<2'],
    ['J', 'J', 'j label', '000010', '–', 'PC ← {PC+4[31:28], target, 00}'],
  ];
  function initISA() {
    $('#isaTable').innerHTML = '<thead><tr><th>Instr</th><th>Fmt</th><th>Syntax</th><th>opcode</th><th>funct</th><th>Operation</th></tr></thead><tbody>' +
      ISA.map((r) => `<tr><td>${r[0]}</td><td>${r[1]}</td><td style="text-align:left">${r[2]}</td><td>${r[3]}</td><td>${r[4]}</td><td class="l">${esc(r[5])}</td></tr>`).join('') + '</tbody>';
    const ex = ['add $t0, $t1, $t2', 'sll $8, $9, 4', 'jr $ra', 'andi $8, $9, 10', 'subui $8, $9, 5', 'lw $t0, 100($t1)', 'sb $t0, 100($t1)', 'beq $8, $9, -3', 'j 0x100040', 'li $1, 42'];
    $('#encExamples').innerHTML = ex.map((e) => `<button class="btn" data-e="${esc(e)}">${esc(e)}</button>`).join('');
    $$('#encExamples button').forEach((b) => b.onclick = () => { $('#encIn').value = b.dataset.e; encode(); });
    $('#encIn').addEventListener('input', encode);
    encode();
  }
  function encode() {
    const src = $('#encIn').value;
    let w;
    try {
      const p = M.assemble(src.includes(':') ? src : src);
      if (p.text.length !== 1) throw new Error(p.text.length ? 'one instruction at a time, please' : 'type an instruction');
      w = p.text[0].word;
    } catch (e) {
      $('#encHex').textContent = ''; $('#encBits').innerHTML = ''; $('#encInfo').innerHTML = `<span style="color:var(--stall)">${esc(e.message)}</span>`;
      return;
    }
    const f = M.decodeFields(w);
    const b = (v, n) => (v >>> 0).toString(2).padStart(n, '0');
    let fields;
    if (f.op === 0) fields = [['opcode', b(f.op, 6), 'i0'], ['rs', b(f.rs, 5), 'i1'], ['rt', b(f.rt, 5), 'i2'], ['rd', b(f.rd, 5), 'i3'], ['shamt', b(f.shamt, 5), 'i4'], ['funct', b(f.funct, 6), 'i5']];
    else if (f.op === 2) fields = [['opcode', b(f.op, 6), 'i0'], ['target', b(f.target, 26), 'i4']];
    else fields = [['opcode', b(f.op, 6), 'i0'], ['rs', b(f.rs, 5), 'i1'], ['rt', b(f.rt, 5), 'i2'], ['immediate', b(f.imm, 16), 'i3']];
    $('#encHex').textContent = hex(w);
    $('#encBits').innerHTML = fields.map(([n, bitsS, c]) => `<div class="fld" style="--c:var(--${c});flex:${bitsS.length} 0 auto"><div class="b">${bitsS}</div><div class="n">${n} [${bitsS.length}]</div></div>`).join('');
    const c = M.control(f.op, f.funct);
    const fmt = f.op === 0 ? 'R-type' : f.op === 2 ? 'J-type' : 'I-type';
    const on = Object.entries(c).filter(([k, v]) => v && k !== 'aluOp').map(([k]) => k);
    $('#encInfo').innerHTML = `<b>${fmt}</b> · decodes as <code>${esc(M.disasm(w, 0))}</code>` +
      '<div class="ctl">' + Object.entries(c).map(([k, v]) => `<span class="bit ${v && k !== 'aluOp' ? 'one' : ''}">${k}=${k === 'aluOp' ? M.ALU_NAME[v] : v}</span>`).join('') + '</div>' +
      (on.length ? '' : '<p class="small">No control signal is asserted, so this is a NOP.</p>');
  }

  /* ================================================================== */
  /* Design review                                                        */
  /* ================================================================== */
  const FINDINGS = [
    ['critical', 'Instruction ROM encodings don\'t match their comments', 'v11/1_Fetch/instruction_memory.vhd', '10 of the 12 words decode to a different instruction than the comment says. "LW R9, 24(R4)" is really add $5,$6,$7. "JR R21" (0x08150008) is J 0x540020. "SUBUI" uses the ANDI opcode.', 'Programs are written in assembly and encoded by an assembler, and the Python and JS assemblers are cross-checked against each other. The ROM is loaded from a hex file.'],
    ['critical', 'Branch selects the wrong next-PC input', 'v11/2_Decode/hazard_control_unit.vhd', 'On a branch the hazard unit drives branch_mux_signal = "10", which is the load_address input (always 0), not "01", the branch target. Every taken branch restarts the program at 0x0. This was seen in simulation at 249 ns.', 'A single pc_sel decision in the hazard unit, resolved in ID, drives the branch and jump MUXes.'],
    ['critical', 'Stage logic is clocked, so results arrive a cycle late', 'control_unit.vhd, alu.vhd, hazard_control_unit.vhd, register_memory.vhd, instruction_memory.vhd', 'The control unit, ALU, hazard unit, register-file reads and instruction ROM are all registered. Control signals therefore reach ID/EX one cycle after the data they belong to. In the ALU, alu_result <= temp_alu_result reads a signal assigned in the same process, which adds a second cycle, and Zero is computed from the stale value.', 'Everything between pipeline registers is combinational. Only the PC, the four pipeline registers, the register file and the data memory hold state.'],
    ['critical', 'LW writes back the store-data register', 'v11/test_bench.vhd (mem_wb_buffer map)', 'MEM/WB read_data_reg is connected to ex_mem_read_data2, not to the data-memory output, so a load never returns memory contents.', 'mem_wb_d.read_data <= dmem_rdata. Directed test 02 checks this, and so does the wb_wrong_data mutant.'],
    ['critical', 'I-type results go to the wrong register', 'v11/test_bench.vhd (ex_mem_buffer map)', 'EX/MEM rd is taken from id_ex_rd instead of the RegDst mux output. ANDI, SUBUI and LW therefore write to the register named by immediate bits [15:11].', 'EX/MEM.dest comes from MUX B (RegDst).'],
    ['critical', 'Register write uses mismatched stages', 'v11/test_bench.vhd (register_file map)', 'write_register comes from wb_buffer, which is delayed a cycle, but reg_write comes straight from MEM/WB. Each write lands in the previous instruction\'s destination.', 'Write enable, address and data all come from MEM/WB in the same cycle.'],
    ['critical', 'JR target never connected', 'v11/test_bench.vhd', 'The jr_address signal feeding the address buffer is never driven, so JR always jumps to 0.', 'JR target = MUX E output (the forwarded rs value), resolved in ID.'],
    ['critical', 'BEQ decoded incorrectly', 'v11/2_Decode/control_unit.vhd', 'BEQ sets RegWrite = 1 and ALUSrc = 1, so it compares rs with the immediate and then writes a register. ALUOp is never assigned for any I-type instruction, so it keeps whatever value the previous instruction left (an inferred latch).', 'Complete truth table, with every output assigned on every path from a CTRL_NOP default.'],
    ['major', 'Forwarding selects swapped between stages', 'v11/test_bench.vhd (forward_control_unit map)', 'The ID-stage comparison outputs (1/2) drive the EX muxes C/D, and the EX-stage outputs (3/4) drive the ID muxes E/F. MemtoReg for MEM/WB forwarding is taken from EX/MEM.', 'A separate, named select for each mux. The EX part matches the textbook conditions exactly.'],
    ['major', 'Forwarding ignores RegWrite and $0', 'v11/3_Execute/forward_control_unit.vhd', 'Any instruction whose rd field matches is forwarded, including SB, BEQ and J, and writes to $0. The combinational process also has a clk sensitivity it does not use.', 'Only producers with RegWrite = 1 and dest ≠ $0 are forwarded. The fwd_r0 and fwd_no_regwrite mutants check this.'],
    ['major', 'Forwarding MUX placed after the ALUSrc MUX', 'datapath diagram, MUX A → MUX D', 'With MUX D after MUX A, a forwarded rt value replaces the immediate of ANDI, SUBUI, LW and SB whenever rt matches a recent destination. SB store data is also taken before forwarding.', 'MUX D (forwarding) comes first, then MUX A (ALUSrc). Store data is the MUX D output.'],
    ['major', 'ID/EX flush does not stop the flushed instruction', 'v11/2_Decode/id_ex_buffer.vhd', 'Flush clears the internal staging signals but not the outputs, and alu_op bypasses the staging entirely. The flushed instruction\'s control still reaches EX.', 'The bubble is loaded into the one ID/EX register, with valid = 0 and all control = 0.'],
    ['major', 'EX/MEM flush never driven', 'v11/test_bench.vhd', 'The hazard unit has an ex_mem_flush output, but it is not mapped. ex_mem_flush and mem_wb_flush are constant 0.', 'With branches resolved in ID, the EX/MEM flush is no longer needed.'],
    ['major', 'Branch decision mixes two instructions', 'v11/test_bench.vhd (branch_and_gate map)', 'The AND gate combines EX/MEM.Branch (MEM stage) with the live ALU Zero output (EX stage), which belong to different instructions.', 'BEQ is compared in ID with forwarded operands.'],
    ['major', '$0 writable, $31 reads as 0', 'v11/2_Decode/register_memory.vhd', 'Reads of register 31 are hard-coded to 0 while writes to register 0 go through. That is the opposite of MIPS.', '$0 is hard-wired to zero and all 31 other registers work normally. A write-through bypass is added.'],
    ['major', 'Store byte writes a stale word, always to lane 0', 'v11/4_Memory/data_memory.vhd', 'The read-modify-write goes through a signal (temp_data), so the old temp value is written. The byte always lands in bits 7:0. The byte address is used as a word index, so addresses ≥ 1024 go out of range.', 'Byte-addressed, little-endian lane select addr[1:0], word index addr[11:2], addresses wrap.'],
    ['major', 'Branch offset not shifted', 'v11/3_Execute/branch_address_calc.vhd', 'Target = PC+4 + imm, missing the << 2 that turns a word offset into a byte offset.', 'PC+4 + (sext(imm) << 2). The branch_no_shift mutant checks this.'],
    ['major', 'Load-use handled by flush and replay', 'v11/2_Decode/hazard_control_unit.vhd', 'On a load-use hazard, v11 flushes IF/ID and ID/EX and reloads the PC through the Load Address path. That costs 2 cycles instead of 1, and it fires even when rt is a destination rather than a source.', 'A classic 1-cycle interlock (PCWrite / IF/ID.Write = 0, bubble into ID/EX) that checks only real source operands.'],
    ['minor', 'Mixed rising/falling-edge clocking', 'address_buffer, if_id_buffer, id_ex_buffer, ex_mem_buffer, mem_wb_buffer, register_memory', 'About half the state updates on the falling edge. That creates half-cycle timing paths and makes the design hard to reason about. The address buffer and WB buffer existed only to paper over this.', 'A single rising edge with synchronous reset. The address buffer and WB buffer are removed.'],
    ['minor', 'U/X values masked instead of fixed', 'program_counter.vhd, alu.vhd, wb_buffer.vhd', 'Comparisons against "UUUU…" and "XXXX…" hide uninitialised signals instead of fixing the missing reset.', 'A proper synchronous reset. No metavalue checks are needed.'],
    ['minor', 'ANDI sign-extends its immediate', 'v11/2_Decode/sign_extend.vhd', 'MIPS logical immediates are zero-extended. With sign extension, an ANDI immediate of 0x8000 or more also keeps the upper 16 bits of rs, which MIPS code does not expect.', 'ExtOp from the control unit: zero-extend for ANDI, sign-extend otherwise.'],
    ['minor', 'Testbench is not self-checking', 'v11/test_bench.vhd', 'It runs 20 clock cycles with no reset and no checks. Every bug above passed without comment.', 'Self-checking against a golden model, 1,000+ random programs, cycle-exact cross-check, and mutation testing.'],
  ];
  function initReview() {
    const rows = [
      ['29', '0x00', 'FFFFFFFF', 'ROM is registered: the first fetch returns the invalid-word default', 1],
      ['69', '0x08', 'XXXXXXXX', 'ALU result undefined (clocked ALU, uninitialised operands)', 1],
      ['109', '0x10', '00000000', 'write-back to $31 (0x1F): wrong destination', 1],
      ['209', '0x24', '00000000', 'jump MUX selects "J" (0x08150008 decoded as J)', 0],
      ['229', '0x540020', '00000008', 'PC has left the program', 1],
      ['249', '0x00', '00012800', 'branch picked load_address = 0, so the program restarts', 1],
    ];
    $('#v11Trace').innerHTML = '<table><thead><tr><th>t (ns)</th><th>PC</th><th>ALU</th><th>observation</th></tr></thead><tbody>' +
      rows.map((r) => `<tr class="${r[4] ? 'bad' : ''}"><td>${r[0]}</td><td>${r[1]}</td><td>${r[2]}</td><td style="white-space:normal">${esc(r[3])}</td></tr>`).join('') + '</tbody></table>';

    const arch = [
      ['Branch resolution', 'BEQ resolved in MEM by an AND gate: 3 wrong-path instructions flushed (IF/ID, ID/EX, EX/MEM).', 'BEQ, J and JR resolved in ID with a comparator and ID forwarding (MUX E/F): 1 flushed slot.'],
      ['Load-use hazard', 'Flush IF/ID and ID/EX, then re-fetch through the "Load Address" path: 2 lost cycles.', 'Classic interlock: PCWrite = IF/ID.Write = 0 and a bubble into ID/EX. 1 lost cycle.'],
      ['Clocking', 'Mixed rising and falling edges. Control, ALU, hazard unit and ROM all registered. Address buffer and WB buffer added to compensate.', 'One rising edge. Every stage is combinational between the pipeline registers.'],
      ['Forwarding order', 'MUX A (ALUSrc) before MUX D (forward): a forward could overwrite the immediate.', 'Forward first (MUX C/D), then ALUSrc (MUX A). SB data uses the forwarded value.'],
      ['Register file', '$31 reads as 0, $0 is writable. A separate WB buffer delays writes.', '$0 hard-wired to zero. A write-through bypass stands in for write-first-half/read-second-half.'],
      ['Verification', '20-cycle testbench, waveform inspection by eye.', 'Self-checking testbench, golden ISS, 1,000 constrained-random programs, mutation testing, and a JS model that matches the RTL cycle for cycle.'],
    ];
    $('#archGrid').innerHTML = arch.map(([t, a, b]) => `<div class="card arch"><h3>${t}</h3><div class="ba"><div><b>v11</b>${esc(a)}</div><div><b>v12</b>${esc(b)}</div></div></div>`).join('');

    const sevs = ['all', 'critical', 'major', 'minor'];
    let cur = 'all';
    const draw = () => {
      const list = FINDINGS.map((f, i) => [i + 1, ...f]).filter((f) => cur === 'all' || f[1] === cur);
      $('#findings').innerHTML = list.map(([n, sev, title, file, what, fix]) => `<div class="card finding"><span class="no">${String(n).padStart(2, '0')}</span>
        <h4>${esc(title)} <span class="sev ${sev}">${sev}</span></h4><div class="body"><div class="file">${esc(file)}</div><p>${esc(what)}</p><p class="fix">${esc(fix)}</p></div></div>`).join('');
      $$('#findFilters button').forEach((b) => b.classList.toggle('on', b.dataset.s === cur));
    };
    const cnt = (s) => FINDINGS.filter((f) => s === 'all' || f[0] === s).length;
    $('#findFilters').innerHTML = sevs.map((s) => `<button data-s="${s}">${s} (${cnt(s)})</button>`).join('');
    $$('#findFilters button').forEach((b) => b.onclick = () => { cur = b.dataset.s; draw(); });
    $('#findCount').textContent = `${FINDINGS.length} items`;
    draw();
  }

  /* ================================================================== */
  /* Verification                                                         */
  /* ================================================================== */
  function initVerify() {
    const V = window.VERIF;
    const fmt = (n) => n.toLocaleString('en-US');
    const killed = V.mutation.filter((m) => m.killed).length;
    const nprog = V.random.n + V.directed.length;
    const aggCpi = V.random.cycles / V.random.instructions;
    $('#heroCycles').textContent = fmt(V.js_cycles);
    $('#heroStats').innerHTML = [
      [fmt(nprog), 'programs pass the golden-model check, 0 fail'],
      [fmt(V.js_cycles), 'cycles where the web model matched the RTL trace'],
      [`${killed}/${V.mutation.length}`, 'injected bugs caught (the 1 survivor is provably equivalent)'],
      [String(FINDINGS.length), 'issues found in the original v11 design'],
    ].map(([v, l]) => `<div class="stat-tile"><div class="v">${v}</div><div class="l">${l}</div></div>`).join('');

    $('#methodGrid').innerHTML = [
      [fmt(V.alu_checks), 'ALU unit test', 'Every operation against a reference model: 36 corner-case pairs, then 20,000 random vectors per operation.'],
      [`${V.directed.length} + ${fmt(V.random.n)}`, 'System regression', 'Directed programs, one per hazard class, plus constrained-random programs whose register pool keeps most instructions dependent on recent ones. The final 32 registers and all 4 KiB of memory are compared with the golden ISS.'],
      [fmt(V.js_cycles), 'Model equivalence', 'The website\'s JS pipeline and the GHDL testbench each write a 26-column trace every cycle. They must match exactly on every cycle of every program, stalls and forwarding decisions included.'],
      [`${killed}/${V.mutation.length}`, 'Mutation score', 'Twenty realistic bugs are injected one at a time, many of them the actual v11 bugs. Each must make some test fail, which shows the tests can find real bugs.'],
    ].map(([v, l, p]) => `<div class="card method"><div class="v">${v}</div><div class="l">${l}</div><p>${p}</p></div>`).join('');

    // directed table
    $('#dirTable').innerHTML = '<caption style="caption-side:bottom;text-align:left;padding:8px 10px" class="small muted">Stall and flush counts run up to the halt, and the flush count includes the halt\'s own jump. CPI includes the 4-cycle pipeline fill.</caption>' + '<thead><tr><th>program</th><th>instr</th><th>cycles</th><th>CPI</th><th>stalls</th><th>flushes</th><th>result</th></tr></thead><tbody>' +
      V.directed.map((r) => `<tr><td><a href="#sim" data-prog="${r.name}">${r.name}</a></td><td class="num">${r.instructions}</td><td class="num">${r.cycles}</td><td class="num">${r.cpi.toFixed(3)}</td><td class="num">${r.stalls}</td><td class="num">${r.flushes}</td><td class="pass">PASS</td></tr>`).join('') +
      `<tr><td>${fmt(V.random.n)} random</td><td class="num">${fmt(V.random.instructions)}</td><td class="num">${fmt(V.random.cycles)}</td><td class="num">${aggCpi.toFixed(3)}</td><td class="num">${fmt(V.random.stalls)}</td><td class="num">${fmt(V.random.flushes)}</td><td class="pass">PASS</td></tr></tbody>`;
    $$('#dirTable [data-prog]').forEach((a) => a.onclick = () => { if (window.PROGRAMS.find((p) => p.id === a.dataset.prog)) loadPreset(a.dataset.prog); });

    // mutants
    $('#mutScore').textContent = `${killed} of ${V.mutation.length} killed`;
    $('#mutants').innerHTML = V.mutation.map((m) => {
      const eq = !m.killed;
      return `<div class="mut"><span class="ic ${eq ? 'e' : 'k'}">${eq ? '≡' : '✓'}</span><span class="d">${esc(m.description)}${eq ? '<small>Equivalent mutant. A load in EX/MEM whose address would be forwarded into ID always makes the hazard unit stall a BEQ/JR, and for any other instruction the value is overwritten by MEM/WB forwarding in EX. No program can observe it. The qualifier is kept so ID/EX never latches an address as data.</small>' : ''}</span><span class="by">${m.killed ? 'by ' + esc(m.killed_by) : 'survives'}</span></div>`;
    }).join('');

    drawFlow();
    drawCpi(V.random.cpi, aggCpi);
  }

  function drawFlow() {
    const svg = $('#flowSvg');
    svg.innerHTML = '<defs><marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" class="arh"/></marker></defs>';
    const B = (x, y, w, h, t, s, cls = '') => {
      el('rect', { x, y, width: w, height: h, rx: 8, class: 'bx ' + cls }, svg);
      text(svg, x + w / 2, y + (s ? h / 2 - 2 : h / 2 + 5), t, '', 'middle', { 'font-weight': 600 });
      if (s) text(svg, x + w / 2, y + h / 2 + 14, s, 's');
    };
    const A = (pts) => el('path', { d: 'M' + pts.map((p) => p.join(',')).join(' L'), class: 'ar' }, svg);
    B(20, 20, 150, 52, 'Random generator', 'constrained, seeded');
    B(20, 124, 150, 52, 'Program (.s)', 'directed or random', 'k');
    B(230, 124, 150, 52, 'Assembler', 'Python · mips_asm.py');
    B(440, 124, 160, 52, 'RTL (GHDL)', 'tb_mips · VHDL-2008', 'k');
    B(440, 20, 160, 52, 'Mutants ×20', 'one bug each');
    B(230, 228, 150, 52, 'Golden ISS', 'Python · mips_iss.py');
    B(660, 124, 170, 52, 'Final regs + memory', 'VHDL-2008 external names');
    B(660, 228, 170, 52, 'Expected state', 'R0–R31, 1024 words');
    B(890, 176, 190, 52, 'Self-check', 'TB_RESULT PASS / FAIL', 'ok');
    B(660, 20, 170, 52, 'Per-cycle trace', '26 columns · CSV');
    B(890, 20, 190, 52, 'JS model = RTL?', 'check_js_model.js', 'ok');
    A([[95, 72], [95, 124]]);
    A([[170, 150], [230, 150]]);
    A([[380, 150], [440, 150]]);
    A([[520, 72], [520, 124]]);
    A([[600, 150], [660, 150]]);
    A([[95, 176], [95, 254], [230, 254]]);
    A([[380, 254], [660, 254]]);
    A([[830, 150], [860, 150], [860, 190], [890, 190]]);
    A([[830, 254], [860, 254], [860, 214], [890, 214]]);
    A([[560, 124], [560, 100], [745, 100], [745, 72]]);
    A([[830, 46], [890, 46]]);
    text(svg, 985, 100, 'website model (mips-core.js)', 's');
    text(svg, 985, 114, 'replays the same program', 's');
  }

  function drawCpi(values, agg) {
    const host = $('#cpiChart');
    const lo = 1.1, hi = 1.5, step = 0.02;
    const nb = Math.round((hi - lo) / step);
    const bins = new Array(nb).fill(0);
    values.forEach((v) => { const i = Math.min(nb - 1, Math.max(0, Math.floor((v - lo) / step))); bins[i]++; });
    const W = 560, H = 250, pl = 40, pr = 12, pt = 26, pb = 34;
    const maxY = Math.ceil(Math.max(...bins) / 20) * 20;
    const x = (v) => pl + (v - lo) / (hi - lo) * (W - pl - pr);
    const y = (n) => H - pb - n / maxY * (H - pt - pb);
    const svg = el('svg', { viewBox: `0 0 ${W} ${H}`, role: 'img', 'aria-label': 'Histogram of CPI over random programs' });
    for (let g = 0; g <= maxY; g += 20) {
      el('line', { x1: pl, x2: W - pr, y1: y(g), y2: y(g), class: 'gridl' }, svg);
      text(svg, pl - 6, y(g) + 4, String(g), '', 'end');
    }
    const bw = (W - pl - pr) / nb;
    bins.forEach((n, i) => {
      if (!n) return;
      const x0 = pl + i * bw + 1, h = H - pb - y(n);
      const r = Math.min(4, h / 2);
      const pth = `M${x0},${H - pb} L${x0},${y(n) + r} Q${x0},${y(n)} ${x0 + r},${y(n)} L${x0 + bw - 2 - r},${y(n)} Q${x0 + bw - 2},${y(n)} ${x0 + bw - 2},${y(n) + r} L${x0 + bw - 2},${H - pb} Z`;
      const b = el('path', { d: pth, class: 'bar' }, svg);
      const hit = el('rect', { x: pl + i * bw, y: pt, width: bw, height: H - pt - pb, fill: 'transparent' }, svg);
      const lab = `CPI ${(lo + i * step).toFixed(2)}–${(lo + (i + 1) * step).toFixed(2)}<br><b>${n}</b> programs`;
      hit.addEventListener('mousemove', (e) => { b.classList.add('hov'); showTip(e, lab); });
      hit.addEventListener('mouseleave', () => { b.classList.remove('hov'); hideTip(); });
    });
    el('line', { x1: pl, x2: W - pr, y1: H - pb, y2: H - pb, class: 'axis' }, svg);
    for (let v = lo; v <= hi + 1e-9; v += 0.1) text(svg, x(v), H - pb + 16, v.toFixed(1), '', 'middle');
    text(svg, (W + pl) / 2, H - 4, 'cycles per instruction', '', 'middle');
    el('line', { x1: x(agg), x2: x(agg), y1: pt - 14, y2: H - pb, class: 'ref' }, svg);
    text(svg, x(agg) + 6, pt - 4, `aggregate CPI ${agg.toFixed(3)}`, 'reft', 'start');
    host.appendChild(svg);
  }

  /* ================================================================== */
  /* Boot                                                                 */
  /* ================================================================== */
  function boot() {
    initTheme();
    buildDatapath();
    initControls();
    initLearn();
    initISA();
    initReview();
    initVerify();
    loadPreset(window.PROGRAMS[0].id, 1);
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', boot); else boot();
})();
