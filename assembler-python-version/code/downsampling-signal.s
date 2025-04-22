start:
    addi $t0, $zero, 3199     # EMG input address = 0xC7F
    addi $t1, $zero, 1709     # EMG output address = 0x6AD
    addi $t2, $zero, 0        # counter = 0
    addi $t3, $zero, 2        # stride = 2
    addi $t5, $zero, 320      # max = 320 samples

    addi $t6, $zero, 2049     # ECG input address = 0x801
    addi $t7, $zero, 1369     # ECG output address = 0x559

loop:
    blt $t2, $t5, do_copy
    j done

do_copy:
    lw   $t4, 0($t0)       # EMG input
    sw   $t4, 0($t1)       # EMG output

    nop                    # Insert nops for safety
    nop

    lw   $t4, 0($t6)       # ECG input
    sw   $t4, 0($t7)       # ECG output

    addi $t0, $t0, 2       # EMG input += 2 (downsample stride)
    addi $t1, $t1, 1       # EMG output++
    addi $t6, $t6, 2       # ECG input += 2
    addi $t7, $t7, 1       # ECG output++
    addi $t2, $t2, 1       # counter++

    j loop

done:
    j done