`timescale 1ns / 100ps
module VGAController(     
    input clock,                // 35 MHz System Clock (not used)
    input reset,                // Reset Signal

    output hSync,               // Horizontal Sync
    output vSync,               // Vertical Sync
    output [3:0] VGA_R,         // Red Channel
    output [3:0] VGA_G,         // Green Channel
    output [3:0] VGA_B,         // Blue Channel

    inout ps2_clk,
    inout ps2_data,

    input [31:0] sig_data,         // RAM Output: 12-bit ECG value in [11:0]
    output reg [11:0] sig_addr     // RAM Address input
);

    // 25 MHz clock for VGA timing
    wire clock25;

    reg[1:0] pixCounter = 0;      // Pixel counter to divide the clock
    assign clock25 = pixCounter[1]; // Set the clock high whenever the second bit (2) is high
	always @(posedge clock) begin
		pixCounter <= pixCounter + 1; // Since the reg is only 3 bits, it will reset every 8 cycles
	end

    // VGA screen size
    localparam VIDEO_WIDTH  = 640;
    localparam VIDEO_HEIGHT = 480;

    wire active, screenEnd;
    wire [9:0] x;
    wire [8:0] y;

    // VGA timing controller
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

    // Scale 12-bit ECG value (0-4095) to screen vertical range (~0-255)
    wire [8:0] y_ecg;

    // Scale 12-bit EMG value (0-4095) to screen vertical range (~0-255)
    wire [8:0] y_emg;

    // Color output logic
    reg [3:0] r, g, b;

    always @(posedge clock25) begin
        if (active && (y < 300)) begin
            sig_addr <= x + 12'h801; // ECG data
            assign y_ecg = 240 - sig_data[11:4]; // Downscale and center
            if (active && y == y_ecg) begin
                r <= 4'd0;
                g <= 4'hF;  // Green waveform
                b <= 4'd0;
            end else begin
                r <= 4'd0;
                g <= 4'd0;
                b <= 4'd0;
            end
        
        end else if (active && (y >= 300)) begin
            assign y_emg = 340 - sig_data[11:4]; // Downscale and center
            sig_addr <= x + 12'hC7F; // EMG data
            if (active && y == y_emg) begin
                r <= 4'hF;
                g <= 4'hF;  // White-ish waveform
                b <= 4'hF;
            end else begin
                r <= 4'd0;
                g <= 4'd0;
                b <= 4'd0;
            end
        end
    end

    assign VGA_R = r;
    assign VGA_G = g;
    assign VGA_B = b;

endmodule