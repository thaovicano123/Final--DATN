module icg_cell (
    input  wire clk,
    input  wire resetn,
    input  wire en,
    input  wire test_en,
    output wire gclk
);
    reg en_latched;

    // Latch enable while clock is low to avoid glitches on gated clock.
    // Reset to 1'b1 to match CMU default (clk_en = 2'b11 after reset),
    // ensuring peripheral clocks are active immediately after reset.
    always @(negedge clk or negedge resetn) begin
        if (!resetn)
            en_latched <= 1'b1;
        else
            en_latched <= en | test_en;
    end

    assign gclk = clk & en_latched;
endmodule
