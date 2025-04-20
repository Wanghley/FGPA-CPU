`timescale 1ns / 1ps
module RAM #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 12,
    parameter DEPTH = 4096
)(
    input wire                      clk,

    // CPU Side (Port A)
    input wire                      wEn,
    input wire [ADDRESS_WIDTH-1:0]  addr,
    input wire [DATA_WIDTH-1:0]     dataIn,
    output reg [DATA_WIDTH-1:0]     dataOut = 0,

    // ADC Side - EMG (Port B1)
    input wire                      adc_wEn,
    input wire [ADDRESS_WIDTH-1:0]  adc_addr_emg,
    input wire [DATA_WIDTH-1:0]     adc_dataIn_emg,

    // ADC Side - ECG (Port B2)
    input wire [ADDRESS_WIDTH-1:0]  adc_addr_ecg,
    input wire [DATA_WIDTH-1:0]     adc_dataIn_ecg
);

reg [DATA_WIDTH-1:0] MemoryArray[0:DEPTH-1];

integer i;
initial begin
    for (i = 0; i < DEPTH; i = i + 1) begin
        MemoryArray[i] <= 0;
    end
end

// CPU Port (Read/Write)
always @(posedge clk) begin
    if (wEn) begin
        MemoryArray[addr] <= dataIn;
    end
    dataOut <= MemoryArray[addr];
end

// ADC Write Port - EMG
always @(posedge clk) begin
    if (adc_wEn) begin
        MemoryArray[adc_addr_emg] <= adc_dataIn_emg;
    end
end

// ADC Write Port - ECG
always @(posedge clk) begin
    if (adc_wEn) begin
        MemoryArray[adc_addr_ecg] <= adc_dataIn_ecg;
    end
end

endmodule