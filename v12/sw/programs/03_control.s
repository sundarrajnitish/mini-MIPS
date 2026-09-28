# 03 - Control hazards: BEQ/J/JR resolved in ID, 1 flushed slot each,
#      plus branch-operand stalls (ALU producer: 1, load producer: 2).
        .data
        .word 3
        .text
        li   $1, 3
        li   $2, 3
        beq  $1, $2, t1      # $2 produced by previous instr -> 1 stall, taken
        li   $10, 1          # flushed
t1:     lw   $3, 0($0)       # $3 = 3 (was 0: a stale read would fall through)
        beq  $3, $1, t1b     # depends on load -> 2 stalls, taken
        li   $13, 0xBAD      # flushed
t1b:    j    t2
        li   $11, 1          # flushed
t2:     la   $4, t3
        jr   $4              # depends on la -> 1 stall
        li   $12, 1          # flushed
t3:     li   $5, 0
        li   $6, 4           # loop counter
loop:   add  $5, $5, $6      # sum 4+3+2+1
        subui $6, $6, 1
        beq  $6, $0, done
        j    loop
done:   sb   $5, 4($0)
        halt
bad:    li   $13, 0xBAD
        halt
