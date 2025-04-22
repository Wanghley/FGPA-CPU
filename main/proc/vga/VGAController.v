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

    // Color
    reg [3:0] r, g, b;
    reg [8:0] y_val;

    always @(posedge clock25) begin
        if (active) begin
            if (y < 240) begin
                sig_addr <= x + 12'h801;               // ECG address
                y_val <= 240 - sig_data[11:4];         // Center ECG
                if (y == y_val) begin
                    r <= 0;
                    g <= 4'hF;  // Green for ECG
                    b <= 0;
                end else begin
                    r <= 0; g <= 0; b <= 0;
                end
            end else begin
                sig_addr <= x + 12'h559;               // EMG address
                y_val <= 480 - sig_data[11:4];         // Center EMG
                if (y == y_val) begin
                    r <= 4'hF;  // White for EMG
                    g <= 4'hF;
                    b <= 4'hF;
                end else begin
                    r <= 0; g <= 0; b <= 0;
                end
            end
        end else begin
            r <= 0; g <= 0; b <= 0;
        end
    end

    assign VGA_R = r;
    assign VGA_G = g;
    assign VGA_B = b;

endmodule