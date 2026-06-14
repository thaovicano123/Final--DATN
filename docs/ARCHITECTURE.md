# TÀI LIỆU KIẾN TRÚC TỔNG QUAN HỆ THỐNG LIBRELANE SoC

Tài liệu này mô tả chi tiết kiến trúc mạch tích hợp (ASIC) hệ thống LibreLane SoC (System-on-Chip) dựa trên nhân vi xử lý PicoRV32, bao gồm luồng dữ liệu (Data Flow) và cơ chế hoạt động của từng khối (Block).

## 1. Sơ đồ Kiến trúc Tổng quan (Architecture Block Diagram)

```mermaid
flowchart TD
    %% Định nghĩa các node
    SysClk([System Clock - clk])
    SysRst([System Reset - resetn])
    
    subgraph Core_Domain [Core Domain (Always-ON)]
        CPU((PicoRV32 Core))
        BusDec{Bus Decoder}
        ROM[(ROM\n0x0000_0000 - 0x0000_FFFF)]
        RAM[(RAM\n0x1000_0000 - 0x1000_FFFF)]
        CMU[Clock Management Unit\n0x2000_3000]
    end

    subgraph Periph_Domain [Peripheral Domain (Clock Gated)]
        UART[UART MMIO\n0x2000_0000]
        SPI[SPI MMIO\n0x2000_1000]
        GPIO[GPIO MMIO\n0x2000_2000]
    end

    %% Clock and Reset
    SysClk --> CPU
    SysClk --> CMU & ROM & RAM
    SysRst --> CPU & CMU & RAM & UART & SPI & GPIO

    %% Datapath and Bus Routing
    CPU ==>|Native Memory IF\naddr, wdata, valid, strb| BusDec
    BusDec ==>|sel_rom| ROM
    BusDec ==>|sel_ram| RAM
    BusDec ==>|sel_cmu| CMU
    BusDec ==>|sel_uart| UART
    BusDec ==>|sel_spi| SPI
    BusDec ==>|sel_gpio| GPIO

    %% Data Return
    ROM -.->|rdata, ready| CPU
    RAM -.->|rdata, ready| CPU
    UART -.->|rdata, ready| CPU
    SPI -.->|rdata, ready| CPU
    GPIO -.->|rdata, ready| CPU
    CMU -.->|rdata, ready| CPU

    %% Clock Gating Paths
    CMU == gclk_uart ==> UART
    CMU == gclk_spi ==> SPI
    CMU == gclk_gpio ==> GPIO

    %% Interrupts & External I/O
    SPI -->|irq| CPU
    UART <-->|RX / TX| EXT_UART([External UART])
    SPI <-->|MISO, MOSI, SCLK, CS_N| EXT_SPI([External SPI Device])
    GPIO <-->|GPIO IN / OUT| EXT_GPIO([External External Pins])
```

## 2. Luồng dữ liệu hệ thống (System Data Flow)

Hệ thống LibreLane SoC hoạt động theo mô hình Memory-Mapped I/O (MMIO). Dữ liệu chảy qua hệ thống theo luồng cơ bản sau:
1. **Instruction Fetch (Nạp lệnh):** Khi CPU khởi động (qua tín hiệu `resetn`), PicoRV32 xuất ra địa chỉ bắt đầu (Reset Vector `0x0000_0000`). Địa chỉ được đưa vào Bus chung, `Bus Decoder` giải mã và kích hoạt tín hiệu `sel_rom`. ROM phản hồi bằng mã lệnh (instruction data) và cờ `ready`.
2. **Data Read/Write (Xử lý dữ liệu):** Trong quá trình tính toán, khi chương trình cần cấp phát vùng nhớ, CPU đẩy yêu cầu vào vùng địa chỉ `0x1000_0000`. Bus Decoder bật bộ chọn của `sel_ram`, đẩy dữ liệu cần ghi (`mem_wdata`, `mem_wstrb`) hoặc lấy dữ liệu về dải thanh ghi CPU.
3. **Peripheral Access (Tương tác ngoại vi):** Bằng cách gửi một yêu cầu truy cập Load/Store Word (LW/SW) vào dải địa chỉ MMIO bắt đầu từ `0x20*`:
   - Lệnh được hướng tới ngoại vi qua Bus Decoder.
   - Ngoại vi xử lý cập nhật trạng thái các thanh ghi nội bộ.
   - Tín hiệu IO xuất ra môi trường thực.
4. **Interrupt Handling (Ngắt):** Module SPI có cờ ngắt (`irq`). Khi giao dịch SPI hoàn tất, module sẽ báo `irq` cho CPU. PicoRV32 lưu trạng thái ngữ cảnh hiện tại và chuyển PC nhảy đến địa chỉ ngắt `0x0000_0010`.

