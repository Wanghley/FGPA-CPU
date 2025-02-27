module regfile (
	clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;

	output [31:0] data_readRegA, data_readRegB;

	wire [31:0] wrt_en; // Write enable for each register
    wire [31:0] regs [31:0]; // Array of 32 registers, 32-bits each
    wire [31:0] actual_write_enable;

    // Generate the actual write enable signals
    assign actual_write_enable = ctrl_writeEnable ? wrt_en : 32'b0;

    // Decoder for Write Register Enable Signals
    decoder decoder_writeReg (
        .in(ctrl_writeReg), // 5-bit input address for write register
        .out(wrt_en)        // 32-bit output signal to enable write to register
    );

    // Decoder for Read Register A
    wire [31:0] readRegA_wire;
    decoder decoder_readRegA (
        .in(ctrl_readRegA), // 5-bit input address for read register A
        .out(readRegA_wire) // 32-bit output signal to select register for read A
    );

    // Decoder for Read Register B
    wire [31:0] readRegB_wire;
    decoder decoder_readRegB (
        .in(ctrl_readRegB), // 5-bit input address for read register B
        .out(readRegB_wire) // 32-bit output signal to select register for read B
    );

    assign regs[0] = 32'b0; // Register 0 is always 0

    // Direct combinational read logic
    assign data_readRegA = regs[ctrl_readRegA];
    assign data_readRegB = regs[ctrl_readRegB];

    // wrt_en_

    //////////////////////////
    // Create 32 Registers  //
    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : reg_write
            wire enable_wire;
            and enable_gate(enable_wire, actual_write_enable[i], ctrl_writeEnable);
            
            register r (
                .q(regs[i]), 
                .d(data_writeReg), 
                .clk(clock), 
                .en(enable_wire),
                .clr(ctrl_reset)
            );
        end
    endgenerate

endmodule