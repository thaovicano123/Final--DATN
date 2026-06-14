# LÝ THUYẾT VÀ QUÁ TRÌNH XỬ LÝ DỮ LIỆU CỦA CPU PICORV32 (HỆ THỐNG LIBRELANE SoC)

Tài liệu này đi sâu vào phần lõi của hệ thống - CPU PicoRV32. Mục tiêu là giải thích rõ lý thuyết hoạt động cơ bản của lõi vi xử lý này và cách nó hòa nhập, điều phối trọn vẹn luồng dữ liệu (Data Path) trong dự án LibreLane SoC.

## 1. Lý thuyết cơ sở về PicoRV32 trong dự án
PicoRV32 là một bộ vi xử lý (CPU core) mã nguồn mở, kích thước siêu nhỏ, tuân thủ hoàn toàn theo tập lệnh kiến trúc **RISC-V 32-bit (RV32IMC)**. 

Trong khuôn khổ dự án LibreLane SoC, nhân PicoRV32 được lựa chọn thay vì các lõi lớn (như Rocket hay BOOM) bởi các đặc điểm lý tưởng cho luồng thiết kế kỹ thuật ASIC:
- **Nguyên lý Giao tiếp Native (Native Memory Interface):** Thay vì sử dụng các giao thức bus phức tạp (như AXI4, AHB, Wishbone), lõi PicoRV32 lấy/cất dữ liệu với mọi thứ bên ngoài theo chuẩn giao tiếp "Native" bao gồm các chân tín hiệu rất trực quan: 
  - `mem_valid` và `mem_ready`: Bắt tay tín hiệu.
  - `mem_addr` (32-bit): Địa chỉ cắm cờ.
  - `mem_wdata` và `mem_wstrb` (32-bit): Dữ liệu để ghi/Lưới mask byte.
  - `mem_rdata` (32-bit): Số liệu đọc về.
  Cơ chế này khiến việc tự chắp bút viết mạch `bus_decoder` và các thanh ghi giao tiếp (MMIO) dễ dàng hơn, thu hẹp lượng tổ hợp cổng logic để P&R thành công.
- **Microarchitecture (Vi kiến trúc):** Đây là một lõi CPI (Cycles Per Instruction) cao. Nó không có hệ thống Pipeline (Đường ống) tĩnh siêu dài hay Cache nhớ đệm phức tạp. Mọi tín hiệu đọc, viết đều được rải liên tục và trung thực ra bên ngoài mặt Bus cấu trúc máy.
- **Ngắt cứng mạch (Interrupt - IRQ):** Tương tự như Core vi điều khiển (MCU), thay vì dùng cơ chế ngắt trung tâm PLIC phức tạp, mạch có chân ngắt `irq` nhận 32 luồng đầu vào chọc nhảy ngẫu nhiên. Trong dự án, `irq[0]` nối trực tiếp vào SPI (các bit ngắt khác bỏ đi, giải phóng cổng thừa).

## 2. Quá trình Xử lý Dữ liệu trong SoC (Data Processing Flow)

Trong hệ thống SoC, PicoRV32 đóng vai trò là "Tổng tư lệnh", điều phối toàn bộ luồng chảy của dữ liệu. Tuy nhiên, nó không thể đứng độc lập mà cần sự phối hợp nhịp nhàng của mạng lưới các module vệ tinh. Dưới đây là bức tranh toàn cảnh về cách dữ liệu di chuyển và tác dụng của từng khối ngoại vi/module trong luồng xử lý:

### Trạm kiểm soát không lưu: Bus Decoder (`bus_decoder.v`)
Mọi luồng dữ liệu (bất kể đọc hay ghi) phát ra từ CPU đều mang theo một "địa chỉ điểm đến" (Address). **Bus Decoder** đứng ở ngã tư đường, soi xét địa chỉ này và làm nhiệm vụ bẻ ghi (routing) mở đường để nối dây truyền dữ liệu từ CPU thẳng đến đúng module cần đón nhận, đảm bảo không có tín hiệu nào bị "lạc đường" hoặc đụng độ nhau.

### Luồng 1. Đọc và giải mã lệnh (Nhận tri thức từ ROM)
- **Cách dữ liệu chạy:** CPU xuất ra địa chỉ bắt đầu `0x0000_0000`. Bus Decoder nhanh chóng chốt tín hiệu mở cổng `sel_rom`. Dữ liệu mã lệnh (32-bit nhị phân) chảy từ module **ROM** truyền ngược lại vào bụng CPU.
- **Tác dụng của ROM (`soc_rom.v`):** Đóng vai trò là cuốn sách hướng dẫn. Đây là nơi chứa Firmware phần mềm điều khiển (code C đã biên dịch cứng). CPU luôn coi ROM là khởi nguồn tri thức để biết phải tính toán cái gì.

### Luồng 2. Giao tiếp bộ nhớ cục bộ (Lưu biến tạm ở RAM)
- **Cách dữ liệu chạy:** Khi nhân ALU trong lõi CPU tính toán xong các mảng số liệu hay biến động phức tạp, CPU đẩy số liệu đó ra mặt Bus kèm vỏ bọc địa chỉ ở dải `0x1000_0000`. Cửa `sel_ram` bật mở, dữ liệu tràn xuống hệ thống D-FF của module RAM. Lúc sau cần thao tác tiếp, CPU lại phát lệnh Load để kéo dữ liệu từ RAM về.
- **Tác dụng của RAM (`soc_ram.v`):** Làm bộ nhớ nháp (Scratchpad/RAM cục bộ), cung cấp vùng không gian (Stack/Heap) để firmware lưu các biến trung gian hoặc chứa tạm các chuỗi dữ liệu (buffer) từ thế giới bên ngoài gửi vào chờ mã hoá.

