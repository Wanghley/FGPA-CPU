module RAM #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 12,
    parameter DEPTH = 4096
)(
    input wire clk,

    // Port A - CPU
    input wire wEn,
    input wire [ADDRESS_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] dataIn,
    output reg [DATA_WIDTH-1:0] dataOut,

    // Port B - ADC
    input wire adc_wEn,
    input wire [ADDRESS_WIDTH-1:0] adc_addr,
    input wire [DATA_WIDTH-1:0] adc_dataIn
);

// Shared memory
reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

// Port A - CPU
always @(posedge clk) begin
    if (wEn)
        memory[addr] <= dataIn;
    dataOut <= memory[addr];
end

// Port B - ADC
always @(posedge clk) begin
    if (adc_wEn)
        memory[adc_addr] <= adc_dataIn;
end

endmodule