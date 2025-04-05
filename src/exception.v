module exception(
    opcode,
    dx_opcode,
    alu_ovf,
    multidiv_exception,
    exception
);

input [4:0] opcode, dx_opcode;
input alu_ovf, multidiv_exception;
output [31:0] exception;

wire is_alu_exception;
assign is_alu_exception = ((opcode == 5'b00000) || (opcode == 5'b00101)) && (alu_ovf || multidiv_exception);

wire [31:0] alu_exception;
assign alu_exception = is_alu_exception ? 
                       (opcode == 5'b00101 ? 32'd2 :     // ADDI overflow
                       (dx_opcode == 5'b00000 ? 32'd1 :      // ADD overflow
                       (dx_opcode == 5'b00001 ? 32'd3 :      // SUB overflow
                       (dx_opcode == 5'b00110 ? 32'd4 :      // MUL overflow
                       (dx_opcode == 5'b00111 ? 32'd5 :      // DIV overflow
                          32'd0))))) : 32'd0;

// TODO: implement multiplication and division exceptions
assign exception = alu_exception;

endmodule