## 3. Hoạt động chi tiết cấu thành các khối (Block-level Documentation)

### 3.1. Vi xử lý Trung tâm - `picorv32.v`
- **Vai trò:** Trái tim của SoC, nhân kiến trúc RISC-V 32-bit mã nguồn mở.
- **Hoạt động:** Chạy chuẩn tập lệnh RV32IMC (hoặc RV32I). Nó giao tiếp bằng một native memory interface rất đơn giản có sẵn (gồm `valid`, `addr`, `wdata`, `ready`, v.v) thay vì xài AXI/AHB phức tạp, giúp việc tích hợp ASIC trở nên trơn tru. Ngoài Memory Interface, nó có thêm port PC IRQ được map cứng cho Interrupt 0.

### 3.2. Bộ giải mã Bus - `bus_decoder.v`
- **Vai trò:** Bản đồ bộ nhớ (Memory Map Router).
- **Hoạt động:** Hoàn toàn chỉ là cách cổng Logic tĩnh (Combinational Logic). Dựa vào dải bit địa chỉ trên cùng `addr[31:X]`, nó trỏ tới Macro cần giao tiếp:
  - `0x0000_...` -> ROM (Memory Fetch)
  - `0x1000_...` -> RAM (Data Space)
  - `0x2000_0...` -> UART
  - `0x2000_1...` -> SPI
  - `0x2000_2...` -> GPIO
  - `0x2000_3...` -> CMU

### 3.3. Tổ hợp Bộ nhớ `soc_ram.v` & `soc_rom.v`
- **Vai trò:** Lưu trữ Chương trình (Firmware) và Dữ liệu Cục bộ (SRAM).
- **Hoạt động:** Trong giới hạn thiết kế của luồng chạy Standard Cell, thay vì sử dụng Macro SRAM chuyên dụng từ OpenRAM (gây lỗi PDN), bộ nhớ hiện tại sử dụng mảng Array cực nhỏ cài cắm cấu hình số bit `ADDR_WIDTH=6`.
  - ROM: Chỉ đọc (Read-only), dữ liệu được nhồi trực tiếp từ file (Hex) tổng hợp cứng hóa.
  - RAM: Hỗ trợ bit mask (`wstrb`) để ghi từng byte. Được tổng hợp bởi hàng ngàn cấu kiện D-Flip-Flop chuẩn hóa (tốn kém diện tích sàn).

### 3.4. Bộ quản lý Xung nhịp và Tiết kiệm điện - `cmu.v` & `icg_cell.v`
- **Vai trò:** Master Clock Controller - điều tiết clock cho các khối ngoài lõi (Peripherals Domain) nhằm làm xanh báo cáo Power Leakage.
- **Hoạt động:** Module CMU chứa thanh ghi ở offset `0x00` bao gồm 3 bits `clk_en`. Khi firmware đẩy dữ liệu (VD: `wdata = 3'b111` enable tất cả). CMU nạp vào các cells đặc biệt là `icg_cell` (Integrated Clock Gating cell).
  - Từng `icg_cell` nhận Latch (chống nhiễu Glitch) để băm/mở (Gating / Un-Gating) xung nhịp hệ thống ra các tín hiệu phái sinh `gclk_uart`, `gclk_spi`, `gclk_gpio`. Khối nào bị khoá xung nhịp thì không tiêu thụ điện ở chế độ Switching Power.

### 3.5. Khối Giao tiếp Ngoại Vi: `uart_mmio.v`, `spi_mmio.v`, `gpio_mmio.v`
- **Vai trò:** Cửa sổ kết nối với thế giới bên ngoài, chịu xung nhịp Clock động từ CMU.
- **Hoạt động:** Tất cả giao tiếp theo cách MMIO, không đồng bộ, và có cấu hình phần cứng nhỏ gọn gọn nhất để luồng ASIC tổng hợp ra diện tích chỉ bằng 1/10 kích thước (80-150um).
  - **UART:** Có thanh ghi `Tx`, `Rx` (mô phỏng Shift Register cơ bản để bắn/nhận tín hiệu nối tiếp qua cổng pin chip theo tốc độ baud-rate xác định).
  - **SPI:** Gồm các tín hiệu Master Out Slave In, ngõ SCLK. Tích hợp khả năng xuất tín hiệu Ngắt (Interrupt) báo Master khi thanh ghi truyền đã shift nhả xong dữ liệu.
  - **GPIO:** Có thanh ghi định hướng IN/OUT, chốt dữ liệu 32-bit linh hoạt ra viền của Chip.
  
---
_Với việc chia miền năng lượng, ép chặt kích thước Memory và P&R độc lập từng module, SoC đã sẵn sàng bước vào sàn "Top-Level Placement" một cách mạnh mẽ nhất._
