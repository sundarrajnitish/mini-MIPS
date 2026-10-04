# 05 - All 11 instructions: one of each, chained through registers and memory.
        .data
        .space 24
        .word 0x0000F0F0     # mem[24]
        .text
        li   $3, 0x0F0F
        li   $4, 0
        li   $5, 7
        la   $21, cont
        li   $26, 1
        li   $14, 3
        lw   $9, 24($4)      # $9  = 0xF0F0
        nor  $11, $9, $3     # $11 = ~(0xF0F0 | 0x0F0F) = 0xFFFF0000
        add  $6, $11, $5     # $6  = 0xFFFF0007
        andi $1, $6, 2       # $1  = 2
        sll  $12, $1, 5      # $12 = 64
        beq  $26, $11, cont  # not taken
        jr   $21             # jump to cont
        li   $30, 0xBAD      # (flushed)
cont:   subui $10, $21, 8    # $10 = address of cont - 8
        sll  $15, $14, 6     # $15 = 192
        xor  $15, $15, $12   # $15 = 192 ^ 64 = 128
        sb   $15, 28($0)     # mem[28] byte 0 = 0x80
        beq  $9, $12, end    # not taken
        add  $12, $12, $10
        j    end
        li   $30, 0xBAD      # (flushed)
end:    halt
