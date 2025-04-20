loop:
    # addi $8, $8, 1 # Increment register $t0 by 1
    lw $9, 2049($zero) # Load word from memory address 0x00000FF0 into register $t0
    j loop # Jump to the label 'loop'