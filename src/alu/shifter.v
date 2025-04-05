module sll(out, x, shamt);
    input [31:0] x;
    input [4:0] shamt; // Updated to 5 bits
    output [31:0] out;

    wire [31:0] sll16w, sll8w, sll4w, sll2w, sll1w;
    wire [31:0] int16, int8, int4, int2, int1;

    // Shift operations
    sll16 out16(sll16w, x);
    sll8 out8(sll8w, int16);
    sll4 out4(sll4w, int8);
    sll2 out2(sll2w, int4);
    sll1 out1(sll1w, int2);

    mux_2_1 muxsll16(
        .out(int16),
        .select(shamt[4]),
        .in0(x),
        .in1(sll16w)
    );

    mux_2_1 muxsll8(
        .out(int8),
        .select(shamt[3]),
        .in0(int16),
        .in1(sll8w)
    );

    mux_2_1 muxsll4(
        .out(int4),
        .select(shamt[2]),
        .in0(int8),
        .in1(sll4w)
    );

    mux_2_1 muxsll2(
        .out(int2),
        .select(shamt[1]),
        .in0(int4), 
        .in1(sll2w)
    );

    mux_2_1 muxsll1(
        .out(int1),
        .select(shamt[0]),
        .in0(int2), 
        .in1(sll1w)
    );

    assign out = (shamt == 5'b00000) ? x : int1;
endmodule



module sra(out, x, shamt);
    input [31:0] x;
    output [31:0] out;
    input [4:0] shamt; // 5-bit shift amount

    wire [31:0] sra16w, sra8w, sra4w, sra2w, sra1w;
    wire [31:0] int16, int8, int4, int2, int1; // Intermediate wires

    sra16 out16(sra16w, x);

    mux_2_1 muxsra16(
        .out(int16),
        .select(shamt[4]),
        .in0(x),
        .in1(sra16w)
    );

    sra8 out8(sra8w, int16);

    mux_2_1 muxsra8(
        .out(int8),
        .select(shamt[3]),
        .in0(int16),
        .in1(sra8w)
    );

    sra4 out4(sra4w, int8);

    mux_2_1 muxsra4(
        .out(int4),
        .select(shamt[2]),
        .in0(int8),
        .in1(sra4w)
    );

    sra2 out2(sra2w, int4);

    mux_2_1 muxsra2(
        .out(int2),
        .select(shamt[1]),
        .in0(int4),
        .in1(sra2w)
    );

    sra1 out1(sra1w, int2);

    mux_2_1 muxsra1(
        .out(int1),
        .select(shamt[0]),
        .in0(int2),
        .in1(sra1w)
    );

    assign out = int1;
    
endmodule


module sll1(out,x);
    input [31:0] x;
    output [31:0] out;

    assign out[0] = 1'b0;
    assign out[1] = x[0];
    assign out[2] = x[1];
    assign out[3] = x[2];
    assign out[4] = x[3];
    assign out[5] = x[4];
    assign out[6] = x[5];
    assign out[7] = x[6];
    assign out[8] = x[7];
    assign out[9] = x[8];
    assign out[10] = x[9];
    assign out[11] = x[10];
    assign out[12] = x[11];
    assign out[13] = x[12];
    assign out[14] = x[13];
    assign out[15] = x[14];
    assign out[16] = x[15];
    assign out[17] = x[16];
    assign out[18] = x[17];
    assign out[19] = x[18];
    assign out[20] = x[19];
    assign out[21] = x[20];
    assign out[22] = x[21];
    assign out[23] = x[22];
    assign out[24] = x[23];
    assign out[25] = x[24];
    assign out[26] = x[25];
    assign out[27] = x[26];
    assign out[28] = x[27];
    assign out[29] = x[28];
    assign out[30] = x[29];
    assign out[31] = x[30];
endmodule

module sll2(out, x);
    input [31:0] x;
    output [31:0] out;

    assign out[0] = 1'b0;
    assign out[1] = 1'b0;
    assign out[2] = x[0];
    assign out[3] = x[1];
    assign out[4] = x[2];
    assign out[5] = x[3];
    assign out[6] = x[4];
    assign out[7] = x[5];
    assign out[8] = x[6];
    assign out[9] = x[7];
    assign out[10] = x[8];
    assign out[11] = x[9];
    assign out[12] = x[10];
    assign out[13] = x[11];
    assign out[14] = x[12];
    assign out[15] = x[13];
    assign out[16] = x[14];
    assign out[17] = x[15];
    assign out[18] = x[16];
    assign out[19] = x[17];
    assign out[20] = x[18];
    assign out[21] = x[19];
    assign out[22] = x[20];
    assign out[23] = x[21];
    assign out[24] = x[22];
    assign out[25] = x[23];
    assign out[26] = x[24];
    assign out[27] = x[25];
    assign out[28] = x[26];
    assign out[29] = x[27];
    assign out[30] = x[28];
    assign out[31] = x[29];
endmodule

module sll4(out, x);
    input [31:0] x;
    output [31:0] out;

    assign out[0] = 1'b0;
    assign out[1] = 1'b0;
    assign out[2] = 1'b0;
    assign out[3] = 1'b0;
    assign out[4] = x[0];
    assign out[5] = x[1];
    assign out[6] = x[2];
    assign out[7] = x[3];
    assign out[8] = x[4];
    assign out[9] = x[5];
    assign out[10] = x[6];
    assign out[11] = x[7];
    assign out[12] = x[8];
    assign out[13] = x[9];
    assign out[14] = x[10];
    assign out[15] = x[11];
    assign out[16] = x[12];
    assign out[17] = x[13];
    assign out[18] = x[14];
    assign out[19] = x[15];
    assign out[20] = x[16];
    assign out[21] = x[17];
    assign out[22] = x[18];
    assign out[23] = x[19];
    assign out[24] = x[20];
    assign out[25] = x[21];
    assign out[26] = x[22];
    assign out[27] = x[23];
    assign out[28] = x[24];
    assign out[29] = x[25];
    assign out[30] = x[26];
    assign out[31] = x[27];
endmodule

module sll8(out, x);
    input [31:0] x;
    output [31:0] out;

    assign out[0] = 1'b0;
    assign out[1] = 1'b0;
    assign out[2] = 1'b0;
    assign out[3] = 1'b0;
    assign out[4] = 1'b0;
    assign out[5] = 1'b0;
    assign out[6] = 1'b0;
    assign out[7] = 1'b0;
    assign out[8] = x[0];
    assign out[9] = x[1];
    assign out[10] = x[2];
    assign out[11] = x[3];
    assign out[12] = x[4];
    assign out[13] = x[5];
    assign out[14] = x[6];
    assign out[15] = x[7];
    assign out[16] = x[8];
    assign out[17] = x[9];
    assign out[18] = x[10];
    assign out[19] = x[11];
    assign out[20] = x[12];
    assign out[21] = x[13];
    assign out[22] = x[14];
    assign out[23] = x[15];
    assign out[24] = x[16];
    assign out[25] = x[17];
    assign out[26] = x[18];
    assign out[27] = x[19];
    assign out[28] = x[20];
    assign out[29] = x[21];
    assign out[30] = x[22];
    assign out[31] = x[23];
endmodule

module sll16(out, x);
    input [31:0] x;
    output [31:0] out;

    assign out[0] = 1'b0;
    assign out[1] = 1'b0;
    assign out[2] = 1'b0;
    assign out[3] = 1'b0;
    assign out[4] = 1'b0;
    assign out[5] = 1'b0;
    assign out[6] = 1'b0;
    assign out[7] = 1'b0;
    assign out[8] = 1'b0;
    assign out[9] = 1'b0;
    assign out[10] = 1'b0;
    assign out[11] = 1'b0;
    assign out[12] = 1'b0;
    assign out[13] = 1'b0;
    assign out[14] = 1'b0;
    assign out[15] = 1'b0;
    assign out[16] = x[0];
    assign out[17] = x[1];
    assign out[18] = x[2];
    assign out[19] = x[3];
    assign out[20] = x[4];
    assign out[21] = x[5];
    assign out[22] = x[6];
    assign out[23] = x[7];
    assign out[24] = x[8];
    assign out[25] = x[9];
    assign out[26] = x[10];
    assign out[27] = x[11];
    assign out[28] = x[12];
    assign out[29] = x[13];
    assign out[30] = x[14];
    assign out[31] = x[15];
endmodule


module sra1(out,x);
    input [31:0] x;
    output[31:0] out;

    assign out[0] = x[1];
    assign out[1] = x[2];
    assign out[2] = x[3];
    assign out[3] = x[4];
    assign out[4] = x[5];
    assign out[5] = x[6];
    assign out[6] = x[7];
    assign out[7] = x[8];
    assign out[8] = x[9];
    assign out[9] = x[10];
    assign out[10] = x[11];
    assign out[11] = x[12];
    assign out[12] = x[13];
    assign out[13] = x[14];
    assign out[14] = x[15];
    assign out[15] = x[16];
    assign out[16] = x[17];
    assign out[17] = x[18];
    assign out[18] = x[19];
    assign out[19] = x[20];
    assign out[20] = x[21];
    assign out[21] = x[22];
    assign out[22] = x[23];
    assign out[23] = x[24];
    assign out[24] = x[25];
    assign out[25] = x[26];
    assign out[26] = x[27];
    assign out[27] = x[28];
    assign out[28] = x[29];
    assign out[29] = x[30];
    assign out[30] = x[31];
    assign out[31] = x[31];
endmodule

module sra2(out, x);
    input [31:0] x;
    output [31:0] out;

    assign out[0] = x[2];
    assign out[1] = x[3];
    assign out[2] = x[4];
    assign out[3] = x[5];
    assign out[4] = x[6];
    assign out[5] = x[7];
    assign out[6] = x[8];
    assign out[7] = x[9];
    assign out[8] = x[10];
    assign out[9] = x[11];
    assign out[10] = x[12];
    assign out[11] = x[13];
    assign out[12] = x[14];
    assign out[13] = x[15];
    assign out[14] = x[16];
    assign out[15] = x[17];
    assign out[16] = x[18];
    assign out[17] = x[19];
    assign out[18] = x[20];
    assign out[19] = x[21];
    assign out[20] = x[22];
    assign out[21] = x[23];
    assign out[22] = x[24];
    assign out[23] = x[25];
    assign out[24] = x[26];
    assign out[25] = x[27];
    assign out[26] = x[28];
    assign out[27] = x[29];
    assign out[28] = x[30];
    assign out[29] = x[31];
    assign out[30] = x[31];
    assign out[31] = x[31];
endmodule

module sra4(out, x);
    input [31:0] x;
    output [31:0] out;

    assign out[0] = x[4];
    assign out[1] = x[5];
    assign out[2] = x[6];
    assign out[3] = x[7];
    assign out[4] = x[8];
    assign out[5] = x[9];
    assign out[6] = x[10];
    assign out[7] = x[11];
    assign out[8] = x[12];
    assign out[9] = x[13];
    assign out[10] = x[14];
    assign out[11] = x[15];
    assign out[12] = x[16];
    assign out[13] = x[17];
    assign out[14] = x[18];
    assign out[15] = x[19];
    assign out[16] = x[20];
    assign out[17] = x[21];
    assign out[18] = x[22];
    assign out[19] = x[23];
    assign out[20] = x[24];
    assign out[21] = x[25];
    assign out[22] = x[26];
    assign out[23] = x[27];
    assign out[24] = x[28];
    assign out[25] = x[29];
    assign out[26] = x[30];
    assign out[27] = x[31];
    assign out[28] = x[31];
    assign out[29] = x[31];
    assign out[30] = x[31];
    assign out[31] = x[31];
endmodule

module sra8(out, x);
    input [31:0] x;
    output [31:0] out;

    assign out[0] = x[8];
    assign out[1] = x[9];
    assign out[2] = x[10];
    assign out[3] = x[11];
    assign out[4] = x[12];
    assign out[5] = x[13];
    assign out[6] = x[14];
    assign out[7] = x[15];
    assign out[8] = x[16];
    assign out[9] = x[17];
    assign out[10] = x[18];
    assign out[11] = x[19];
    assign out[12] = x[20];
    assign out[13] = x[21];
    assign out[14] = x[22];
    assign out[15] = x[23];
    assign out[16] = x[24];
    assign out[17] = x[25];
    assign out[18] = x[26];
    assign out[19] = x[27];
    assign out[20] = x[28];
    assign out[21] = x[29];
    assign out[22] = x[30];
    assign out[23] = x[31];
    assign out[24] = x[31];
    assign out[25] = x[31];
    assign out[26] = x[31];
    assign out[27] = x[31];
    assign out[28] = x[31];
    assign out[29] = x[31];
    assign out[30] = x[31];
    assign out[31] = x[31];
endmodule

module sra16(out, x);
    input [31:0] x;
    output [31:0] out;

    assign out[0]  = x[16];
    assign out[1]  = x[17];
    assign out[2]  = x[18];
    assign out[3]  = x[19];
    assign out[4]  = x[20];
    assign out[5]  = x[21];
    assign out[6]  = x[22];
    assign out[7]  = x[23];
    assign out[8]  = x[24];
    assign out[9]  = x[25];
    assign out[10] = x[26];
    assign out[11] = x[27];
    assign out[12] = x[28];
    assign out[13] = x[29];
    assign out[14] = x[30];
    assign out[15] = x[31];
    assign out[16] = x[31];
    assign out[17] = x[31];
    assign out[18] = x[31];
    assign out[19] = x[31];
    assign out[20] = x[31];
    assign out[21] = x[31];
    assign out[22] = x[31];
    assign out[23] = x[31];
    assign out[24] = x[31];
    assign out[25] = x[31];
    assign out[26] = x[31];
    assign out[27] = x[31];
    assign out[28] = x[31];
    assign out[29] = x[31];
    assign out[30] = x[31];
    assign out[31] = x[31];

endmodule
