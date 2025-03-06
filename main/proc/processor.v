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

	/* ############################################################# */
    /* #                Instruction Fetch (IF) Stage               # */
    /* ############################################################# */
    // Create register for PC
    wire [31:0] PCout, PCin;

    latch PROGRAMCOUNTER(
        .data_out(PCout),
        .data_in(PCin),
        .clk(clock),
        .en(1'b1), // FIXME: need to buildup logic for this signal with branch and jump instructions
        .clr(reset)
    );

    // calculate next PC
    wire [31:0] PCnext;
    cla nextPC(
        .S(PCnext),
        .cout(),
        .ovf(),
        .x(PCout),
        .y(32'b1)
    );
    assign PCin = PCnext;
    assign address_imem = PCout;
    

    /* ------------------------------------------------------------- */
    /* |                           FD Latch                        | */
    /* ------------------------------------------------------------- */
    wire [31:0] IR_FD, PC_FD;
    latch PC_FD_LATCH(
        .data_out(PC_FD),
        .data_in(PCnext),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch IR_FD_LATCH(
        .data_out(IR_FD),
        .data_in(q_imem),
        .clk(clock),
        .en(1'b1),
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
    wire aluInB, RWE, Dmem_WE, mem_to_reg;
    wire [4:0] aluop_out;
    control ctrl(
        .opcode(opcode),
        .aluop_in(aluop),
        .aluop(aluop_out),
        .aluInB(aluInB),
        .RWE(RWE),
        .Dmem_WE(Dmem_WE),
        .mem_to_reg(mem_to_reg)
    );

    wire [31:0] ctrl_in;
    assign ctrl_in[31:27] = rd;
    assign ctrl_in[26:22] = shamt;
    assign ctrl_in[21:17] = aluop_out;
    assign ctrl_in[16] = aluInB;
    assign ctrl_in[15] = RWE;
    assign ctrl_in[14] = Dmem_WE;
    assign ctrl_in[13] = mem_to_reg;
    // TODO: implement control signals for the rest of the control unit
    assign ctrl_in[14:0] = 15'd0;

    // pass arguments to my registerfile in the wrapper module
    assign ctrl_readRegA = rs;
    assign ctrl_readRegB = rt;

    // rs and rt data come from the regfile in data_readRegA and data_readRegB
    // extend immediate value
    wire [31:0] imm_ext;
    sra IMMEXT(
        .out(imm_ext),
        .x({imm, 15'b0}),
        .shamt(5'd15) // 15 bit shift
    );

    /* ------------------------------------------------------------- */
    /* |                           DX Latch                        | */
    /* ------------------------------------------------------------- */
    wire [31:0] IR_DX, PC_DX, CONTROL_DX;
    wire [31:0] A_DX, B_DX, imm_DX, shamt_DX, aluop_DX;
    latch PC_DX_LATCH(
        .data_out(PC_DX),
        .data_in(PC_FD),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch IR_DX_LATCH(
        .data_out(IR_DX),
        .data_in(IR_FD),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch A_DX_LATCH(
        .data_out(A_DX),
        .data_in(data_readRegA),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch B_DX_LATCH(
        .data_out(B_DX),
        .data_in(data_readRegB),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch IMM_DX_LATCH(
        .data_out(imm_DX),
        .data_in(imm_ext),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    latch CONTROL_DX_LATCH(
        .data_out(CONTROL_DX),
        .data_in(ctrl_in),
        .clk(clock),
        .en(1'b1),
        .clr(reset)
    );
    /* ------------------------------------------------------------- */
    /* ############################################################# */
    /* #                Execute (EX) Stage                         # */
    /* ############################################################# */
    // immediate value sign extension
    wire [31:0] data_ALUInB;
    wire aluInB_ctrl = CONTROL_DX[16];
    wire [4:0] alu_op_ctrl = CONTROL_DX[21:17];
    wire [4:0] shamt_alu_ctrl = CONTROL_DX[26:22];
    assign data_ALUInB = (aluInB_ctrl) ? imm_DX : B_DX;
    
    // ALU
    wire [31:0] ALUout;
    alu ALU(
        .data_operandA(A_DX),
        .data_operandB(data_ALUInB),
        .ctrl_ALUopcode(alu_op_ctrl),
        .data_result(ALUout),
        .ctrl_shiftamt(shamt_alu_ctrl),
        .isNotEqual(),
        .isLessThan(),
        .overflow()
    );

    /* ------------------------------------------------------------- */
    /* |                           XM Latch                        | */
    /* ------------------------------------------------------------- */
    wire [31:0] O_XM, B_XM, IR_XM, CONTROL_XM;
    latch O_XM_LATCH(
        .data_out(O_XM),
        .data_in(ALUout),
        .clk(clock),
        .en(1'b1),
        .clr(reset) 
    );
    latch B_XM_LATCH(
        .data_out(B_XM),
        .data_in(data_ALUInB),
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
        .data_in(CONTROL_DX),
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
    assign data = B_XM;
    assign wren = CONTROL_XM[14];
    assign dmem_out = q_dmem;


    /* ------------------------------------------------------------- */
    /* |                           MW Latch                        | */
    /* ------------------------------------------------------------- */
    wire [31:0] O_MW, D_MW, IR_MW, CONTROL_MW;
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
    /* ------------------------------------------------------------- */
    /* ############################################################# */
    /* #                Write Back (WB) Stage                      # */
    /* ############################################################# */
    assign data_writeReg = (CONTROL_MW[13]) ? D_MW : O_MW;
    assign ctrl_writeEnable = CONTROL_MW[15];
    assign ctrl_writeReg = CONTROL_MW[31:27];

	
	/* END CODE */

endmodule
