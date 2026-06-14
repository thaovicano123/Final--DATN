`timescale 1ns/1ps

// ============================================================================
// Module: tb_decoder (Address Decoder Testbench)
// Mô tả: Testbench kiểm chứng logic dồn kênh địa chỉ (bus decoder)
// và Deadlock Prevention với sel_none signal
// ============================================================================
module tb_decoder;
    reg [31:0] addr;
    wire sel_rom;
    wire sel_ram;
    wire sel_uart;
    wire sel_gpio;
    wire sel_cmu;
    wire sel_none;
    
    bus_decoder u_bus_decoder (
        .addr(addr),
        .sel_rom(sel_rom),
        .sel_ram(sel_ram),
        .sel_uart(sel_uart),
        .sel_gpio(sel_gpio),
        .sel_cmu(sel_cmu),
        .sel_none(sel_none)
    );
    
    initial begin
        $dumpfile("results/phase3/tb_decoder.vcd");
        $dumpvars(0, tb_decoder);
        
        $display("=================================================");
        $display("BAT DAU MO PHONG ADDRESS DECODER");
        $display("=================================================");
        
        // Test 1: ROM address range (0x0000_0000)
        $display("\nTest 1: ROM address range");
        addr = 32'h00000000;
        #1;
        
        if (sel_rom && !sel_ram && !sel_uart && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] ROM selected for address 0x%08x", addr);
        end else begin
            $display("[FAIL] ROM selection failed for address 0x%08x", addr);
            $fatal(1);
        end
        
        // Test 2: RAM address range (0x1000_0000)
        $display("\nTest 2: RAM address range");
        addr = 32'h10000000;
        #1;
        
        if (!sel_rom && sel_ram && !sel_uart && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] RAM selected for address 0x%08x", addr);
        end else begin
            $display("[FAIL] RAM selection failed for address 0x%08x", addr);
            $fatal(1);
        end
        
        // Test 3: UART address (0x2000_0000)
        $display("\nTest 3: UART address");
        addr = 32'h20000000;
        #1;
        
        if (!sel_rom && !sel_ram && sel_uart && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] UART selected for address 0x%08x", addr);
        end else begin
            $display("[FAIL] UART selection failed for address 0x%08x", addr);
            $fatal(1);
        end
        
        // Test 4: UART address offset (0x2000_0004)
        $display("\nTest 4: UART address offset");
        addr = 32'h20000004;
        #1;
        
        if (!sel_rom && !sel_ram && sel_uart && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] UART selected for offset address 0x%08x", addr);
        end else begin
            $display("[FAIL] UART selection failed for offset address 0x%08x", addr);
            $fatal(1);
        end
        
        // Test 5: GPIO address (0x2000_2000)
        $display("\nTest 5: GPIO address");
        addr = 32'h20002000;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] GPIO selected for address 0x%08x", addr);
        end else begin
            $display("[FAIL] GPIO selection failed for address 0x%08x", addr);
            $fatal(1);
        end
        
        // Test 6: CMU address (0x2000_3000)
        $display("\nTest 6: CMU address");
        addr = 32'h20003000;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && !sel_gpio && sel_cmu && !sel_none) begin
            $display("[PASS] CMU selected for address 0x%08x", addr);
        end else begin
            $display("[FAIL] CMU selection failed for address 0x%08x", addr);
            $fatal(1);
        end
        
        // Test 7: Unknown address - Deadlock Prevention (sel_none)
        $display("\nTest 7: Unknown address - Deadlock Prevention");
        addr = 32'h30000000;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && !sel_gpio && !sel_cmu && sel_none) begin
            $display("[PASS] sel_none asserted for unmapped address 0x%08x", addr);
        end else begin
            $display("[FAIL] Deadlock prevention failed for address 0x%08x", addr);
            $fatal(1);
        end
        
        // Test 8: ROM upper boundary (0x0000_FFFF)
        $display("\nTest 8: ROM upper boundary");
        addr = 32'h0000FFFF;
        #1;
        
        if (sel_rom && !sel_ram && !sel_uart && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] ROM upper bound correctly selects ROM");
        end else begin
            $display("[FAIL] ROM upper bound test failed");
            $fatal(1);
        end
        
        // Test 9: RAM offset address (0x1000_0010)
        $display("\nTest 9: RAM offset address");
        addr = 32'h10000010;
        #1;
        
        if (!sel_rom && sel_ram && !sel_uart && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] RAM offset address correctly selects RAM");
        end else begin
            $display("[FAIL] RAM offset test failed");
            $fatal(1);
        end
        
        // Test 10: GPIO offset (0x2000_2004)
        $display("\nTest 10: GPIO offset address");
        addr = 32'h20002004;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] GPIO offset correctly selects GPIO");
        end else begin
            $display("[FAIL] GPIO offset test failed");
            $fatal(1);
        end
        
        // Test 11: UART upper boundary (0x2000_0FFF)
        $display("\nTest 11: UART upper boundary");
        addr = 32'h20000FFF;
        #1;
        
        if (!sel_rom && !sel_ram && sel_uart && !sel_gpio && !sel_cmu && !sel_none) begin
            $display("[PASS] UART upper bound correctly selects UART");
        end else begin
            $display("[FAIL] UART upper bound test failed");
            $fatal(1);
        end
        
        // Test 12: Gap address between UART and GPIO (0x2000_1000)
        $display("\nTest 12: Gap address (Deadlock Prevention)");
        addr = 32'h20001000;
        #1;
        
        if (!sel_rom && !sel_ram && !sel_uart && !sel_gpio && !sel_cmu && sel_none) begin
            $display("[PASS] Gap address correctly triggers sel_none");
        end else begin
            $display("[FAIL] Gap address handling failed");
            $fatal(1);
        end
        
        $display("\n=================================================");
        $display("DECODER TEST: ALL TESTS PASSED");
        $display("=================================================");
        $finish;
    end
endmodule