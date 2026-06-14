`timescale 1ns/1ps

// ============================================================================
// Module: tb_ram
// Mô tả: Testbench tự động (Self-checking) cho bộ nhớ soc_ram phiên bản Đồng bộ
// Tính năng: Sử dụng Task bus_read/write để tự động handshake với tín hiệu ready,
// tương thích hoàn hảo với độ trễ 1 chu kỳ của bộ nhớ ASIC.
// ============================================================================
module tb_ram;
    reg clk;
    reg resetn;
    reg valid;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] wstrb;
    wire ready;
    wire [31:0] rdata;

    reg [31:0] rd_val;

    // Khởi tạo khối RAM (Phiên bản Hardening / Đọc đồng bộ)
    soc_ram #(
        .ADDR_WIDTH(8),
        .INIT_ZERO(1)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .valid(valid),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .ready(ready),
        .rdata(rdata)
    );

    // Tạo xung clock 50MHz (Chu kỳ 20ns)
    always #10 clk = ~clk;

    // ------------------------------------------------------------------------
    // TASK: Ghi dữ liệu vào RAM (Có handshake chờ ready)
    // ------------------------------------------------------------------------
    task bus_write;
        input [31:0] w_addr;
        input [31:0] w_data;
        input [3:0]  w_be;
        begin
            @(negedge clk);
            valid = 1'b1;
            addr  = w_addr;
            wdata = w_data;
            wstrb = w_be;
            wait(ready === 1'b1);
            @(negedge clk);
            valid = 1'b0;
            wstrb = 4'h0;
        end
    endtask

    // ------------------------------------------------------------------------
    // TASK: Đọc dữ liệu từ RAM (Có handshake chờ ready)
    // ------------------------------------------------------------------------
    task bus_read;
        input  [31:0] r_addr;
        output [31:0] r_data;
        begin
            @(negedge clk);
            valid = 1'b1;
            addr  = r_addr;
            wstrb = 4'h0;
            wait(ready === 1'b1);
            #1;
            r_data = rdata;
            @(negedge clk);
            valid = 1'b0;
        end
    endtask

    // ------------------------------------------------------------------------
    // KỊCH BẢN KIỂM TRA TỰ ĐỘNG
    // ------------------------------------------------------------------------
    initial begin
        // Khởi tạo
        clk = 1'b0;
        resetn = 1'b0;
        valid = 1'b0;
        addr = 32'h0;
        wdata = 32'h0;
        wstrb = 4'h0;

        $dumpfile("results/phase3/tb_ram.vcd");
        $dumpvars(0, tb_ram);

        // Giả lập Reset
        repeat (2) @(posedge clk);
        resetn = 1'b1;
        repeat (2) @(posedge clk);

        $display("=================================================");
        $display("BAT DAU MO PHONG SOC_RAM (SYNCHRONOUS READ)");
        $display("=================================================");

        // 1. Đọc địa chỉ 0 ngay sau khi khởi động (Phải bằng 0)
        bus_read(32'h0000_0000, rd_val);
        if (rd_val !== 32'h0000_0000) begin
            $display("[FAIL] RAM init read mismatch: 0x%08x", rd_val);
            $fatal(1);
        end else begin
            $display("[PASS] RAM init read = 0x00000000");
        end

        // 2. Ghi 1 Word đầy đủ (32-bit) và Đọc lại
        bus_write(32'h0000_0004, 32'hDEAD_BEEF, 4'hF);
        bus_read(32'h0000_0004, rd_val);
        if (rd_val !== 32'hDEAD_BEEF) begin
            $display("[FAIL] RAM full-word write mismatch: 0x%08x", rd_val);
            $fatal(1);
        end else begin
            $display("[PASS] RAM full-word write/read = 0xDEADBEEF");
        end

        // 3. Ghi 1 Byte cục bộ (wstrb = 4'h1) vào đúng word vừa rồi và Đọc lại
        bus_write(32'h0000_0004, 32'h0000_00AA, 4'h1);
        bus_read(32'h0000_0004, rd_val);
        if (rd_val !== 32'hDEAD_BEAA) begin // Byte thấp nhất EF đổi thành AA
            $display("[FAIL] RAM partial write mismatch: 0x%08x", rd_val);
            $fatal(1);
        end else begin
            $display("[PASS] RAM partial byte write/read = 0xDEADBEAA");
        end

        // 4. Kiểm tra trạng thái rơi của cờ ready
        valid = 1'b0;
        @(posedge clk);
        @(posedge clk);
        if (ready !== 1'b0) begin
            $display("[FAIL] RAM ready should follow valid");
            $fatal(1);
        end else begin
            $display("[PASS] RAM ready drops correctly");
        end

        $display("=================================================");
        $display("RAM TEST: ALL TESTS PASSED");
        $display("=================================================");
        $finish;
    end
endmodule