`timescale 1ns / 1ps
module RAM #( parameter DATA_WIDTH = 32, ADDRESS_WIDTH = 12, DEPTH = 4096) (
    input wire                     clk,

    // CPU Side (Port A - RW)
    input wire                     wEn,
    input wire [ADDRESS_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0]    dataIn,
    output reg [DATA_WIDTH-1:0]    dataOut = 0,

    // ADC Side (Port B - W)
    // Note: This port is write-only, no readback
    input wire                     adc_wEn,
    input wire [ADDRESS_WIDTH-1:0] adc_addr,
    input wire [DATA_WIDTH-1:0]    adc_dataIn,

    // VGA Side (Port C - R)
    // Note: This port is read-only, no writeback
    input wire [ADDRESS_WIDTH-1:0] vga_addr,
    output reg [DATA_WIDTH-1:0]    vga_dataOut = 0
);

reg [DATA_WIDTH-1:0] MemoryArray[0:DEPTH-1];

integer i;
initial begin
    for (i = 0; i < DEPTH; i = i + 1) begin
        MemoryArray[i] <= 0;
    end
end

// CPU Port (original naming)
always @(posedge clk) begin
    if(wEn) begin
        MemoryArray[addr] <= dataIn;
    end
    dataOut <= MemoryArray[addr];
end

// ADC Port (write-only)
always @(posedge clk) begin
    if(adc_wEn) begin
        MemoryArray[adc_addr] <= adc_dataIn;
    end
end

// VGA Port (read-only)
always @(posedge clk) begin
    vga_dataOut <= MemoryArray[vga_addr];
end

endmodule