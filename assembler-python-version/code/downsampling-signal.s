start:
    addi $t0, $zero, 3199     # EMG base address (input) = 0xC7F
    addi $t1, $zero, 1709     # EMG output base address = 0x6AD
    addi $t2, $zero, 0        # counter = 0
    addi $t3, $zero, 2        # stride = 2
    addi $t5, $zero, 320      # max count = 320

    addi $t6, $zero, 2049     # ECG base address (input) = 0x801
    addi $t7, $zero, 1369     # ECG output base address = 0x559

loop:
    blt  $t2, $t5, do_copy
    j    done

do_copy:
    lw   $t4, 0($t0)       # load EMG input
    sw   $t4, 0($t1)       # store EMG output
    lw   $t4, 0($t6)       # load ECG input
    sw   $t4, 0($t7)       # store ECG output
    addi $t0, $t0, 2          # increment input address by 2 words (assuming word addressing)
    addi $t1, $t1, 1          # increment output address
    addi $t2, $t2, 1          # increment counter
    addi $t6, $t6, 2          # increment ECG input address by 2 words (assuming word addressing)
    addi $t7, $t7, 1          # increment ECG output address
    j    loop

done:
    j    start                # loop forever