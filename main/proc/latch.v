module latch(PCin, Ain, Bin, IRin, clk, PCout, Aout, Bout, IRout, en, clr);
    input [31:0] PCin, Ain, Bin, IRin;
    input clk, en, clr;
    output [31:0] PCout, Aout, Bout, IRout;

    // Create inverted clock signal to latch data on falling edge
    wire invert_clk;
    assign invert_clk = ~clk;

    // Instantiate registers
    register PC(
        .q(PCout),
        .d(PCin),
        .clk(clk),
        .en(en),
        .clr(clr)
    );
    register A(
        .q(Aout),
        .d(Ain),
        .clk(clk),
        .en(en),
        .clr(clr)
    );
    register B(
        .q(Bout),
        .d(Bin),
        .clk(clk),
        .en(en),
        .clr(clr)
    );
    register IR(
        .q(IRout),
        .d(IRin),
        .clk(clk),
        .en(en),
        .clr(clr)
    );
endmodule
