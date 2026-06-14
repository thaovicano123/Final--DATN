# Tổng quan Kiến trúc Phần cứng (RTL) và Phần mềm (Firmware)

Đồ án LibreLane SoC là một hệ thống nhúng hoàn chỉnh (Full-Stack). Dưới đây là giải phẫu chi tiết về chức năng của từng "nội tạng" phần cứng (RTL) và các kịch bản phần mềm (Firmware) đang chạy trên con chip này.

---

## PHẦN 1: TỪ ĐIỂN CÁC MODULE PHẦN CỨNG (RTL)

Các file này nằm trong thư mục `rtl/`. Chúng tạo nên cấu trúc vật lý của con chip.

### 1. Nhóm Lõi và Điều phối Hệ thống
*   **`picorv32.v` (Vi xử lý trung tâm):** Trái tim của SoC. Nó giải mã và thực thi các lệnh RISC-V 32-bit (RV32IMC), điều khiển toàn bộ luồng dữ liệu.
*   **`soc_top_asic.v` (Vỏ bọc ngoài cùng):** Đây là file hàn nối tất cả các khối con lại với nhau thành một con chip duy nhất. Mọi chân tín hiệu (I/O) giao tiếp với thế giới bên ngoài đều được định nghĩa tại đây.
*   **`bus_decoder.v` (Cảnh sát giao thông):** Dựa vào địa chỉ mà CPU yêu cầu (VD: `0x20000000`), nó sẽ bẻ ghi đường dẫn dữ liệu đến đúng module (ROM, RAM, UART hay GPIO) thông qua giao thức bắt tay `valid-ready` 1-chu-kỳ cực nhanh.

### 2. Nhóm Quản lý Điện năng (Low-Power Core)
*   **`cmu.v` (Clock Management Unit):** Khối ra lệnh bật/tắt điện. Nó nhận cấu hình từ CPU và gửi tín hiệu Enable đi đóng/mở xung nhịp.
*   **`icg_cell.v` (Integrated Clock Gating):** Cái "Cầu dao" vật lý. Nó nhận tín hiệu Enable từ CMU để cắt dòng Clock đi vào UART/GPIO một cách trơn tru, tuyệt đối không tạo ra xung nhiễu (Glitch) làm cháy chập linh kiện.

### 3. Nhóm Bộ nhớ (Memory)
*   **`soc_rom.v` (ROM - 1KB):** Bộ nhớ tĩnh, dùng để chứa các dòng lệnh mã máy (Firmware) đã được biên dịch.
*   **`soc_ram.v` (RAM - 256 Bytes):** Bộ nhớ động, cung cấp không gian Stack (ngăn xếp) để CPU lưu biến tạm, phục vụ các hàm gọi lồng nhau. Cả RAM và ROM đều được thu nhỏ tối đa để ép thành cổng logic (Inferred), chống nghẽn mạch khi đúc chip.

### 4. Nhóm Ngoại vi (Peripherals)
*   **`gpio_mmio.v`:** Giao tiếp bật/tắt đèn LED hoặc đọc nút bấm. Hỗ trợ kích hoạt ngắt (Interrupt).
*   **`real_uart_mmio.v`:** Cổng nối tiếp COM, dùng để in chữ từ chip ra màn hình máy tính thông qua cáp USB-to-TTL, có khả năng kích hoạt ngắt khi nhận được dữ liệu (RX).

---

## PHẦN 2: TỪ ĐIỂN CÁC KỊCH BẢN PHẦN MỀM (FIRMWARE)

Các file này nằm trong thư mục `fw/`. Chúng là các chương trình C/Assembly được biên dịch thành file `.hex` để nạp vào ROM. Do mục đích kiểm thử khác nhau, dự án có nhiều kịch bản phần mềm:

### 1. Nhóm Khởi động (Bootloader & Linker)
*   **`start.S` / `irq_start.S`:** Điểm chạm đầu tiên khi chip vừa cấp điện. Chứa mã Assembly dùng để khởi tạo con trỏ ngăn xếp (Stack Pointer `sp`), thiết lập bảng Vector Ngắt (Interrupt Vector) và cuối cùng là gọi hàm `main()` của C.
*   **`linker.ld` / `irq_linker.ld`:** Bản đồ định hướng cho trình biên dịch (GCC compiler). Nó ra lệnh: "Hãy nhét toàn bộ các câu lệnh C vào địa chỉ `0x00000000` (ROM) và các biến số vào địa chỉ `0x10000000` (RAM)".

### 2. Nhóm Chương trình Chính (C Code)
*   **`main.c` (Kịch bản Tổng hợp):** Mã nguồn chính cho báo cáo. Nó kết hợp in chữ qua UART, chớp tắt đèn LED (GPIO) và thao tác bật/tắt Clock Gating cơ bản để chứng minh chip sống.
*   **`main_gating.c` (Kịch bản Test Điện năng):** Chuyên dùng để tra tấn (Stress-test) khối `cmu.v`. Nó liên tục đóng ngắt xung nhịp của GPIO hàng ngàn lần một giây để chứng minh chip không bị treo do nhiễu (Glitch-free).
*   **`main_irq.c` (Kịch bản Test Ngắt):** Kiểm tra khả năng phản xạ của CPU. CPU không cần chờ đợi dữ liệu mà sẽ rơi vào trạng thái rảnh rỗi. Khi có ai đó gõ bàn phím gửi vào UART, phần cứng sẽ kích một dây tín hiệu IRQ "tát" CPU tỉnh dậy để xử lý ký tự vừa nhập.

---
> 💡 **Mẹo:** Bạn có thể sao chép trực tiếp nội dung file này vào phần **Cơ sở Lý thuyết & Triển khai** trong cuốn báo cáo Word tốt nghiệp của mình.
