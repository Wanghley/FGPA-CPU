start:
    # Base addresses
    addi $t1, $zero, 1709     # ECG output base
    addi $t7, $zero, 1369     # EMG output base
    addi $t2, $zero, 0        # counter
    addi $t5, $zero, 320      # sample count
    addi $t3, $zero, 2049     # EMG input base
    addi $t4, $zero, 3199     # ECG input base

    # Init min/max, state
    addi $t8, $zero, 4095     # min ECG
    addi $t9, $zero, 4095     # min EMG
    add  $s0, $zero, $zero    # max ECG
    add  $s1, $zero, $zero    # max EMG
    add  $s4, $zero, $zero    # peak count
    add  $s5, $zero, $zero    # previous ECG
    add  $s6, $zero, $zero    # adaptive threshold
    add  $s7, $zero, $zero    # threshold state

    # New features
    add  $s3, $zero, $zero    # EMG burst mask
    add  $s8, $zero, $zero    # SQI
    add  $s9, $zero, $zero    # clipping count
    add  $t6, $zero, $zero    # RR: last peak position
    add  $t0, $zero, 0        # stddev sum (∑BPM²)
    add  $s2, $zero, 0        # index for RR buffer

loop:
    blt $t2, $t5, do_copy
    j calculate_bpm

do_copy:
    lw $a0, 0($t4)            # ECG input
    lw $a1, 0($t3)            # EMG input

    sw $a0, 0($t1)
    sw $a1, 0($t7)

    # Clipping detection
    beq $a0, $t8, inc_clip
    beq $a0, $s0, inc_clip
    j skip_clip
inc_clip:
    addi $s9, $s9, 1
skip_clip:

    # Min/Max ECG
    blt $a0, $t8, set_min_ecg
    j skip_min_ecg
set_min_ecg:
    add $t8, $a0, $zero
skip_min_ecg:
    blt $s0, $a0, set_max_ecg
    j skip_max_ecg
set_max_ecg:
    add $s0, $a0, $zero
skip_max_ecg:

    # Min/Max EMG
    blt $a1, $t9, set_min_emg
    j skip_min_emg
set_min_emg:
    add $t9, $a1, $zero
skip_min_emg:
    blt $s1, $a1, set_max_emg
    j skip_max_emg
set_max_emg:
    add $s1, $a1, $zero
skip_max_emg:

    # SQI
    bne $a0, $s5, sqi_inc
    j sqi_done
sqi_inc:
    addi $s8, $s8, 1
sqi_done:
    add $s5, $a0, $zero

    # Adaptive threshold
    addi $t8, $zero, 160
    blt $t2, $t8, skip_thresh
    bne $s6, $zero, skip_thresh

    sub $a2, $s0, $t8
    div $a3, $a2, $t8
    addi $t8, $zero, 3
    div $a3, $a3, $t8
    add $s6, $t8, $a3
skip_thresh:

    # Peak detection
    bne $s6, $zero, check_peak
    j skip_peak
check_peak:
    blt $a0, $s6, below
    bne $s7, $zero, skip_peak_count
    addi $s4, $s4, 1
    addi $s7, $zero, 1

    # RR Interval = t2 - last_peak
    sub $a2, $t2, $t6
    add $t6, $t2, $zero
    # Save to buffer 1697 + RR index
    addi $a3, $zero, 1697
    add $a3, $a3, $s2
    sw $a2, 0($a3)
    addi $s2, $s2, 1
    addi $t8, $zero, 4
    blt $s2, $t8, skip_rr_reset
    add  $s2, $zero, $zero
skip_rr_reset:
    j skip_peak_count
below:
    add $s7, $zero, $zero
skip_peak_count:
skip_peak:

    # EMG high threshold
    sll $a3, $t9, 2
    blt $a1, $a3, skip_emg
    addi $s3, $zero, 1
skip_emg:

    # Next sample
    addi $t1, $t1, 1
    addi $t7, $t7, 1
    addi $t2, $t2, 1
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    j loop

calculate_bpm:
    addi $a1, $zero, 60
    mul $s4, $s4, $a1
    sw $s4, 0($t0)            # BPM to 1704

    # Store min/max
    addi $t0, $zero, 1705
    sw $t8, 0($t0)
    addi $t0, $t0, 1
    sw $t9, 0($t0)
    addi $t0, $t0, 1
    sw $s0, 0($t0)
    addi $t0, $t0, 1
    sw $s1, 0($t0)

    # EMG mask
    addi $t0, $zero, 1703
    sw $s3, 0($t0)

    # SQI and clipping
    addi $t0, $zero, 1701
    sw $s8, 0($t0)
    addi $t0, $t0, 1
    sw $s9, 0($t0)

    # Save ∑BPM² for software STD
    mul $a2, $s4, $s4
    addi $t0, $zero, 1696
    sw $a2, 0($t0)

    j start