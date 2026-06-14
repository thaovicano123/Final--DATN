`timescale 1ns/1ps

module tb_soc_top_smoke;
    reg clk;
    reg resetn;
    reg uart_rx;
    reg [31:0] gpio_in;
    wire uart_tx;
    wire [31:0] gpio_out;

    integer cycles;
    reg seen_gpio_change;
    reg [31:0] last_gpio_out;

    soc_top #(
        .MEMFILE("fw/firmware.hex")
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        uart_rx = 1'b1;
        gpio_in = 32'hDEAD_BEEF;
        cycles = 0;
        seen_gpio_change = 1'b0;
        last_gpio_out = 32'h0;

        $dumpfile("results/phase2/tb_soc_top_smoke.vcd");
        $dumpvars(0, tb_soc_top_smoke);

        repeat (8) @(posedge clk);
        resetn = 1'b1;

        repeat (300000) begin
            @(posedge clk);
            cycles = cycles + 1;

            if (gpio_out != last_gpio_out)
                seen_gpio_change = 1'b1;
            last_gpio_out = gpio_out;
        end

        if (!seen_gpio_change) begin
            $display("SOC_TOP_SMOKE: FAIL (no GPIO activity observed)");
            $fatal(1);
        end else begin
            $display("SOC_TOP_SMOKE: PASS (GPIO activity observed)");
        end

        $finish;
    end
endmodule
