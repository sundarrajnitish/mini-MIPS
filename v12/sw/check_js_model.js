#!/usr/bin/env node
/* Cross-checks the website's JavaScript pipeline model against the RTL.
 *
 *   node sw/check_js_model.js [tests-dir]     (default: build/tests, recursive)
 *
 * For every <name>.s that the regression ran, it
 *   1. assembles the source with the JS assembler and compares every word
 *      with the Python assembler output (<name>.imem.hex / .dmem.hex)
 *   2. runs the JS pipeline model and compares its per-cycle trace, column by
 *      column, with the GHDL testbench trace (<name>.trace.csv)
 */
const fs = require('fs');
const path = require('path');
const M = require(path.join(__dirname, '..', 'web', 'mips-core.js'));

const dir = process.argv[2] || path.join(__dirname, '..', 'build', 'tests');
const files = [];
(function walk(d) {
  for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) walk(p); else if (p.endsWith('.s')) files.push(p);
  }
})(dir);

let ok = 0, bad = 0, cycles = 0;
for (const f of files.sort()) {
  const stem = f.slice(0, -2);
  if (!fs.existsSync(stem + '.trace.csv')) continue;
  const prog = M.assemble(fs.readFileSync(f, 'utf8'));
  const pyHex = fs.readFileSync(stem + '.imem.hex', 'utf8').trim().split('\n').map((l) => parseInt(l.slice(0, 8), 16));
  const pyData = fs.readFileSync(stem + '.dmem.hex', 'utf8').trim().split('\n').filter(Boolean).map((l) => parseInt(l, 16));
  let err = null;
  if (pyHex.length !== prog.text.length || pyHex.some((w, i) => w !== prog.text[i].word)) err = 'assembler (text) differs';
  else if (pyData.length !== prog.data.length || pyData.some((w, i) => w !== prog.data[i])) err = 'assembler (data) differs';
  if (!err) {
    const rtl = fs.readFileSync(stem + '.trace.csv', 'utf8').trim().split('\n').slice(1);
    const p = new M.Pipeline(prog);
    const js = [];
    while (!p.done && js.length < rtl.length + 5) js.push(M.Pipeline.traceLine(p.step()));
    const hdr = 'cycle,pc,ifid_v,ifid_pc,ifid_instr,idex_v,idex_pc,exmem_v,exmem_pc,memwb_v,memwb_pc,stall,flush,pc_sel,next_pc,fwd_a,fwd_b,fwd_e,fwd_f,alu,wb_en,wb_rd,wb_data,mem_we,mem_addr,mem_wdata'.split(',');
    if (js.length !== rtl.length) err = `trace length js=${js.length} rtl=${rtl.length}`;
    for (let i = 0; !err && i < rtl.length; i++) {
      if (js[i] !== rtl[i]) {
        const a = js[i].split(','), b = rtl[i].split(',');
        const cols = hdr.filter((_, k) => a[k] !== b[k]).map((h) => `${h}: js=${a[hdr.indexOf(h)]} rtl=${b[hdr.indexOf(h)]}`);
        err = `cycle ${i + 1}: ${cols.join('; ')}`;
      }
    }
    cycles += rtl.length;
  }
  if (err) { bad++; console.log(`MISMATCH ${path.relative(dir, f)} -> ${err}`); } else ok++;
}
console.log(`${ok} programs cycle-exact (${cycles} cycles compared), ${bad} mismatches`);
process.exit(bad ? 1 : 0);
