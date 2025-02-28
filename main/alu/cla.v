/**
* CARRY LOOKAHEAD ADDER
*/

module cla(S,cout,ovf,x,y);
    input [31:0] x;
    input [31:0] y;
    output [31:0] S;
    output cout,ovf;

    wire c0, c8, c16, c24, c32;

    assign c0 = 1'b0;

    //bits 7-0
    wire G0,P0, P0c0;
    block bits70(.S(S[7:0]),.P(P0),.G(G0),.x(x[7:0]),.y(y[7:0]),.cin(c0));
    and P0c0_inst(P0c0,P0,c0);
    or c8_inst(c8,G0,P0c0);

    //bits 15-8
    wire G1,P1, P1G0,P1P0C0;
    block bits158(.S(S[15:8]),.P(P1),.G(G1),.x(x[15:8]),.y(y[15:8]),.cin(c8));
    and P1G0_inst(P1G0,P1,G0);
    and P1P0C0_inst(P1P0C0,P1,P0,c0);
    or c16_inst(c16,G1,P1G0,P1P0C0);

    //bits 23-16
    wire G2,P2, P2G1,P2P1G0,P2P1P0C0;
    block bits2316(.S(S[23:16]),.P(P2),.G(G2),.x(x[23:16]),.y(y[23:16]),.cin(c16));
    and P2G1_inst(P2G1,P2,G1);
    and P2P1G0_inst(P2P1G0,P2,P1,G0);
    and P2P1P0C0_inst(P2P1P0C0,P2,P1,P0,c0);
    or c24_inst(c24,G2,P2G1,P2P1G0,P2P1P0C0);

    //bits 31-24
    wire G3,P3, P3G2,P3P2G1,P3P2P1G0,P3P2P1P0C0;
    block bits3124(.S(S[31:24]),.P(P3),.G(G3),.x(x[31:24]),.y(y[31:24]),.cin(c24));
    and P3G2_inst(P3G2,P3,G2);
    and P3P2G1_inst(P3P2G1,P3,P2,G1);
    and P3P2P1G0_inst(P3P2P1G0,P3,P2,P1,G0);
    and P3P2P1P0C0_inst(P3P2P1P0C0,P3,P2,P1,P0,c0);
    or c32_inst(c32,G3,P3G2,P3P2G1,P3P2P1G0,P3P2P1P0C0);

    wire ovfaux, ovfaux2;
    xnor ovfaux_inst(ovfaux, x[31], y[31]);      // This part is correct - checks if signs are same
    xor ovfaux2_inst(ovfaux2, x[31], S[31]);     // This part is correct - checks if result sign differs
    and overflow_inst(ovf, ovfaux, ovfaux2);     // This part is correct - both conditions must be true
    assign cout = c32;

endmodule


// 8 bit block
module block(S,G,P,cin,x,y);
    input cin;
    input [7:0] x;
    input [7:0] y;

    output [7:0] S;
    output P,G;

    wire [7:0] c;
    wire [7:0] g;
    wire [7:0] p;


    // calculate g terms (gi = Xi*Yi)
    and g0_inst(g[0],x[0],y[0]);
    and g1_inst(g[1],x[1],y[1]);
    and g2_inst(g[2],x[2],y[2]);
    and g3_inst(g[3],x[3],y[3]);
    and g4_inst(g[4],x[4],y[4]);
    and g5_inst(g[5],x[5],y[5]);
    and g6_inst(g[6],x[6],y[6]);
    and g7_inst(g[7],x[7],y[7]);

    // calculate p terms (pi = Xi+Yi)
    or p0_inst(p[0],x[0],y[0]);
    or p1_inst(p[1],x[1],y[1]);
    or p2_inst(p[2],x[2],y[2]);
    or p3_inst(p[3],x[3],y[3]);
    or p4_inst(p[4],x[4],y[4]);
    or p5_inst(p[5],x[5],y[5]);
    or p6_inst(p[6],x[6],y[6]);
    or p7_inst(p[7],x[7],y[7]);

    // calculate P term
    and P_inst(P,p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7]);

    // calculate G term
    wire p7g6,p7p6g5,p7p6p5g4,p7p6p5p4g3,p7p6p5p4p3g2,p7p6p5p4p3p2g1,p7p6p5p4p3p2p1g0;
    and p7g6_inst(p7g6,p[7],g[6]);
    and p7p6g5_inst(p7p6g5,p[7],p[6],g[5]);
    and p7p6p5g4_inst(p7p6p5g4,p[7],p[6],p[5],g[4]);
    and p7p6p5p4g3_inst(p7p6p5p4g3,p[7],p[6],p[5],p[4],g[3]);
    and p7p6p5p4p3g2_inst(p7p6p5p4p3g2,p[7],p[6],p[5],p[4],p[3],g[2]);
    and p7p6p5p4p3p2g1_inst(p7p6p5p4p3p2g1,p[7],p[6],p[5],p[4],p[3],p[2],g[1]);
    and p7p6p5p4p3p2p1g0_inst(p7p6p5p4p3p2p1g0,p[7],p[6],p[5],p[4],p[3],p[2],p[1],g[0]);
    or G_inst(G,g[7],p7p6p5p4p3p2p1g0,p7p6p5p4p3p2g1,p7p6p5p4p3g2,p7p6p5p4g3,p7p6p5g4,p7p6g5,p7g6);

    //calculate internal carries
    assign c[0] = cin;
    wire c1,c2,c3,c4,c5,c6,c7,c8;
    and c1_inst(c1,p[0],c[0]);
    or c1_out(c[1],g[0],c1);
    
    and c2_inst(c2,p[1],c[1]);
    or c2_out(c[2],g[1],c2);
    
    and c3_inst(c3,p[2],c[2]);
    or c3_out(c[3],g[2],c3);
    
    and c4_inst(c4,p[3],c[3]);
    or c4_out(c[4],g[3],c4);
    
    and c5_inst(c5,p[4],c[4]);
    or c5_out(c[5],g[4],c5);
    
    and c6_inst(c6,p[5],c[5]);
    or c6_out(c[6],g[5],c6);
    
    and c7_inst(c7,p[6],c[6]);
    or c7_out(c[7],g[6],c7);

    // Calculate sums
    fulladder bit0(.sum(S[0]),.x(x[0]),.y(y[0]),.cin(c[0]));
    fulladder bit1(.sum(S[1]),.x(x[1]),.y(y[1]),.cin(c[1]));
    fulladder bit2(.sum(S[2]),.x(x[2]),.y(y[2]),.cin(c[2]));
    fulladder bit3(.sum(S[3]),.x(x[3]),.y(y[3]),.cin(c[3]));
    fulladder bit4(.sum(S[4]),.x(x[4]),.y(y[4]),.cin(c[4]));
    fulladder bit5(.sum(S[5]),.x(x[5]),.y(y[5]),.cin(c[5]));
    fulladder bit6(.sum(S[6]),.x(x[6]),.y(y[6]),.cin(c[6]));
    fulladder bit7(.sum(S[7]),.x(x[7]),.y(y[7]),.cin(c[7]));
endmodule



module fulladder(x,y,cin,sum);
    input x,y,cin;
    output sum;

    xor SUM(sum,x,y,cin);
endmodule