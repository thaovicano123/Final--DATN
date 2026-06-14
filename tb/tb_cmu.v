`timescale 1ns/1ps

module tb_cmu;
    reg clk;
    reg resetn;
    reg valid;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    wire ready;
    wire [31:0] rdata;
    wire gclk_uart;
    wire gclk_gpio;
    wire [1:0] clk_en_state;
    
    integer uart_toggle_count;
    integer gpio_toggle_count;
    
    // Task for safe CMU register write with handshake
    task cmu_write;
        input [31:0] w_data;
        input [3:0]  w_be;
        begin
            @(negedge clk);
            valid = 1'b1;
            addr  = 32'h20003000;
            wdata = w_data;
            wstrb = w_be;
            wait(ready === 1'b1);
            @(negedge clk);
            valid = 1'b0;
            wstrb = 4'h0;
        end
    endtask
    
    // Task for safe CMU register read with handshake
    task cmu_read;
        output [31:0] r_data;
        begin
            @(negedge clk);
            valid = 1'b1;
            addr  = 32'h20003000;
            wstrb = 4'h0;
            wait(ready === 1'b1);
            #1;
            r_data = rdata;
            @(negedge clk);
            valid = 1'b0;
        end
    endtask
    
    cmu u_cmu (
        .clk(clk),
        .resetn(resetn),
        .valid(valid),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .ready(ready),
        .rdata(rdata),
        .gclk_uart(gclk_uart),
        .gclk_gpio(gclk_gpio),
        .clk_en_state(clk_en_state)
    );
    
    // Toggle counters for clock gating verification
    always @(posedge gclk_uart) begin
        if (resetn) uart_toggle_count = uart_toggle_count + 1;
    end
    
    always @(posedge gclk_gpio) begin
        if (resetn) gpio_toggle_count = gpio_toggle_count + 1;
    end
    
    reg [31:0] rd_val;

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        valid = 1'b0;
        addr = 32'h0;
        wdata = 32'h0;
        wstrb = 4'h0;
        uart_toggle_count = 0;
        gpio_toggle_count = 0;
        
        $dumpfile("results/phase3/tb_cmu.vcd");
        $dumpvars(0, tb_cmu);
        
        // Initialize
        repeat (10) @(posedge clk);
        resetn = 1'b1;
        repeat (10) @(posedge clk);
        
        $display("=================================================");
        $display("BAT DAU MO PHONG CMU (SYNCHRONOUS HANDSHAKE)");
        $display("=================================================");
        
        // Test 1: Check reset state
        $display("\nTest 1: Checking reset state");
        if (clk_en_state !== 2'b11) begin
            $display("[FAIL] Clock enables should be 11 after reset");
            $fatal(1);
        end else begin
            $display("[PASS] Clock enables are 11 after reset");
        end
        
        // Test 2: Test reading clock enable register
        $display("\nTest 2: Test reading clock enable register");
        cmu_read(rd_val);
        if (rd_val[1:0] === 2'b11) begin
            $display("[PASS] Read clock enable register: 0x%08x", rd_val);
        end else begin
            $display("[FAIL] Expected 0x00000003, got 0x%08x", rd_val);
            $fatal(1);
        end
        
        repeat (5) @(posedge clk);
        
        // Test 3: Test enabling all clocks
        $display("\nTest 3: Test enabling all clocks");
        cmu_write(32'h00000003, 4'hF);
        repeat (10) @(posedge clk);
        
        if (clk_en_state === 2'b11) begin
            $display("[PASS] All clocks enabled (11)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        repeat (20) @(posedge clk);  // Let clocks toggle
        
        // Check toggle counts
        if (uart_toggle_count > 0 && gpio_toggle_count > 0) begin
            $display("[PASS] All clocks are toggling when enabled");
        end else begin
            $display("[FAIL] Some clocks are not toggling (UART: %d, GPIO: %d)", uart_toggle_count, gpio_toggle_count);
            $fatal(1);
        end
        
        // Test 4: Test disabling all clocks
        $display("\nTest 4: Test disabling all clocks");
        uart_toggle_count = 0;
        gpio_toggle_count = 0;
        
        cmu_write(32'h00000000, 4'hF);
        repeat (10) @(posedge clk);
        
        if (clk_en_state === 2'b00) begin
            $display("[PASS] All clocks disabled (00)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        repeat (20) @(posedge clk);  // Check if clocks stop
        
        // Check toggle counts (should be minimal)
        if (uart_toggle_count < 3 && gpio_toggle_count < 3) begin
            $display("[PASS] All clocks stopped when disabled");
        end else begin
            $display("[FAIL] Clocks are still toggling (UART: %d, GPIO: %d)", uart_toggle_count, gpio_toggle_count);
            $fatal(1);
        end
        
        // Test 5: Test enabling only GPIO
        $display("\nTest 5: Test enabling only GPIO");
        uart_toggle_count = 0;
        gpio_toggle_count = 0;
        
        cmu_write(32'h00000002, 4'hF);
        repeat (10) @(posedge clk);
        
        if (clk_en_state === 2'b10) begin
            $display("[PASS] Only GPIO enabled (10)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        repeat (20) @(posedge clk);
        
        // Check which clocks are toggling
        if (uart_toggle_count < 3 && gpio_toggle_count > 0) begin
            $display("[PASS] Only GPIO clock is toggling");
        end else begin
            $display("[FAIL] GPIO clock toggle count: %d, UART: %d", gpio_toggle_count, uart_toggle_count);
            $fatal(1);
        end
        
        // Test 6: Test enabling only UART
        $display("\nTest 6: Test enabling only UART");
        uart_toggle_count = 0;
        gpio_toggle_count = 0;
        
        cmu_write(32'h00000001, 4'hF);
        repeat (10) @(posedge clk);
        
        if (clk_en_state === 2'b01) begin
            $display("[PASS] Only UART enabled (01)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        repeat (20) @(posedge clk);
        
        if (uart_toggle_count > 0 && gpio_toggle_count < 3) begin
            $display("[PASS] Only UART clock is toggling");
        end else begin
            $display("[FAIL] UART clock toggle count: %d, GPIO: %d", uart_toggle_count, gpio_toggle_count);
            $fatal(1);
        end
        
        // Test 7: Test reading back
        $display("\nTest 7: Test reading back");
        cmu_read(rd_val);
        if (rd_val[1:0] === 2'b01) begin
            $display("[PASS] Read back correct clock enable state: 0x%08x", rd_val);
        end else begin
            $display("[FAIL] Expected 0x00000001, got 0x%08x", rd_val);
            $fatal(1);
        end
        
        repeat (5) @(posedge clk);
        
        // Test 8: Test combined UART + GPIO
        $display("\nTest 8: Test combined UART + GPIO");
        cmu_write(32'h00000003, 4'hF);
        repeat (10) @(posedge clk);
        
        if (clk_en_state === 2'b11) begin
            $display("[PASS] Both UART and GPIO enabled (11)");
        end else begin
            $display("[FAIL] Clock enable state: %b", clk_en_state);
            $fatal(1);
        end
        
        repeat (5) @(posedge clk);
        
        $display("\n=================================================");
        $display("CMU TEST: ALL TESTS PASSED");
        $display("=================================================");
        $finish;
    end
    
    // Clock for simulation
    always #5 clk = ~clk;
endmodule