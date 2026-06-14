# BÁO CÁO TIẾN ĐỘ GIAI ĐOẠN 1 (TUẦN 1-2)

**Tên đề tài:** Thiết kế SoC Low Power với PicoRV32 theo luồng ASIC  
**Giai đoạn báo cáo:** Giai đoạn 1 - Chuẩn bị môi trường và kiến thức nền  
**Thời gian thực hiện:** Tuần 1 đến Tuần 2  
**Ngày báo cáo:** 18/04/2026

## 1. Mục tiêu
Giai đoạn 1 đặt ra ba mục tiêu chính:
1. Hoàn tất môi trường làm việc trên Linux và cài đặt các công cụ thiết kế/mô phỏng cần thiết.
2. Nắm được nền tảng tích hợp PicoRV32, tập trung vào giao tiếp bộ nhớ (Native Memory Interface/AXI4-Lite) và cơ chế ngắt (Interrupt/IRQ).
3. Chuẩn bị cơ sở cho hướng thiết kế low power, đặc biệt là định hướng áp dụng clock gating cho ngoại vi trong các giai đoạn sau.

## 2. Việc đã làm
Trong giai đoạn này, nhóm đã thực hiện các công việc sau:

### 2.1. Thiết lập môi trường và toolchain
- Xác nhận môi trường Linux (Ubuntu) sẵn sàng cho luồng phát triển.
- Cài đặt các công cụ mô phỏng và biên dịch:
  - make
  - Icarus Verilog (iverilog, vvp)
  - GTKWave
  - RISC-V GNU toolchain (riscv64-unknown-elf-*)
- Chuẩn hóa script chạy smoke test để tương thích với toolchain cài từ Ubuntu package.

### 2.2. Thu thập mã nguồn và đọc hiểu PicoRV32
- Clone mã nguồn PicoRV32 từ GitHub (YosysHQ/Clifford Wolf).
- Đọc README theo đúng trọng tâm kỹ thuật:
  - Native Memory Interface (valid-ready protocol, read/write semantics, mem_wstrb)
  - Lựa chọn AXI4-Lite (picorv32_axi, picorv32_axi_adapter)
  - Cơ chế Interrupt/IRQ (irq input, eoi output, IRQ nội bộ 0/1/2)
- Tổng hợp thành tài liệu ghi chú kỹ thuật phục vụ thiết kế tích hợp SoC.

### 2.3. Chạy mô phỏng xác minh ban đầu
- Chạy testbench chuẩn của PicoRV32 với firmware test.
- Chạy testbench ở chế độ tạo VCD waveform.
- Lưu log và artifact để làm minh chứng báo cáo.

## 3. Kết quả đạt được
Kết quả chính của Giai đoạn 1 như sau:
1. Môi trường thiết kế và mô phỏng đã hoạt động ổn định.
2. Luồng biên dịch firmware và mô phỏng PicoRV32 chạy hoàn chỉnh.
3. Kết quả mô phỏng trả về trạng thái thành công toàn bộ test (ALL TESTS PASSED).
4. Đã tạo được waveform VCD phục vụ phân tích tín hiệu bằng GTKWave.
5. Đã hoàn tất tài liệu đọc hiểu interface/interrupt, sẵn sàng chuyển sang giai đoạn thiết kế kiến trúc SoC.

## 4. Bằng chứng
Các bằng chứng lưu trong workspace:
1. Biên bản xác nhận hoàn thành Giai đoạn 1: `docs/phase1_verification.md`
2. Ghi chú kỹ thuật PicoRV32 (Memory Interface/IRQ): `docs/notes_picorv32_interfaces.md`
3. Log mô phỏng smoke test: `results/phase1/make_test.log`
4. Log mô phỏng có tạo VCD: `results/phase1/make_test_vcd.log`
5. Waveform VCD: `third_party/picorv32/testbench.vcd`
6. Trace mô phỏng: `third_party/picorv32/testbench.trace`
7. Firmware hex sinh ra từ toolchain: `third_party/picorv32/firmware/firmware.hex`

## 5. Kế hoạch tuần tới (bắt đầu Giai đoạn 2)
Trong tuần tới, nhóm sẽ chuyển sang Giai đoạn 2 với các đầu việc cụ thể:
1. Chốt block diagram SoC gồm PicoRV32, ROM, RAM, UART, SPI, GPIO, CMU.
2. Xây dựng address map chính thức cho toàn hệ thống.
3. Viết RTL cho bus/address decoder và khung top-level SoC.
4. Xác định và tài liệu hóa policy clock gating cho UART/SPI/GPIO.
5. Chuẩn bị testbench mức hệ thống để verify chức năng đọc/ghi thanh ghi ngoại vi.

## 6. Kết luận
Giai đoạn 1 đã hoàn thành đúng mục tiêu đề ra: môi trường đã sẵn sàng, kiến thức nền về PicoRV32 đã được hệ thống hóa, và đã có bằng chứng mô phỏng pass đầy đủ. Cơ sở kỹ thuật hiện tại đủ điều kiện để triển khai Giai đoạn 2 (thiết kế kiến trúc và viết RTL tích hợp SoC).