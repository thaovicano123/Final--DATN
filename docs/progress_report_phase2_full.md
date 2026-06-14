# BÁO CÁO TIẾN ĐỘ ĐẦY ĐỦ GIAI ĐOẠN 2 (TUẦN 3-6)

**Tên đề tài:** SoC Low Power với PicoRV32 theo hướng ASIC  
**Giai đoạn:** Giai đoạn 2 - Thiết kế kiến trúc SoC và viết RTL  
**Thời gian thực hiện:** Tuần 3 đến Tuần 6  
**Ngày cập nhật:** 18/04/2026

## 1. Mục tiêu giai đoạn
 Giai đoạn 2 đặt mục tiêu xây dựng một hệ thống phần cứng hoàn chỉnh ở mức RTL, trong đó CPU PicoRV32 kết nối và giao tiếp được với các ngoại vi cơ bản (ROM, RAM, UART, GPIO), đồng thời tích hợp cơ chế low-power bằng clock gating cho các ngoại vi.

Mục tiêu cụ thể gồm:
1. Hoàn thiện kiến trúc SoC và sơ đồ khối.
2. Thiết kế bus/interconnect đơn giản dựa trên address decoder.
3. Tích hợp module quản lý clock (CMU) và cổng ICG cho UART/GPIO.
4. Hoàn thiện top-level wrapper và kiểm chứng mô phỏng.

## 2. Phạm vi công việc đã thực hiện

### 2.1. Thiết kế kiến trúc và tài liệu hóa
Đã hoàn thiện các tài liệu thiết kế nền tảng:
1. Sơ đồ khối hệ thống: [docs/block_diagram.md](docs/block_diagram.md)
2. Bản đồ địa chỉ MMIO và memory map: [docs/address_map.md](docs/address_map.md)
3. Chính sách clock gating: [docs/clock_gating_policy.md](docs/clock_gating_policy.md)

Kết quả:
- Kiến trúc được chốt rõ ràng trước khi viết RTL, giảm sửa đổi lớn về sau.
- Address map nhất quán giữa RTL, testbench và firmware.

### 2.2. Viết RTL hệ thống SoC
Đã triển khai đầy đủ các module RTL cốt lõi:
1. Top-level tích hợp: [rtl/soc_top.v](rtl/soc_top.v)
2. Decoder/interconnect:
   - [rtl/bus_decoder.v](rtl/bus_decoder.v)
3. Clock management và low-power:
   - [rtl/icg_cell.v](rtl/icg_cell.v)
   - [rtl/cmu.v](rtl/cmu.v)
4. Bộ nhớ hệ thống:
   - [rtl/soc_rom.v](rtl/soc_rom.v)
   - [rtl/soc_ram.v](rtl/soc_ram.v)
5. Ngoại vi MMIO:
   - [rtl/uart_mmio.v](rtl/uart_mmio.v)
   - [rtl/gpio_mmio.v](rtl/gpio_mmio.v)

Kết quả:
- Hệ thống có thể định tuyến đúng truy cập bộ nhớ/ngoại vi theo địa chỉ.
- (SPI peripheral has been removed from this project.)
- CMU có thể bật/tắt clock ngoại vi theo thanh ghi điều khiển.

Ghi chú triển khai bộ nhớ:
- ROM/RAM được triển khai dưới dạng inferred memory models (wrapper học thuật), không dùng macro doanh nghiệp.
- Cách làm này đảm bảo kiểm chứng chức năng end-to-end trong điều kiện đồ án.
- Interface wrapper được giữ ổn định để thay bằng memory macro ở giai đoạn ASIC enterprise.

### 2.3. Xây dựng quy trình kiểm chứng tự động
Đã xây dựng bộ script/testbench để verify nhiều lớp:

1. RTL compile check:
- Script: [scripts/check_phase2_rtl.sh](scripts/check_phase2_rtl.sh)

- 2. Testbench ngoại vi (MMIO + Clock Gating):
- - Testbench: [tb/tb_phase2_mmio_irq_gating.v](tb/tb_phase2_mmio_irq_gating.v)
- Script chạy: [scripts/run_phase2_tb.sh](scripts/run_phase2_tb.sh)
- Log PASS: [results/phase2/tb_phase2_mmio_irq_gating.log](results/phase2/tb_phase2_mmio_irq_gating.log)
- Waveform: [results/phase2/tb_phase2_mmio_irq_gating.vcd](results/phase2/tb_phase2_mmio_irq_gating.vcd)

