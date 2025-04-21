    addi $8, $zero, 0          # $8 = address index
    addi $11, $zero, 640       # $11 = 640 for wraparound

loop:
    lw   $9, 2049($8)          # Load word from RAM[0x801 + $8]
    addi $8, $8, 1             # Increment index
    blt  $8, $11, skip_reset
    addi $8, $zero, 0          # Reset to 0 if $8 >= 640
skip_reset:

    # === Delay Loop ===
    addi $12, $zero, 500       # Outer loop counter
outer_delay:
    addi $13, $zero, 5000      # Inner loop counter
inner_delay:
    addi $13, $13, -1
    bne  $13, $zero, inner_delay
    addi $12, $12, -1
    bne  $12, $zero, outer_delay

    j loop                     # Repeat
