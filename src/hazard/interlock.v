module interlock(
    stall, // output wire stall
    DIR, // decode stage instruction
    EIR, // execute stage instruction
);

    input [5:0] DIR, EIR;
    output stall;

    // stall if the decode stage instruction is a load instruction and the execute stage instruction is a store instruction
    wire [4:0] decode_rs1, decode_rs2, execute_rd, DOP, EOP;
    assign DOP = DIR[31:27];
    assign EOP = EIR[31:27];
    assign decode_rs1 = DIR[21:17];
    assign decode_rs2 = DOP == 5'b00010 || DOP == 5'b00100 ? DIR[26:22] : DIR[16:12];
    assign execute_rd = EIR[26:22];

    assign stall = (EOP == 5'b01000 && (decode_rs1 == execute_rd || ((decode_rs2 == execute_rd) && DOP != 5'b00111))) || // lw and sw stall
                     ((DOP == 5'b00100 && EOP == 5'b01000)&& (decode_rs1 == execute_rd)) ||
                     ((DOP == 5'b00111 && EOP == 5'b00111) && (decode_rs1 == execute_rd));


endmodule