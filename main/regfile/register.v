module register (q, d, clk, en, clr);
    input [31:0] d;
    input clk, en, clr;
    output [31:0] q;

    // Instantiate 32 DFFEs
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : REG
            dffe_ref dff (.q(q[i]), .d(d[i]), .clk(clk), .en(en), .clr(clr));
        end
    endgenerate

endmodule