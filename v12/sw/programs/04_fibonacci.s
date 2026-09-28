# 04 - Fibonacci: F(0..15) stored as bytes, then read back as packed words
#      (little-endian: byte k of word i is F(4i+k)).
        li   $1, 0           # F(n-2)
        li   $2, 1           # F(n-1)
        li   $3, 0           # address / index
        li   $4, 16          # count
        sb   $1, 0($3)       # F(0)
        sb   $2, 1($3)       # F(1)
        li   $3, 2
loop:   add  $5, $1, $2      # F(n)
        sb   $5, 0($3)
        move $1, $2
        move $2, $5
        subui $3, $3, -1     # $3 += 1
        beq  $3, $4, done
        j    loop
done:   lw   $10, 0($0)      # F0..F3
        lw   $11, 4($0)
        lw   $12, 8($0)
        lw   $13, 12($0)     # F12..F15 (233 fits in a byte, 377 wraps to 0x79)
        halt
