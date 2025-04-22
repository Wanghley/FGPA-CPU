start:
    addi $t1, $zero, 1708     # output base address = 0x6AC
    addi $t2, $zero, 0        # counter = 0
    addi $t5, $zero, 320      # max count = 320
    addi $t4, $zero, 1234     # constant to write

loop:
    blt  $t2, $t5, do_copy
    j    done

do_copy:
    sw   $t4, 0($t1)          # store constant to output
    addi $t1, $t1, 1          # increment address (by word index)
    addi $t2, $t2, 1          # increment counter
    j    loop

done:
    j    start                # loop forever