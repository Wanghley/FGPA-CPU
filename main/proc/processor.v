/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for RegFile
    ctrl_writeReg,                  // O: Register to write to in RegFile
    ctrl_readRegA,                  // O: Register to read from port A of RegFile
    ctrl_readRegB,                  // O: Register to read from port B of RegFile
    data_writeReg,                  // O: Data to write to for RegFile
    data_readRegA,                  // I: Data from port A of RegFile
    data_readRegB                   // I: Data from port B of RegFile
	 
	);

	// Control signals
	input clock, reset;
	
	// Imem
    output [31:0] address_imem;
	input [31:0] q_imem;

	// Dmem
	output [31:0] address_dmem, data;
	output wren;
	input [31:0] q_dmem;

	// Regfile
	output ctrl_writeEnable;
	output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	output [31:0] data_writeReg;
	input [31:0] data_readRegA, data_readRegB;

    // Latches
    wire [31:0] IR_FD, IR_DX, IR_MW, IR_XM;
    wire [31:0] PC_FD, PC_DX, PC_MW, PC_XM;
    wire [31:0] A_DX, B_DX, A_MW, B_MW, A_XM, B_XM;
    wire [31:0] TARGET_DX, TARGET_MW, TARGET_XM;
    wire [31:0] CONTROL_DX, CONTROL_MW, CONTROL_XM;

	/* ############################################################# */
    /* #                Instruction Fetch (IF) Stage               # */
    /* ############################################################# */
    // Create register for PC
    wire [31:0] PCout, PCin;
    wire pc_stall, branch_taken, branch_mispredicted;

    latch PROGRAMCOUNTER(
        .data_out(PCout),
        .data_in(PCin),
        .clk(clock),
        .en(~pc_stall), 
        .clr(reset)
    );

    // calculate next PC
    wire [31:0] PCnext, PCplus1;
    wire [31:0] branch_target; // Target address for branches
    wire is_jump;              // Jump detection signal

    cla nextPC(
        .S(PCplus1),
        .cout(),
        .ovf(),
        .x(PCout),
        .y(32'b1)
    );

    // Branch prediction - simple static "not taken" prediction
    assign PCnext = branch_mispredicted ? branch_target : PCplus1;
    assign address_imem = PCout;


    // -------------------------------------------------------------
    // Improved Jump Detection and Target Logic
    // -------------------------------------------------------------

    // Extract opcode and target from instruction
    wire [4:0] if_opcode = q_imem[31:27];
    wire [26:0] if_target = q_imem[26:0];

    // Identify jump instructions more clearly
    wire is_j = (if_opcode == 5'b00001);   // j instruction
    wire is_jal = (if_opcode == 5'b00011); // jal instruction
    assign is_jump = is_j || is_jal;       // Any unconditional jump
    
    // Extract rs and rt from instruction
    wire [4:0] if_rs = q_imem[26:22];
    wire [4:0] if_rt = q_imem[21:17];

    // Identify branch instructions
    wire if_is_bne = (if_opcode == 5'b00010); // branch not equal
    wire if_is_blt = (if_opcode == 5'b00110); // branch less than
    wire if_is_bex = (if_opcode == 5'b10110); // branch exception

    // Sign-extend the target/immediate field for jump addresses
    wire [31:0] if_jump_target;
    sra IF_IMMEXT(
        .out(if_jump_target),
        .x({if_target[16:0], 15'b0}), // Only use the immediate portion for jump target
        .shamt(5'd15)                 // 15 bit shift
    );

    // For branches, calculate potential branch target using PC+1
    cla branchTargetIF(
        .S(branch_target),
        .cout(),
        .ovf(),
        .x(PCplus1),   // Use PC+1 as base
        .y(if_jump_target) // Add the offset
    );

    // PC input selection logic
    // For jumps, use the jump target directly
    // For normal execution, use PC+1
    assign PCin = ctrl_flow_change ? jump_pc : PCnext;

    wire reg_dependency_hazard = 
                (CONTROL_DX[31:27] == if_rs || CONTROL_DX[31:27] == if_rt) || // RAW hazard with ID stage
                (CONTROL_XM[31:27] == if_rs || CONTROL_XM[31:27] == if_rt);  // RAW hazard with EX stage

    // Only stall for BNE/BLT that have register dependencies, not for BEX
    wire branch_hazard = (if_is_bne || if_is_blt) && reg_dependency_hazard;

    // BEX only depends on $30, which is accessed directly
    wire bex_hazard = if_is_bex && 
                    ((CONTROL_DX[31:27] == 5'd30) || (CONTROL_XM[31:27] == 5'd30));
    // -------------------------------------------------------------
    // |                    Stall Logic                           |
    // -------------------------------------------------------------
    // Simplified stall logic - only stall on unresolved branches

    // Stall signals for each stage
    wire stall_signal;
    wire [31:0] nop = 32'd0;
    stall STALL(
        .ctrl_dx(CONTROL_DX),
        .ir_dx(IR_DX),
        .ir_fd(IR_FD),
        .stall(stall_signal)
    );

    assign pc_stall = bex_hazard || multdiv_hazard || stall_signal;
    wire fd_stall = multdiv_hazard || stall_signal;
    wire dx_stall = multdiv_hazard;
    wire jump_flush = is_jump_ex && ~pc_stall;
    wire branch, is_bex_taken, is_jump_ex;

    // -------------------------------------------------------------
    // |                    Bypassing Logic                        |
    // -------------------------------------------------------------
    wire [1:0] byp_selALU_A, byp_selALU_B; // ALU A and B bypass selectors
    wire [31:0] DXB, XMB,MWB,FDB; // bypassed data from DX, XM, MW, and WB stages
    wire byp_selMem_data; // Memory data bypass selector

    bypass BYP(
        .ctrl_xm(CONTROL_XM),
        .ctrl_dx(CONTROL_DX),
        .ctrl_mw(CONTROL_MW),
        .byp_selALU_A(byp_selALU_A),
        .byp_selALU_B(byp_selALU_B),
        .IR_DX(IR_DX),
        .IR_MW(IR_MW),
        .IR_XM(IR_XM),
        .byp_selMem_data(byp_selMem_data)
    );


    /* ------------------------------------------------------------- */
    /* |                           FD Latch                        | */
    /* ------------------------------------------------------------- */
    latch PC_FD_LATCH(
        .data_out(PC_FD),
        .data_in((stall_signal || branch || is_bex_taken)? 32'd0:PCnext),
        .clk(clock),
        .en(~fd_stall),
        .clr(reset)
    );
    latch IR_FD_LATCH(
        .data_out(IR_FD),
        .data_in((stall_signal || branch || is_bex_taken || jump_flush) ? 32'd0 : q_imem),
        .clk(clock),
        .en(~fd_stall),
        .clr(reset)
    );
    /* ------------------------------------------------------------- */
    /* ############################################################# */
    /* #                Instruction Decode (ID) Stage              # */
    /* ############################################################# */

    // get opcode
    wire [4:0] opcode;
    assign opcode = IR_FD[31:27];

    // instr decoder
    wire [4:0] rs, rt, rd, shamt;
    wire [4:0] aluop;
    wire [16:0] imm;
    wire [26:0] target;

    instrdecoder instr_decoder(
        .instruction(IR_FD),
        .opcode(opcode),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .shamt(shamt),
        .aluop(aluop),
        .imm(imm),
        .target(target)
    );

    // control unit
    wire aluInB, RWE, Dmem_WE, mem_to_reg,regfile_readB_rt_rd, bne, blt, br, jp, jal, jr;
    wire [4:0] aluop_out;
    control ctrl(
        .opcode(opcode),
        .aluop_in(aluop),
        .aluop(aluop_out),
        .aluInB(aluInB),
        .RWE(RWE),
        .Dmem_WE(Dmem_WE),
        .mem_to_reg(mem_to_reg),
        .regfile_readB_rt_rd(regfile_readB_rt_rd),
        .bne(bne),
        .blt(blt),
        .br(br),
        .jp(jp),
        .jal(jal),
        .jr(jr)
    );

    wire [31:0] ctrl_in;
    assign ctrl_in[31:27] = rd;
    assign ctrl_in[26:22] = shamt;
    assign ctrl_in[21:17] = aluop_out;
    assign ctrl_in[16] = aluInB;
    assign ctrl_in[15] = RWE;
    assign ctrl_in[14] = Dmem_WE;
    assign ctrl_in[13] = mem_to_reg;
    assign ctrl_in[12] = bne;
    assign ctrl_in[11] = blt;
    assign ctrl_in[10] = br;
    assign ctrl_in[9] = jp;
    assign ctrl_in[8] = jal;
    assign ctrl_in[7] = jr;
    assign ctrl_in[6] = (opcode == 5'b10110 && data_readRegA != 32'd0) ? 1'b1 : 1'b0; // BEX instruction
    assign ctrl_in[5:1] = rs;
    assign ctrl_in[0] = 1'b0; // tobeused

    // pass arguments to my registerfile in the wrapper module
    assign ctrl_readRegA = (jr || bne ||blt) ? rd : (opcode == 5'b10110)? 5'd30 : rs;
    assign ctrl_readRegB = (regfile_readB_rt_rd) ? rd : (bne||blt)? rs : rt;

    // rs and rt data come from the regfile in data_readRegA and data_readRegB
    // extend immediate value
    wire [31:0] imm_ext;
    sra IMMEXT(
        .out(imm_ext),
        .x({imm, 15'b0}),
        .shamt(5'd15) // 15 bit shift
    );

    // // BEX instruction - exception handling
    // // For BEX, we need to set the PC to the exception handler address
    wire [31:0] bex_target;
    sra BEX_IMMEXT(
        .out(bex_target),
        .x({target, 5'b0}),
        .shamt(5'd5) // 5 bit shift
    );

    /* ------------------------------------------------------------- */
    /* |                           DX Latch                        | */
    /* ------------------------------------------------------------- */
    wire [31:0] imm_DX, shamt_DX, aluop_DX;
    latch PC_DX_LATCH(
        .data_out(PC_DX),
        .data_in((stall_signal || branch || is_bex_taken || is_jump_ex)? 32'd0:PC_FD),
        .clk(clock),
        .en(~dx_stall),
        .clr(reset)
    );
    latch IR_DX_LATCH(
        .data_out(IR_DX),
        .data_in((stall_signal || branch || is_bex_taken || is_jump_ex)? 32'd0:IR_FD),
        .clk(clock),
        .en(~dx_stall),
        .clr(reset)
    );
    latch A_DX_LATCH(
        .data_out(A_DX),
        .data_in((stall_signal || branch || is_bex_taken || is_jump_ex)? 32'd0:data_readRegA),
        .clk(clock),
        .en(~dx_stall),
        .clr(reset)
    );
    latch B_DX_LATCH(
        .data_out(B_DX),
        .data_in((stall_signal || branch || is_bex_taken || is_jump_ex)? 32'd0:data_readRegB),
        .clk(clock),
        .en(~dx_stall),
        .clr(reset)
    );
    latch IMM_DX_LATCH(
        .data_out(imm_DX),
        .data_in((stall_signal || branch || is_bex_taken || is_jump_ex)? 32'd0:imm_ext),
        .clk(clock),
        .en(~dx_stall),
        .clr(reset)
    );
    latch CONTROL_DX_LATCH(
        .data_out(CONTROL_DX),
        .data_in((stall_signal || branch || is_bex_taken || is_jump_ex)? 32'd0:ctrl_in),
        .clk(clock),
        .en(~dx_stall),
        .clr(reset)
    );
    latch TARGET_LATCH(
        .data_out(TARGET_DX),
        .data_in((stall_signal || branch || is_bex_taken || is_jump_ex)? 32'd0:bex_target),
        .clk(clock),
        .en(~dx_stall),
        .clr(reset)
    );
    /* ------------------------------------------------------------- */
    /* ############################################################# */
    /* #                Execute (EX) Stage                         # */
    /* ############################################################# */
    // immediate value sign extension
    wire [31:0] data_ALUInB;
    wire aluInB_ctrl = CONTROL_DX[16];
    wire [4:0] op_ctrl_dx = CONTROL_DX[21:17];
    wire [4:0] shamt_alu_ctrl = CONTROL_DX[26:22];

    
    // -------------------------------------------------------------
    // |                    ALU Logic                              |
    // -------------------------------------------------------------

    // ALU input selection
    wire [31:0] ALUinA;
    mux_4_1 ALU_A_MUX(
        .out(ALUinA),
        .select(byp_selALU_A),
        .in0(XMB),
        .in1(MWB),
        .in2(A_DX),
        .in3(A_DX)
    );

    wire[31:0] ALUInB;

    mux_4_1 ALU_B_MUX(
        .out(ALUInB),
        .select(byp_selALU_B),
        .in0(XMB),
        .in1(MWB),
        .in2(B_DX),
        .in3(B_DX)
    );

    assign data_ALUInB = (aluInB_ctrl) ? imm_DX : ALUInB;


    wire [31:0] ALUout;
    wire ne_ALU, lessThan_ALU, overflow_ALU; // flags for not equality, less than, overflow
    alu ALU(
        .data_operandA(ALUinA),
        .data_operandB(data_ALUInB),
        .ctrl_ALUopcode(op_ctrl_dx),
        .data_result(ALUout),
        .ctrl_shiftamt(shamt_alu_ctrl),
        .isNotEqual(ne_ALU),
        .isLessThan(lessThan_ALU),
        .overflow(overflow_ALU)
    );

    // -------------------------------------------------------------
    // |                    Multiplication and Division            |
    // -------------------------------------------------------------
    // TODO: implement multiplication and division logic
    //data_operandA, data_operandB, ctrl_MULT, ctrl_DIV, clock, data_result, data_exception, data_resultRDY
    wire ctrl_multidiv_datardy, multidiv_exception_int_dx, ctrl_MULT, ctrl_DIV;
    wire [31:0] multdiv_result;
    multdiv MULTIDIV(
        .data_operandA(ALUinA),
        .data_operandB(ALUInB),
        .ctrl_MULT(ctrl_MULT), // signal to start multiplication
        .ctrl_DIV(ctrl_DIV), // signal to start division
        .clock(clock),
        .data_exception(multidiv_exception_int_dx),
        .data_result(multdiv_result),
        .data_resultRDY(ctrl_multidiv_datardy)
    );

    // process opcode for MULT and DIV
    wire is_mult = (op_ctrl_dx == 5'b00110) && IR_DX[31:27] == 5'b00000;
    wire is_div = (op_ctrl_dx == 5'b00111) && IR_DX[31:27] == 5'b00000;

    wire multdiv_hazard = (is_mult || is_div) && ~ctrl_multidiv_datardy;

    // MULT signals
    wire dff_mult_ctrl_int_dx;
    wire not_dff_mult_ctrl_int_dx = ~dff_mult_ctrl_int_dx;
    assign ctrl_MULT = is_mult & not_dff_mult_ctrl_int_dx;
    wire dff_mult_ctrl_int_dx2;
    dffe_ref MULT_CTRL_1(
        .q(dff_mult_ctrl_int_dx),
        .d(is_mult),
        .clk(clock),
        .en(1'b1),
        .clr(dff_mult_ctrl_int_dx2)
    );
    dffe_ref MULT_CTRL_2(
        .q(dff_mult_ctrl_int_dx2),
        .d(ctrl_multidiv_datardy),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    // DIV signals
    wire dff_div_ctrl_int_dx;
    wire not_dff_div_ctrl_int_dx = ~dff_div_ctrl_int_dx;
    assign ctrl_DIV = is_div & not_dff_div_ctrl_int_dx;
    wire dff_div_ctrl_int_dx2;
    dffe_ref DIV_CTRL_1(
        .q(dff_div_ctrl_int_dx),
        .d(is_div),
        .clk(clock),
        .en(1'b1),
        .clr(dff_div_ctrl_int_dx2)
    );
    dffe_ref DIV_CTRL_2(
        .q(dff_div_ctrl_int_dx2),
        .d(ctrl_multidiv_datardy),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );

    wire multdiv_excp_dex = multidiv_exception_int_dx && ctrl_multidiv_datardy;
    
   

    // -------------------------------------------------------------
    // |                    exception detection                    |
    // -------------------------------------------------------------
    wire [31:0] exception;
    exception EXC(
        .opcode(IR_DX[31:27]),
        .dx_opcode(op_ctrl_dx),
        .alu_ovf(overflow_ALU),
        .multidiv_exception(multdiv_excp_dex),
        .exception(exception)
    );

    // -------------------------------------------------------------
    // |                    Branch and Jump Logic                  |
    // -------------------------------------------------------------
    // Branch condition evaluation - now with cleaner definitions
    wire bne_instr = CONTROL_DX[12]; // BNE control signal
    wire blt_instr = CONTROL_DX[11]; // BLT control signal
    wire branch_instr = CONTROL_DX[10]; // Branch instruction indicator
    assign is_bex_taken = (IR_DX[31:27] == 5'b10110) && CONTROL_DX[6];

    wire branch_condition_met = (ne_ALU & bne_instr) || (lessThan_ALU & blt_instr) || is_bex_taken;
    assign branch = branch_condition_met && branch_instr;

    // Calculate branch target - this is the correct target address if branch is taken
    wire [31:0] branchPC_calculated;
    cla branchTargetCalc(
        .S(branchPC_calculated),
        .cout(),
        .ovf(),
        .x(PC_DX),
        .y(imm_DX)
    );

    // Branch misprediction detection
    // Since we use static not-taken prediction, a misprediction occurs when branch is actually taken
    assign branch_mispredicted = branch; // Branch was taken but predicted not taken

    // Branch resolution logic - choose between branch target and next sequential PC
    wire [31:0] pc_plus_1_ex;
    cla nextPC_EX(
        .S(pc_plus_1_ex),
        .cout(),
        .ovf(),
        .x(PC_DX),
        .y(32'b1)
    );
    wire [31:0] branch_pc = branch ? 
             ((IR_DX[31:27] == 5'b10110) ? TARGET_DX : branchPC_calculated) 
             : pc_plus_1_ex;


    // Final PC selection - choose jump target if this is a jump instruction (CONTROL_DX[9])
    // otherwise use the branch_pc value (which may be either the branch target or next PC)
    // check if it is a jr instruction
    // Correct jump PC selection logic
    assign is_jump_ex = CONTROL_DX[9] || CONTROL_DX[8] || CONTROL_DX[7]; // j, jal, or jr
    wire [31:0] jump_pc = CONTROL_DX[7] ? A_DX :             // JR: jump to register value
                         (CONTROL_DX[9] || CONTROL_DX[8]) ? imm_DX :  // J/JAL: jump to immediate
                         branch_pc;

    // Control flow change signal - true when we need to redirect the pipeline
    wire ctrl_flow_change = is_jump_ex || branch_mispredicted;
    

    /* ------------------------------------------------------------- */
    /* |                           XM Latch                        | */
    /* ------------------------------------------------------------- */
    // Add this before the XM latch
    wire [31:0] O_XM;
    assign XMB = O_XM; // bypassed data from XM stage
    latch O_XM_LATCH(
    .data_out(O_XM),
    .data_in(CONTROL_DX[8] ? PC_DX : (exception==32'd0) ? (is_mult || is_div) && ctrl_multidiv_datardy ? multdiv_result : ALUout : exception),
    .clk(clock),
    .en(1'b1),
    .clr(reset) 
);
    latch B_XM_LATCH(
        .data_out(B_XM),
        .data_in(B_DX),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch IR_XM_LATCH(
        .data_out(IR_XM),
        .data_in(IR_DX),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch CONTROL_XM_LATCH(
        .data_out(CONTROL_XM),
        .data_in((exception==32'd0) ? CONTROL_DX : {5'd30, CONTROL_DX[26:17], 1'b1, CONTROL_DX[15:0]}),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch TARGET_XM_LATCH(
        .data_out(TARGET_XM),
        .data_in(TARGET_DX),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    /* ------------------------------------------------------------- */
    /* ############################################################# */
    /* #                Memory Access (MA) Stage                   # */
    /* ############################################################# */
    // TODO: need to implement memory access stage
    // RAM access

    wire [31:0] dmem_out;
    assign address_dmem = O_XM;
    assign data = byp_selMem_data==1'b0 ? MWB : B_XM;
    assign wren = CONTROL_XM[14];
    assign dmem_out = q_dmem;


    /* ------------------------------------------------------------- */
    /* |                           MW Latch                        | */
    /* ------------------------------------------------------------- */
    wire [31:0] O_MW, D_MW;
    latch O_MW_LATCH(
        .data_out(O_MW),
        .data_in(O_XM),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch D_MW_LATCH(
        .data_out(D_MW),
        .data_in(dmem_out),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch IR_MW_LATCH(
        .data_out(IR_MW),
        .data_in(IR_XM),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch CONTROL_MW_LATCH(
        .data_out(CONTROL_MW),
        .data_in(CONTROL_XM),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch TARGET_MW_LATCH(
        .data_out(TARGET_MW),
        .data_in(TARGET_XM),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );

    /* ------------------------------------------------------------- */
    /* ############################################################# */
    /* #                Write Back (WB) Stage                      # */
    /* ############################################################# */

    // Decide which register to write to
    wire [31:0] regWrite = (IR_MW[31:27]==5'b00011) ? 32'd31 : (IR_MW[31:27]==5'b10101) ? 32'd30 : CONTROL_MW[31:27];

    assign data_writeReg = (CONTROL_MW[13]) ? D_MW : (IR_MW[31:27]==5'b10101) ? TARGET_MW : O_MW;
    assign MWB = data_writeReg;
    assign ctrl_writeEnable = CONTROL_MW[15] || (IR_MW[31:27]==5'b10101);
    assign ctrl_writeReg = regWrite;

	
	/* END CODE */

endmodule
