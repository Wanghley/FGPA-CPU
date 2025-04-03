module stall(ctrl_dx, ir_dx, ir_fd, stall);
    input [31:0] ctrl_dx, ir_dx, ir_fd;
    output stall;
    wire [4:0] opcode_dx, opcode_fd, rt_dx, rt_fd, rs_fd;
    instrdecoder decoder_dx (
        .instruction(ir_dx),
        .opcode(opcode_dx),
        .rt(rt_dx)
    );
    instrdecoder decoder_fd (
        .instruction(ir_fd),
        .opcode(opcode_fd),
        .rt(rt_fd),
        .rs(rs_fd)
    );

    // DEBUG WIRES - REMOVE IN FINAL VERSION
    wire [4:0] rd_dx;
    assign rd_dx = ctrl_dx[31:27];

    // Don't stall for BLT following a load instruction
    assign stall = (opcode_dx == 5'b01000) && 
               ((rs_fd == ctrl_dx[31:27]) ||
                (rt_fd == ctrl_dx[31:27])) && 
               (opcode_fd != 5'b00110);    // Don't stall for BLT only
endmodule