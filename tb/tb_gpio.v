`timescale 1ns/1ps

module tb_gpio;
    reg clk;
    reg resetn;
    reg valid;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg [31:0] gpio_in;
    wire ready;
    wire [31:0] rdata;
    wire [31:0] gpio_out;

    reg [31:0] rd;
    
    gpio_mmio u_gpio (
        .clk(clk),
        .resetn(resetn),
        .valid(valid),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .ready(ready),
        .rdata(rdata),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out)
    );

    always #5 clk = ~clk;

    // Updated bus tasks for req_seen protocol (wait for ready signal)
    task bus_write;
        input [31:0] wr_addr;
        input [31:0] wr_data;
        input [3:0] wr_be;
        begin
            @(negedge clk);
            valid = 1'b1;
            addr = wr_addr;
            wdata = wr_data;
            wstrb = wr_be;
            @(posedge clk);
            while (!ready) @(posedge clk);
            @(negedge clk);
            valid = 1'b0;
            wstrb = 4'h0;
            @(posedge clk);
        end
    endtask

    task bus_read;
        input [31:0] rd_addr;
        output [31:0] rd_data;
        begin
            @(negedge clk);
            valid = 1'b1;
            addr = rd_addr;
            wstrb = 4'h0;
            @(posedge clk);
            while (!ready) @(posedge clk);
            rd_data = rdata;
            @(negedge clk);
            valid = 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        valid = 1'b0;
        addr = 32'h0;
        wdata = 32'h0;
        wstrb = 4'h0;
        gpio_in = 32'h00000000;

        $dumpfile("results/phase3/tb_gpio.vcd");
        $dumpvars(0, tb_gpio);

        repeat (10) @(posedge clk);
        resetn = 1'b1;
        repeat (10) @(posedge clk);

        if (gpio_out !== 32'h00000000) begin
            $display("[FAIL] GPIO output should be 0 after reset");
            $fatal(1);
        end

        // Configure direction and data output
        bus_write(32'h0000_0008, 32'h0000_00FF, 4'hF); // DIR
        bus_write(32'h0000_0000, 32'h0000_005A, 4'hF); // DATA_OUT
        #1;
        if (gpio_out !== 32'h0000_005A) begin
            $display("[FAIL] GPIO output mismatch after DATA/DIR write: 0x%08x", gpio_out);
            $fatal(1);
        end

        // Readback DATA_OUT and DIR
        bus_read(32'h0000_0000, rd);
        if (rd !== 32'h0000_005A) begin
            $display("[FAIL] DATA_OUT readback mismatch: 0x%08x", rd);
            $fatal(1);
        end

        bus_read(32'h0000_0008, rd);
        if (rd !== 32'h0000_00FF) begin
            $display("[FAIL] DIR readback mismatch: 0x%08x", rd);
            $fatal(1);
        end

        // Toggle lower nibble via TOGGLE register
        bus_write(32'h0000_000C, 32'h0000_000F, 4'hF);
        #1;
        if (gpio_out !== 32'h0000_0055) begin
            $display("[FAIL] GPIO toggle mismatch: 0x%08x", gpio_out);
            $fatal(1);
        end

        // Input register readback
        gpio_in = 32'hA5A5_5A5A;
        bus_read(32'h0000_0004, rd);
        if (rd !== 32'hA5A5_5A5A) begin
            $display("[FAIL] GPIO input readback mismatch: 0x%08x", rd);
            $fatal(1);
        end

        // Byte enable write: update only byte0 of DATA_OUT
        bus_write(32'h0000_0000, 32'h0000_00AA, 4'h1);
        bus_read(32'h0000_0000, rd);
        if (rd[7:0] !== 8'hAA) begin
            $display("[FAIL] DATA_OUT byte write mismatch: 0x%08x", rd);
            $fatal(1);
        end

        $display("\nGPIO TEST: ALL TESTS PASSED");
        $finish;
    end
endmodule