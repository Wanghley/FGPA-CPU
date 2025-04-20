`timescale 1ns / 1ps

/**
 * Wrapper module for integrating processor, register file, memory,
 * and XADC sampling of EMG and ECG signals.
 *
 * IMPORTANT: Set your instruction memory file name below at line ~40
 */

module Wrapper (
    input clock,                  // 35 MHz system clock
    input reset,                  // Reset signal
    input vauxn3, vauxp3,         // EMG input (VAUX3)
    input vauxn11, vauxp11,       // ECG input (VAUX11)
    output [3:0] VGA_R,          // VGA Red channel
    output [3:0] VGA_G,          // VGA Green channel
    output [3:0] VGA_B,          // VGA Blue channel
    output [15:0] LED,
    output hSync,           // VGA horizontal sync
    output vSync           // VGA vertical sync
);

    // ===================== //
    // === Control Wires === //
    // ===================== //
    wire rwe, mwe;
    wire [4:0] rd, rs1, rs2;
    wire [31:0] instAddr, instData;
    wire [31:0] rData, regA, regB;
    wire [31:0] memAddr, memDataIn, memDataOut;

    // =============================== //
    // === Instruction Memory File === //
    // =============================== //
    localparam INSTR_FILE = "emg-test";

    // ============================= //
    // === Instantiate Processor === //
    // ============================= //

    wire clock25; // 25 MHz clock for CPU

    reg[1:0] pixCounter = 0;      // Pixel counter to divide the clock
    assign clock25 = pixCounter[1]; // Set the clock high whenever the second bit (2) is high
	always @(posedge clk) begin
		pixCounter <= pixCounter + 1; // Since the reg is only 3 bits, it will reset every 8 cycles
	end

    processor CPU (
        .clock(clock25), .reset(reset),
        .address_imem(instAddr), .q_imem(instData),
        .ctrl_writeEnable(rwe), .ctrl_writeReg(rd),
        .ctrl_readRegA(rs1), .ctrl_readRegB(rs2),
        .data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
        .wren(mwe), .address_dmem(memAddr),
        .data(memDataIn), .q_dmem(memDataOut)
    );

    // ============================ //
    // === ADC Data Acquisition === //
    // ============================ //
    wire [31:0] emg_out, ecg_out;
    adc_data_capture ADC_Capture (
        .clk(clock), .reset(reset),
        .vauxn3(vauxn3), .vauxp3(vauxp3),
        .vauxn11(vauxn11), .vauxp11(vauxp11),
        .emg_out(emg_out), .ecg_out(ecg_out)
    );

    // Reserved memory address base for ADC writes
    localparam EMG_ADDR_BASE = 12'hC7F;  // 0x00000FFC
    localparam ECG_ADDR_BASE = 12'h801;  // 0x00000FF8

    // ============================ //
    // === Sample Control Logic === //
    // ============================ //
    localparam SAMPLE_INTERVAL = 18'd125000;  // 5ms @ 35MHz = 200Hz
    reg [17:0] sample_counter = 0;
    reg sample_enable = 0;
    reg channel_select = 0;  // 0 = EMG, 1 = ECG
    reg [9:0] sample_number_emg = 0;
    reg [9:0] sample_number_ecg = 0;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            sample_counter <= 0;
            sample_enable <= 0;
            channel_select <= 0;
            sample_number_emg <= 0;
            sample_number_ecg <= 0;
        end else if (sample_counter == SAMPLE_INTERVAL - 1) begin
            sample_counter <= 0;
            sample_enable <= 1;
            channel_select <= ~channel_select;

            if (channel_select == 0) begin  // EMG
                sample_number_emg <= sample_number_emg + 1;
                if (sample_number_emg == 10'd640)
                    sample_number_emg <= 0;
            end else begin  // ECG
                sample_number_ecg <= sample_number_ecg + 1;
                if (sample_number_ecg == 10'd640)
                    sample_number_ecg <= 0;
            end
        end else begin
            sample_counter <= sample_counter + 1;
            sample_enable <= 0;
        end
    end

    // ADC Data Routing Logic
    reg [31:0] adc_data_mux;
    reg [11:0] adc_addr_mux;
    always @(posedge clock) begin
        if (channel_select == 0) begin
            adc_data_mux = emg_out;
            adc_addr_mux = EMG_ADDR_BASE + sample_number_emg;
        end else begin
            adc_data_mux = ecg_out;
            adc_addr_mux = ECG_ADDR_BASE + sample_number_ecg;
        end
    end

    // ============================ //
    // === VGA Display Logic === //
    // ============================ //
    wire [11:0] vga_ecg_addr;
    wire [31:0] vga_ecg_data;


    VGAController DISPLAY(
        .clock(clock),
        .reset(reset),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .hSync(hSync),
        .vSync(vSync),
        .ecg_data(memDataOut), // ECG data from RAM
        .ecg_addr(vga_ecg_addr) // Address to read ECG data
    );


    // ============================== //
    // === Instruction ROM Module === //
    // ============================== //
    ROM #(.MEMFILE({INSTR_FILE, ".mem"})) InstMem (
        .clk(clock),
        .addr(instAddr[11:0]),
        .dataOut(instData)
    );

    // ============================ //
    // === Register File Module === //
    // ============================ //
    regfile RegisterFile (
        .clock(clock),
        .ctrl_writeEnable(rwe), .ctrl_reset(reset),
        .ctrl_writeReg(rd),
        .ctrl_readRegA(rs1), .ctrl_readRegB(rs2),
        .data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
        .LED(LED)
    );

    // ====================== //
    // === Data RAM Block === //
    // ====================== //
    RAM ProcMem (
        .clk(clock),
        .wEn(mwe),
        .addr(memAddr[11:0]),
        .dataIn(memDataIn),
        .dataOut(memDataOut),

        // ADC Write-Only Port
        .adc_wEn(sample_enable),
        .adc_addr(adc_addr_mux),
        .adc_dataIn(adc_data_mux),

        // VGA Read-Only Port
        .vga_addr(vga_ecg_addr),
        .vga_dataOut(vga_ecg_data)
    );

endmodule