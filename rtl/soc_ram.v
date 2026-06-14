`timescale 1ns/1ps

// ============================================================================
// Module: soc_ram (Phiên bản Hardening / Inferred SRAM)
// Mô tả: Bộ nhớ RAM nội bộ tương thích quy trình tổng hợp Standard Cell ASIC.
// Đặc điểm thiết kế (ASIC-ready):
// 1. Không dùng tín hiệu Reset cho mảng nhớ (Tránh bùng nổ diện tích Area).
// 2. Sử dụng Đọc đồng bộ - Synchronous Read (Tránh Timing Violation do MUX khổng lồ).
// 3. Hỗ trợ ghi theo byte (Byte-Enable wstrb) tiêu chuẩn RISC-V.
// ============================================================================
module soc_ram #(
    parameter ADDR_WIDTH = 14,
    parameter INIT_ZERO  = 1
) (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output wire [31:0] rdata
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    // ------------------------------------------------------------------------
    // MẢNG BỘ NHỚ CỐT LÕI (Memory Array)
    // Công cụ tổng hợp sẽ map mảng này thành các D-FlipFlop / Latch 
    // kết hợp với Clock Gating cấp độ thanh ghi (nếu công cụ hỗ trợ).
    // ------------------------------------------------------------------------
    reg [31:0] mem [0:DEPTH-1];
    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2];

    // ------------------------------------------------------------------------
    // THANH GHI ĐẦU RA ĐỒNG BỘ (Synchronous Outputs)
    // Bắt buộc phải có để quá trình Hardening đạt được Timing Closure.
    // ------------------------------------------------------------------------
    reg        ready_reg;
    reg [31:0] rdata_reg;
    reg        req_seen;

    assign ready = ready_reg;
    assign rdata = rdata_reg;

    always @(posedge clk) begin
        if (!resetn) begin
            ready_reg <= 1'b0;
            rdata_reg <= 32'h0;
            req_seen <= 1'b0;
        end else begin
            ready_reg <= 1'b0;

            // Clear burst-state once master deasserts valid.
            if (!valid)
                req_seen <= 1'b0;

            // Execute exactly once for each contiguous valid burst.
            if (valid && !req_seen) begin
                req_seen <= 1'b1;
                ready_reg <= 1'b1;
                if (|wstrb) begin
                    if (wstrb[0]) mem[word_addr][7:0]   <= wdata[7:0];
                    if (wstrb[1]) mem[word_addr][15:8]  <= wdata[15:8];
                    if (wstrb[2]) mem[word_addr][23:16] <= wdata[23:16];
                    if (wstrb[3]) mem[word_addr][31:24] <= wdata[31:24];
                end else begin
                    rdata_reg <= mem[word_addr];
                end
            end
        end
    end

    // ------------------------------------------------------------------------
    // KHỞI TẠO MÔ PHỎNG (Simulation Only)
    // Công cụ tổng hợp ASIC sẽ tự động bỏ qua khối initial này, 
    // đảm bảo không sinh ra mạng lưới dây Reset khổng lồ đi vào mảng mem.
    // ------------------------------------------------------------------------
    integer i;
    initial begin
        if (INIT_ZERO) begin
            for (i = 0; i < DEPTH; i = i + 1)
                mem[i] = 32'h0000_0000;
        end
    end

endmodule