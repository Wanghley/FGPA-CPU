module adc_data_capture(
    input clk,
    input reset,
    input vauxn3, input vauxp3,        // EMG input (VAUX3)
    input vauxn11, input vauxp11,      // ECG input (VAUX11)
    output reg [31:0] emg_out,         // Output for EMG
    output reg [31:0] ecg_out          // Output for ECG
);

reg [6:0] daddr_in = 7'h13;            // Start with VAUX3
reg channel_select = 1'b0;             // 0 = EMG, 1 = ECG
wire [15:0] adc_data;
wire drdy;

// XADC instantiation
xadc_wiz_0 xadc_inst (
    .dclk_in(clk),
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
    .vauxn11(vauxn11),
    .reset_in(reset) // ✅ no comma here!
);                   // ✅ good

// Read and route ADC values to EMG or ECG outputs
always @(posedge clk) begin 
    if (drdy) begin
        if (channel_select == 1'b0) begin
            // convert 12-bit to 32-bit
            emg_out <= {21'h0, adc_data[15:4]};  // 32-bit EMG data
            daddr_in <= 7'h1B;          // Set next to ECG
        end else begin
            ecg_out <= {21'h0, adc_data[15:4]};  // 32-bit ECG data
            daddr_in <= 7'h13;          // Set next to EMG
        end
        channel_select <= ~channel_select;
    end
end

endmodule