`timescale 1ns / 1ps

module RAM #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 12,
    parameter DEPTH = 4096
)(
    input wire clk,

    // Port A - CPU (read/write)
    input wire                  wEnA,
    input wire [ADDRESS_WIDTH-1:0] addrA,
    input wire [DATA_WIDTH-1:0] dataInA,
    output reg [DATA_WIDTH-1:0] dataOutA,

    // Port B - ADC or VGA (read/write)
    input wire                  wEnB,
    input wire [ADDRESS_WIDTH-1:0] addrB,
    input wire [DATA_WIDTH-1:0] dataInB,
    output reg [DATA_WIDTH-1:0] dataOutB
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] MemoryArray [0:DEPTH-1];

    // Port A logic
    always @(posedge clk) begin
        if (wEnA)
            MemoryArray[addrA] <= dataInA;
        dataOutA <= MemoryArray[addrA];
    end

    // Port B logic
    always @(posedge clk) begin
        if (wEnB)
            MemoryArray[addrB] <= dataInB;
        dataOutB <= MemoryArray[addrB];
    end

endmodule
