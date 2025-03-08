module exception(
    opcode,
    aluop,
    alu_ovf,
    multidiv_exception,
    exception
);

input [4:0] opcode, aluop;
input alu_ovf, multidiv_exception;
output [31:0] exception;

wire is_alu_exception;
assign is_alu_exception = ((opcode == 5'b00000) || (opcode == 5'b00101)) && alu_ovf;

wire [31:0] alu_exception;
assign alu_exception = is_alu_exception ? 
                       (opcode == 5'b00101 ? 32'd2 :     // ADDI overflow
                       (aluop == 5'b00000 ? 32'd1 :      // ADD overflow
                       (aluop == 5'b00001 ? 32'd3 :      // SUB overflow
                       32'd0)))                          // Default case
                       : 32'd0;

// TODO: implement multiplication and division exceptions
assign exception = alu_exception;

endmodule