`timescale 1ns / 100ps
module VGAController(     
    input clock,                // 35 MHz System Clock
    input reset,                // Reset Signal

    output hSync,               // Horizontal Sync
    output vSync,               // Vertical Sync
    output [3:0] VGA_R,         // Red Channel
    output [3:0] VGA_G,         // Green Channel
    output [3:0] VGA_B,         // Blue Channel

    output reg [11:0] emg_addr, // EMG RAM address
    output reg [11:0] ecg_addr, // ECG RAM address
    input [31:0] emg_data,      // EMG data from RAM
    input [31:0] ecg_data       // ECG data from RAM
);

    // 25 MHz clock for VGA timing
    wire clock25;
    reg [1:0] pixCounter = 0;
    assign clock25 = pixCounter[1];

    always @(posedge clock) begin
        pixCounter <= pixCounter + 1;
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

    reg [8:0] y_ecg;
    reg [8:0] y_emg;
    reg [3:0] r, g, b;

    always @(posedge clock25) begin
        if (reset) begin
            r <= 0;
            g <= 0;
            b <= 0;
        end else if (active) begin
            // Set RAM addresses for both signals
            ecg_addr <= x + 12'h801;
            emg_addr <= x + 12'hC7F;

            // Compute Y positions for waveform pixels
            y_ecg <= 240 - ecg_data[11:4];  // ECG centered at 240
            y_emg <= 480 - emg_data[11:4];  // EMG centered at 480

            // Pixel rendering
            if (y == y_ecg) begin
                r <= 4'd0;
                g <= 4'hF;  // Green for ECG
                b <= 4'd0;
            end else if (y == y_emg) begin
                r <= 4'hF;
                g <= 4'hF;  // White for EMG
                b <= 4'hF;
            end else begin
                r <= 4'd0;
                g <= 4'd0;
                b <= 4'd0;
            end
        end else begin
            r <= 0;
            g <= 0;
            b <= 0;
        end
    end

    assign VGA_R = r;
    assign VGA_G = g;
    assign VGA_B = b;

endmodule