3. SoC smoke test có CPU chạy firmware thực:
- Testbench: [tb/tb_soc_top_smoke.v](tb/tb_soc_top_smoke.v)
- Script chạy: [scripts/run_soc_top_smoke.sh](scripts/run_soc_top_smoke.sh)
- Log PASS: [results/phase2/tb_soc_top_smoke.log](results/phase2/tb_soc_top_smoke.log)
- Waveform: [results/phase2/tb_soc_top_smoke.vcd](results/phase2/tb_soc_top_smoke.vcd)

4. IRQ end-to-end với firmware và ISR thực thi:
- Testbench: [tb/tb_soc_top_irq.v](tb/tb_soc_top_irq.v)
- Script chạy: [scripts/run_phase3_irq_tb.sh](scripts/run_phase3_irq_tb.sh)
- Log PASS: [results/phase2/tb_soc_top_irq.log](results/phase2/tb_soc_top_irq.log)
- Waveform: [results/phase2/tb_soc_top_irq.vcd](results/phase2/tb_soc_top_irq.vcd)

## 3. Các cải thiện kỹ thuật đã đạt được

### 3.1. Cải thiện khả năng tái lập (reproducibility)
- Trước: chạy mô phỏng thủ công, phụ thuộc thao tác từng lệnh.
- Sau: đã chuẩn hóa thành script một lệnh, giảm sai sót và dễ demo/nộp bài.
- Tác động: giảm thời gian xác minh lại hệ thống, phù hợp làm việc theo mốc tuần.

### 3.2. Cải thiện độ tin cậy kiểm chứng
- Trước: mới dừng ở compile RTL và test ngoại vi rời rạc.
- Sau: đã có kiểm chứng nhiều tầng, từ module-level đến SoC-level có CPU và firmware thực.
- Tác động: tăng độ tin cậy rằng thiết kế không chỉ đúng cú pháp mà còn đúng hành vi hệ thống.

### 3.3. Cải thiện tích hợp low-power
- Trước: mới có định hướng clock gating trên tài liệu.
- Sau: đã tích hợp CMU + ICG và chứng minh clock ngoại vi dừng/chạy theo bit enable.
- Tác động: đáp ứng đúng trọng tâm kỹ thuật low-power trong đề tài.

### 3.4. Cải thiện luồng firmware-hardware co-design
- Trước: firmware chung, chưa tối ưu cho bản đồ địa chỉ SoC hiện tại.
- Sau: đã có firmware phù hợp address map, chạy được UART/GPIO và IRQ flow thực.
- Tác động: chuẩn bị tốt cho Giai đoạn 3 và giảm rủi ro khi sang tổng hợp/synthesis.

## 4. Mức độ đáp ứng yêu cầu Giai đoạn 2

### Yêu cầu 1: Lên sơ đồ khối
**Trạng thái:** Đã đáp ứng đầy đủ  
**Bằng chứng:** [docs/block_diagram.md](docs/block_diagram.md), [docs/address_map.md](docs/address_map.md)

### Yêu cầu 2: Thiết kế bus hệ thống
**Trạng thái:** Đã đáp ứng đầy đủ  
**Bằng chứng:** [rtl/bus_decoder.v](rtl/bus_decoder.v), [rtl/soc_top.v](rtl/soc_top.v)

### Yêu cầu 3: Tích hợp thiết kế low power (CMU + ICG)
**Trạng thái:** Đã đáp ứng đầy đủ  
**Bằng chứng:** [rtl/cmu.v](rtl/cmu.v), [rtl/icg_cell.v](rtl/icg_cell.v), [results/phase2/tb_phase2_mmio_irq_gating.log](results/phase2/tb_phase2_mmio_irq_gating.log)

### Yêu cầu 4: Kết nối hệ thống top-level
**Trạng thái:** Đã đáp ứng đầy đủ  
**Bằng chứng:** [rtl/soc_top.v](rtl/soc_top.v), [results/phase2/tb_soc_top_smoke.log](results/phase2/tb_soc_top_smoke.log)

## 5. Kết quả định lượng/định tính nổi bật

### 5.1. Bằng chứng định lượng giảm switching trên clock ngoại vi
Để lượng hóa hiệu quả clock gating trong Giai đoạn 2, testbench đã đo số lần chuyển trạng thái (toggle count) của từng gated clock trong cùng một cửa sổ quan sát khi:
1. Clock enable ban đầu (trạng thái hoạt động bình thường).
2. Clock bị disable qua thanh ghi CMU.
3. Clock được enable lại có chọn lọc.

