window.PROGRAMS = [
 {
  "id": "00_tour",
  "title": "00 \u00b7 Guided tour",
  "desc": "every pipeline event in 14 instructions.",
  "src": "# 00 - Guided tour: every pipeline event in 14 instructions.\n        li   $1, 7\n        li   $2, 3\n        add  $3, $1, $2      # A <- MEM/WB ($1), B <- EX/MEM ($2)      = 10\n        sb   $3, 0($0)       # store data forwarded from EX/MEM\n        lw   $4, 0($0)       # $4 = 10\n        xor  $5, $4, $1      # load-use: 1 stall, then MEM/WB -> EX    = 13\n        beq  $5, $0, skip    # operand still in EX: 1 stall, not taken\n        beq  $3, $4, skip    # 10 == 10: taken, wrong-path slot flushed\n        li   $6, 99          # (squashed)\nskip:   la   $7, sub\n        jr   $7              # JR target in EX: 1 stall, then flush\n        li   $6, 1           # (squashed)\nsub:    sll  $8, $5, 2       # 52\n        halt\n"
 },
 {
  "id": "01_forwarding",
  "title": "01 \u00b7 Data forwarding",
  "desc": "every RAW dependence on an ALU result is resolved",
  "src": "# 01 - Data forwarding: every RAW dependence on an ALU result is resolved\n#      without stalling (EX/MEM -> EX and MEM/WB -> EX paths).\n        li   $1, 12          # producer\n        li   $2, 30\n        add  $3, $1, $2      # $1 from MEM/WB, $2 from EX/MEM       -> 42\n        xor  $4, $3, $1      # $3 from EX/MEM                       -> 38\n        nor  $5, $4, $3      # $4 EX/MEM, $3 MEM/WB                 -> ~(38|42)\n        sll  $6, $5, 3       # rt forwarded into the shifter\n        add  $6, $6, $6      # same reg as src & dest\n        add  $6, $6, $6      # chain through EX/MEM again\n        add  $7, $6, $0      # $0 is never forwarded\n        andi $8, $7, 0xfff0  # I-type: rt is a destination, not an operand\n        subui $9, $8, -100   # immediate is NOT overwritten by forwarding\n        halt\n"
 },
 {
  "id": "02_load_use",
  "title": "02 \u00b7 Load-use hazard",
  "desc": "1 stall + MEM/WB forwarding, and store-byte merging.",
  "src": "# 02 - Load-use hazard: 1 stall + MEM/WB forwarding, and store-byte merging.\n        .data\nvals:   .word 100, 200, 0xAABBCCDD, 0\n        .text\n        lw   $1, 0($0)       # 100\n        add  $2, $1, $1      # load-use -> 1 bubble, then MEM/WB -> EX\n        lw   $3, 4($0)       # 200\n        nop\n        add  $4, $3, $2      # distance 2: no stall, MEM/WB forwarding\n        lw   $5, 8($0)\n        sb   $5, 12($0)      # store data depends on load -> stall, fwd to store data\n        sb   $4, 13($0)      # byte lane 1\n        li   $6, 0x7F\n        sb   $6, 14($0)      # byte lane 2\n        lw   $7, 12($0)      # read back merged word 0x007F90DD\n        lw   $8, 8($7)       # address depends on load -> stall, fwd into address\n        halt\n"
 },
 {
  "id": "03_control",
  "title": "03 \u00b7 Control hazards",
  "desc": "BEQ/J/JR resolved in ID, 1 flushed slot each,",
  "src": "# 03 - Control hazards: BEQ/J/JR resolved in ID, 1 flushed slot each,\n#      plus branch-operand stalls (ALU producer: 1, load producer: 2).\n        .data\n        .word 3\n        .text\n        li   $1, 3\n        li   $2, 3\n        beq  $1, $2, t1      # $2 produced by previous instr -> 1 stall, taken\n        li   $10, 1          # flushed\nt1:     lw   $3, 0($0)       # $3 = 3 (was 0: a stale read would fall through)\n        beq  $3, $1, t1b     # depends on load -> 2 stalls, taken\n        li   $13, 0xBAD      # flushed\nt1b:    j    t2\n        li   $11, 1          # flushed\nt2:     la   $4, t3\n        jr   $4              # depends on la -> 1 stall\n        li   $12, 1          # flushed\nt3:     li   $5, 0\n        li   $6, 4           # loop counter\nloop:   add  $5, $5, $6      # sum 4+3+2+1\n        subui $6, $6, 1\n        beq  $6, $0, done\n        j    loop\ndone:   sb   $5, 4($0)\n        halt\nbad:    li   $13, 0xBAD\n        halt\n"
 },
 {
  "id": "04_fibonacci",
  "title": "04 \u00b7 Fibonacci",
  "desc": "F(0..15) stored as bytes, then read back as packed words",
  "src": "# 04 - Fibonacci: F(0..15) stored as bytes, then read back as packed words\n#      (little-endian: byte k of word i is F(4i+k)).\n        li   $1, 0           # F(n-2)\n        li   $2, 1           # F(n-1)\n        li   $3, 0           # address / index\n        li   $4, 16          # count\n        sb   $1, 0($3)       # F(0)\n        sb   $2, 1($3)       # F(1)\n        li   $3, 2\nloop:   add  $5, $1, $2      # F(n)\n        sb   $5, 0($3)\n        move $1, $2\n        move $2, $5\n        subui $3, $3, -1     # $3 += 1\n        beq  $3, $4, done\n        j    loop\ndone:   lw   $10, 0($0)      # F0..F3\n        lw   $11, 4($0)\n        lw   $12, 8($0)\n        lw   $13, 12($0)     # F12..F15 (233 fits in a byte, 377 wraps to 0x79)\n        halt\n"
 },
 {
  "id": "05_all_instructions",
  "title": "05 \u00b7 All 11 instructions",
  "desc": "one of each, chained through registers and memory.",
  "src": "# 05 - All 11 instructions: one of each, chained through registers and memory.\n        .data\n        .space 24\n        .word 0x0000F0F0     # mem[24]\n        .text\n        li   $3, 0x0F0F\n        li   $4, 0\n        li   $5, 7\n        la   $21, cont\n        li   $26, 1\n        li   $14, 3\n        lw   $9, 24($4)      # $9  = 0xF0F0\n        nor  $11, $9, $3     # $11 = ~(0xF0F0 | 0x0F0F) = 0xFFFF0000\n        add  $6, $11, $5     # $6  = 0xFFFF0007\n        andi $1, $6, 2       # $1  = 2\n        sll  $12, $1, 5      # $12 = 64\n        beq  $26, $11, cont  # not taken\n        jr   $21             # jump to cont\n        li   $30, 0xBAD      # (flushed)\ncont:   subui $10, $21, 8    # $10 = address of cont - 8\n        sll  $15, $14, 6     # $15 = 192\n        xor  $15, $15, $12   # $15 = 192 ^ 64 = 128\n        sb   $15, 28($0)     # mem[28] byte 0 = 0x80\n        beq  $9, $12, end    # not taken\n        add  $12, $12, $10\n        j    end\n        li   $30, 0xBAD      # (flushed)\nend:    halt\n"
 }
];
