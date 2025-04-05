module bypass (ctrl_xm, ctrl_dx, ctrl_mw, byp_selALU_A, byp_selALU_B, byp_selMem_data, IR_DX, IR_MW, IR_XM, byp_jr, byp_b_dx);

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

    wire [4:0] rt_xm;
    instrdecoder decoder_IR_XM (
        .instruction(IR_XM),
        .rt(rt_xm)
    );

    // Check if XM stage contains a SW instruction
    wire is_sw_xm = IR_XM[31:27] == 5'b00111; // SW opcode

    wire is_blt = IR_DX[31:27] == 5'b00110; // BLT opcode
    wire [4:0] blt_rd = IR_DX[26:22]; // rd field - CORRECT position for blt
    wire [4:0] blt_rs = IR_DX[21:17]; // rs field - CORRECT position for blt

    wire blt_rd_hazard_xm = is_blt && (blt_rd == ctrl_xm[31:27]) && ctrl_xm[15]; // XM stage writing to rd
    wire blt_rd_hazard_mw = is_blt && (blt_rd == ctrl_mw[31:27]) && ctrl_mw[15]; // MW stage writing to rd  
    wire blt_rs_hazard_xm = is_blt && (blt_rs == ctrl_xm[31:27]) && ctrl_xm[15]; // XM stage writing to rs
    wire blt_rs_hazard_mw = is_blt && (blt_rs == ctrl_mw[31:27]) && ctrl_mw[15]; // MW stage writing to rs

    // Specific check for LW in XM stage (memory-to-register operation)
    wire is_lw_xm = ctrl_xm[13]; // LW in XM stage (mem_to_reg is set)
    wire is_lw_mw = ctrl_mw[13]; // LW in MW stage (mem_to_reg is set)

    // LW → BLT hazards (register in LW is needed by BLT)
    wire lw_blt_rd_hazard = is_blt && is_lw_xm && (blt_rd == ctrl_xm[31:27]) && ctrl_xm[15];
    wire lw_blt_rs_hazard = is_blt && is_lw_xm && (blt_rs == ctrl_xm[31:27]) && ctrl_xm[15];

    // Detect LW->BNE dependency
    // Detect LW->BNE dependency
    wire is_bne = IR_DX[31:27] == 5'b00010; // BNE opcode
    wire [4:0] bne_rd = IR_DX[26:22]; // First compare register
    wire [4:0] bne_rs = IR_DX[21:17]; // Second compare register

    // BNE hazards with previous instructions
    wire bne_rd_hazard_xm = is_bne && (bne_rd == ctrl_xm[31:27]) && ctrl_xm[15]; 
    wire bne_rd_hazard_mw = is_bne && (bne_rd == ctrl_mw[31:27]) && ctrl_mw[15];
    wire bne_rs_hazard_xm = is_bne && (bne_rs == ctrl_xm[31:27]) && ctrl_xm[15];
    wire bne_rs_hazard_mw = is_bne && (bne_rs == ctrl_mw[31:27]) && ctrl_mw[15];

    // LW → BNE hazards (when LW result is needed by BNE)
    wire lw_bne_rd_hazard = is_bne && is_lw_xm && (bne_rd == ctrl_xm[31:27]) && ctrl_xm[15];
    wire lw_bne_rs_hazard = is_bne && (is_lw_xm||is_lw_mw) && (bne_rs == ctrl_xm[31:27]) && ctrl_xm[15];

    // ALU A bypass - update to handle LW → BLT case for rd
    // 00 = bypass from XM
    // 01 = bypass from MW
    // 10 = use register file value
    // 11 = use direct memory value (for LW → BLT case)
    assign byp_selALU_A = (is_bne || is_blt) ? 
                        (  // Branch instruction special case
                            (bne_rd == 5'd0 || blt_rd == 5'd0) ? 2'b10 :  // $r0 always comes from regfile
                            lw_blt_rd_hazard || lw_bne_rd_hazard ? 2'b11 :  // Direct from memory 
                            blt_rd_hazard_xm || bne_rd_hazard_xm ? 2'b00 :   // Bypass from XM
                            blt_rd_hazard_mw || bne_rd_hazard_mw ? 2'b01 : 2'b10  // Bypass from MW or regfile
                        ) :
                        (  // Regular instruction case
                            (ctrl_dx[5:1] == 5'd0) ? 2'b10 :  // $r0 always from regfile
                            (ctrl_dx[5:1] == ctrl_xm[31:27] && ctrl_xm[15] && ctrl_xm[31:27] != 5'd0) ? 2'b00 :
                            (ctrl_dx[5:1] == ctrl_mw[31:27] && ctrl_mw[15] && ctrl_mw[31:27] != 5'd0) ? 2'b01 :
                            2'b10  // Default to register file
                        );

    // ALU B bypass selector
    assign byp_selALU_B = (is_bne || is_blt) ? 
                        (  // Branch instruction special case
                            (bne_rs == 5'd0 || blt_rs == 5'd0) ? 2'b10 :  // $r0 always comes from regfile
                            lw_blt_rs_hazard || lw_bne_rs_hazard ? 2'b11 :  // Direct from memory
                            blt_rs_hazard_xm || bne_rs_hazard_xm ? 2'b00 :   // Bypass from XM
                            blt_rs_hazard_mw || bne_rs_hazard_mw ? 2'b01 : 2'b10  // Bypass from MW or regfile
                        ) :
                        (  // Regular instruction case
                            (rt_dx == 5'd0) ? 2'b10 :  // $r0 always from regfile
                            (rt_dx == ctrl_xm[31:27] && ctrl_xm[15]) ? 2'b00 :
                            (rt_dx == ctrl_mw[31:27] && ctrl_mw[15]) ? 2'b01 :

                            2'b10  // Default to register file
                        );

    
    
    assign byp_selMem_data = (ctrl_xm[31:27] == ctrl_mw[31:27] && ctrl_mw[15] && ctrl_mw[31:27] != 5'd0) ? 1'b0 :
                             1'b1;


    // JR bypass
    wire is_jr_dx = ctrl_dx[7]; // JR control bit
    wire [4:0] jr_rd;
    instrdecoder decoder_jr_reg (
        .instruction(IR_DX),
        .rd(jr_rd)
    );

    // Check if current instruction is JR
    wire is_jr = IR_DX[31:27] == 5'b00100 || ctrl_dx[7];  // JR opcode or JR control bit

    // Check for hazards with previous instructions
    wire jr_rd_hazard_xm = is_jr && (jr_rd == ctrl_xm[31:27]) && ctrl_xm[15]; // XM stage writing to jr_rd
    wire jr_rd_hazard_mw = is_jr && (jr_rd == ctrl_mw[31:27]) && ctrl_mw[15]; // MW stage writing to jr_rd

    // Specific check for LW in XM stage (memory-to-register operation)
    wire lw_jr_hazard = is_jr && is_lw_xm && (jr_rd == ctrl_xm[31:27]) && ctrl_xm[15];

    // JR bypass mux selector
    // 00 = bypass from LW in XM
    // 01 = bypass from XM
    // 10 = bypass from MW
    // 11 = use register file value
    assign byp_jr = lw_jr_hazard ? 2'b00 :       // Bypass from LW in XM
                    jr_rd_hazard_xm ? 2'b01 :       // Bypass from XM
                    jr_rd_hazard_mw ? 2'b10 :       // Bypass from MW
                    2'b11;                          // Use register file value

    // for sw bypassing
    // 00 = bypass from XM
    // 01 = bypass from MW 
    // 10 = use register file value
    wire is_sw_dx = IR_DX[31:27] == 5'b00111; // SW opcode
    output [1:0] byp_b_dx;
    wire [4:0] rd_byp_dx = ctrl_dx[31:27]; // Destination register for SW
    wire [4:0] rt_byp_dx = IR_DX[26:22]; // Source register for SW
    assign byp_b_dx = (is_sw_dx) ? 
                    (  // SW instruction special case
                        (IR_DX[26:22] == 5'd0) ? 2'b10 :  // $r0 always from regfile
                        (IR_DX[26:22] == ctrl_xm[31:27] && ctrl_xm[15]) ? 2'b00 :  // Bypass from XM
                        (IR_DX[26:22] == ctrl_mw[31:27] && ctrl_mw[15]) ? 2'b01 :  // Bypass from MW
                        2'b10  // Default to register file
                    ) :
                    2'b10; // Default to register file
    

endmodule