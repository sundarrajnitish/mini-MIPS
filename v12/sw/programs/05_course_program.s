# 05 - Original course program: the COEN 6741 test program from
#      v11/instruction_memory.vhd, re-encoded correctly. A short prologue loads the
#      registers the program expects (the v11 ROM ran with every register = 0), and the targets of
#      BEQ/JR were adjusted so the program terminates.
        .data
        .space 24
        .word 0x0000F0F0     # mem[24] read by "LW R9, 24(R4)"
        .text
        li   $3, 0x0F0F      # prologue
        li   $4, 0
        li   $5, 7
        la   $21, cont
        li   $26, 1
        li   $14, 3
        lw   $9, 24($4)      # LW   R9, 24(R4)
        nor  $11, $9, $3     # NOR  R11, R9, R3
        add  $6, $11, $5     # ADD  R6, R11, R5
        andi $1, $6, 2       # ANDI R1, R6, 2
        sll  $12, $1, 5      # SLL  R12, R1, 5
        beq  $26, $11, cont  # BEQ  R26, R11, ... (not taken)
        jr   $21             # JR   R21
        li   $30, 0xBAD      # (flushed)
cont:   subui $10, $21, 8    # SUBUI R10, R21, 8
        sll  $15, $14, 6     # SLL  R15, R14, 6   (v11 comment used a register)
        nor  $15, $15, $31   # NOR  R15, R15, R31
        beq  $9, $12, end    # BEQ  R9, R12, ... (not taken)
        add  $12, $12, $10   # ADD  R12, R12, R10
end:    halt
