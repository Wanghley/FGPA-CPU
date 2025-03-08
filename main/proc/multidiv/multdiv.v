module multdiv(
	data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Multiplier setup - Modified Booth's Algorithm
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    wire [31:0] data_result_mult;
    wire data_exception_mult, data_resultRDY_mult;
    multiplier BOOTH_MULTIPLIER(
        .multiplicand(data_operandA),
        .multiplier(data_operandB),
        .clk(clock),
        .rst(ctrl_MULT),
        .out(data_result_mult),
        .ready(data_resultRDY_mult),
        .exception(data_exception_mult)
    );

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Divider setup - Non-restoring Division
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wire [31:0] data_result_div;
    wire data_exception_div, data_resultRDY_div;
    divider NON_RESTORING_DIVIDER(
        .dividend(data_operandA),
        .divisor(data_operandB),
        .clk(clock),
        .rst(ctrl_DIV),
        .quotient(data_result_div),
        .ready(data_resultRDY_div),
        .exception(data_exception_div)
    ); 

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Multiplexer for selecting the result
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wire operation;
    dffe_ref dffop(
        .d(ctrl_DIV),
        .q(operation),
        .clr(ctrl_MULT),
        .clk(clock),
        .en(ctrl_DIV | ctrl_MULT)
    );

    assign data_result = operation? data_result_div:data_result_mult;
    assign data_exception = operation? data_exception_div:data_exception_mult;
    assign data_resultRDY = operation? data_resultRDY_div:data_resultRDY_mult;

endmodule