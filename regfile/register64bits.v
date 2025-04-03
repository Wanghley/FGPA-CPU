module register_64 (q, d, clk, en, clr);
    input [63:0] d;
    input clk, en, clr;
    output [63:0] q;

    // Instantiate 64 DFFEs
    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin: REG_LOOP
            dffe_ref dff (.q(q[i]), .d(d[i]), .clk(clk), .en(en), .clr(clr));
        end
    endgenerate

endmodule