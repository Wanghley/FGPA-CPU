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
    localparam FILES_PATH = "C:/Users/ws186/Documents/FGPA-CPU/assets/background/";

    reg [1:0] pixCounter = 0;
    wire clock25 = pixCounter[1];
    always @(posedge clock) begin
        pixCounter <= pixCounter + 1;
    end

    localparam VIDEO_WIDTH  = 640;
    localparam VIDEO_HEIGHT = 480;

    wire active, screenEnd;
    wire [9:0] x;
    wire [8:0] y;

    VGATimingGenerator #( .HEIGHT(VIDEO_HEIGHT), .WIDTH(VIDEO_WIDTH) ) Display (
        .clk25(clock25),
        .reset(reset),
        .screenEnd(screenEnd),
        .active(active),
        .hSync(hSync),
        .vSync(vSync),
        .x(x),
        .y(y)
    );

    localparam PIXEL_COUNT = VIDEO_WIDTH * VIDEO_HEIGHT;
    localparam PIXEL_ADDRESS_WIDTH = $clog2(PIXEL_COUNT) + 1;
    localparam BITS_PER_COLOR = 12;
    localparam PALETTE_COLOR_COUNT = 256;
    localparam PALETTE_ADDRESS_WIDTH = $clog2(PALETTE_COLOR_COUNT) + 1;

    wire [PIXEL_ADDRESS_WIDTH-1:0] imgAddress = x + 640 * y;
    wire [PALETTE_ADDRESS_WIDTH-1:0] colorAddr;

    VGA_RAM #( .DEPTH(PIXEL_COUNT), .DATA_WIDTH(PALETTE_ADDRESS_WIDTH), .ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH), .MEMFILE({FILES_PATH, "image.mem"})) ImageData (
        .clk(clock),
        .addr(imgAddress),
        .dataOut(colorAddr),
        .wEn(1'b0)
    );

    wire [BITS_PER_COLOR-1:0] colorData;
    VGA_RAM #( .DEPTH(PALETTE_COLOR_COUNT), .DATA_WIDTH(BITS_PER_COLOR), .ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH), .MEMFILE({FILES_PATH, "colors.mem"})) ColorPalette (
        .clk(clock),
        .addr(colorAddr),
        .dataOut(colorData),
        .wEn(1'b0)
    );

    reg [BITS_PER_COLOR-1:0] pixelColor;
    reg [31:0] decimalValue;
    reg [3:0] digits[4:0];
    reg [31:0] temp;
    integer i;

    wire [9:0] digitXStart[4:0];
    assign digitXStart[0] = 430;
    assign digitXStart[1] = 462;
    assign digitXStart[2] = 494;
    assign digitXStart[3] = 526;
    assign digitXStart[4] = 558;

    // SPRITE MEMORY using VGA_RAM
    localparam SPRITE_DEPTH = 270; // 10 digits * 27 lines
    localparam SPRITE_ADDR_WIDTH = $clog2(SPRITE_DEPTH);

    reg [SPRITE_ADDR_WIDTH-1:0] sprite_addr;
    wire [31:0] sprite_data;

    VGA_RAM #( .DEPTH(SPRITE_DEPTH), .DATA_WIDTH(32), .ADDRESS_WIDTH(SPRITE_ADDR_WIDTH), .MEMFILE({FILES_PATH, "sprites.mem"})) SpriteMemory (
        .clk(clock),
        .addr(sprite_addr),
        .dataOut(sprite_data),
        .wEn(1'b0)
    );

    always @(posedge clock) begin
        sig_addr <= 12'd1704; // fixed address for decimal display

        decimalValue <= sig_data;
        temp = sig_data;
        digits[4] <= temp / 10000;
        temp = temp % 10000;
        digits[3] <= temp / 1000;
        temp = temp % 1000;
        digits[2] <= temp / 100;
        temp = temp % 100;
        digits[1] <= temp / 10;
        digits[0] <= temp % 10;
    end

    reg [9:0] sx;
    reg [9:0] sy;

    always @(posedge clock25) begin
        if (active) begin
            pixelColor <= colorData; // default background

            // Draw digits in box (430,260)-(596,310)
            if (x >= 430 && x < 596 && y >= 260 && y < 310) begin
                for (i = 0; i < 5; i = i + 1) begin
                    if (x >= digitXStart[i] && x < digitXStart[i] + 32) begin
                        sx = x - digitXStart[i];
                        sy = y - 260;
                        sprite_addr <= digits[4 - i]*27 + sy;
                        if (sprite_data[31 - sx]) // MSB = leftmost pixel
                            pixelColor <= 12'b1111_1111_0000; // yellow
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