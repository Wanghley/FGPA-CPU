module adc_dual_channel(
    input CLK100MHZ,
    output reg [15:0] LED,
    input vauxn3,    // EMG
    input vauxp3,    // EMG
    input vauxn11,   // ECG
    input vauxp11,    // ECG
    input BTN0   // Button to reset or toggle channels
);

wire [15:0] adc_data;
wire drdy;
reg [6:0] daddr_in = 7'h13;  // Start at VAUX3 (EMG)

// Instantiate XADC
xadc_wiz_0 xadc_inst (
    .dclk_in(CLK100MHZ),
    .daddr_in(daddr_in),
    .den_in(1'b1),            // Continuous enable
    .di_in(16'h0000),
    .dwe_in(1'b0),
    .do_out(adc_data),
    .drdy_out(drdy),
    .vp_in(1'b0),
    .vn_in(1'b0),
    .vauxp3(vauxp3),
    .vauxn3(vauxn3),
    .vauxp11(vauxp11),
    .vauxn11(vauxn11)
);

// Toggle channel and update LEDs when new data is ready
always @(posedge CLK100MHZ) begin
    if (drdy) begin
        if (BTN0 == 0) begin
            LED <= {4'b0001, adc_data[15:4]}; // EMG (channel indicator: 0001)
            daddr_in <= 7'h1B;                // Next: switch to ECG (VAUX11)
        end else begin
            LED <= {4'b0010, adc_data[15:4]}; // ECG (channel indicator: 0010)
            daddr_in <= 7'h13;                // Next: switch back to EMG (VAUX3)
        end
    end
end

endmodule