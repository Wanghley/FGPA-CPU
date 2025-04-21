start:
    addi $t0, $zero, 3199     # $t0 = 0xC7F    (input base address original signal)
    addi $t1, $zero, 1708     # $t1 = 0x6AC    (output base address for downsampled signal)
    addi $t2, $zero, 0        # $t2 = 0         (counter = 0)
    addi $t3, $zero, 2        # $t3 = 2         (stride = 2)
    addi $t5, $zero, 320      # $t5 = 320       (max count)

loop:
    blt  $t2, $t5, do_copy    # if t2 < 320 → copy
    j    done                # else jump to done

do_copy:
    lw   $t4, 0($t0)         # t4 = RAM[t0]
    sw   $t4, 0($t1)         # RAM[t1] = t4
    add  $t0, $t0, $t3       # t0 += 2
    addi $t1, $t1, 1         # t1 += 1
    addi $t2, $t2, 1         # t2 += 1
    j    loop                # repeat

done:
    nop                  # No operation (NOP)
    # loop forever
    j start                   # Jump back to start
