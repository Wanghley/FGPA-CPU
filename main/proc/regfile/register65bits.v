module register_65 (q, d, clk, en, clr);
    input [64:0] d;
    input clk, en, clr;
    output [64:0] q;

    // Instantiate 64 DFFEs
    genvar i;
    generate
        for (i = 0; i < 65; i = i + 1) begin: REG_LOOP
            dffe_ref dff (.q(q[i]), .d(d[i]), .clk(clk), .en(en), .clr(clr));
        end
    endgenerate

endmodule