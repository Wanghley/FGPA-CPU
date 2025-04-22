start:
    addi $t0, $zero, 3199     # EMG base address (input) = 0xC7F
    addi $t1, $zero, 1708     # output base address = 0x6AC
    addi $t2, $zero, 0        # counter = 0
    addi $t3, $zero, 2        # stride = 2
    addi $t5, $zero, 320      # max count = 320
    addi $t6, $zero, 2047          # max count for output = 0

loop:
    blt  $t2, $t5, do_copy
    j    done

do_copy:
    lw   $t4, 0($t0)
    nop
    nop
    nop
    sw   $t6, 0($t1)          # Store the value from input
    addi $t0, $t0, 2          # increment input address by 2 words (assuming word addressing)
    addi $t1, $t1, 1          # increment output address
    addi $t2, $t2, 1          # increment counter
    j    loop

done:
    j    start                # loop forever