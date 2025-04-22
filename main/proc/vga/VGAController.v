`timescale 1ns / 100ps
module VGAController(     
    input clock,
    input reset,

    output hSync,
    output vSync,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,

    output reg [11:0] sig_addr,
    input      [31:0] sig_data
);
    // Use `define for parameters since localparam is not supported in older Verilog
    `define FILES_PATH "C:/Users/ws186/Documents/FGPA-CPU/assets/background/"
    `define VIDEO_WIDTH 640
    `define VIDEO_HEIGHT 480
    `define PIXEL_COUNT (`VIDEO_WIDTH * `VIDEO_HEIGHT)
    `define PIXEL_ADDRESS_WIDTH 19
    `define BITS_PER_COLOR 12
    `define PALETTE_COLOR_COUNT 256
    `define PALETTE_ADDRESS_WIDTH 9

    // Define digit X positions as parameters
    parameter DIGIT_X0 = 430;
    parameter DIGIT_X1 = 462;
    parameter DIGIT_X2 = 494;
    parameter DIGIT_X3 = 526;
    parameter DIGIT_X4 = 558;

    // Define sprite depth and address width
    `define SPRITE_DEPTH 270
    `define SPRITE_ADDR_WIDTH 9

    reg [1:0] pixCounter;
    wire clock25;
    assign clock25 = pixCounter[1];
    
    // Initialize registers in an initial block
    initial begin
        pixCounter = 0;
    end
    
    always @(posedge clock) begin
        pixCounter <= pixCounter + 1;
    end

    wire active, screenEnd;
    wire [9:0] x;
    wire [8:0] y;

    VGATimingGenerator Display (
        .clk25(clock25),
        .reset(reset),
        .screenEnd(screenEnd),
        .active(active),
        .hSync(hSync),
        .vSync(vSync),
        .x(x),
        .y(y)
    );
    
    // Add parameter passing to the timing generator
    defparam Display.HEIGHT = `VIDEO_HEIGHT;
    defparam Display.WIDTH = `VIDEO_WIDTH;

    wire [`PIXEL_ADDRESS_WIDTH-1:0] imgAddress;
    assign imgAddress = x + 640 * y;
    wire [`PALETTE_ADDRESS_WIDTH-1:0] colorAddr;

    VGA_RAM ImageData (
        .clk(clock),
        .addr(imgAddress),
        .dataOut(colorAddr),
        .wEn(1'b0)
    );
    // Add parameter passing for ImageData
    defparam ImageData.DEPTH = `PIXEL_COUNT;
    defparam ImageData.DATA_WIDTH = `PALETTE_ADDRESS_WIDTH;
    defparam ImageData.ADDRESS_WIDTH = `PIXEL_ADDRESS_WIDTH;
    defparam ImageData.MEMFILE = {`FILES_PATH, "image.mem"};

    wire [`BITS_PER_COLOR-1:0] colorData;
    VGA_RAM ColorPalette (
        .clk(clock),
        .addr(colorAddr),
        .dataOut(colorData),
        .wEn(1'b0)
    );
    // Add parameter passing for ColorPalette
    defparam ColorPalette.DEPTH = `PALETTE_COLOR_COUNT;
    defparam ColorPalette.DATA_WIDTH = `BITS_PER_COLOR;
    defparam ColorPalette.ADDRESS_WIDTH = `PALETTE_ADDRESS_WIDTH;
    defparam ColorPalette.MEMFILE = {`FILES_PATH, "colors.mem"};

    reg [`BITS_PER_COLOR-1:0] pixelColor;
    reg [31:0] decimalValue;
    reg [3:0] digit0, digit1, digit2, digit3, digit4;

    reg [`SPRITE_ADDR_WIDTH-1:0] sprite_addr;
    wire [31:0] sprite_data;

    VGA_RAM SpriteMemory (
        .clk(clock),
        .addr(sprite_addr),
        .dataOut(sprite_data),
        .wEn(1'b0)
    );
    // Add parameter passing for SpriteMemory
    defparam SpriteMemory.DEPTH = `SPRITE_DEPTH;
    defparam SpriteMemory.DATA_WIDTH = 32;
    defparam SpriteMemory.ADDRESS_WIDTH = `SPRITE_ADDR_WIDTH;
    defparam SpriteMemory.MEMFILE = {`FILES_PATH, "sprites.mem"};

    // Declare temp variable outside of always block
    reg [31:0] temp;

    always @(posedge clock) begin
        sig_addr <= 12'd1704; // fixed address for decimal display

        decimalValue <= sig_data;
        // Extract digits
        temp = sig_data;
        digit4 <= temp / 10000;
        temp = temp % 10000;
        digit3 <= temp / 1000;
        temp = temp % 1000;
        digit2 <= temp / 100;
        temp = temp % 100;
        digit1 <= temp / 10;
        digit0 <= temp % 10;
    end

    // Additional registers for sprite drawing logic
    reg [9:0] sx;
    reg [8:0] sy;
    reg [9:0] digitX;
    reg [31:0] sprite_line;
    reg [3:0] curr_digit;
    reg [31:0] i;

    always @(posedge clock25) begin
        if (active) begin
            pixelColor <= colorData; // default background

            // Draw digits in box (430,260)-(596,310)
            if (x >= 430 && x < 596 && y >= 260 && y < 310) begin
                // Reset variables for digit checking
                i = 0;
                
                // Check first digit
                if (i == 0) begin
                    digitX = DIGIT_X0; 
                    curr_digit = digit4;
                    if (x >= digitX && x < digitX + 32) begin
                        sx = x - digitX;
                        sy = y - 260;
                        sprite_line = 765 + curr_digit*27 + sy;
                        sprite_addr <= sprite_line;
                        if (sprite_data[31 - sx]) // MSB = leftmost pixel
                            pixelColor <= 12'b1111_1111_0000; // yellow
                    end
                    i = i + 1;
                end
                
                // Check second digit
                if (i == 1) begin
                    digitX = DIGIT_X1;
                    curr_digit = digit3;
                    if (x >= digitX && x < digitX + 32) begin
                        sx = x - digitX;
                        sy = y - 260;
                        sprite_line = 765 + curr_digit*27 + sy;
                        sprite_addr <= sprite_line;
                        if (sprite_data[31 - sx])
                            pixelColor <= 12'b1111_1111_0000;
                    end
                    i = i + 1;
                end
                
                // Check third digit
                if (i == 2) begin
                    digitX = DIGIT_X2;
                    curr_digit = digit2;
                    if (x >= digitX && x < digitX + 32) begin
                        sx = x - digitX;
                        sy = y - 260;
                        sprite_line = 765 + curr_digit*27 + sy;
                        sprite_addr <= sprite_line;
                        if (sprite_data[31 - sx])
                            pixelColor <= 12'b1111_1111_0000;
                    end
                    i = i + 1;
                end
                
                // Check fourth digit
                if (i == 3) begin
                    digitX = DIGIT_X3;
                    curr_digit = digit1;
                    if (x >= digitX && x < digitX + 32) begin
                        sx = x - digitX;
                        sy = y - 260;
                        sprite_line = 765 + curr_digit*27 + sy;
                        sprite_addr <= sprite_line;
                        if (sprite_data[31 - sx])
                            pixelColor <= 12'b1111_1111_0000;
                    end
                    i = i + 1;
                end
                
                // Check fifth digit
                if (i == 4) begin
                    digitX = DIGIT_X4;
                    curr_digit = digit0;
                    if (x >= digitX && x < digitX + 32) begin
                        sx = x - digitX;
                        sy = y - 260;
                        sprite_line = 765 + curr_digit*27 + sy;
                        sprite_addr <= sprite_line;
                        if (sprite_data[31 - sx])
                            pixelColor <= 12'b1111_1111_0000;
                    end
                end
            end

            // ECG waveform
            if (x >= 55 && x < 390 && y >= 45 && y < 226) begin
                if (x < 360) begin
                    sig_addr <= 12'h559 + x - 40;
                    if (y == (350 - sig_data[11:4])) begin
                        pixelColor <= 12'b000011110000;
                    end
                end
            end
            // EMG waveform
            else if (x >= 55 && x < 390 && y >= 254 && y < 434) begin
                if (x < 360) begin
                    sig_addr <= 12'h6AD + x - 40;
                    if (y == (400 - sig_data[11:4])) begin
                        pixelColor <= 12'b111100000000;
                    end
                end
            end
        end else begin
            pixelColor <= 12'd0;
        end
    end

    assign {VGA_R, VGA_G, VGA_B} = pixelColor;

endmodule