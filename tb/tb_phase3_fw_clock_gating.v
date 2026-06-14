`timescale 1ns/1ps

module tb_phase3_fw_clock_gating;
    reg clk;
    reg resetn;
    reg uart_rx;
    reg [31:0] gpio_in;
    wire uart_tx;
    wire [31:0] gpio_out;

    integer fail_count;
    integer gclk_uart_toggle_a;
    integer gclk_uart_toggle_b;
    integer gclk_uart_toggle_c;
    integer gclk_gpio_toggle_a;
    integer gclk_gpio_toggle_b;
    integer gclk_gpio_toggle_c;
    integer gpio_toggle_a;
    integer gpio_toggle_b;
    integer gpio_toggle_c;

    localparam PHASE_A = 2'd0;
    localparam PHASE_B = 2'd1;
    localparam PHASE_C = 2'd2;

    reg [1:0] phase;

    soc_top #(
        .MEMFILE("fw/firmware_gating.hex")
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    always #5 clk = ~clk;

    task check_true;
        input [255:0] name;
        input cond;
        begin
            if (!cond) begin
                $display("[FAIL] %0s", name);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s", name);
            end
        end
    endtask

    always @(posedge clk) begin
        if (!resetn)
            phase <= PHASE_A;
        else begin
            case (phase)
                PHASE_A: if (dut.u_cmu.clk_en_state == 2'b00) phase <= PHASE_B;
                PHASE_B: if (dut.u_cmu.clk_en_state == 2'b10) phase <= PHASE_C;
                default: phase <= phase;
            endcase
        end
    end

    always @(dut.u_cmu.gclk_uart) begin
        if (resetn) begin
            case (phase)
                PHASE_A: gclk_uart_toggle_a = gclk_uart_toggle_a + 1;
                PHASE_B: gclk_uart_toggle_b = gclk_uart_toggle_b + 1;
                PHASE_C: gclk_uart_toggle_c = gclk_uart_toggle_c + 1;
            endcase
        end
    end

    always @(dut.u_cmu.gclk_gpio) begin
        if (resetn) begin
            case (phase)
                PHASE_A: gclk_gpio_toggle_a = gclk_gpio_toggle_a + 1;
                PHASE_B: gclk_gpio_toggle_b = gclk_gpio_toggle_b + 1;
                PHASE_C: gclk_gpio_toggle_c = gclk_gpio_toggle_c + 1;
            endcase
        end
    end

    always @(gpio_out[0]) begin
        if (resetn) begin
            case (phase)
                PHASE_A: gpio_toggle_a = gpio_toggle_a + 1;
                PHASE_B: gpio_toggle_b = gpio_toggle_b + 1;
                PHASE_C: gpio_toggle_c = gpio_toggle_c + 1;
            endcase
        end
    end

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        uart_rx = 1'b1;
        gpio_in = 32'h0;

        fail_count = 0;
        gclk_uart_toggle_a = 0;
        gclk_uart_toggle_b = 0;
        gclk_uart_toggle_c = 0;
        gclk_gpio_toggle_a = 0;
        gclk_gpio_toggle_b = 0;
        gclk_gpio_toggle_c = 0;
        gpio_toggle_a = 0;
        gpio_toggle_b = 0;
        gpio_toggle_c = 0;

        phase = PHASE_A;

        $dumpfile("results/phase3/tb_phase3_fw_clock_gating.vcd");
        $dumpvars(0, tb_phase3_fw_clock_gating);

        repeat (8) @(posedge clk);
        resetn = 1'b1;

        // Let firmware run through all three phases.
        repeat (350000) @(posedge clk);

        $display("[INFO] Toggle counts:");
        $display("  PhaseA gclk(u,g)=(%0d,%0d) gpio0=%0d", gclk_uart_toggle_a, gclk_gpio_toggle_a, gpio_toggle_a);
        $display("  PhaseB gclk(u,g)=(%0d,%0d) gpio0=%0d", gclk_uart_toggle_b, gclk_gpio_toggle_b, gpio_toggle_b);
        $display("  PhaseC gclk(u,g)=(%0d,%0d) gpio0=%0d", gclk_uart_toggle_c, gclk_gpio_toggle_c, gpio_toggle_c);

        check_true("Phase transitions reached", (phase == PHASE_C));
        check_true("Phase A UART gclk active", gclk_uart_toggle_a > 10);
        check_true("Phase A GPIO gclk active", gclk_gpio_toggle_a > 10);

        check_true("Phase B UART gclk stopped", gclk_uart_toggle_b < 3);
        check_true("Phase B GPIO gclk stopped", gclk_gpio_toggle_b < 3);

        check_true("Phase C UART remains gated", gclk_uart_toggle_c < 3);
        check_true("Phase C GPIO gclk resumes", gclk_gpio_toggle_c > 10);

        check_true("Phase A foreground GPIO toggles", gpio_toggle_a > 5);
        check_true("Phase B foreground GPIO pauses", gpio_toggle_b < 3);
        check_true("Phase C foreground GPIO resumes", gpio_toggle_c > 5);

        if (fail_count != 0) begin
            $display("PHASE3_FW_CLOCK_GATING: FAIL (%0d checks failed)", fail_count);
            $fatal(1);
        end else begin
            $display("PHASE3_FW_CLOCK_GATING: PASS");
        end

        $finish;
    end
endmodule
