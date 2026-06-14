module icg_cell (
    input  wire clk,
    input  wire resetn,
    input  wire en,
    input  wire test_en,
    output wire gclk
);
    // No-clock-gating synthesis model: force passthrough clock.
    wire _unused_resetn = resetn;
    wire _unused_en = en;
    wire _unused_test_en = test_en;
    assign gclk = clk;
endmodule
