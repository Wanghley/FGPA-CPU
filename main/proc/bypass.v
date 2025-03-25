module bypass (ctrl_xm, ctrl_dx, ctrl_mw, byp_selALU_A, byp_selALU_B);

    // ctrl signals
    // 31:27 = destination register (rd)
    // 26:22 = shift amount (shamt)
    // 21:17 = ALU operation code output (aluop_out)
    // 16    = ALU second operand selector (aluInB)
    // 15    = Register Write Enable (RWE)
    // 14    = Data memory Write Enable (Dmem_WE)
    // 13    = Memory to Register (mem_to_reg)
    // 12    = Branch on Not Equal (bne)
    // 11    = Branch on Less Than (blt)
    // 10    = General branch signal (br)
    // 9     = Jump instruction (jp)
    // 8     = Jump and Link (jal)
    // 7     = Jump Register (jr)
    // 6     = BEX instruction (opcode == 10110 && rs ≠ 0)
    // 5:0   = Source register (rs)


    input [31:0] ctrl_xm, ctrl_dx, ctrl_mw;
    output [1:0] byp_selALU_A, byp_selALU_B;

    assign byp_selALU_A = (ctrl_dx[5:0] == ctrl_xm[31:27]) ? 2'd0 :
                          (ctrl_dx[5:0] == ctrl_mw[31:27]) ? 2'd1 :
                          2'd2;

endmodule