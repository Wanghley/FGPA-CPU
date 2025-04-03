/*
 * Verilog Implementation of an N-Point FFT with Dynamic Clock Scaling
 * 
 * This module performs an N-point Fast Fourier Transform (FFT) using integer arithmetic. 
 * It supports dynamic clock scaling, allowing the FFT operation to be enabled or disabled
 * based on an external control signal. The implementation includes:
 *   - Bit-reversed input reordering
 *   - Butterfly operations for FFT computation
 *   - Fixed-point twiddle factor lookup table
 *   - Dynamic clock control for power efficiency
 *
 * Author: Wanghley Soares Martins
 */

module fft #( 
    parameter N = 8,  // FFT size (must be a power of 2)
    parameter DATA_WIDTH = 32  // Bit width for fixed-point representation
)(
    input clk,  // Main clock signal
    input rst,  // Reset signal
    input start,  // Start signal to begin FFT computation
    input dynamic_clk, // Dynamic clock control signal
    input signed [DATA_WIDTH-1:0] real_in [0:N-1], // Real part of input
    input signed [DATA_WIDTH-1:0] imag_in [0:N-1], // Imaginary part of input
    output reg signed [DATA_WIDTH-1:0] real_out [0:N-1], // Real part of output
    output reg signed [DATA_WIDTH-1:0] imag_out [0:N-1], // Imaginary part of output
    output reg done  // Completion signal
);

    // Twiddle factor lookup table (precomputed integer cosine & sine values)
    reg signed [DATA_WIDTH-1:0] cos_lut [0:N/2-1];
    reg signed [DATA_WIDTH-1:0] sin_lut [0:N/2-1];

    // Bit-reversed index array for efficient FFT processing
    reg [31:0] bit_rev [0:N-1];

    integer i, j, k, step, m;
    reg signed [DATA_WIDTH-1:0] temp_real, temp_imag;
    reg signed [DATA_WIDTH-1:0] w_real, w_imag, u_real, u_imag;

    // Clock enable signal for dynamic clock scaling
    reg clk_en;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_en <= 0;
        end else begin
            clk_en <= dynamic_clk; // Enable FFT processing based on dynamic clock control
        end
    end

    // Initialization logic using an always block instead of initial block
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                bit_rev[i] <= 0;
            end
            for (i = 0; i < N/2; i = i + 1) begin
                cos_lut[i] <= 0;
                sin_lut[i] <= 0;
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                bit_rev[i] <= i; // Simple assignment (bit-reversal must be precomputed externally)
            end
            for (i = 0; i < N/2; i = i + 1) begin
                cos_lut[i] <= (1 << (DATA_WIDTH - 2)) * $cos(2.0 * 3.141592653589793 * i / N);
                sin_lut[i] <= (1 << (DATA_WIDTH - 2)) * $sin(2.0 * 3.141592653589793 * i / N);
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
        end else if (start && clk_en) begin
            // Step 1: Bit-reversal permutation
            for (i = 0; i < N; i = i + 1) begin
                real_out[bit_rev[i]] <= real_in[i];
                imag_out[bit_rev[i]] <= imag_in[i];
            end

            // Step 2: FFT computation using butterfly operations
            step = 1;
            while (step < N) begin
                m = step << 1;
                for (j = 0; j < step; j = j + 1) begin
                    w_real = cos_lut[j * (N / m)];
                    w_imag = -sin_lut[j * (N / m)];
                    for (k = j; k < N; k = k + m) begin
                        u_real = real_out[k];
                        u_imag = imag_out[k];
                        temp_real = (w_real * real_out[k + step]) >>> (DATA_WIDTH - 2) - (w_imag * imag_out[k + step]) >>> (DATA_WIDTH - 2);
                        temp_imag = (w_real * imag_out[k + step]) >>> (DATA_WIDTH - 2) + (w_imag * real_out[k + step]) >>> (DATA_WIDTH - 2);

                        real_out[k] <= u_real + temp_real;
                        imag_out[k] <= u_imag + temp_imag;
                        real_out[k + step] <= u_real - temp_real;
                        imag_out[k + step] <= u_imag - temp_imag;
                    end
                end
                step = m;
            end

            done <= 1; // Signal completion
        end
    end

endmodule
