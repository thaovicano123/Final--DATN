# Kiến Trúc Firmware & Cơ Chế Hoạt Động (SoC Low-Power)

Tài liệu này giải thích chi tiết tác dụng của từng file trong thư mục `fw/` (Firmware), vai trò của chúng trong hệ thống bare-metal RISC-V, cũng như cách dòng chảy thực thi (Execution Flow) được định tuyến từ lúc Cấp nguồn (Power-on) đến khi Vận hành Low-power (IRQ / Clock Gating).

---

## 1. Chi Tiết Từng File Trong Thư Mục `fw/`

Thư mục `fw/` chứa mã nguồn hệ thống nhúng chạy trực tiếp trên vi xử lý **PicoRV32 (RV32I)** mà không cần Hệ điều hành (Bare-metal). Chúng được chia làm 3 nhóm chính:

### Nhóm 1: Startup & Bootcode (Assembly)
Đây là những câu lệnh đầu tiên vi xử lý chạy ngay khi thoát khỏi trạng thái Reset.

- **`start.S`**
  - **Tác dụng:** Mã khởi động (Bootcode) cơ bản.
  - **Chức năng:** Khởi tạo thanh ghi biến ngăn xếp (Stack Pointer - `sp` trỏ tới cuối RAM `_stack_top`). Sao chép dữ liệu có giá trị khởi tạo (section `.data`) từ ROM sang RAM. Khóa toàn bộ vùng nhớ `.bss` (các biến toàn cục bằng 0) về mức `0`. Cuối cùng gọi lệnh `call main` để nhảy vào code C.
- **`irq_start.S`**
  - **Tác dụng:** Mã khởi động dành riêng cho **phiên bản hỗ trợ Ngắt (Interrupt/IRQ)**.
  - **Chức năng:** Tương tự `start.S` nhưng sẽ thiết lập thêm bảng Vector Ngắt (`irq_vec`). Khi có ngắt cứng phần cứng (Vd: UART có dữ liệu), CPU sẽ tự động nhảy vào nhãn `irq_vec`. Tại đây có các đoạn mã "cứu ngữ cảnh" (Context Save: push các thanh ghi `t0-t3` vào Stack), xử lý ngắt, ghi dấu Vết ngắt lên GPIO, phục hồi ngữ cảnh (Context Restore) và sử dụng lệnh chuyên dụng `retirq` (`.word 0x0400000b`) của PicoRV32 để quay lại luồng C lúc trước khi bị ngắt.

### Nhóm 2: Linker Scripts (Bản Đồ Bộ Nhớ)
Trình liên kết (GNU ld) sử dụng các file này để biết phải đặt Code và Data ở vị trí vật lý nào trên Chip.

- **`linker.ld`**
  - **Tác dụng:** Quy định sơ đồ cấp phát bộ nhớ (Memory Map) chuẩn.
  - **Chức năng:** Gán vùng `.text` (Code) và `.rodata` (Hằng số) vào **ROM (bắt đầu tại `0x0000_0000`)**. Gán vùng `.data` và `.bss` vào **RAM (bắt đầu tại `0x1000_0000`)**. Chỉ định điểm bắt tay (Entry point) là `_start`.
- **`irq_linker.ld`**
  - **Tác dụng:** Quy định sơ đồ cấp phát bộ nhớ dành cho chương trình có IRQ.
  - **Chức năng:** Lõi vi xử lý PicoRV32 được thiết kế "cứng" để khi có ngắt sẽ tự động nhảy tới địa chỉ vật lý `0x0000_0010`. Do đó file linker này sẽ cố tình ghim cứng (pin) label `irq_vec` chính xác vào địa chỉ `0x10` trên ROM, đảm bảo hệ thống không bị crash (treo) khi nhảy ngắt.

### Nhóm 3: Application Logic (Code C)
Logic thực thi chính, nơi C được dịch thành mã máy giao tiếp qua Bus (MMIO).

- **`main.c`**
  - **Tác dụng:** Bài Test "Smoke" nguyên thủy (Phase 1).
  - **Chức năng:** Test giao tiếp cơ bản nhất qua thanh ghi MMIO. Định tuyến trực tiếp các con trỏ logic `volatile uint32_t*` vào các địa chỉ `0x2000_XXXX` để ra lệnh chớp tắt LED (GPIO toggling). Dùng vòng lặp `for` mềm để tạo delay.
- **`main_irq.c`**
  - **Tác dụng:** Bài Test Interrupt & WFI (Đánh Thức / Ngủ Sâu).
  - **Chức năng:** Trình diễn tính năng cốt lõi của **Low-Power SoC**. Thay vì CPU phải chạy vòng lặp liên tục để hỏi xem UART có Data chưa (Polling - rất tốn điện), `main_irq.c` sẽ thiết lập ngắt, sau đó gọi **giả lập WFI** (Wait-For-Interrupt) thông qua register đặc biệt của PicoV32. Lúc này, lõi CPU sẽ ngưng hoàn toàn việc nạp lệnh (Fetch). Khi `real_uart_mmio.v` nhận đủ 1 byte, tín hiệu giật lên, CPU tỉnh dậy, chớp GPIO, đếm số lượng ngắt, xóa định danh ngắt rồi trở lại ngủ tiếp.
- **`main_gating.c`**
  - **Tác dụng:** Bài Test Quản Lý Tài Nguyên Điện (Dynamic Clock Gating).
  - **Chức năng:** Tương tác trực tiếp với Khối CMU (Clock Management Unit) tại `0x2000_3000`. Cố tình "tắt điện" bằng cách ghi chuỗi `00` vào thanh ghi `CLK_EN` -> Cắt xung nhịp cấp xuống GPIO và UART, sau đó mở lại (`03`). Phần cứng `tb` sẽ verify việc này thông qua kiểm đếm số lần đảo chiều xung clock thật sự ở mức Cổng logic.

