module control(
    opcode,
    aluop,
    aluop_in,
    aluInB, // decide if B is immediate or register
    RWE, // register write enable
    Dmem_WE, // data memory write enable
    mem_to_reg, // select if data from memory or ALU goes to register
    regfile_readB_rt_rd, // select if B is rt or rd to read from register file
    bne, // branch not equal signal
    blt, // branch less than signal
    br, // branch signal
    jp, // jump signal
    jal, // jump and link signal
    jr, // jump return signal
);

input [4:0] opcode, aluop_in;
output [4:0] aluop;
output aluInB, RWE, Dmem_WE, mem_to_reg, regfile_readB_rt_rd, bne, blt, jp, jal, jr, br;
assign aluInB = (opcode == 5'b00101 || opcode ==5'b00111 || opcode ==5'b01000) ? 1'b1 : 1'b0;
assign aluop = (opcode == 5'b00000) ? aluop_in :
                (opcode == 5'b00101) ? 5'b00000 :
                5'b00000;

assign Dmem_WE = (opcode == 5'b00111) ? 1'b1 : 1'b0;
assign mem_to_reg = (opcode == 5'b01000) ? 1'b1 : 1'b0;

// write enable if r-type operation is detected
assign RWE = ((opcode == 5'b00000) || (opcode == 5'b00101) || opcode ==5'b01000 || opcode ==5'b00011) ? 1'b1 : 1'b0;

// if opcode is 00111 or 01000, then read from rd, else read from rt
assign regfile_readB_rt_rd = (opcode == 5'b00111 || opcode == 5'b01000) ? 1'b1 : 1'b0;

// branches signaling
assign bne = (opcode == 5'b00010) ? 1'b1 : 1'b0;
assign blt = (opcode == 5'b00110) ? 1'b1 : 1'b0;
assign br = (opcode == 5'b00010 || opcode == 5'b00110) ? 1'b1 : 1'b0;

// jump signaling
assign jp = (opcode == 5'b00001) ? 1'b1 : 1'b0;
assign jal = (opcode == 5'b00011) ? 1'b1 : 1'b0;
assign jr = (opcode == 5'b00100) ? 1'b1 : 1'b0;
              
endmodule