module matrix_mult #(
    parameter N = 50, // Define the matrix size dynamically
    parameter DATA_WIDTH = 8 // Bit-width of matrix elements
)(
    input clk,
    input rst,
    input start, // Signal to start computation
    output reg done, // Signal to indicate computation is done
    input [DATA_WIDTH-1:0] A [0:N-1][0:N-1], // NxN matrix A
    input [DATA_WIDTH-1:0] B [0:N-1][0:N-1], // NxN matrix B
    output reg [(2*DATA_WIDTH)-1:0] C [0:N-1][0:N-1] // NxN result matrix C
);
    
    integer i, j, k;
    reg [1:0] state;
    localparam IDLE = 0, COMPUTE = 1, DONE = 2;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset output matrix and state
            done <= 0;
            state <= IDLE;
            for (i = 0; i < N; i = i + 1)
                for (j = 0; j < N; j = j + 1)
                    C[i][j] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        done <= 0;
                        state <= COMPUTE;
                        i <= 0;
                        j <= 0;
                        k <= 0;
                    end
                end
                COMPUTE: begin
                    if (i < N) begin
                        if (j < N) begin
                            if (k == 0) C[i][j] = 0;
                            C[i][j] = C[i][j] + (A[i][k] * B[k][j]);
                            if (k < N-1) k = k + 1;
                            else begin
                                k = 0;
                                j = j + 1;
                            end
                        end else begin
                            j = 0;
                            i = i + 1;
                        end
                    end else begin
                        state <= DONE;
                    end
                end
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule