module divider (
    dividend, divisor, quotient, remainder, clk, rst, exception, ready
);
    input [31:0] dividend;
    input [31:0] divisor;
    output [31:0] quotient;
    output [31:0] remainder;
    input clk;
    input rst;
    output exception;
    output ready;

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Counter for Non-restoring division
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wire [5:0] counter_out;
    counter32 counter(.clk(clk), .rst(rst), .out(counter_out));

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Register for Remainder and Quotient together
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wire [63:0] AQ, AQ_in;
    register_64 AQ_reg(
        .q(AQ), 
        .d(AQ_in), 
        .clk(clk), 
        .en(~rst), 
        .clr(rst)
    );

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Set initial values
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wire initial_cycle = ~counter_out[5] & ~counter_out[4] & ~counter_out[3] & ~counter_out[2] & ~counter_out[1] & ~counter_out[0];
    wire [63:0] initial_AQ = {32'd0, dividend_processed};
    
    // convert negative dividend and divisor to positive
    wire [31:0] dividend_positive;
    wire [31:0] divisor_positive;
    two_complement two_complement_dividend(.y(dividend_positive), .x(dividend));
    two_complement two_complement_divisor(.y(divisor_positive), .x(divisor));

    wire [31:0] dividend_processed, divisor_processed;
    assign dividend_processed = dividend[31]? dividend_positive : dividend;
    assign divisor_processed = divisor[31]? divisor_positive : divisor;

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Control for Non-restoring division
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wire add, sub;
    wire [63:0] AQ_shifted;
    assign AQ_shifted = {AQ[62:0], 1'b0};
    div_control_before_add control(
        .MSB(AQ[63]),
        .add(add),
        .sub(sub)
    );

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // ALU for Non-restoring division
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wire [31:0] ALU_out, AQ_final;
    alu ALU(
        .data_operandA(AQ_shifted[63:32]),
        .data_operandB(divisor_processed),
        .ctrl_ALUopcode(sub ? 5'd1 : 5'd0),
        .ctrl_shiftamt(5'b0),
        .data_result(ALU_out)
    );

    wire q0 = ~ALU_out[31];
    assign AQ_final = {AQ_shifted[31:1], q0};
    assign AQ_in = initial_cycle ? initial_AQ : {ALU_out, AQ_final[31:1], q0};

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Ready signal
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    assign ready = counter_out[5] & ~counter_out[4] & ~counter_out[3] & ~counter_out[2] & ~counter_out[1] & counter_out[0];

    // convert quotient to negative if dividend and divisor have different signs
    wire quotient_sign_fix;
    wire [31:0] quotient_complemented;
    two_complement two_complement_quotient(.y(quotient_complemented), .x(AQ[31:0]));
    assign quotient_sign_fix = dividend[31] ^ divisor[31];
    assign quotient = quotient_sign_fix? quotient_complemented : AQ[31:0];


    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Exception signal
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Division by zero exception
    wire div_by_zero;
    assign div_by_zero = ~divisor[31] & ~divisor[30] & ~divisor[29] & ~divisor[28] & ~divisor[27] & ~divisor[26] & ~divisor[25] & ~divisor[24] & ~divisor[23] & ~divisor[22] & ~divisor[21] & ~divisor[20] & ~divisor[19] & ~divisor[18] & ~divisor[17] & ~divisor[16] & ~divisor[15] & ~divisor[14] & ~divisor[13] & ~divisor[12] & ~divisor[11] & ~divisor[10] & ~divisor[9] & ~divisor[8] & ~divisor[7] & ~divisor[6] & ~divisor[5] & ~divisor[4] & ~divisor[3] & ~divisor[2] & ~divisor[1] & ~divisor[0];
    assign exception = div_by_zero;
endmodule