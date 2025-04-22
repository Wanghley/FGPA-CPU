start:
    # Base addresses
    addi $t1, $zero, 1709     # ECG output base address = 0x6AD
    addi $t7, $zero, 1369     # EMG output base address = 0x559
    addi $t2, $zero, 0        # counter = 0
    addi $t5, $zero, 320      # max count = 320
    addi $t3, $zero, 2049     # EMG input base address = 0x801
    addi $t4, $zero, 3199     # ECG input base address = 0xC7F

    # Init min/max values
    addi $t8, $zero, 4095     # min ECG
    addi $t9, $zero, 4095     # min EMG
    add  $s0, $zero, $zero    # max ECG
    add  $s1, $zero, $zero    # max EMG

    # BPM calculation setup
    add  $s4, $zero, $zero    # peak counter
    addi $s5, $zero, 0        # previous ECG value
    addi $s6, $zero, 100      # threshold for peak detection
    add  $s7, $zero, $zero    # state (0=below, 1=above)

    # Initialize EMG mask flag
    add  $s3, $zero, $zero    # flag = 0 (no high value yet)

loop:
    blt $t2, $t5, do_copy
    j calculate_bpm

do_copy:
    lw $s2, 0($t3)            # EMG input
    lw $s3, 0($t4)            # ECG input

    # Save ECG/EMG outputs
    sw $s3, 0($t1)
    sw $s2, 0($t7)

    # Update min/max ECG
    blt $s3, $t8, update_min_ecg
    j skip_min_ecg
update_min_ecg:
    add $t8, $s3, $zero
skip_min_ecg:
    blt $s0, $s3, update_max_ecg
    j skip_max_ecg
update_max_ecg:
    add $s0, $s3, $zero
skip_max_ecg:

    # Update min/max EMG
    blt $s2, $t9, update_min_emg
    j skip_min_emg
update_min_emg:
    add $t9, $s2, $zero
skip_min_emg:
    blt $s1, $s2, update_max_emg
    j skip_max_emg
update_max_emg:
    add $s1, $s2, $zero
skip_max_emg:

    # Peak detection logic
    blt $s3, $s6, below_threshold
    bne $s7, $zero, skip_peak_check
    addi $s4, $s4, 1
    addi $s7, $zero, 1
    j skip_peak_check
below_threshold:
    add $s7, $zero, $zero
skip_peak_check:

    # EMG high threshold check
    sll $t6, $t9, 1           # t6 = 4 * min(EMG)
    blt $s2, $t6, skip_emg_high
    addi $s3, $zero, 1        # flag = 1
skip_emg_high:

    # Advance pointers
    addi $t1, $t1, 1
    addi $t7, $t7, 1
    addi $t2, $t2, 1
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j loop

calculate_bpm:
    # BPM = peak count * 19 (approx)
    addi $t0, $zero, 19
    mul $s4, $s4, $t0

    # Save BPM
    addi $t0, $zero, 1704
    sw $s4, 0($t0)

save_min_max:
    # Save: 1705=min ECG, 1706=min EMG, 1707=max ECG, 1708=max EMG
    addi $t0, $zero, 1705
    sw $t8, 0($t0)
    addi $t0, $t0, 1
    sw $t9, 0($t0)
    addi $t0, $t0, 1
    sw $s0, 0($t0)
    addi $t0, $t0, 1
    sw $s1, 0($t0)

save_emg_mask:
    addi $t0, $zero, 1703     # Store EMG mask (1 if any sample > 4x min)
    sw   $s3, 0($t0)

    j start                   # loop forever