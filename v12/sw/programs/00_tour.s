# 00 - Guided tour: every pipeline event in 14 instructions.
        li   $1, 7
        li   $2, 3
        add  $3, $1, $2      # A <- MEM/WB ($1), B <- EX/MEM ($2)      = 10
        sb   $3, 0($0)       # store data forwarded from EX/MEM
        lw   $4, 0($0)       # $4 = 10
        xor  $5, $4, $1      # load-use: 1 stall, then MEM/WB -> EX    = 13
        beq  $5, $0, skip    # operand still in EX: 1 stall, not taken
        beq  $3, $4, skip    # 10 == 10: taken, wrong-path slot flushed
        li   $6, 99          # (squashed)
skip:   la   $7, sub
        jr   $7              # JR target in EX: 1 stall, then flush
        li   $6, 1           # (squashed)
sub:    sll  $8, $5, 2       # 52
        halt