---

## 2. Luồng Hoạt Động (Execution Flow) Của SoC Low-Power

Mọi module của project này là một thiết kế Custom ASIC, các luồng trao đổi Master/Slave sẽ tuân thủ tuyệt đối chuẩn truyền 1-chu-kỳ (1-Wait State pulse, `req_seen`).

### A. Pha Cấp Nguồn và Khởi Động (Boot Sequence)
1. **Reset State:** Cờ `resetn` bị kéo xuống 0. Mọi Thanh ghi (Flip-flop) trên RTL khởi tạo về trạng thái xuất xưởng. `CMU` tự động đặt `clk_en = 2'b11` (Mở điện toàn hệ thống lúc boot).
2. **ROM Nạp Mã Máy:** Vi xử lý PicoRV32 đưa lệnh đọc tại `0x0000_0000`. `soc_rom` nhận `valid`, sau 1 chu kỳ sẽ nổ `ready` trả về các byte mã máy của hàm `_start` trong `start.S`.
3. **C/C++ Environment Initialization:** `start.S` lấy các biến mà ta khai báo bằng C (trong `.data`) load từ ROM ra RAM (tại `0x1000_0000`). Trả RAM rác (`.bss`) về `0`. Kéo con trỏ Stack Pointer về vạch đích để chuẩn bị sẵn sàng cho lệnh `push/pop` biến cục bộ của C.

### B. Pha Tương Tác Ngoại Vi (Memory-Mapped I/O - MMIO Flow)
Do CPU RISC-V không có lệnh I/O riêng (như in, out trên x86), mọi tương tác phần cứng được mô hình hóa qua ĐỊA CHỈ BỘ NHỚ.
1. CPU chạy câu lệnh `mmio_write(GPIO_BASE + GPIO_DATA_OUT, 1);` trong `main.c`.
2. Trình biên dịch hiểu thành lệnh Store Word (`sw`). PicoRV32 đặt `addr = 0x2000_2000`, `wdata = 0x1`, `valid = 1`.
3. Mã RTL `bus_decoder.v` lấy 16-bit cao của địa chỉ, nhận diện là `0x2000`. Nó kiểm tra tiếp offset và bật chốt `sel_gpio = 1`.
4. Logic `gpio_mmio.v` thấy hiệu lệnh, đẩy `0x1` vào chân F/F `gpio_out`. Đèn LED bên ngoài bật sáng. Cấp lại `ready = 1` báo hiệu bus giao dịch xong.

### C. Pha Ngủ Sâu & Xử Lý Ngắt Cứng (Low-Power WFI & IRQ Flow)
*Luồng này giải quyết triệt để vấn đề "Lãng phí điện năng" do kiểm tra rảnh tay thường xuyên.*
1. **Sleep Mode:** Tại `main_irq.c`, vi điều khiển gọi mã lệnh Mask IRQ để cho phép ngắt, sau đó vào vòng lặp ngắt trống `wait_for_interrupt()`. PicoRV32 xập xuống trạng thái treo Fetch. Chỉ có `clk` của UART còn chạy. Mức tiêu thụ điện toàn Chip giảm mạnh.
2. **UART Event:** Pin `uart_rx` bên ngoài (từ máy tính) đánh sườn (Start bit). `real_uart_mmio.v` lấy mẫu xong 8-bit và kéo đường dây `irq_rx` lên mức cao `1`.
3. **CPU Wake-up:** PicoRV32 phát hiện Tín hiệu IRQ, thoát lập tức trạng thái ngủ. Bỏ dở công việc hiện tại, Nhảy tới địa chỉ cứng `0x0000_0010`.
4. **Mã `irq_vec` (trong `irq_start.S`):** Cất các thanh ghi `t0, t1..` đang dùng dở vào Stack (RAM). Toggle Flip-flop tại `0x2000_200C` (GPIO). Giúp kỹ sư bên ngoài biết ngắt đang được xử lý.
5. **Clear Flag:** Trả lại cờ báo ngắt trên UART xuống mức 0 qua thanh ghi MMIO.
6. **Return:** Lệnh `retirq` (Custom instruction) kéo các thanh ghi ra khỏi Stack, CPU trở lại vòng lặp ngủ ở dòng 1.

### D. Pha Cắt Xung Nhịp Cục Bộ (Dynamic Clock Gating Flow)
*Luồng này chứng minh tính năng quản trị điện năng tiên tiến của Chip.*
1. `main_gating.c` gọi hàm ghi vào thanh ghi `CMU (0x2000_3000)` giá trị `0`.
2. `cmu.v` trên phần cứng lưu trữ giá trị này vào `clk_en <= 2'b00`.
3. Tín hiệu này lập tức chốt vào logic `icg_cell.v` (Integrated Clock Gating Cell) có chức năng Latch-Based chắn kim clock (glitch-free).
4. Do `en = 0`, logic F/F Failsafe chặn Clock nhịp, các khối `uart` và `gpio_mmio` phía sau khối ICG hoàn toàn MẤT XUNG CLOCK (`gclk_uart = 0`).
5. Các tụ điện (Transistor Capacitance) bên trong RTL UART và GPIO ngừng nạp xả. Điện năng **Dynamic Power biến mất hoàn toàn**.
6. CPU (Do nối thẳng với main clk) vẫn đang chạy, mở điện lại bằng lệnh ghi ngược giá trị `3` vào `CMU_BASE`. Dòng điện phục hồi, Chip hoạt động tiếp tục.
