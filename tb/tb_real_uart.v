`timescale 1ns / 1ps

// ============================================================================
// Module: tb_real_uart_mmio
// Mô tả: Testbench kiểm tra module real_uart_mmio (Phiên bản Low-Power có IRQ)
// ============================================================================
module tb_real_uart_mmio();

    // ------------------------------------------------------------------------
    // Khai báo tín hiệu
    // ------------------------------------------------------------------------
    reg         clk;
    reg         resetn;
    reg         valid;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    wire        ready;
    wire [31:0] rdata;
    
    wire        uart_tx;
    reg         uart_rx;
    wire        irq_rx;

    // ------------------------------------------------------------------------
    // Cấu hình tham số mô phỏng
    // ------------------------------------------------------------------------
    // Để mô phỏng chạy nhanh, ta ghi đè CLK_DIV bằng một số nhỏ (ví dụ 10) 
    // thay vì 434. Hệ số chia 10 nghĩa là 1 bit baud sẽ kéo dài 10 chu kỳ clock.
    parameter CLK_DIV = 10;
    parameter CLK_PERIOD = 20; // 50MHz = 20ns
    parameter BAUD_PERIOD = CLK_PERIOD * CLK_DIV;

    // ------------------------------------------------------------------------
    // Khởi tạo Module (Instantiate)
    // ------------------------------------------------------------------------
    real_uart_mmio #(
        .CLK_DIV(CLK_DIV)
    ) uut (
        .clk(clk),
        .resetn(resetn),
        .valid(valid),
        .addr(addr),
        .wdata(wdata),
        .wstrb(wstrb),
        .ready(ready),
        .rdata(rdata),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx),
        .irq_rx(irq_rx)
    );

    // ------------------------------------------------------------------------
    // Tạo xung nhịp Clock
    // ------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // ------------------------------------------------------------------------
    // Các Task hỗ trợ mô phỏng thao tác của CPU PicoRV32
    // ------------------------------------------------------------------------
    
    // Task: Ghi dữ liệu vào thanh ghi qua MMIO (req_seen compatible)
    task write_mmio(input [31:0] t_addr, input [31:0] t_data);
        begin
            @(negedge clk);
            valid = 1'b1;
            wstrb = 4'hF;
            addr  = t_addr;
            wdata = t_data;
            @(posedge clk);
            while (!ready) @(posedge clk);
            @(negedge clk);
            valid = 1'b0;
            wstrb = 4'h0;
        end
    endtask

    // Task: Đọc dữ liệu từ thanh ghi qua MMIO (req_seen compatible)
    task read_mmio(input [31:0] t_addr, output [31:0] t_data);
        begin
            @(negedge clk);
            valid = 1'b1;
            wstrb = 4'h0;
            addr  = t_addr;
            @(posedge clk);
            while (!ready) @(posedge clk);
            t_data = rdata;  // Sample rdata same edge as ready
            @(negedge clk);
            valid = 1'b0;
        end
    endtask

    // ------------------------------------------------------------------------
    // Task hỗ trợ mô phỏng PC gửi dữ liệu vào chân RX của chip
    // ------------------------------------------------------------------------
    task pc_send_byte(input [7:0] t_byte);
        integer i;
        begin
            $display("[%0t] PC bat dau gui byte: 8'h%h", $time, t_byte);
            // 1. Gửi Start Bit (Mức 0)
            uart_rx = 1'b0;
            #(BAUD_PERIOD);
            
            // 2. Gửi 8 Data Bits (LSB trước)
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = t_byte[i];
                #(BAUD_PERIOD);
            end
            
            // 3. Gửi Stop Bit (Mức 1)
            uart_rx = 1'b1;
            #(BAUD_PERIOD);
            $display("[%0t] PC da gui xong.", $time);
        end
    endtask

    // ------------------------------------------------------------------------
    // KỊCH BẢN KIỂM TRA CHÍNH (TEST SCENARIO)
    // ------------------------------------------------------------------------
    reg [31:0] read_val;

    initial begin
        // Khởi tạo trạng thái ban đầu
        resetn  = 1'b0;
        valid   = 1'b0;
        addr    = 32'h0;
        wdata   = 32'h0;
        wstrb   = 4'h0;
        uart_rx = 1'b1; // Trạng thái nghỉ của UART là mức Cao (1)

        $display("=================================================");
        $display("BAT DAU MO PHONG UART LOW-POWER");
        $display("=================================================");

        // Giải phóng Reset
        #(CLK_PERIOD * 5);
        resetn = 1'b1;
        #(CLK_PERIOD * 2);

        // Waveform dump: dump the whole testbench module (avoid duplicate entries)
        $dumpfile("results/phase3/tb_real_uart.vcd");
        $dumpvars(0, tb_real_uart_mmio);

        // -------------------------------------------------------
        // TEST 1: Truyền dữ liệu ra (TX)
        // -------------------------------------------------------
        $display("\n--- TEST 1: CPU gui du lieu ra chan TX ---");
        // CPU ghi giá trị 8'hA5 (10100101) vào địa chỉ 0x0
        write_mmio(32'h0000_0000, 32'h0000_00A5);
        
        // Đọc thanh ghi trạng thái (0x4) xem có báo bận không
        read_mmio(32'h0000_0004, read_val);
        if (read_val[0] == 0) $display("[%0t] TX dang ban (Chinh xac!)", $time);
        
        // Chờ thời gian để UART truyền xong 10 bit (Start + 8 Data + Stop)
        #(BAUD_PERIOD * 12); 
        
        // Đọc lại trạng thái xem đã rảnh chưa
        read_mmio(32'h0000_0004, read_val);
        if (read_val[0] == 1) $display("[%0t] TX da ranh (Chinh xac!)", $time);


        // -------------------------------------------------------
        // TEST 2: Nhận dữ liệu (RX) & Cờ Ngắt (IRQ)
        // -------------------------------------------------------
        $display("\n--- TEST 2: PC gui du lieu vao chan RX & Kiem tra IRQ ---");
        
        // Kiểm tra chắc chắn irq_rx ban đầu đang ở mức 0
        if (irq_rx == 0) $display("[%0t] IRQ ban dau dang tat (Chinh xac!)", $time);

        // PC gửi byte 8'h5A (01011010)
        pc_send_byte(8'h5A);

        // Đợi một chút để mạch Synchronizer và State Machine cập nhật
        #(CLK_PERIOD * 5);

        // Kiểm tra xem cờ ngắt IRQ đã được dựng lên chưa
        if (irq_rx == 1'b1) 
            $display("[%0t] THANG CONG: Co Ngat (irq_rx) da duoc dung len!", $time);
        else 
            $display("[%0t] LOI: Co Ngat (irq_rx) khong hoat dong!", $time);

        // -------------------------------------------------------
        // TEST 3: Đọc dữ liệu & Tự động xóa ngắt
        // -------------------------------------------------------
        $display("\n--- TEST 3: CPU doc du lieu tu 0x8 & Xoa ngat ---");
        // CPU thức dậy (do có IRQ) và thực hiện đọc địa chỉ 0x8
        read_mmio(32'h0000_0008, read_val);
        $display("[%0t] CPU doc duoc tu 0x8 gia tri: 32'h%h", $time, read_val);
        
        if (read_val[7:0] == 8'h5A)
            $display("[%0t] THANG CONG: Byte nhan duoc dung la 8'h5A!", $time);
        else
            $display("[%0t] LOI: Du lieu bi sai!", $time);

        // Kiểm tra xem irq_rx đã tự động xóa về 0 sau khi đọc chưa
        #(CLK_PERIOD * 2);
        if (irq_rx == 1'b0)
            $display("[%0t] THANG CONG: Co ngat da tu dong xoa (irq_rx = 0)!", $time);
        else
            $display("[%0t] LOI: Co ngat van chua duoc xoa!", $time);


        $display("\n=================================================");
        $display("MO PHONG HOAN TAT!");
        $display("=================================================");
        $finish;
    end

endmodule