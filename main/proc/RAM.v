`timescale 1ns / 1ps
module RAM #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 12,
    parameter DEPTH = 4096
)(
    input wire                      clk,

    // CPU Side
    input wire                      wEn,
    input wire [ADDRESS_WIDTH-1:0]  addr,
    input wire [DATA_WIDTH-1:0]     dataIn,
    output reg [DATA_WIDTH-1:0]     dataOut = 0,

    // ADC Side
    input wire                      adc_wEn,
    input wire [ADDRESS_WIDTH-1:0]  adc_addr_emg,
    input wire [DATA_WIDTH-1:0]     adc_dataIn_emg,
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

always @(posedge clk) begin
    // Priority: CPU > EMG > ECG (or change as needed)
    if (wEn) begin
        MemoryArray[addr] <= dataIn;
    end else if (adc_wEn) begin
        MemoryArray[adc_addr_emg] <= adc_dataIn_emg;
        MemoryArray[adc_addr_ecg] <= adc_dataIn_ecg;
    end

    // Always read from CPU port
    dataOut <= MemoryArray[addr];
end

endmodule