Nguồn số liệu: [results/phase2/tb_phase2_mmio_irq_gating.log](results/phase2/tb_phase2_mmio_irq_gating.log)

Kết quả đo:

| Tín hiệu | Toggle khi enable ban đầu | Toggle khi disable | Mức giảm switching |
|---|---:|---:|---:|
| GCLK_UART | 40 | 1 | 97.5% |
| GCLK_GPIO | 40 | 0 | 100% |

Giải thích cách tính:
- Mức giảm switching (%) = `(toggle_enable - toggle_disable) / toggle_enable * 100`.
- Ví dụ UART: `(40 - 1) / 40 = 97.5%`.

Ý nghĩa kỹ thuật:
1. Khi tắt gate, hoạt động chuyển mạch clock của SPI/GPIO về 0 trong cửa sổ đo, cho thấy clock đã bị cắt đúng chức năng.
2. UART còn 1 toggle ở thời điểm chuyển trạng thái enable->disable (biên chuyển tiếp hợp lệ), không phải dao động duy trì.
3. Sau khi re-enable, các clock hoạt động trở lại đúng kỳ vọng (UART/GPIO có toggle, SPI giữ off khi chưa bật lại), chứng minh cơ chế điều khiển gate là ổn định và có chọn lọc.

### 5.2. Kết quả kiểm chứng chức năng liên quan
1. Testbench MMIO + gating + IRQ: PASS.
2. SoC CPU smoke test: PASS.
3. SoC IRQ end-to-end: PASS với chỉ dấu ISR rõ ràng (`irq_gpio_toggles=1880`).
4. VCD cho các nhóm kiểm chứng đã được tạo và lưu để minh họa báo cáo.

### 5.3. Giới hạn của số liệu ở Giai đoạn 2
1. Số liệu hiện tại là switching activity (mức chuyển mạch tín hiệu clock) trong mô phỏng RTL.
2. Đây là bằng chứng định lượng cho hiệu quả cơ chế clock gating ở mức hành vi số.
3. Chưa phải số liệu công suất vật lý (mW/uW) ở mức ASIC; phần đó cần synthesis và power report trong Giai đoạn 4.
4. ROM/RAM hiện là inferred models nên timing/area/power chưa đại diện cho macro bộ nhớ của công nghệ đích.

### 5.4. Khẳng định phạm vi hợp lệ của kiểm chứng bộ nhớ
1. Hợp lệ trong phạm vi đồ án: kiểm chứng chức năng CPU-memory-MMIO-IRQ ở mức RTL.
2. Chưa phải sign-off silicon memory: cần thay wrapper bằng macro thực trong flow doanh nghiệp.
3. Chiến lược thay thế đã được tài liệu hóa tại [docs/memory_model_strategy.md](docs/memory_model_strategy.md).

## 6. Rủi ro còn lại và biện pháp giảm rủi ro
1. Chưa chạy synthesis/power report trong giai đoạn này.
- Biện pháp: chuyển sang Giai đoạn 4 với flow Yosys baseline và so sánh before/after gating.

2. Chưa có regression test matrix dạng chuẩn báo cáo.
- Biện pháp: xây bảng test case (mục tiêu, expected, actual, artifact) trong tuần kế tiếp.

3. Cần bổ sung lint theo coding style ASIC.
- Biện pháp: thêm bước lint tự động trước synthesis.

## 7. Kế hoạch tuần tiếp theo
1. Hoàn thiện firmware Giai đoạn 3 theo kịch bản đề bài (UART hello, GPIO control, SPI interrupt flow rõ ràng hơn).
2. Hoàn thiện testbench hệ thống có đo/ghi chỉ số hành vi low-power từ waveform.
3. Chuẩn bị script synthesis baseline để mở đầu Giai đoạn 4.
4. Tạo verification matrix và phụ lục bằng chứng để nộp giáo viên.

## 8. Kết luận
Giai đoạn 2 đã được hoàn thành đầy đủ theo yêu cầu đề bài. Ngoài các yêu cầu bắt buộc, hệ thống còn được nâng cấp chất lượng kiểm chứng bằng các flow tự động và kiểm tra end-to-end có CPU chạy firmware thực và IRQ handler thực thi. Điều này tạo nền tảng kỹ thuật vững chắc để bước sang Giai đoạn 3 và Giai đoạn 4 với rủi ro tích hợp thấp hơn.
