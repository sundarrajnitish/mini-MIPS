# 02 - Load-use hazard: 1 stall + MEM/WB forwarding, and store-byte merging.
        .data
vals:   .word 100, 200, 0xAABBCCDD, 0
        .text
        lw   $1, 0($0)       # 100
        add  $2, $1, $1      # load-use -> 1 bubble, then MEM/WB -> EX
        lw   $3, 4($0)       # 200
        nop
        add  $4, $3, $2      # distance 2: no stall, MEM/WB forwarding
        lw   $5, 8($0)
        sb   $5, 12($0)      # store data depends on load -> stall, fwd to store data
        sb   $4, 13($0)      # byte lane 1
        li   $6, 0x7F
        sb   $6, 14($0)      # byte lane 2
        lw   $7, 12($0)      # read back merged word 0x007F90DD
        lw   $8, 8($7)       # address depends on load -> stall, fwd into address
        halt
