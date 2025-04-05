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
    // data input register
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    wire in_operation;
    wire operation_start;
    assign operation_start = ctrl_MULT | ctrl_DIV;

    dffe_ref operation_tracker(
        .d(1'b1),
        .q(in_operation),
        .clr(data_resultRDY),
        .clk(clock),
        .en(operation_start)
    );

    // Signal to determine when to update the operand registers
    wire load_operands;
    assign load_operands = operation_start & ~in_operation;
    
    // Registers to store the operands
    wire [31:0] stored_operandA, stored_operandB;

    register operandA_reg(
        .d(data_operandA),
        .q(stored_operandA),
        .clk(clock),
        .en(load_operands),
        .clr(1'b0)  // No need to clear the registers
    );
    register operandB_reg(
        .d(data_operandB),
        .q(stored_operandB),
        .clk(clock),
        .en(load_operands),
        .clr(1'b0)  // No need to clear the registers
    );

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Multiplier setup - Modified Booth's Algorithm
    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    wire [31:0] data_result_mult;
    wire data_exception_mult, data_resultRDY_mult;
    multiplier BOOTH_MULTIPLIER(
        .multiplicand(stored_operandA),
        .multiplier(stored_operandB),
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
        .dividend(stored_operandA),
        .divisor(stored_operandB),
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