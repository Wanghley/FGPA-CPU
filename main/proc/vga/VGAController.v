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
    localparam VIDEO_WIDTH  = 640;
    localparam VIDEO_HEIGHT = 480;

    // Generate 25 MHz clock
    reg [1:0] pixCounter;
    wire clock25;
    
    initial begin
        pixCounter = 0;
    end
    
    assign clock25 = pixCounter[1];
    
    always @(posedge clock) begin
        pixCounter <= pixCounter + 1;
    end

    // VGA timing
    wire active, screenEnd;
    wire [9:0] x;
    wire [8:0] y;

    VGATimingGenerator #(
        .HEIGHT(VIDEO_HEIGHT),
        .WIDTH(VIDEO_WIDTH)
    ) Display (
        .clk25(clock25),
        .reset(reset),
        .screenEnd(screenEnd),
        .active(active),
        .hSync(hSync),
        .vSync(vSync),
        .x(x),
        .y(y)
    );

    // Image Data (Background)
    localparam PIXEL_COUNT = VIDEO_WIDTH*VIDEO_HEIGHT;
    localparam PIXEL_ADDRESS_WIDTH = $clog2(PIXEL_COUNT) + 1;
    localparam BITS_PER_COLOR = 12;
    localparam PALETTE_COLOR_COUNT = 256;
    localparam PALETTE_ADDRESS_WIDTH = $clog2(PALETTE_COLOR_COUNT) + 1;

    wire[PIXEL_ADDRESS_WIDTH-1:0] imgAddress = x + 640*y;
    wire[PALETTE_ADDRESS_WIDTH-1:0] colorAddr;

    VGA_RAM #(		
        .DEPTH(PIXEL_COUNT),
        .DATA_WIDTH(PALETTE_ADDRESS_WIDTH),
        .ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH),
        .MEMFILE("C:/Users/ws186/Documents/FGPA-CPU/assets/background/image.mem")
    ) ImageData (
        .clk(clock),
        .addr(imgAddress),
        .dataOut(colorAddr),
        .wEn(1'b0)
    );

    wire [BITS_PER_COLOR-1:0] colorData;
    VGA_RAM #(
        .DEPTH(PALETTE_COLOR_COUNT),
        .DATA_WIDTH(BITS_PER_COLOR),
        .ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),
        .MEMFILE("C:/Users/ws186/Documents/FGPA-CPU/assets/background/colors.mem")
    ) ColorPalette (
        .clk(clock),
        .addr(colorAddr),
        .dataOut(colorData),
        .wEn(1'b0)
    );

    // Sprite data for digits (0-9)
    localparam SPRITE_COUNT = 10; // 10 digits (0-9)
    localparam SPRITE_WIDTH = 32;
    localparam SPRITE_HEIGHT = 32;
    localparam SPRITE_LINES_TOTAL = SPRITE_COUNT * SPRITE_HEIGHT;
    localparam SPRITE_ADDR_WIDTH = $clog2(SPRITE_LINES_TOTAL) + 1;
    
    reg [SPRITE_ADDR_WIDTH-1:0] spriteAddr;
    wire [31:0] spriteData;
    
    VGA_RAM #(
        .DEPTH(SPRITE_LINES_TOTAL),
        .DATA_WIDTH(32),  // 32-bit lines for 32 pixels wide sprites
        .ADDRESS_WIDTH(SPRITE_ADDR_WIDTH),
        .MEMFILE("C:/Users/ws186/Documents/FGPA-CPU/assets/sprites.mem")
    ) SpriteROM (
        .clk(clock),
        .addr(spriteAddr),
        .dataOut(spriteData),
        .wEn(1'b0)
    );

    // Shadow values of BPM digits
    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;

    // Track BPM value
    reg [31:0] bpm_value;

    // For digit rendering
    reg [3:0] digit;
    reg [9:0] row_offset;
    reg [4:0] col_offset;
    reg digit_pixel_on;

    // 1-second timer for BPM updates
    // For 25MHz clock, we need to count to 25,000,000 for 1 second
    reg [24:0] second_counter;
    reg update_ready;
    
    // Initialize registers
    initial begin
        hundreds = 0;
        tens = 0;
        ones = 0;
        second_counter = 0;
        update_ready = 1; // Start with ready to update
    end

    // 1-second counter logic
    always @(posedge clock25) begin
        if (reset) begin
            second_counter <= 0;
            update_ready <= 1;
        end
        else begin
            if (second_counter >= 25000000) begin
                second_counter <= 0;
                update_ready <= 1;
            end
            else begin
                second_counter <= second_counter + 1;
            end
        end
    end

    // Rendering logic
    reg [BITS_PER_COLOR-1:0] pixelColor;

    // Inside the always @(posedge clock25)
    always @(posedge clock25) begin
        if (reset) begin
            sig_addr <= 12'd1704;
            bpm_value <= 0;
            hundreds <= 0;
            tens <= 0;
            ones <= 0;
            second_counter <= 0;
            update_ready <= 1;
        end else begin
            pixelColor <= colorData;

            // === Update BPM Value once every second ===
            if (screenEnd) begin  // One-shot per frame
                if (second_counter >= 25000000) begin
                    sig_addr <= 12'd1704;
                    bpm_value <= sig_data;
                    hundreds <= (sig_data / 100) % 10;
                    tens     <= (sig_data / 10)  % 10;
                    ones     <= sig_data % 10;
                    second_counter <= 0;
                end else begin
                    second_counter <= second_counter + 1;
                end
            end

            // === Draw Signal (ECG + EMG) ===
            if (x >= 55 && x < 390 && y >= 45 && y < 226) begin
                sig_addr <= 12'h559 + x - 55;
                if (y == (350 - sig_data[11:4]))
                    pixelColor <= 12'b0000_1111_0000; // green
            end
            else if (x >= 55 && x < 390 && y >= 254 && y < 434) begin
                sig_addr <= 12'h6AD + x - 55;
                if (y == (400 - sig_data[11:4]))
                    pixelColor <= 12'b1111_0000_0000; // red
            end

            // === Render BPM Digits using Sprites ===
            else if (x >= 480 && x < 576 && y >= 100 && y < 132) begin
                row_offset = y - 100;
                col_offset = x[4:0]; // x % 32
                case ((x - 480) / 32)
                    2'd0: digit = hundreds;
                    2'd1: digit = tens;
                    2'd2: digit = ones;
                    default: digit = 4'd0;
                endcase

                // Compute sprite line address and get pixel bit
                spriteAddr <= digit * 32 + row_offset;
                digit_pixel_on = spriteData[31 - col_offset];

                if (digit_pixel_on)
                    pixelColor <= 12'b1111_1111_1111; // white
            end
        end
    end


    assign {VGA_R, VGA_G, VGA_B} = pixelColor;

endmodule