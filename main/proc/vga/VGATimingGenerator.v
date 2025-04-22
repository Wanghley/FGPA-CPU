`timescale 1 ns / 1 ps
module VGATimingGenerator #(parameter HEIGHT = 480, WIDTH = 800) (
	input clk25,        // 25 MHz clock
	input reset,        // Reset the Frame
	output active,      // In the visible area
	output screenEnd,   // High for one cycle between frames
	output hSync,       // Horizontal sync, active high
	output vSync,       // Vertical sync, active high
	output [9:0] x,     // X coordinate from left
	output [8:0] y      // Y coordinate from top
);

	// Horizontal timings for 800x480 @ 60Hz with 25 MHz pixel clock (non-standard mode)
	localparam 
		H_FRONT_PORCH = 40,
		H_SYNC_WIDTH  = 128,
		H_BACK_PORCH  = 88,

		H_SYNC_START  = WIDTH + H_FRONT_PORCH,             // 800 + 40 = 840
		H_SYNC_END    = H_SYNC_START + H_SYNC_WIDTH,       // 840 + 128 = 968
		H_LINE        = H_SYNC_END + H_BACK_PORCH,         // 968 + 88 = 1056

		// Vertical timings are unchanged from standard 480p
		V_FRONT_PORCH = 11,
		V_SYNC_WIDTH  = 2,
		V_BACK_PORCH  = 31,

		V_SYNC_START  = HEIGHT + V_FRONT_PORCH,            // 480 + 11 = 491
		V_SYNC_END    = V_SYNC_START + V_SYNC_WIDTH,       // 491 + 2 = 493
		V_LINE        = V_SYNC_END + V_BACK_PORCH;         // 493 + 31 = 524

	// Horizontal and vertical position counters
	reg [9:0] hPos = 0;
	reg [9:0] vPos = 0;

	always @(posedge clk25 or posedge reset) begin
		if (reset) begin
			hPos <= 0;
			vPos <= 0;
		end else begin
			if (hPos == H_LINE - 1) begin
				hPos <= 0;
				if (vPos == V_LINE - 1)
					vPos <= 0;
				else
					vPos <= vPos + 1;
			end else
				hPos <= hPos + 1;
		end
	end

	// Determine active display area
	wire activeX = (hPos < WIDTH);
	wire activeY = (vPos < HEIGHT);
	assign active = activeX & activeY;

	assign x = activeX ? hPos : 0;
	assign y = activeY ? vPos : 0;

	assign screenEnd = (vPos == V_LINE - 1) && (hPos == H_LINE - 1);

	assign hSync = (hPos < H_SYNC_START) || (hPos >= H_SYNC_END);
	assign vSync = (vPos < V_SYNC_START) || (vPos >= V_SYNC_END);
endmodule
