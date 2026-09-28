# 01 - Data forwarding: every RAW dependence on an ALU result is resolved
#      without stalling (EX/MEM -> EX and MEM/WB -> EX paths).
        li   $1, 12          # producer
        li   $2, 30
        add  $3, $1, $2      # $1 from MEM/WB, $2 from EX/MEM       -> 42
        xor  $4, $3, $1      # $3 from EX/MEM                       -> 38
        nor  $5, $4, $3      # $4 EX/MEM, $3 MEM/WB                 -> ~(38|42)
        sll  $6, $5, 3       # rt forwarded into the shifter
        add  $6, $6, $6      # same reg as src & dest
        add  $6, $6, $6      # chain through EX/MEM again
        add  $7, $6, $0      # $0 is never forwarded
        andi $8, $7, 0xfff0  # I-type: rt is a destination, not an operand
        subui $9, $8, -100   # immediate is NOT overwritten by forwarding
        halt
