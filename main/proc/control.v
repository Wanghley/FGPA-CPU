module control(
    opcode,
    aluop,
    aluop_in,
    aluInB, // decide if B is immediate or register
    RWE, // register write enable
    Dmem_WE, // data memory write enable
    mem_to_reg // select if data from memory or ALU goes to register
);

input [4:0] opcode, aluop_in;
output [4:0] aluop;
output aluInB, RWE, Dmem_WE, mem_to_reg;
assign aluInB = (opcode == 5'b00101) ? 1'b1 : 1'b0;
assign aluop = (opcode == 5'b00000) ? aluop_in :
                (opcode == 5'b00101) ? 5'b00000 :
                5'b00000;

assign Dmem_WE = (opcode == 5'b00111) ? 1'b1 : 1'b0;
assign mem_to_reg = (opcode == 5'b01000) ? 1'b1 : 1'b0;

// write enable if r-type operation is detected
assign RWE = ((opcode == 5'b00000) || (opcode == 5'b00101) )? 1'b1 : 1'b0;

              
endmodule