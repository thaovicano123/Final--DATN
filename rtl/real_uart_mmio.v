`timescale 1ns / 1ps

// ============================================================================
// Module: real_uart_mmio (Registered Output, req_seen Handshake, Low-Power IRQ)
// Mô tả: UART synthesizable với giao thức bus nhất quán toàn hệ thống.
// Đặc điểm:
//   1. req_seen pulse protocol — đồng nhất với RAM/ROM/CMU/GPIO.
//   2. Registered rdata output — tránh combinational path dài qua bus MUX.
//   3. TX: Thanh ghi dịch 10-bit (Start + 8 Data + Stop).
//   4. RX: 2-stage synchronizer chống metastability, sampling chính giữa bit.
//   5. IRQ: irq_rx assert khi có dữ liệu mới, auto-clear khi CPU đọc RX.
// ============================================================================
module real_uart_mmio #(
    parameter CLK_DIV = 434  // 50MHz / 115200 ≈ 434
) (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output wire [31:0] rdata,

    output reg         uart_tx,
    input  wire        uart_rx,

    // ĐẦU RA NGẮT
    output wire        irq_rx
);

    // ------------------------------------------------------------------------
    // Bus Handshake — req_seen protocol (nhất quán toàn hệ thống)
    // ------------------------------------------------------------------------
    reg        ready_reg;
    reg [31:0] rdata_reg;
    reg        req_seen;

    wire [3:0] reg_word = addr[5:2];

    assign ready = ready_reg;
    assign rdata = rdata_reg;

    // ------------------------------------------------------------------------
    // Mạch phát (TX Logic) & Thanh ghi Điều khiển
    // ------------------------------------------------------------------------
    reg [31:0] tx_clk_cnt;
    reg [3:0]  tx_bit_cnt;
    reg [9:0]  tx_shift_reg; // 1 bit Start (0), 8 bit Data, 1 bit Stop (1)
    reg        tx_busy;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            tx_clk_cnt   <= 0;
            tx_bit_cnt   <= 0;
            tx_shift_reg <= 10'h3FF; // Tất cả là 1 (Idle)
            tx_busy      <= 1'b0;
            uart_tx      <= 1'b1;
        end else begin
            if (tx_busy) begin
                // Đang truyền dữ liệu
                if (tx_clk_cnt == CLK_DIV - 1) begin
                    tx_clk_cnt <= 0;
                    uart_tx    <= tx_shift_reg[0]; // Đẩy bit thấp nhất ra chân TX
                    tx_shift_reg <= {1'b1, tx_shift_reg[9:1]}; // Dịch phải

                    if (tx_bit_cnt == 9) begin
                        tx_busy <= 1'b0; // Đã truyền xong
                    end else begin
                        tx_bit_cnt <= tx_bit_cnt + 1;
                    end
                end else begin
                    tx_clk_cnt <= tx_clk_cnt + 1;
                end
            end else begin
                // Trạng thái nghỉ (Idle)
                uart_tx <= 1'b1;

                // CPU ra lệnh Ghi — chỉ kích hoạt 1 lần per transaction (req_seen)
                if (valid && (|wstrb) && !req_seen) begin
                    case (reg_word)
                        4'h0: begin // Ghi vào 0x0 -> Kích hoạt truyền TX
                            tx_shift_reg <= {1'b1, wdata[7:0], 1'b0};
                            tx_clk_cnt   <= 0;
                            tx_bit_cnt   <= 0;
                            tx_busy      <= 1'b1;
                        end
                        default: ;
                    endcase
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // Mạch nhận (RX Logic)
    // ------------------------------------------------------------------------
    reg [31:0] rx_clk_cnt;
    reg [3:0]  rx_bit_cnt;
    reg [7:0]  rx_data_reg;
    reg        rx_busy;
    reg        rx_valid_flag; // Cờ báo hiệu có dữ liệu mới

    // Synchronizer để chống Metastability cho chân uart_rx
    reg rx_sync_1, rx_sync_2;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) {rx_sync_2, rx_sync_1} <= 2'b11;
        else         {rx_sync_2, rx_sync_1} <= {rx_sync_1, uart_rx};
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            rx_clk_cnt    <= 0;
            rx_bit_cnt    <= 0;
            rx_data_reg   <= 8'h00;
            rx_busy       <= 1'b0;
            rx_valid_flag <= 1'b0;
        end else begin
            // TỰ ĐỘNG XÓA NGẮT: Khi CPU đọc thanh ghi RX (địa chỉ 0x8)
            // Chỉ xóa 1 lần per transaction nhờ req_seen guard
            if (valid && !(|wstrb) && !req_seen && reg_word == 4'h2) begin
                rx_valid_flag <= 1'b0;
            end

            if (rx_busy) begin
                if (rx_clk_cnt == CLK_DIV - 1) begin
                    rx_clk_cnt <= 0;
                    if (rx_bit_cnt == 8) begin
                        // Nhận xong Bit Stop
                        rx_busy <= 1'b0;
                        rx_valid_flag <= 1'b1; // Dựng cờ Valid (kích hoạt IRQ)
                    end else begin
                        // Lấy mẫu 8 bit Data
                        rx_data_reg <= {rx_sync_2, rx_data_reg[7:1]};
                        rx_bit_cnt  <= rx_bit_cnt + 1;
                    end
                end else begin
                    rx_clk_cnt <= rx_clk_cnt + 1;
                end
            end else begin
                // Dò tìm sườn xuống của bit Start
                if (rx_sync_2 == 1'b0) begin
                    if (rx_clk_cnt == (CLK_DIV / 2) - 1) begin
                        if (rx_sync_2 == 1'b0) begin
                            rx_clk_cnt <= 0;
                            rx_bit_cnt <= 0;
                            rx_busy    <= 1'b1;
                        end else begin
                            rx_clk_cnt <= 0; // Nhiễu, bỏ qua
                        end
                    end else begin
                        rx_clk_cnt <= rx_clk_cnt + 1;
                    end
                end else begin
                    rx_clk_cnt <= 0;
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // CƠ CHẾ SINH NGẮT (IRQ GENERATION)
    // ------------------------------------------------------------------------
    assign irq_rx = rx_valid_flag;

    // ------------------------------------------------------------------------
    // Bus Handshake + Registered Read Data (req_seen protocol)
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            ready_reg <= 1'b0;
            rdata_reg <= 32'h0000_0000;
            req_seen  <= 1'b0;
        end else begin
            ready_reg <= 1'b0;  // Default: ready not asserted

            // Clear burst state once master deasserts valid
            if (!valid)
                req_seen <= 1'b0;

            // Execute exactly once per valid burst
            if (valid && !req_seen) begin
                req_seen  <= 1'b1;
                ready_reg <= 1'b1;  // Assert ready for exactly 1 cycle

                // Registered read data output
                if (!(|wstrb)) begin
                    case (reg_word)
                        4'h0: rdata_reg <= 32'h0000_0000; // TX register (write-only)
                        4'h1: rdata_reg <= {31'h0, !tx_busy}; // Status
                        4'h2: rdata_reg <= {rx_valid_flag, 23'h0, rx_data_reg}; // RX data
                        default: rdata_reg <= 32'h0000_0000;
                    endcase
                end
            end
        end
    end

endmodule