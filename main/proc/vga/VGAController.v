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
    // File path for memory initialization
    localparam FILES_PATH = "C:/Users/ws186/Documents/FGPA-CPU/assets/background/";

    // 25 MHz clock generation
    reg [1:0] pixCounter = 0;
    wire clock25 = pixCounter[1];
    always @(posedge clock) begin
        pixCounter <= pixCounter + 1;
    end

    // VGA timing
    localparam VIDEO_WIDTH  = 640;
    localparam VIDEO_HEIGHT = 480;

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

    // Image Data to Map Pixel Location to Color Address
    localparam 
        PIXEL_COUNT = VIDEO_WIDTH*VIDEO_HEIGHT,                  // Number of pixels on the screen
        PIXEL_ADDRESS_WIDTH = $clog2(PIXEL_COUNT) + 1,           // Use built in log2 command
        BITS_PER_COLOR = 12,                                     // Nexys A7 uses 12 bits/color
        PALETTE_COLOR_COUNT = 256,                               // Number of Colors available
        PALETTE_ADDRESS_WIDTH = $clog2(PALETTE_COLOR_COUNT) + 1; // Use built in log2 Command

    wire[PIXEL_ADDRESS_WIDTH-1:0] imgAddress;     // Image address for the image data
    wire[PALETTE_ADDRESS_WIDTH-1:0] colorAddr;    // Color address for the color palette
    assign imgAddress = x + 640*y;                // Address calculated coordinate

    VGA_RAM #(        
        .DEPTH(PIXEL_COUNT),                      // Set RAM depth to contain every pixel
        .DATA_WIDTH(PALETTE_ADDRESS_WIDTH),       // Set data width according to the color palette
        .ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH),      // Set address with according to the pixel count
        .MEMFILE({FILES_PATH, "image.mem"}))      // Memory initialization
    ImageData(
        .clk(clock),                           // Falling edge of the 100 MHz clk
        .addr(imgAddress),                     // Image data address
        .dataOut(colorAddr),                   // Color palette address
        .wEn(1'b0));                           // We're always reading

    // Color Palette to Map Color Address to 12-Bit Color
    wire[BITS_PER_COLOR-1:0] colorData;        // 12-bit color data at current pixel

    VGA_RAM #(
        .DEPTH(PALETTE_COLOR_COUNT),           // Set depth to contain every color        
        .DATA_WIDTH(BITS_PER_COLOR),           // Set data width according to the bits per color
        .ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH), // Set address width according to the color count
        .MEMFILE({FILES_PATH, "colors.mem"}))  // Memory initialization
    ColorPalette(
        .clk(clock),                           // Rising edge of the 100 MHz clk
        .addr(colorAddr),                      // Address from the ImageData RAM
        .dataOut(colorData),                   // Color at current pixel
        .wEn(1'b0));                           // We're always reading

    // Sprite Memory for Digits
    // Define sprite dimensions based on your example
    localparam SPRITE_WIDTH = 32;              // Width of the sprite (50 columns)
    localparam SPRITE_HEIGHT = 32;             // Height of the sprite (32 rows)
    localparam DIGIT_SPACING = 55;             // Space between digits (adjusted for 32x32)

    // Sprite RAM for digits (0-9)
    reg [14:0] sprite_addr;                    // Address width for sprite memory
    wire sprite_data;                          // 1-bit sprite data (binary image)

    VGA_RAM #(
        .DEPTH(10 * SPRITE_WIDTH * SPRITE_HEIGHT), // 10 digits, each SPRITE_WIDTH x SPRITE_HEIGHT
        .DATA_WIDTH(1),                         // Binary image (1 or 0)
        .ADDRESS_WIDTH(15),                     // Address width for sprite memory
        .MEMFILE({FILES_PATH, "sprite.mem"}))   // Memory initialization file
    SpriteMemory(
        .clk(clock),                            // Clock
        .addr(sprite_addr),                     // Sprite memory address
        .dataOut(sprite_data),                  // Sprite data (0 or 1)
        .wEn(1'b0)                              // Always reading
    );

    // Register to store the value from RAM address 1704
    reg [31:0] display_value;
    reg [3:0] hundreds, tens, ones;            // Decimal digits (3 digits for 0-999)

    // Parameters for digit display area
    localparam DIGIT_X_START = 430;
    localparam DIGIT_Y_START = 260;
    localparam DIGIT_AREA_WIDTH = 166;         // 596-430
    localparam DIGIT_AREA_HEIGHT = 50;         // 310-260

    // For BCD conversion
    always @(posedge clock) begin
        if (sig_addr == 12'h6A8) begin         // 1704 decimal = 0x6A8 hex
            display_value <= sig_data;
            
            // Convert to BCD digits (assuming value 0-999)
            hundreds <= (sig_data % 1000) / 100;
            tens <= (sig_data % 100) / 10;
            ones <= sig_data % 10;
        end
    end

    // Color Mapping
    reg [BITS_PER_COLOR-1:0] pixelColor;
    
    // Determine if current pixel is within a digit sprite
    reg insideDigitArea;
    reg [3:0] currentDigit;      // Which digit (0-9) is being drawn
    reg [4:0] sprite_x;          // X position within the sprite (0-31)
    reg [4:0] sprite_y;          // Y position within the sprite (0-31)
    reg [1:0] digitPosition;     // 0=hundreds, 1=tens, 2=ones

    always @(*) begin
        // Default: not inside digit area
        insideDigitArea = 0;
        currentDigit = 0;
        sprite_x = 0;
        sprite_y = 0;
        digitPosition = 0;
        
        // Check if we're in the digit display area
        if (x >= DIGIT_X_START && x < DIGIT_X_START + DIGIT_AREA_WIDTH && 
            y >= DIGIT_Y_START && y < DIGIT_Y_START + DIGIT_HEIGHT) begin
            
            // Determine which digit position we're drawing (hundreds, tens, ones)
            if (x < DIGIT_X_START + DIGIT_SPACING) begin
                // Hundreds position
                digitPosition = 0;
                currentDigit = hundreds;
                sprite_x = x - DIGIT_X_START;
                sprite_y = y - DIGIT_Y_START;
                if (sprite_x < SPRITE_WIDTH && sprite_y < SPRITE_HEIGHT)
                    insideDigitArea = 1;
            end
            else if (x < DIGIT_X_START + 2*DIGIT_SPACING) begin
                // Tens position
                digitPosition = 1;
                currentDigit = tens;
                sprite_x = x - (DIGIT_X_START + DIGIT_SPACING);
                sprite_y = y - DIGIT_Y_START;
                if (sprite_x < SPRITE_WIDTH && sprite_y < SPRITE_HEIGHT)
                    insideDigitArea = 1;
            end
            else if (x < DIGIT_X_START + 3*DIGIT_SPACING) begin
                // Ones position
                digitPosition = 2;
                currentDigit = ones;
                sprite_x = x - (DIGIT_X_START + 2*DIGIT_SPACING);
                sprite_y = y - DIGIT_Y_START;
                if (sprite_x < SPRITE_WIDTH && sprite_y < SPRITE_HEIGHT)
                    insideDigitArea = 1;
            end
        end
    end
    
    // Calculate sprite memory address based on current digit and pixel position
    always @(*) begin
        if (insideDigitArea) begin
            // Address = DigitValue * (SPRITE_WIDTH * SPRITE_HEIGHT) + y * SPRITE_WIDTH + x
            sprite_addr = (currentDigit * SPRITE_WIDTH * SPRITE_HEIGHT) + 
                          (sprite_y * SPRITE_WIDTH) + sprite_x;
        end else begin
            sprite_addr = 0;
        end
    end

    // Define the height of the digit display area
    localparam DIGIT_HEIGHT = SPRITE_HEIGHT;

    always @(posedge clock25) begin
        if (active) begin
            // Default to background image
            pixelColor <= colorData;
            
            // Signal display in designated areas (kept from original code)
            if (x >= 55 && x < 390 && y >= 45 && y < 226) begin
                if (x < 360) begin  // limit to 320 data points
                    sig_addr <= 12'h559 + x - 40;  // fetch address based on x
                    // Scale signal to box height (181 px): assume sig_data[11:4] is 8 bits
                    if (y == (350 - sig_data[11:4])) begin
                        pixelColor <= 12'b000011110000; // green
                    end
                end
            end
            else if (x >= 55 && x < 390 && y >= 254 && y < 434) begin
                if (x < 360) begin  // limit to 320 data points
                    sig_addr <= 12'h6AD + x - 40;  // fetch address based on x
                    // Scale signal to box height (181 px): assume sig_data[11:4] is 8 bits
                    if (y == (400 - sig_data[11:4])) begin
                        pixelColor <= 12'b111100000000; // white
                    end
                end
            end
            
            // Trigger read of the value to display from RAM address 1704
            if (x == 0 && y == 0) begin
                sig_addr <= 12'h6A8;  // 1704 decimal = 0x6A8 hex
            end
            
            // Draw digit sprites if in digit area and sprite data shows a "1"
            if (insideDigitArea && sprite_data) begin
                pixelColor <= 12'b111111110000;  // Yellow for digits
            end
        end else begin
            pixelColor <= 12'd0; // black outside visible area
        end
    end

    assign {VGA_R, VGA_G, VGA_B} = pixelColor;
endmodule