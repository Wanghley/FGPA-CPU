module instrdecoder(
    instruction,
    opcode,
    rs,
    rt,
    rd,
    shamt,
    aluop,
    imm,
    target
);

input [31:0] instruction;
output [4:0] opcode, rs, rt, rd, shamt, aluop;
output [16:0] imm;
output [26:0] target;

assign opcode = instruction[31:27];
assign rd = instruction[26:22];
assign rs = instruction[21:17];
assign rt = instruction[16:12];
assign shamt = instruction[11:7];
assign aluop = instruction[6:2];
assign imm = instruction[16:0];
assign target = instruction[26:0];

endmodule