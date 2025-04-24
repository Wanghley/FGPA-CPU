module binary_to_bcd(
    input [7:0] binary,  // Assuming 8-bit binary input
    output reg [11:0] bcd // 3 BCD digits (12 bits)
);
    integer i;
    
    always @(*) begin
        bcd = 0;
        
        for (i = 7; i >= 0; i = i - 1) begin
            // Add 3 to columns >= 5
            if (bcd[3:0] >= 5) bcd[3:0] = bcd[3:0] + 3;
            if (bcd[7:4] >= 5) bcd[7:4] = bcd[7:4] + 3;
            if (bcd[11:8] >= 5) bcd[11:8] = bcd[11:8] + 3;
            
            // Shift one bit
            bcd = {bcd[10:0], binary[i]};
        end
    end
endmodule