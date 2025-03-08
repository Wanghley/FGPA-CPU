
/*
* 32 bit multiplier using modified booth algorithm
* param multiplicand: 32 bit input
* param multiplier: 32 bit input
* param clk: clock signal
* param rst: reset signal
* return out: 32 bit output
* return ready: ready signal
* return overflow: overflow signal
* return exception: exception signal
*/

module multiplier(multiplicand, multiplier, clk, rst, out, ready, exception);
    input [31:0] multiplicand, multiplier;
    input clk, rst;
    output [31:0] out;
    output ready, exception;

    wire [31:0] booth_upper, booth_lower;

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Counter for the booth algorithm
    wire [4:0] cycle_count;
    counter COUNTER(
        .clk(clk),
        .rst(rst),
        .out(cycle_count)
    );

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // define 65 bit register for the product
    wire [64:0] product_reg, product_reg_in;
    register_65 PRODUCT_REG(
        .q(product_reg),
        .d(product_reg_in),
        .clk(clk),
        .en(~rst),
        .clr(rst)
    );

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // set initial values for the register
    wire initial_cycle = ~cycle_count[4] & ~cycle_count[3] & ~cycle_count[2] & ~cycle_count[1] & ~cycle_count[0];
    wire [64:0] product_in_reg;
    assign product_in_reg = {32'b0, multiplier,1'b0};
    assign product_reg_in = initial_cycle ? product_in_reg : shifted_product;

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // control signals for the booth algorithm
    wire add_signal, sub_signal, shift_signal, do_nothing_signal;
    multi_control BOOTH_CONTROL(
        .LSB(product_reg[2:0]),
        .shift(shift_signal),
        .add(add_signal),
        .sub(sub_signal),
        .do_nothing(do_nothing_signal)
    );

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // define shifted multiplicand
    wire [31:0] multiplicand_shifted, op_multiplicand;
    assign multiplicand_shifted = multiplicand << 1;
    assign op_multiplicand = shift_signal ? multiplicand_shifted : multiplicand;

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // ALU for the booth algorithm
    wire [31:0] alu_out;
    alu ALU(
        .data_operandA(add_signal | sub_signal ? product_reg[64:33] : 32'b0),
        .data_operandB(add_signal | sub_signal ? op_multiplicand : 32'b0),
        .ctrl_ALUopcode(add_signal ? 5'b00000 : (sub_signal ? 5'b00001 : 5'b0)),
        .ctrl_shiftamt(5'b0),
        .data_result(alu_out),
        .isNotEqual(),
        .isLessThan(),
        .overflow()
    );

    wire [64:0] unshifted_product, shifted_product;
    assign unshifted_product = do_nothing_signal ? product_reg : {alu_out, product_reg[32:0]};
    assign shifted_product = {unshifted_product[64], unshifted_product[64], unshifted_product[64:2]};
    // assign product_reg_in = shifted_product; // >>> 2 always before save to register

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // ready signal is asserted when all bits of cycle_count is 10001
    wire cycle_count_max;
    assign cycle_count_max = cycle_count[4] & ~cycle_count[3] & ~cycle_count[2] & ~cycle_count[1] & cycle_count[0];
    assign ready = cycle_count_max;

    assign out = product_reg[32:1];

    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // Exception signal when overflow or sign issues occur
    wire top_bits_0s, top_bits_1s, excp_top_bits;
    assign top_bits_0s = (product_reg[64] | product_reg[63] | product_reg[62] | product_reg[61] | product_reg[60] | product_reg[59] | product_reg[58] | product_reg[57] | product_reg[56] | product_reg[55] | product_reg[54] | product_reg[53] | product_reg[52] | product_reg[51] | product_reg[50] | product_reg[49] | product_reg[48] | product_reg[47] | product_reg[46] | product_reg[45] | product_reg[44] | product_reg[43] | product_reg[42] | product_reg[41] | product_reg[40] | product_reg[39] | product_reg[38] | product_reg[37] | product_reg[36] | product_reg[35] | product_reg[34] | product_reg[33]);
    assign top_bits_1s = (product_reg[64] & product_reg[63] & product_reg[62] & product_reg[61] & product_reg[60] & product_reg[59] & product_reg[58] & product_reg[57] & product_reg[56] & product_reg[55] & product_reg[54] & product_reg[53] & product_reg[52] & product_reg[51] & product_reg[50] & product_reg[49] & product_reg[48] & product_reg[47] & product_reg[46] & product_reg[45] & product_reg[44] & product_reg[43] & product_reg[42] & product_reg[41] & product_reg[40] & product_reg[39] & product_reg[38] & product_reg[37] & product_reg[36] & product_reg[35] & product_reg[34] & product_reg[33]);
    assign excp_top_bits = top_bits_0s & ~top_bits_1s;

    wire ovf_operands_out;
    assign ovf_operands_out = multiplicand[31] ^ multiplier[31] ^ out[31];

    wire excp_ovf;
    assign excp_ovf = (top_bits_0s & ~top_bits_1s) | ovf_operands_out;

    // check for inputs as zero
    wire excp_zero, is_multiplicand_zero, is_multiplier_zero;
    assign is_multiplicand_zero = ~(multiplicand[31] | multiplicand[30] | multiplicand[29] | multiplicand[28] | multiplicand[27] | multiplicand[26] | multiplicand[25] | multiplicand[24] | multiplicand[23] | multiplicand[22] | multiplicand[21] | multiplicand[20] | multiplicand[19] | multiplicand[18] | multiplicand[17] | multiplicand[16] | multiplicand[15] | multiplicand[14] | multiplicand[13] | multiplicand[12] | multiplicand[11] | multiplicand[10] | multiplicand[9] | multiplicand[8] | multiplicand[7] | multiplicand[6] | multiplicand[5] | multiplicand[4] | multiplicand[3] | multiplicand[2] | multiplicand[1] | multiplicand[0]);
    assign is_multiplier_zero = ~(multiplier[31] | multiplier[30] | multiplier[29] | multiplier[28] | multiplier[27] | multiplier[26] | multiplier[25] | multiplier[24] | multiplier[23] | multiplier[22] | multiplier[21] | multiplier[20] | multiplier[19] | multiplier[18] | multiplier[17] | multiplier[16] | multiplier[15] | multiplier[14] | multiplier[13] | multiplier[12] | multiplier[11] | multiplier[10] | multiplier[9] | multiplier[8] | multiplier[7] | multiplier[6] | multiplier[5] | multiplier[4] | multiplier[3] | multiplier[2] | multiplier[1] | multiplier[0]);
    assign excp_zero = is_multiplicand_zero | is_multiplier_zero;

    // check if inputs are maximum positive or negative
    wire excp_max, is_multiplicand_max, is_multiplier_max;
    assign is_multiplicand_max = ~multiplicand[31] & multiplicand[30] & multiplicand[29] & multiplicand[28] & multiplicand[27] & multiplicand[26] & multiplicand[25] & multiplicand[24] & multiplicand[23] & multiplicand[22] & multiplicand[21] & multiplicand[20] & multiplicand[19] & multiplicand[18] & multiplicand[17] & multiplicand[16] & multiplicand[15] & multiplicand[14] & multiplicand[13] & multiplicand[12] & multiplicand[11] & multiplicand[10] & multiplicand[9] & multiplicand[8] & multiplicand[7] & multiplicand[6] & multiplicand[5] & multiplicand[4] & multiplicand[3] & multiplicand[2] & multiplicand[1] & multiplicand[0];
    assign is_multiplier_max = ~multiplier[31] & multiplier[30] & multiplier[29] & multiplier[28] & multiplier[27] & multiplier[26] & multiplier[25] & multiplier[24] & multiplier[23] & multiplier[22] & multiplier[21] & multiplier[20] & multiplier[19] & multiplier[18] & multiplier[17] & multiplier[16] & multiplier[15] & multiplier[14] & multiplier[13] & multiplier[12] & multiplier[11] & multiplier[10] & multiplier[9] & multiplier[8] & multiplier[7] & multiplier[6] & multiplier[5] & multiplier[4] & multiplier[3] & multiplier[2] & multiplier[1] & multiplier[0];
    wire isMultiplicand1 = ~multiplicand[31] & ~multiplicand[30] & ~multiplicand[29] & ~multiplicand[28] & ~multiplicand[27] & ~multiplicand[26] & ~multiplicand[25] & ~multiplicand[24] & ~multiplicand[23] & ~multiplicand[22] & ~multiplicand[21] & ~multiplicand[20] & ~multiplicand[19] & ~multiplicand[18] & ~multiplicand[17] & ~multiplicand[16] & ~multiplicand[15] & ~multiplicand[14] & ~multiplicand[13] & ~multiplicand[12] & ~multiplicand[11] & ~multiplicand[10] & ~multiplicand[9] & ~multiplicand[8] & ~multiplicand[7] & ~multiplicand[6] & ~multiplicand[5] & ~multiplicand[4] & ~multiplicand[3] & ~multiplicand[2] & ~multiplicand[1] & multiplicand[0];
    wire isMultiplier1 = ~multiplier[31] & ~multiplier[30] & ~multiplier[29] & ~multiplier[28] & ~multiplier[27] & ~multiplier[26] & ~multiplier[25] & ~multiplier[24] & ~multiplier[23] & ~multiplier[22] & ~multiplier[21] & ~multiplier[20] & ~multiplier[19] & ~multiplier[18] & ~multiplier[17] & ~multiplier[16] & ~multiplier[15] & ~multiplier[14] & ~multiplier[13] & ~multiplier[12] & ~multiplier[11] & ~multiplier[10] & ~multiplier[9] & ~multiplier[8] & ~multiplier[7] & ~multiplier[6] & ~multiplier[5] & ~multiplier[4] & ~multiplier[3] & ~multiplier[2] & ~multiplier[1] & multiplier[0];

    assign excp_max = (~isMultiplicand1 & ~isMultiplier1) & (is_multiplicand_max | is_multiplier_max);

    // check if inputs are minimum negative
    wire excp_min, is_multiplicand_min, is_multiplier_min;
    assign is_multiplicand_min = multiplicand[31] & ~multiplicand[30] & ~multiplicand[29] & ~multiplicand[28] & ~multiplicand[27] & ~multiplicand[26] & ~multiplicand[25] & ~multiplicand[24] & ~multiplicand[23] & ~multiplicand[22] & ~multiplicand[21] & ~multiplicand[20] & ~multiplicand[19] & ~multiplicand[18] & ~multiplicand[17] & ~multiplicand[16] & ~multiplicand[15] & ~multiplicand[14] & ~multiplicand[13] & ~multiplicand[12] & ~multiplicand[11] & ~multiplicand[10] & ~multiplicand[9] & ~multiplicand[8] & ~multiplicand[7] & ~multiplicand[6] & ~multiplicand[5] & ~multiplicand[4] & ~multiplicand[3] & ~multiplicand[2] & ~multiplicand[1] & ~multiplicand[0];
    assign is_multiplier_min = multiplier[31] & ~multiplier[30] & ~multiplier[29] & ~multiplier[28] & ~multiplier[27] & ~multiplier[26] & ~multiplier[25] & ~multiplier[24] & ~multiplier[23] & ~multiplier[22] & ~multiplier[21] & ~multiplier[20] & ~multiplier[19] & ~multiplier[18] & ~multiplier[17] & ~multiplier[16] & ~multiplier[15] & ~multiplier[14] & ~multiplier[13] & ~multiplier[12] & ~multiplier[11] & ~multiplier[10] & ~multiplier[9] & ~multiplier[8] & ~multiplier[7] & ~multiplier[6] & ~multiplier[5] & ~multiplier[4] & ~multiplier[3] & ~multiplier[2] & ~multiplier[1] & ~multiplier[0];
    assign excp_min = (~isMultiplicand1 & ~isMultiplier1) & (is_multiplicand_min | is_multiplier_min);



    // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // exception signal
    assign exception = ~excp_zero&(excp_ovf | excp_max | excp_min);


endmodule