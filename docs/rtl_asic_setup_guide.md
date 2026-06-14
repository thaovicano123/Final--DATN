# Hướng dẫn Chuẩn bị Mã nguồn RTL cho Quy trình ASIC (OpenLane)

Việc viết code Verilog chạy đúng trên mô phỏng (Simulation) hoặc FPGA là chưa đủ để đúc thành một con chip thực tế (ASIC). Để luồng OpenLane chạy suôn sẻ từ đầu đến cuối mà không bị treo hay báo lỗi nghẽn mạch, mã nguồn RTL của dự án LibreLane SoC đã được thiết lập và tinh chỉnh vô cùng kỹ lưỡng.

Dưới đây là các kỹ thuật thiết lập RTL cốt lõi đã được áp dụng:

---

## 1. Xử lý Bộ nhớ (RAM và ROM)

Bộ nhớ luôn là thành phần nhạy cảm nhất khi chuyển từ RTL sang ASIC. Trong dự án này, chúng ta đã áp dụng chiến lược **Inferred Memory (Bộ nhớ Suy luận)** kết hợp với **Tối ưu kích thước**.

*   **Từ bỏ Hard Macro:** Môi trường Nix-shell thiếu các file thư viện vật lý (`.lef`, `.gds`) của SkyWater SRAM Macro. Do đó, mã nguồn RTL đã được sửa để không gọi (instantiate) các Macro đúc sẵn này.
*   **Inferred Logic:** ROM (`soc_rom.v`) và RAM (`soc_ram.v`) được viết lại dưới dạng các mảng thanh ghi (registers array) Verilog chuẩn. Công cụ Yosys sẽ tự động suy luận (infer) và dịch các mảng này thành hàng ngàn cổng Flip-Flop tiêu chuẩn (Standard Cells).
*   **Thu nhỏ triệt để (Critical Sizing):** Việc xây RAM bằng Flip-flop cực kỳ tốn diện tích và dễ gây nghẽn mạch (Routing Congestion) khiến phần mềm treo cứng. Để luồng ASIC chạy mượt mà, kích thước đã được ép xuống mức tối giản thông qua tham số `ADDR_WIDTH`:
    *   **ROM:** Giảm xuống `1KB` (`ADDR_WIDTH = 8`).
    *   **RAM:** Giảm xuống `256 Bytes` (`ADDR_WIDTH = 6`).
    Mức dung lượng này vừa đủ cho Firmware hoạt động, vừa giữ cho số lượng cổng logic sinh ra cực thấp (~4000 cells).
*   **Gỡ bỏ Blackbox:** Các định nghĩa của RAM/ROM trong file `mem_blackbox_cells.v` đã được xóa bỏ để cho phép Yosys tự do tổng hợp chúng thành cổng logic thay vì coi chúng là các hộp đen bí ẩn.

## 2. Quản lý Xung nhịp và Clock Gating (Low-Power)

Để biến dự án thành một chip tiết kiệm năng lượng (Low-Power) đúng nghĩa trên silicon, việc xử lý tín hiệu Clock trong RTL là tối quan trọng:

*   **Tích hợp Cổng ICG Vật lý:** Thay vì dùng lệnh `if (enable) clk_out = clk;` (điều này sẽ sinh ra nhiễu Glitch phá hỏng chip), RTL đã được trang bị module `icg_cell.v`. Module này mô phỏng chính xác cấu trúc của một cổng **Integrated Clock Gating** chuyên nghiệp (gồm 1 Latch giữ trạng thái và 1 cổng AND).
*   **Phân phối qua CMU:** Tín hiệu Clock gốc không đi thẳng vào các ngoại vi. Nó đi qua Khối Quản lý Xung nhịp (`cmu.v`). Tại đây, tín hiệu Enable từ CPU sẽ đóng/mở các cổng ICG, cho phép ngắt hoàn toàn nguồn Clock vào UART và GPIO khi không sử dụng.

## 3. Kiến trúc Cấp cao (Top-Level Wrapper)

Phần mềm OpenLane yêu cầu một module cao nhất duy nhất (Top Module) chứa toàn bộ thiết kế với các chân tín hiệu (I/O pins) phẳng.

*   **Module `soc_top_asic.v`:** Một module bọc ngoài cùng đã được tạo ra. Nó làm nhiệm vụ khởi tạo CPU PicoRV32, Bus Decoder, CMU, RAM, ROM và các Ngoại vi, sau đó đấu nối toàn bộ dây tín hiệu bên trong lại với nhau.
*   **Định nghĩa Pin I/O rõ ràng:** Các cổng giao tiếp với thế giới bên ngoài được định nghĩa tường minh:
    *   `clk`, `resetn` (Đầu vào hệ thống).
    *   `uart_tx`, `uart_rx` (Giao tiếp nối tiếp).
    *   `gpio_in[31:0]`, `gpio_out[31:0]` (Cổng đa dụng).
    *   `irq_ext` (Ngắt ngoài).
*   Sự rõ ràng này giúp công cụ dễ dàng gắn vị trí các chân cắm (Pin Placement) quanh viền con chip 1500x1500um.

## 4. Giao thức Bus (Native Memory Interface)

Thay vì tích hợp các bộ mã nguồn mở của AXI4 hay Wishbone (vốn chứa hàng chục ngàn dòng code RTL phức tạp và nặng nề), RTL được thiết kế sử dụng giao thức **Native Memory Interface** nguyên bản của PicoRV32.

*   **Tín hiệu bắt tay đơn giản:** Chỉ sử dụng 6 tín hiệu: `valid`, `ready`, `addr`, `wdata`, `wstrb`, `rdata`.
*   **Lợi ích cho ASIC:** Giao thức này giúp giảm thiểu hàng vạn cổng logic không cần thiết, giảm áp lực đi dây (routing) và đảm bảo mọi chu kỳ đọc/ghi bộ nhớ chỉ mất đúng **1 xung nhịp (Zero-latency)**.

---
> [!IMPORTANT]  
> **Bài học rút ra:** Việc chuẩn bị RTL cho ASIC không phải là viết thêm nhiều tính năng, mà là nghệ thuật **CẮT GIẢM** và **TỐI ƯU**. Bằng cách ép nhỏ RAM, dùng giao thức Bus đơn giản và phân phối Clock thông minh, chúng ta đã biến một thiết kế từ chỗ làm treo phần mềm suốt 8 tiếng, trở thành một quy trình chạy trơn tru, hoàn hảo và ra được GDSII chỉ trong 15 phút.