### Luồng 3. Giao tiếp thực tế (Xuất nhập liệu qua MMIO Peripherals)
Khi dữ liệu đã sẵn sàng để gửi ra thế giới bên ngoài (màn hình, cảm biến) hay đón nhận từ thực tế, luồng dữ liệu sẽ đi vào góc phần tư `0x2000_xxxx` để đổ về các khối ngoại vi:
    
- **Luồng dữ liệu qua UART (`uart_mmio.v` ở `0x2000_0000`): Giao tiếp văn bản/log.**
  - *Data Flow:* CPU ném 1 byte dữ liệu (ví dụ: cữ 'A') xuống module UART. Khối UART này làm nhiệm vụ quy đổi mảng dữ liệu song song đó thành một đoàn tàu nối tiếp từng bit rải đều ra chân vật lý `uart_tx` nối với máy tính người dùng. Ngược lại, nó gom các xung điện từ chân `uart_rx` (khi người bấm phím) chuyển thành ký tự để tải vào CPU.
- **Luồng dữ liệu qua SPI (`spi_mmio.v` ở `0x2000_1000`): Giao tiếp thiết bị tốc độ cao.**
  - *Data Flow:* Được thiết kế để nói chuyện với thẻ nhớ, Flash ngoài hoặc màn hình. SPI nhận một cụm bit thô từ CPU, tự động sinh ra nhịp Clock nội bộ (`spi_sclk`) điều phối đẩy dữ liệu ra `spi_mosi`. Quá trình giao dịch xong xuôi, nó gửi ngược lại sóng **Interrupt (`spi_irq`)** chọc trực tiếp vào CPU báo hiệu *"đã kéo dữ liệu cảm biến về xong, vào lấy đi!"*.
- **Luồng dữ liệu qua GPIO (`gpio_mmio.v` ở `0x2000_2000`): Đóng ngắt vật lý đơn giản.**
  - *Data Flow:* Đây là nơi chốt tín hiệu thô sơ nhất. Firmware CPU đẩy số `1` cực kỳ đơn giản vào địa chỉ này. Module GPIO sẽ giữ vững giá trị điện áp số 1 đó, làm năng lượng búng sáng một đèn LED, hoặc chốt để điều khiển động cơ quay.

### Luồng 4. Điều phối nhịp đập & Năng lượng (Vai trò của CMU)
- Các ngoại vi như UART, SPI, GPIO bên trên nêú lúc nào cũng há miệng chờ luồng dữ liệu đẩy vào thì sẽ chạy tiêu tốn điện năng hao phí. Để giải quyết, mọi luồng giao tiếp phải qua sự quản lý của **CMU (`cmu.v` ở `0x2000_3000`)**.
- **Tác dụng của CMU và ICG_Cell:** CPU gửi vài byte cấu hình vào CMU. CMU sẽ hoạt động như những "chiếc van nước" (Clock Gating). Nó trực tiếp ngắt cầu dao nhịp xung nhịp Clock của SPI hay GPIO khi các khối này chưa có luồng dữ liệu đi qua. Giúp chip nghỉ ngơi (Sleep/Ngủ đông) một phần, giữ cho báo cáo tiêu thụ Năng Lượng (Power Leakage) ở khâu ASIC đạt chuẩn màu xanh lá.

## 3. Case Study: Từ Cảm biến (Rx) tới RAM tới Gửi phản hồi (Tx)
Mô phỏng minh chứng tiến trình một Gói Dữ liệu đi lòng vòng trong thiết kế SoC của bạn:
1. **[Ngoại vi -> SoC]:** Người dùng gõ "Hello" lên bàn phím gửi qua giao diện Terminal COM. Module `uart_mmio.v` nhận các hạt điện tích, ghép lại thành mã nhị phân "H" và báo trạng thái.
2. **[SoC -> CPU]:** Lõi CPU PicoRV32 dùng luồng xoay (Polling Routine), bủa vây quét định kỳ vào vị trí `0x2000_0000`. Phóng sóng Load Word lấy ký tự "H" đó rinh vào dạ dày thanh ghi ALU của nó.
3. **[CPU -> RAM]:** ALU phân tách, CPU ra lệnh Store Word (`sw`). Dòng chữ "H" lội ngược dòng qua Bus Data chui vào khối `soc_ram.v` lữu trữ tại địa chỉ RAM cục bộ `0x1000_0080` dùng cho việc tích lũy chữ liệu.
4. **[CPU -> Ngoại vi]:** Firmware kêu làm một thuật toán mã hoá (VD chữ "H" đổi thành chữ "J"). ALU lấy cớ dời chữ đó, lại ra lệnh ném mạnh vào `0x2000_1000` (GPIO Port hoặc UART Tx). Thế là đầu dây phần cứng của module lập tức bung số liệu bắn vọt trở ra thiên nhiên thực.

_(Kết thúc quá trình hoàn chỉnh của một bộ não Chip SoC)_