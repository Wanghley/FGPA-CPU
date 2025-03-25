module bypass (ctrl_xm, ctrl_dx, ctrl_mw, byp_selALU_A, byp_selALU_B, byp_selMem_data, IR_DX, IR_MW, IR_XM);

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
    input [31:0] IR_DX, IR_MW, IR_XM;
    output [1:0] byp_selALU_A, byp_selALU_B;
    output byp_selMem_data;

    // get rt from IR
    wire [4:0] rt_dx, rt_mw, rt_xm;
    instrdecoder decoder_IR_DX (
        .instruction(IR_DX),
        .rt(rt_dx)
    );


    // ALU A bypass
    // 00 = no bypass
    // 01 = bypass from DX
    // 10 = bypass from MW
    // DXRS == MWRS && DXRWE && DXRS != 0
    assign byp_selALU_A = (ctrl_dx[5:1] == ctrl_xm[31:27] && ctrl_xm[15] && ctrl_xm[31:27] != 5'd0) ? 2'd0 :
                          (ctrl_dx[5:1] == ctrl_mw[31:27] && ctrl_mw[15] && ctrl_mw[31:27] != 5'd0) ? 2'd1 :
                          2'd2;

    assign byp_selALU_B = (rt_dx == ctrl_xm[31:27] && ctrl_xm[15] && rt_dx != 5'd0) ? 2'd0 :
                          (rt_dx == ctrl_mw[31:27] && ctrl_mw[15] && rt_dx != 5'd0) ? 2'd1 :
                          2'd2;

    assign byp_selMem_data = (ctrl_xm[31:27] == ctrl_mw[31:27] && ctrl_mw[15] && ctrl_mw[31:27] != 5'd0) ? 1'b0 :
                             1'b1;
    

endmodule