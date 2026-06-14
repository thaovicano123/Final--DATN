`timescale 1ns/1ps

module tb_soc_top_irq;
    reg clk;
    reg resetn;
    reg uart_rx;
    reg [31:0] gpio_in;
    wire uart_tx;
    wire [31:0] gpio_out;

    integer cycles;
    integer irq_toggles;
    reg last_irq_gpio;

    // Task to send UART byte (simulates external serial input)
    task send_uart_byte;
        input [7:0] byte_val;
        integer i;
        localparam UART_CLK_PERIOD = 434; // CLK_DIV in real_uart_mmio.v
        begin
            // Send START bit (0)
            uart_rx = 1'b0;
            repeat (UART_CLK_PERIOD) @(posedge clk);
            
            // Send 8 data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = byte_val[i];
                repeat (UART_CLK_PERIOD) @(posedge clk);
            end
            
            // Send STOP bit (1)
            uart_rx = 1'b1;
            repeat (UART_CLK_PERIOD) @(posedge clk);
        end
    endtask

    soc_top #(
        .MEMFILE("fw/firmware_irq.hex")
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
        gpio_in = 32'h1234_5678;
        cycles = 0;
        irq_toggles = 0;
        last_irq_gpio = 1'b0;

        $dumpfile("results/phase2/tb_soc_top_irq.vcd");
        $dumpvars(0, tb_soc_top_irq);

        repeat (8) @(posedge clk);
        resetn = 1'b1;

        repeat (200000) begin
            @(posedge clk);
            cycles = cycles + 1;

            // Inject UART RX bytes at various times to trigger IRQ handler
            if (cycles == 20000 || cycles == 50000 || cycles == 80000 || cycles == 110000 || cycles == 140000) begin
                send_uart_byte({cycles[7:0]});
            end

            if (gpio_out[8] != last_irq_gpio)
                irq_toggles = irq_toggles + 1;
            last_irq_gpio = gpio_out[8];
        end

        if (irq_toggles < 3) begin
            $display("SOC_TOP_IRQ: FAIL (irq_gpio_toggles=%0d, expect >=3 from UART stimulus)", irq_toggles);
            $fatal(1);
        end else begin
            $display("SOC_TOP_IRQ: PASS (irq_gpio_toggles=%0d)", irq_toggles);
        end

        $finish;
    end
endmodule
