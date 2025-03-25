module stall(ctrl_dx, ir_dx, ctrl_fd, ir_fd, stall);
    input [31:0] ctrl_dx, ir_dx, ctrl_fd, ir_fd;
    output stall;
    wire [4:0] opcode_dx, opcode_fd, rt_dx, rt_fd;
    instrdecoder decoder_dx (
        .instruction(ir_dx),
        .opcode(opcode_dx),
        .rt(rt_dx)
    );
    instrdecoder decoder_fd (
        .instruction(ir_fd),
        .opcode(opcode_fd),
        .rt(rt_fd)
    );
    assign stall = (opcode_dx==5'b01000) && 
                    ((ctrl_fd[5:1] == ctrl_dx[31:27]) ||
                    (rt_fd == ctrl_dx[31:27]) && (opcode_fd!=5'b00111));
endmodule