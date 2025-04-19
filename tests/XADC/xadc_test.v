module adc_dual_channel_switch(
    input clk_35mhz,
    input BTN0,                         // Slide switch to choose EMG or ECG
    input vauxn3, input vauxp3,        // EMG input (VAUX3)
    input vauxn11, input vauxp11,      // ECG input (VAUX11)
    output reg [15:0] LED              // LED output
);

reg [6:0] daddr_in;
wire [15:0] adc_data;
wire drdy;

// Update daddr_in based on switch position
always @(*) begin
    if (SW0)
        daddr_in = 7'h1B;  // VAUX11 = ECG
    else
        daddr_in = 7'h13;  // VAUX3 = EMG
end

// Instantiate XADC
xadc_wiz_0 xadc_inst (
    .dclk_in(clk_35mhz),
    .daddr_in(daddr_in),
    .den_in(1'b1),
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

// Display ADC value on LEDs
always @(posedge clk_35mhz) begin
    if (drdy) begin
        LED <= {SW0 ? 4'b0010 : 4'b0001, adc_data[15:4]};  // top 4 bits = channel
    end
end

endmodule
