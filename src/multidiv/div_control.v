module div_control_before_add(MSB, add, sub);
    input MSB;
    output add, sub;

    assign add = MSB;
    assign sub = ~MSB;
endmodule