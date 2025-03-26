module bypass (ctrl_xm, ctrl_dx, ctrl_mw, byp_selALU_A, byp_selALU_B, byp_selMem_data, IR_DX, IR_MW, IR_XM, byp_jr);

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
    output [1:0] byp_selALU_A, byp_selALU_B,byp_jr;
    output byp_selMem_data;

    // get rt from IR
    wire [4:0] rt_dx;
    instrdecoder decoder_IR_DX (
        .instruction(IR_DX),
        .rt(rt_dx)
    );

    wire is_blt = IR_DX[31:27] == 5'b00110; // BLT opcode
    wire [4:0] blt_rd = IR_DX[26:22]; // rd field - CORRECT position for blt
    wire [4:0] blt_rs = IR_DX[21:17]; // rs field - CORRECT position for blt

    wire blt_rd_hazard_xm = is_blt && (blt_rd == ctrl_xm[31:27]) && ctrl_xm[15]; // XM stage writing to rd
    wire blt_rd_hazard_mw = is_blt && (blt_rd == ctrl_mw[31:27]) && ctrl_mw[15]; // MW stage writing to rd  
    wire blt_rs_hazard_xm = is_blt && (blt_rs == ctrl_xm[31:27]) && ctrl_xm[15]; // XM stage writing to rs
    wire blt_rs_hazard_mw = is_blt && (blt_rs == ctrl_mw[31:27]) && ctrl_mw[15]; // MW stage writing to rs

    // ALU A bypass
    // 00 = no bypass
    // 01 = bypass from DX
    // 10 = bypass from MW
    // DXRS == MWRS && DXRWE && DXRS != 0
    assign byp_selALU_A = blt_rd_hazard_xm ? 2'b00 :   // Bypass from XM
                      blt_rd_hazard_mw ? 2'b01 :   // Bypass from MW 
                        (ctrl_dx[5:1] == ctrl_xm[31:27] && ctrl_xm[15] && ctrl_xm[31:27] != 5'd0) ? 2'd0 :
                          (ctrl_dx[5:1] == ctrl_mw[31:27] && ctrl_mw[15] && ctrl_mw[31:27] != 5'd0) ? 2'd1 :
                          2'd2;

    assign byp_selALU_B = blt_rs_hazard_xm ? 2'b00 :   // Bypass from XM
                        blt_rs_hazard_mw ? 2'b01 :   // Bypass from MW
                        (rt_dx == ctrl_xm[31:27] && ctrl_xm[15] && rt_dx != 5'd0) ? 2'd0 :
                          (rt_dx == ctrl_mw[31:27] && ctrl_mw[15] && rt_dx != 5'd0) ? 2'd1 :
                          2'd2;

    assign byp_selMem_data = (ctrl_xm[31:27] == ctrl_mw[31:27] && ctrl_mw[15] && ctrl_mw[31:27] != 5'd0) ? 1'b0 :
                             1'b1;


    // JR bypass
    assign byp_jr = (ctrl_xm[31:27] == 5'd31 && ctrl_xm[15]) ? 2'b00 :  // Bypass from XM
                    (ctrl_mw[31:27] == 5'd31 && ctrl_mw[15]) ? 2'b01 :  // Bypass from MW
                    2'b10;  // Use the value directly
    

endmodule