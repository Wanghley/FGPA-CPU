`timescale 1ns / 1ps

/**
 * Wrapper module for integrating processor, register file, memory,
 * and XADC sampling of EMG and ECG signals.
 *
 * IMPORTANT: Set your instruction memory file name below at line ~40
 */

module Wrapper (
    input clock,
    input reset,
    input vauxn3, vauxp3,         // EMG input (VAUX3)
    input vauxn11, vauxp11,       // ECG input (VAUX11)
    output [15:0] LED
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
    processor CPU (
        .clock(clock), .reset(reset),
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
    localparam SAMPLE_INTERVAL = 18'd175000;  // 5ms @ 35MHz = 200Hz
    reg [17:0] sample_counter = 0;
    reg sample_enable = 0;
    reg channel_select = 0;  // 0 = EMG, 1 = ECG
    reg [9:0] sample_number = 0;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            sample_counter <= 0;
            sample_enable <= 0;
            sample_number <= 0;
        end else if (sample_counter == SAMPLE_INTERVAL - 1) begin
            sample_counter <= 0;
            sample_enable <= 1;
            sample_number <= sample_number + 1;
            if (sample_number == 10'd800) begin
                sample_number <= 0; // Wrap around
            end
        end else begin
            sample_counter <= sample_counter + 1;
            sample_enable <= 0;
        end
    end


    // ADC Data Routing Logic
    reg [31:0] adc_data_mux;
    reg [11:0] adc_addr_mux;
    always @(*) begin
        if (channel_select == 0) begin
            adc_data_mux = emg_out;
            adc_addr_mux = EMG_ADDR_BASE + sample_number;
        end else begin
            adc_data_mux = ecg_out;
            adc_addr_mux = ECG_ADDR_BASE + sample_number;
        end
    end

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

            // ADC Write Ports for EMG and ECG
            .adc_wEn(sample_enable),
            .adc_addr_emg(emg_addr),
            .adc_dataIn_emg(emg_out),
            .adc_addr_ecg(ecg_addr),
            .adc_dataIn_ecg(ecg_out)
        );


endmodule