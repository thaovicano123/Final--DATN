`timescale 1ns / 1ps

// ============================================================================
// Module: sky130_sram_wrapper
// Mô tả: Wrapper bọc lấy Hard Macro SRAM sky130_sram_2kbyte_1rw1r_32x512_8 (2KB).
// Chuyển đổi giao thức req_seen của LibreLane SoC sang tín hiệu điều khiển SRAM.
// ============================================================================

module sky130_sram_wrapper (
    input  wire        clk,
    input  wire        resetn,
    input  wire        valid,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output wire        ready,
    output wire [31:0] rdata
);

    // ------------------------------------------------------------------------
    // Tín hiệu điều khiển SRAM (Port 0 - RW)
    // ------------------------------------------------------------------------
    wire       csb0;   // Chip Select (Active Low)
    wire       web0;   // Write Enable (Active Low)
    wire [3:0] wmask0; // Write Mask (Active High)
    wire [8:0] addr0;  // 9-bit address for 512 words
    wire [31:0] din0;
    wire [31:0] dout0;

    // csb0 kéo xuống 0 khi có valid
    assign csb0 = ~valid;
    
    // web0 kéo xuống 0 nếu có bất kỳ bit wstrb nào = 1 (đây là thao tác ghi)
    assign web0 = ~(|wstrb);
    
    // wmask0 dùng chính wstrb
    assign wmask0 = wstrb;
    
    // addr0 lấy từ bit [10:2] của addr (địa chỉ word)
    assign addr0 = addr[10:2];
    
    // Data in
    assign din0 = wdata;

    // ------------------------------------------------------------------------
    // Logic req_seen cho ready signal (1-cycle read latency)
    // ------------------------------------------------------------------------
    reg ready_reg;
    reg req_seen;
    
    assign ready = ready_reg;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            ready_reg <= 1'b0;
            req_seen  <= 1'b0;
        end else begin
            ready_reg <= 1'b0;
            if (!valid)
                req_seen <= 1'b0;
                
            if (valid && !req_seen) begin
                req_seen  <= 1'b1;
                ready_reg <= 1'b1; // Assert ready after 1 cycle delay
            end
        end
    end

    // ------------------------------------------------------------------------
    // Xử lý dữ liệu đọc
    // Nếu vừa có lệnh đọc (valid && !web0), dout0 sẽ có dữ liệu ở cycle sau.
    // ------------------------------------------------------------------------
    assign rdata = dout0;

    // ------------------------------------------------------------------------
    // Instantiate Sky130 SRAM Macro
    // 2 Kbyte (16384 bits), 32 bits width, 512 words depth
    // ------------------------------------------------------------------------
    sky130_sram_2kbyte_1rw1r_32x512_8 u_sram_macro (
`ifdef USE_POWER_PINS
        .vccd1 (1'b1),
        .vssd1 (1'b0),
`endif
        // Port 0: RW (Sử dụng cho SoC bus)
        .clk0   (clk),
        .csb0   (csb0),
        .web0   (web0),
        .wmask0 (wmask0),
        .addr0  (addr0),
        .din0   (din0),
        .dout0  (dout0),

        // Port 1: Read-Only (Không sử dụng, nối đất để tiết kiệm năng lượng)
        .clk1   (1'b0),
        .csb1   (1'b1), // Disabled (Active Low)
        .addr1  (9'd0),
        .dout1  ()
    );

endmodule
