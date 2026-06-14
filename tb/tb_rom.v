`timescale 1ns/1ps

// ============================================================================
// Module: tb_rom (Self-checking testbench for soc_rom with proper handshake)
// Mô tả: Testbench tự động sử dụng task bus_read để handshake an toàn với ready,
// tương thích hoàn hảo với giao thức 1-cycle pulse của ROM.
// ============================================================================
module tb_rom;
    reg clk;
    reg valid;
    reg [31:0] addr;
    wire ready;
    wire [31:0] rdata;

    soc_rom #(
        .ADDR_WIDTH(8),
        .INIT_NOP(1)
    ) dut (
        .clk(clk),
        .valid(valid),
        .addr(addr),
        .ready(ready),
        .rdata(rdata)
    );

    always #10 clk = ~clk;

    // ========================================================================
    // TASK: Đọc dữ liệu từ ROM (Có handshake chờ ready)
    // ========================================================================
    task bus_read;
        input  [31:0] r_addr;
        output [31:0] r_data;
        begin
            @(negedge clk);
            valid = 1'b1;
            addr  = r_addr;
            wait(ready === 1'b1);  // Safe wait for ready pulse
            #1;
            r_data = rdata;        // Capture data after ready asserts
            @(negedge clk);
            valid = 1'b0;
        end
    endtask

    // ========================================================================
    // KỊCH BẢN KIỂM TRA TỰ ĐỘNG
    // ========================================================================
    reg [31:0] rd_val;

    initial begin
        clk = 1'b0;
        valid = 1'b0;
        addr = 32'h0;

        $dumpfile("results/phase3/tb_rom.vcd");
        $dumpvars(0, tb_rom);

        repeat (2) @(posedge clk);

        $display("=================================================");
        $display("BAT DAU MO PHONG SOC_ROM (SYNCHRONOUS READ)");
        $display("=================================================");

        // Test 1: Read word 0 - Should get NOPs by default
        bus_read(32'h0000_0000, rd_val);
        if (rd_val !== 32'h0000_0013) begin
            $display("[FAIL] ROM default word mismatch at addr 0: 0x%08x (expected 0x0000_0013)", rd_val);
            $fatal(1);
        end
        $display("[PASS] Read addr 0x00: 0x%08x", rd_val);

        // Test 2: Read another address
        bus_read(32'h0000_0010, rd_val);
        if (rd_val !== 32'h0000_0013) begin
            $display("[FAIL] ROM default word mismatch at addr 0x10: 0x%08x (expected 0x0000_0013)", rd_val);
            $fatal(1);
        end
        $display("[PASS] Read addr 0x10: 0x%08x", rd_val);

        // Test 3: Rapid reads to verify no ready glitch
        bus_read(32'h0000_0020, rd_val);
        if (rd_val !== 32'h0000_0013) begin
            $display("[FAIL] ROM rapid read failed at addr 0x20");
            $fatal(1);
        end
        $display("[PASS] Read addr 0x20: 0x%08x", rd_val);

        repeat (2) @(posedge clk);
        
        // Final verification: ready should be low when valid is low
        if (ready !== 1'b0) begin
            $display("[FAIL] ROM ready should be low after all requests complete");
            $fatal(1);
        end

        $display("=================================================");
        $display("ROM TEST: ALL TESTS PASSED");
        $display("=================================================");
        $finish;
    end
endmodule
