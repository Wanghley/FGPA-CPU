module control(
    opcode,
    aluop,
    aluop_in,
    aluInB, // decide if B is immediate or register
    RWE, // register write enable
);

input [4:0] opcode, aluop_in;
output [4:0] aluop;
output aluInB, RWE;

assign aluInB = (opcode == 5'b00101) ? 1'b1 : 1'b0;
assign aluop = (opcode == 5'b00000) ? aluop_in :
                (opcode == 5'b00101) ? 5'b00000 :
                5'b00000;

// write enable if r-type operation is detected
assign RWE = ((opcode == 5'b00000) || (opcode == 5'b00101) )? 1'b1 : 1'b0;
              
endmodule