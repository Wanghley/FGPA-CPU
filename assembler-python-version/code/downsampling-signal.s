start:
    # Base addresses
    addi $t1, $zero, 1709     # EMG output base address = 0x6AD
    addi $t7, $zero, 1369     # ECG output base address = 0x559
    addi $t2, $zero, 0        # counter = 0
    addi $t5, $zero, 320      # max count = 320
    addi $t3, $zero, 2049     # EMG input base address = 0x801
    # addi $t4, $zero, 0        # ECG input base address = 0x000
    

    # Constants
    addi $t4, $zero, 1000     # EMG constant
    # addi $t6, $zero, 1500     # ECG constant

loop:
    blt  $t2, $t5, do_copy
    j    done

do_copy:
    # Copy EMG and ECG data
    lw   $t6, 0($t3)          # read EMG data

    sw   $t4, 0($t1)          # write 1000 to EMG output
    sw   $t6, 0($t7)          # write ECG data to output
    addi $t1, $t1, 1          # EMG output++
    addi $t7, $t7, 1          # ECG output++
    addi $t2, $t2, 1          # counter++
    addi $t3, $t3, 1          # EMG input++
    j    loop

done:
    j    start                # loop forever