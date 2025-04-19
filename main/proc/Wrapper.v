`timescale 1ns / 1ps
/**
 * 
 * READ THIS DESCRIPTION:
 *
 * This is the Wrapper module that will serve as the header file combining your processor, 
 * RegFile and Memory elements together.
 *
 * This file will be used to generate the bitstream to upload to the FPGA.
 * We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
 * 
 * We will be using our own separate Wrapper_tb.v to test your code. You are allowed to make changes to the Wrapper files 
 * for your own individual testing, but we expect your final processor.v and memory modules to work with the 
 * provided Wrapper interface.
 * 
 * Refer to Lab 5 documents for detailed instructions on how to interface 
 * with the memory elements. Each imem and dmem modules will take 12-bit 
 * addresses and will allow for storing of 32-bit values at each address. 
 * Each memory module should receive a single clock. At which edges, is 
 * purely a design choice (and thereby up to you). 
 * 
 * You must change line 36 to add the memory file of the test you created using the assembler
 * For example, you would add sample inside of the quotes on line 38 after assembling sample.s
 *
 **/

module Wrapper (clock, reset, vauxn11, vauxp11, vauxn3, vauxp3, LED);
	input clock, reset;
	input vauxn3, vauxp3;        // EMG input (VAUX3)
	input vauxn11, vauxp11;    // ECG input (VAUX11)

	wire rwe, mwe;
	wire[4:0] rd, rs1, rs2;
	wire[31:0] instAddr, instData, 
		rData, regA, regB,
		memAddr, memDataIn, memDataOut;

	// LED output
	output [15:0] LED;


	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "emg-test";
	
	// Main Processing Unit
	processor CPU(.clock(clock), .reset(reset), 
								
		// ROM
		.address_imem(instAddr), .q_imem(instData),
									
		// Regfile
		.ctrl_writeEnable(rwe),     .ctrl_writeReg(rd),
		.ctrl_readRegA(rs1),     .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
									
		// RAM
		.wren(mwe), .address_dmem(memAddr), 
		.data(memDataIn), .q_dmem(memDataOut)); 

	// EMG and ECG ADC Capture
	wire [31:0] emg_out, ecg_out;
	adc_data_capture ADC_Capture(
		.clk(clock),
		.vauxn3(vauxn3), .vauxp3(vauxp3),        // EMG input (VAUX3)
		.vauxn11(vauxn11), .vauxp11(vauxp11),    // ECG input (VAUX11)
		.emg_out(emg_out),         // Output for EMG
		.ecg_out(ecg_out),          // Output for ECG
		.reset(reset)
	);

	// RAM addresses reserved for ADC samples
	localparam EMG_ADDR = 12'hC7F; // 0x00000FFC
	localparam ECG_ADDR = 12'hFFE; // 0x00000FF8
	
	// Instruction Memory (ROM)
	ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
	InstMem(.clk(clock), 
		.addr(instAddr[11:0]), 
		.dataOut(instData));
	
	// Register File
	regfile RegisterFile(.clock(clock), 
		.ctrl_writeEnable(rwe), .ctrl_reset(reset), 
		.ctrl_writeReg(rd),
		.ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),.LED(LED));
						
	// Processor Memory (RAM)
	RAM ProcMem(.clk(clock), 
		.wEn(mwe), 
		.addr(memAddr[11:0]), 
		.dataIn(memDataIn), 
		.dataOut(memDataOut),

		// ADC Port (write-only)
		.adc_wEn(1'b1),
		.adc_addr(EMG_ADDR),
		.adc_dataIn(emg_out)
		);

endmodule
