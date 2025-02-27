module mux_2_1(out, select, in0, in1);
    input select; // 0: in0, 1: in1
    input [31:0] in0, in1; // 32-bit input
    output [31:0] out; // 32-bit output
    assign out = select ? in1 : in0; // 32-bit mux
endmodule

module mux_4_1(out, select, in0, in1,in2,in3);
    input [1:0] select; // 2-bit select
    input [31:0] in0, in1, in2, in3; // 32-bit input
    output [31:0] out; // 32-bit output
    wire [31:0] mux1_out, mux2_out; // intermediate 32-bit output
    mux_2_1 mux1(mux1_out, select[0], in0, in1); // 1st 32-bit mux
    mux_2_1 mux2(mux2_out, select[0], in2, in3); // 2nd 32-bit mux
    mux_2_1 mux3(out, select[1], mux1_out, mux2_out); // 3rd 32-bit mux
endmodule

module mux_8_1(out, select, in0, in1, in2, in3, in4, in5, in6, in7);
    input [2:0] select; // 2-bit select
    input [31:0] in0, in1, in2, in3, in4, in5, in6, in7; // 32-bit input
    output [31:0] out; // 32-bit output
    wire [31:0] mux1_out, mux2_out; // intermediate 32-bit output
    mux_4_1 mux1(mux1_out, select[1:0], in0, in1, in2, in3); // 1st 32-bit mux
    mux_4_1 mux2(mux2_out, select[1:0], in4, in5, in6, in7); // 2nd 32-bit mux
    mux_2_1 mux3(out, select[2], mux1_out, mux2_out); // 3rd 32-bit mux
endmodule

module mux_8(out, select, in0, in1, in2, in3, in4, in5, in6, in7);
    input [2:0] select; // 2-bit select
    input in0, in1, in2, in3, in4, in5, in6, in7; // 32-bit input
    output out; // 32-bit output
    wire mux1_out, mux2_out; // intermediate 32-bit output
    mux_4 mux1(mux1_out, select[1:0], in0, in1, in2, in3); // 1st 32-bit mux
    mux_4 mux2(mux2_out, select[1:0], in4, in5, in6, in7); // 2nd 32-bit mux
    mux_2 mux3(out, select[2], mux1_out, mux2_out); // 3rd 32-bit mux
endmodule

module mux_4(out, select, in0, in1, in2, in3);
    input [1:0] select; // 2-bit select
    input  in0, in1, in2, in3; // 32-bit input
    output out; // 32-bit output
    wire mux1_out, mux2_out; // intermediate 32-bit output
    mux_2 mux1(mux1_out, select[0], in0, in1); // 1st 32-bit mux
    mux_2 mux2(mux2_out, select[0], in2, in3); // 2nd 32-bit mux
    mux_2 mux3(out, select[1], mux1_out, mux2_out); // 3rd 32-bit mux
endmodule

module mux_2(out, select, in0, in1);
    input select; // 0: in0, 1: in1
    input in0, in1; // 32-bit input
    output out; // 32-bit output
    assign out = select ? in1 : in0; // 32-bit mux
endmodule