/*
 * counter.v 
 * A 4-bit counter implemented using D flip-flops.
 * It counts from 15 to 0.
 *
*/

module counter (clk, rst, out);
    input clk, rst;
    output [4:0] out;
    wire [4:0] q;

    // Using T flip-flops with dffe
    dffe_ref dff0(.d(~q[0]), .q(q[0]), .clr(rst), .clk(clk), .en(1'b1));
    dffe_ref dff1(.d(q[1] ^ q[0]), .q(q[1]), .clr(rst), .clk(clk), .en(1'b1));
    dffe_ref dff2(.d(q[2] ^ (q[1] & q[0])), .q(q[2]), .clr(rst), .clk(clk), .en(1'b1));
    dffe_ref dff3(.d(q[3] ^ (q[2] & q[1] & q[0])), .q(q[3]), .clr(rst), .clk(clk), .en(1'b1));
    dffe_ref dff4(.d(q[4] ^ (q[3] & q[2] & q[1] & q[0])), .q(q[4]), .clr(rst), .clk(clk), .en(1'b1));

    assign out = q;

endmodule

// counter from 32 to 0 in 6 bits
module counter32 (clk, rst, out);
    input clk, rst;
    output [5:0] out;
    wire [5:0] q;

    // Using T flip-flops with dffe
    dffe_ref dff0(.d(~q[0]), .q(q[0]), .clr(rst), .clk(clk), .en(1'b1));
    dffe_ref dff1(.d(q[1] ^ q[0]), .q(q[1]), .clr(rst), .clk(clk), .en(1'b1));
    dffe_ref dff2(.d(q[2] ^ (q[1] & q[0])), .q(q[2]), .clr(rst), .clk(clk), .en(1'b1));
    dffe_ref dff3(.d(q[3] ^ (q[2] & q[1] & q[0])), .q(q[3]), .clr(rst), .clk(clk), .en(1'b1));
    dffe_ref dff4(.d(q[4] ^ (q[3] & q[2] & q[1] & q[0])), .q(q[4]), .clr(rst), .clk(clk), .en(1'b1));
    dffe_ref dff5(.d(q[5] ^ (q[4] & q[3] & q[2] & q[1] & q[0])), .q(q[5]), .clr(rst), .clk(clk), .en(1'b1));

    assign out = q;
endmodule