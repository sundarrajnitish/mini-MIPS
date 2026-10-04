# mini-MIPS

A 32-bit, 5-stage pipelined MIPS subset in synthesizable VHDL-2008, with a self-checking
verification flow and an interactive website.

**Interactive site:** [`../docs`](../docs/index.html) (published through GitHub Pages). It has a
cycle-by-cycle datapath simulator, a hazard tutorial, the design decisions, and the verification
results.

## Microarchitecture

- One rising clock edge with synchronous reset. All stage logic is combinational between the PC, the four
  pipeline registers, the register file and the data memory.
- BEQ, J and JR are resolved in ID. The comparator gets its operands through ID forwarding (MUX E/F),
  and fetch predicts not-taken.
- A classic load-use interlock: the PC and IF/ID hold, and a bubble goes into ID/EX.
- EX forwarding (MUX C/D) sits in front of the ALUSrc mux (MUX A), so an immediate is never overwritten.
- The register file has `$0` hard-wired to zero and a write-through bypass.
- Data memory is 4 KiB, byte-addressed and little-endian, with per-lane SB writes.

## ISA (11 instructions)

| Instr | Fmt | opcode | funct | Operation |
|---|---|---|---|---|
| ADD / NOR / XOR | R | 000000 | 100000 / 100111 / 100110 | rd ← rs op rt |
| SLL | R | 000000 | 000000 | rd ← rt << shamt |
| JR | R | 000000 | 001000 | PC ← rs |
| ANDI | I | 001100 | | rt ← rs & zext(imm) |
| SUBUI | I | 011001 | | rt ← rs − sext(imm) |
| LW | I | 100011 | | rt ← MEM32[rs + sext(off)] |
| SB | I | 101000 | | MEM8[rs + sext(off)] ← rt[7:0] |
| BEQ | I | 000100 | | if rs = rt: PC ← PC+4 + sext(off)<<2 |
| J | J | 000010 | | PC ← {PC+4[31:28], target, 00} |

Assembler pseudo-instructions: `li` (SUBUI from `$0` with the negated constant), `la`, `move`, `b`,
`nop`, and `halt` (`j .`, which the testbench uses as the end-of-program marker).

## Hazard handling

| Situation | Hardware | Cost |
|---|---|---|
| ALU result needed by next instruction | EX/MEM → EX forwarding (MUX C/D) | 0 |
| Result needed 2 instructions later | MEM/WB → EX forwarding | 0 |
| Result needed 3 instructions later | register-file write-through bypass | 0 |
| Load-use | interlock + MEM/WB → EX forwarding | 1 stall |
| BEQ/JR operand produced by the previous ALU op | interlock + EX/MEM → ID forwarding (MUX E/F) | 1 stall |
| BEQ/JR operand produced by the previous LW | interlock ×2 + register-file bypass | 2 stalls |
| Taken BEQ, J, JR | redirect in ID, flush IF/ID (predict not-taken) | 1 slot |

## Layout

```
rtl/        mips_pkg.vhd (types, constants, pipeline-register records), mips_cpu.vhd (top)
            1_fetch/ 2_decode/ 3_execute/ 4_memory/ 5_writeback/  - one entity per unit
tb/         tb_mips.vhd - self-checking system testbench (trace + golden-state compare)
            tb_alu.vhd  - ALU unit test
sw/         mips_asm.py (assembler), mips_iss.py (golden ISS), random_program.py,
            run_regression.py, mutation_test.py, check_js_model.js, programs/*.s
web/        site sources; mips-core.js is the JS pipeline model the site animates
scripts/    files.txt (compile order), build_site.py, export_verification.py
```

## Running

Requirements: GHDL ≥ 3 (VHDL-2008), Python 3, Node ≥ 18.

```sh
make test       # ALU unit test + directed programs + 200 random programs
make regress    # 1,000 constrained-random programs vs the golden ISS
make jscheck    # website JS model vs RTL trace, every cycle of every program
make mutation   # 20 injected bugs; each must make a test fail
make site       # regenerate ../docs
```

One program by hand:

```sh
python3 sw/mips_asm.py sw/programs/00_tour.s            # -> .imem.hex / .dmem.hex / .lst
python3 sw/mips_iss.py sw/programs/00_tour.s -e exp.txt
make compile && cd build && ghdl -e --std=08 --workdir=. tb_mips && \
  ghdl -r --std=08 --workdir=. tb_mips -gIMEM_FILE=../sw/programs/00_tour.imem.hex \
  -gDMEM_FILE=../sw/programs/00_tour.dmem.hex -gEXPECT_FILE=exp.txt -gTRACE_FILE=trace.csv
```

In ModelSim/Questa, compile the files in `scripts/files.txt` order with `-2008`, then simulate
`tb_mips` with the same generics.

## Verification results

| Check | Result |
|---|---|
| ALU unit test | 120,216 vectors, pass |
| Directed programs (6) | pass |
| Constrained-random programs (1,000; 75,810 instructions) | pass, aggregate CPI 1.298 |
| JS model vs RTL trace | 1,006 programs, 98,669 cycles, cycle-exact |
| Mutation testing | 19/20 killed; the survivor is an equivalent mutant (see site) |
| `ghdl --synth` of `mips_cpu` | elaborates to a netlist |

## Design notes and limits

- Harvard memories: 256-word instruction ROM (hex file loaded at elaboration) and a 1024-word data RAM.
  Both have asynchronous reads, which matches the textbook 5-stage timing. For FPGA block RAM, register
  the read address and move the pipeline boundary accordingly.
- LW ignores address bits [1:0] (word aligned). Addresses wrap modulo the memory size. There are no
  exceptions or overflow traps (SUBUI/ADD behave like SUBU/ADDU).
- Branches are statically predicted not-taken.
- `valid`/`pc` fields travel down the pipeline only for tracing. Synthesis removes them.
