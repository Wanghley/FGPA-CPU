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
    add  $s5, $zero, $zero    # previous ECG value
    add  $s6, $zero, $zero    # will store adaptive threshold
    add  $s7, $zero, $zero    # state (0=below, 1=above)
    # Initialize EMG mask flag
    add  $s3, $zero, $zero    # flag = 0 (no high value yet)
loop:
    blt $t2, $t5, do_copy
    j calculate_bpm
do_copy:
    lw $s2, 0($t3)            # EMG input
    lw $a0, 0($t4)            # ECG input (using $a0 temporarily)
    # Save ECG/EMG outputs
    sw $a0, 0($t1)
    sw $s2, 0($t7)
    # Update min/max ECG
    blt $a0, $t8, update_min_ecg
    j skip_min_ecg
update_min_ecg:
    add $t8, $a0, $zero
skip_min_ecg:
    blt $s0, $a0, update_max_ecg
    j skip_max_ecg
update_max_ecg:
    add $s0, $a0, $zero
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

    # Check if first half of samples are collected to calculate adaptive threshold
    addi $a1, $zero, 160      # Halfway point for samples
    blt $t2, $a1, skip_threshold_calculation
    bne $s6, $zero, skip_threshold_calculation  # Skip if threshold already set
    
    # Calculate adaptive threshold: threshold = min + (max-min)/3
    sub $a2, $s0, $t8         # a2 = max - min
    div $a3, $a2, $a1         # Divide by 3 (approximation: use 160)
    addi $a1, $zero, 3        
    div $a3, $a3, $a1         # a3 = (max-min)/3
    add $s6, $t8, $a3         # s6 = min + (max-min)/3
    
skip_threshold_calculation:
    # If threshold not set yet, skip peak detection
    bne $s6, $zero, do_peak_detection
    j skip_peak_detection
    
do_peak_detection:
    # Peak detection using adaptive threshold
    blt $a0, $s6, below_threshold
    bne $s7, $zero, skip_peak_check
    addi $s4, $s4, 1          # Count the peak
    addi $s7, $zero, 1        # State = above threshold
    j skip_peak_check
    
below_threshold:
    add $s7, $zero, $zero     # State = below threshold
    
skip_peak_check:
skip_peak_detection:

    # EMG high threshold check
    sll $a3, $t9, 2           # a3 = 4 * min(EMG)
    blt $s2, $a3, skip_emg_high
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
    # BPM = peak count * 60 * (samples_per_second / total_samples)
    # For 320 samples at 320Hz = 1 second total time
    # BPM = peaks * 60
    addi $a1, $zero, 60
    mul $s4, $s4, $a1
    
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
    sw $s3, 0($t0)
    j start                   # loop forever