module latch(data_out, data_in, clk, en, clr);
    input [31:0] data_in;
    input clk, en, clr;
    output [31:0] data_out;

    // Instantiate register to capture data on falling edge
    register reg_inst(
        .q(data_out),
        .d(data_in),
        .clk(~clk), // Use inverted clock for falling edge behavior
        .en(en),
        .clr(clr)
    );
endmodule
