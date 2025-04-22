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
    input [31:0] sig_data
);
    localparam VIDEO_WIDTH = 640;
    localparam VIDEO_HEIGHT = 480;
    
    // 25 MHz clock generation
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
    
    // Digit rendering state
    reg [31:0] bpm_val;
    reg [3:0] hundreds, tens, ones;
    
    // Read stages
    reg fetch_bpm;
    reg [11:0] current_sprite_addr;
    reg [31:0] current_sprite_line;
    
    // Temp variables for digit extraction
    reg [31:0] temp;
    reg [4:0] x_offset;
    reg [4:0] row;
    reg [3:0] digit;
    
    // Color output
    reg [11:0] pixelColor;
    
    // Initialize registers
    initial begin
        bpm_val = 0;
        hundreds = 0;
        tens = 0;
        ones = 0;
        fetch_bpm = 0;
        temp = 0;
    end
    
    // Function to extract hundreds digit
    function [3:0] extract_hundreds;
        input [31:0] value;
        reg [31:0] temp_val;
        reg [3:0] result;
        begin
            temp_val = value;
            result = 0;
            
            if (temp_val >= 900) begin temp_val = temp_val - 900; result = result + 9; end
            if (temp_val >= 800) begin temp_val = temp_val - 800; result = result + 8; end
            if (temp_val >= 700) begin temp_val = temp_val - 700; result = result + 7; end
            if (temp_val >= 600) begin temp_val = temp_val - 600; result = result + 6; end
            if (temp_val >= 500) begin temp_val = temp_val - 500; result = result + 5; end
            if (temp_val >= 400) begin temp_val = temp_val - 400; result = result + 4; end
            if (temp_val >= 300) begin temp_val = temp_val - 300; result = result + 3; end
            if (temp_val >= 200) begin temp_val = temp_val - 200; result = result + 2; end
            if (temp_val >= 100) begin temp_val = temp_val - 100; result = result + 1; end
            
            extract_hundreds = result;
        end
    endfunction
    
    // Function to extract tens digit
    function [3:0] extract_tens;
        input [31:0] value;
        reg [31:0] temp_val;
        reg [3:0] result;
        begin
            temp_val = value % 100;
            result = 0;
            
            if (temp_val >= 90) begin temp_val = temp_val - 90; result = result + 9; end
            if (temp_val >= 80) begin temp_val = temp_val - 80; result = result + 8; end
            if (temp_val >= 70) begin temp_val = temp_val - 70; result = result + 7; end
            if (temp_val >= 60) begin temp_val = temp_val - 60; result = result + 6; end
            if (temp_val >= 50) begin temp_val = temp_val - 50; result = result + 5; end
            if (temp_val >= 40) begin temp_val = temp_val - 40; result = result + 4; end
            if (temp_val >= 30) begin temp_val = temp_val - 30; result = result + 3; end
            if (temp_val >= 20) begin temp_val = temp_val - 20; result = result + 2; end
            if (temp_val >= 10) begin temp_val = temp_val - 10; result = result + 1; end
            
            extract_tens = result;
        end
    endfunction
    
    // Addressing & display logic
    always @(posedge clock25) begin
        if (reset) begin
            sig_addr <= 12'd1704;
            fetch_bpm <= 0;
            pixelColor <= 12'd0;
        end 
        else if (active) begin
            pixelColor <= 12'd0; // default black
            fetch_bpm <= 0;
            
            // Load BPM value once per frame (top-left corner)
            if (x == 0 && y == 0) begin
                sig_addr <= 12'd1704;
                fetch_bpm <= 1;
            end 
            else if (x == 1 && y == 0 && fetch_bpm) begin
                bpm_val <= sig_data;
                
                // Digit extraction using functions instead of while loops
                hundreds <= extract_hundreds(sig_data);
                tens <= extract_tens(sig_data);
                ones <= sig_data % 10;
            end
            
            // ECG box drawing
            if (x >= 55 && x < 390 && y >= 45 && y < 226) begin
                if (x < 360) begin
                    sig_addr <= 12'h559 + x - 40;
                    if (y == (350 - sig_data[11:4])) begin
                        pixelColor <= 12'b000011110000; // green
                    end
                end
            end
            
            // EMG box drawing
            else if (x >= 55 && x < 390 && y >= 254 && y < 434) begin
                if (x < 360) begin
                    sig_addr <= 12'h6AD + x - 40;
                    if (y == (400 - sig_data[11:4])) begin
                        pixelColor <= 12'b111100000000; // red
                    end
                end
            end
            
            // BPM digit drawing
            else if (x >= 480 && x < 576 && y >= 100 && y < 132) begin
                row = y - 100;
                x_offset = x % 32;
                
                case ((x - 480) / 32)
                    0: digit = hundreds;
                    1: digit = tens;
                    2: digit = ones;
                    default: digit = 0;
                endcase
                
                // Request sprite line
                current_sprite_addr = 12'd760 + digit * 32 + row;
                sig_addr <= current_sprite_addr;
                current_sprite_line <= sig_data;
                
                // Draw pixel from sprite
                if (current_sprite_line[31 - x_offset]) begin
                    pixelColor <= 12'b111111111111; // white
                end
            end
        end 
        else begin
            pixelColor <= 12'd0;
        end
    end
    
    assign {VGA_R, VGA_G, VGA_B} = pixelColor;
    
endmodule