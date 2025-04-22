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
		PIXEL_COUNT = VIDEO_WIDTH*VIDEO_HEIGHT, 	             // Number of pixels on the screen
		PIXEL_ADDRESS_WIDTH = $clog2(PIXEL_COUNT) + 1,           // Use built in log2 command
		BITS_PER_COLOR = 12, 	  								 // Nexys A7 uses 12 bits/color
		PALETTE_COLOR_COUNT = 256, 								 // Number of Colors available
		PALETTE_ADDRESS_WIDTH = $clog2(PALETTE_COLOR_COUNT) + 1; // Use built in log2 Command

	wire[PIXEL_ADDRESS_WIDTH-1:0] imgAddress;  	 // Image address for the image data
	wire[PALETTE_ADDRESS_WIDTH-1:0] colorAddr; 	 // Color address for the color palette
	assign imgAddress = x + 640*y;				 // Address calculated coordinate

    VGA_RAM #(		
		.DEPTH(PIXEL_COUNT), 				     // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),      // Set data width according to the color palette
		.ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({FILES_PATH, "image.mem"})) // Memory initialization
	ImageData(
		.clk(clock), 						 // Falling edge of the 100 MHz clk
		.addr(imgAddress),					 // Image data address
		.dataOut(colorAddr),				 // Color palette address
		.wEn(1'b0)); 						 // We're always reading

    // Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] colorData; // 12-bit color data at current pixel

	VGA_RAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({FILES_PATH, "colors.mem"}))  // Memory initialization
	ColorPalette(
		.clk(clock), 							   	   // Rising edge of the 100 MHz clk
		.addr(colorAddr),					       // Address from the ImageData RAM
		.dataOut(colorData),				       // Color at current pixel
		.wEn(1'b0)); 						       // We're always reading


    // Color Mapping
    reg [BITS_PER_COLOR-1:0] pixelColor;

    always @(posedge clock25) begin
        if (active) begin
            pixelColor <= colorData;  // default image pixel

            // Check if inside the drawing box
            if (x >= 40 && x < 390 && y >= 45 && y < 226) begin
                if (x < 360) begin  // limit to 320 data points
                    sig_addr <= 12'h559 + x - 40;  // fetch address based on x
                    // Scale signal to box height (181 px): assume sig_data[11:4] is 8 bits
                    if (y == (226 - sig_data[11:4])) begin
                        pixelColor <= 12'b000011110000; // green
                    end
                end
            end
        end else begin
            pixelColor <= 12'd0; // black outside visible area
        end
    end

    assign {VGA_R, VGA_G, VGA_B} = pixelColor;


    // OLD CODE FOR REFERENCE
    // Color
    // reg [3:0] r, g, b;
    // reg [8:0] y_val;

    // always @(posedge clock25) begin
    //     if (active) begin
    //         if (y < 240) begin
    //             sig_addr <= x + 12'h801;               // ECG address
    //             y_val <= 240 - sig_data[11:4];         // Center ECG
    //             if (y == y_val) begin
    //                 r <= 0;
    //                 g <= 4'hF;  // Green for ECG
    //                 b <= 0;
    //             end else begin
    //                 r <= 0; g <= 0; b <= 0;
    //             end
    //         end else begin
    //             sig_addr <= x + 12'h559;               // EMG address
    //             y_val <= 480 - sig_data[11:4];         // Center EMG
    //             if (y == y_val) begin
    //                 r <= 4'hF;  // White for EMG
    //                 g <= 4'hF;
    //                 b <= 4'hF;
    //             end else begin
    //                 r <= 0; g <= 0; b <= 0;
    //             end
    //         end
    //     end else begin
    //         r <= 0; g <= 0; b <= 0;
    //     end
    // end

    // assign VGA_R = r;
    // assign VGA_G = g;
    // assign VGA_B = b;

endmodule