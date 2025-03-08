
module multi_control(LSB, shift, add, sub, do_nothing);
    input [2:0] LSB;
    output shift, add, sub, do_nothing;

    wire addlog_1, addlog_2, addlog_3;
    assign addlog_1 = ~LSB[2] & ~LSB[1] & LSB[0]; // 001
    assign addlog_2 = ~LSB[2] & LSB[1] & ~LSB[0]; // 010
    assign addlog_3 = ~LSB[2] & LSB[1] & LSB[0]; // 011
    assign add = addlog_1 | addlog_2 | addlog_3;

    wire sublog_1, sublog_2, sublog_3;
    assign sublog_1 = LSB[2] & ~LSB[1] & ~LSB[0]; // 100
    assign sublog_2 = LSB[2] & ~LSB[1] & LSB[0]; // 101
    assign sublog_3 = LSB[2] & LSB[1] & ~LSB[0]; // 110
    assign sub = sublog_1 | sublog_2 | sublog_3;

    assign shift = (~LSB[2] & LSB[1] & LSB[0]) | (LSB[2] & ~LSB[1] & ~LSB[0]);

    assign do_nothing = ~add & ~sub & ~shift;
endmodule