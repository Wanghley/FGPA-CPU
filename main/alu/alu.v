module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
        
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    // add your code here:

    // calculations
    wire [31:0] addw,subw,andw,orw,sllw,sraw;
    wire cout_add, cout_sub;
    wire ovfadd,ovfsub;

    //addition
    cla addi(
        .S(addw),
        .cout(cout_add),
        .ovf(ovfadd),
        .x(data_operandA),
        .y(data_operandB)
    );

    //subtraction
    wire [31:0] subtractor;
    two_complement negativenum(
        .y(subtractor),
        .x(data_operandB)
    );
    cla subi(
        .S(subw),
        .cout(cout_sub),
        .ovf(ovfsub),
        .x(data_operandA),
        .y(subtractor)
    );


    // bitwise AND
    bitwiseand andbit(
        .out(andw),
        .x(data_operandA),
        .y(data_operandB)
    );

    //bitwise OR
    bitwiseor orbit(
        .out(orw),
        .x(data_operandA),
        .y(data_operandB)
    );

    // sll
    sll logicleftshift(
        .out(sllw), 
        .x(data_operandA), 
        .shamt(ctrl_shiftamt)
    );

    // sra
    sra arithrightshift(
        .out(sraw), 
        .x(data_operandA), 
        .shamt(ctrl_shiftamt)
    );


    mux_8_1 opcode(
        .out(data_result), 
        .select(ctrl_ALUopcode[2:0]), 
        .in0(addw),  // 0: add
        .in1(subw),  // 1: sub
        .in2(andw),  // 2: and
        .in3(orw),   // 3: or
        .in4(sllw),  // 4: sll
        .in5(sraw),  // 5: sra
        .in6(32'b0), // 6: zero
        .in7(32'b0)  // 7: zero
    );

    assign isNotEqual = (subw != 32'b0); // not equal if the subtraction is different from zero
    wire notsubwMSB;
    not nott(notsubwMSB,subw[31]);
    assign overflow = (ctrl_ALUopcode == 5'b00001) ? ovfsub : (ctrl_ALUopcode == 5'b00000) ? ovfadd : 1'b0;
    assign isLessThan = ovfsub? notsubwMSB: subw[31];

endmodule

module two_complement(y,x);
    input [31:0] x;
    output [31:0]y;

    // negate all bits
    wire [31:0] xnot;
    wire overflow,cout; 
    bitwisenot negate(
        .out(xnot),
        .x(x)
    );

    cla complement2(
        .S(y),
        .cout(cout),
        .ovf(overflow),
        .x(xnot),
        .y(32'b1)
    );
endmodule