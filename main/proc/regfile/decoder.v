module decoder(in, out);
    input [4:0] in;
    output [31:0] out;
    
    wire [31:0] wire_out;
    assign wire_out = 32'b1;

    assign out = wire_out << in;
endmodule