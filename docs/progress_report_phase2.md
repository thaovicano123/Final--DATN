# BÁO CÁO TIẾN ĐỘ GIAI ĐOẠN 2 (TUẦN 3-6)

**Tên đề tài:** Thiết kế SoC Low Power với PicoRV32 theo luồng ASIC  
**Giai đoạn báo cáo:** Giai đoạn 2 - Thiết kế kiến trúc SoC và viết RTL  
**Ngày báo cáo:** 18/04/2026

## 1. Mục tiêu
1. Hoàn thiện kiến trúc SoC gồm PicoRV32, ROM, RAM, UART, SPI, GPIO.
2. Thiết kế bus/interconnect đơn giản bằng address decoder để định tuyến truy cập MMIO.
3. Tích hợp low power bằng CMU và clock gating cho UART/SPI/GPIO.
4. Kết nối hoàn chỉnh ở mức top-level RTL và kiểm chứng bằng mô phỏng.

## 2. Việc đã làm
### 2.1. Thiết kế kiến trúc
- Hoàn thiện sơ đồ khối hệ thống: `docs/block_diagram.md`
- Hoàn thiện bản đồ địa chỉ: `docs/address_map.md`
- Hoàn thiện policy clock gating: `docs/clock_gating_policy.md`

### 2.2. Viết RTL
- Top-level SoC: `rtl/soc_top.v`
- Address decoder: `rtl/bus_decoder.v`
- Clock gating:
  - ICG cell: `rtl/icg_cell.v`
  - CMU: `rtl/cmu.v`
- Bộ nhớ:
  - ROM: `rtl/soc_rom.v`
  - RAM: `rtl/soc_ram.v`
- Ngoại vi MMIO:
  - UART: `rtl/uart_mmio.v`
  - SPI + IRQ: `rtl/spi_mmio.v`
  - GPIO: `rtl/gpio_mmio.v`

### 2.3. Kiểm chứng RTL và chức năng
- Kiểm tra compile RTL: `scripts/check_phase2_rtl.sh` (PASS)
- Testbench tự động MMIO + IRQ + clock gating:
  - `tb/tb_phase2_mmio_irq_gating.v`
  - `scripts/run_phase2_tb.sh`
  - Kết quả PASS
- Testbench SoC có CPU chạy firmware thực:
  - Firmware: `fw/start.S`, `fw/main.c`, `fw/linker.ld`
  - Build firmware: `scripts/build_fw.sh`
  - Smoke test SoC: `tb/tb_soc_top_smoke.v`, `scripts/run_soc_top_smoke.sh`
  - Kết quả PASS

## 3. Kết quả đạt được
1. SoC RTL tích hợp hoàn chỉnh đã hình thành.
2. Clock gating hoạt động đúng theo điều khiển CMU (enable/disable/selective re-enable).
3. SPI interrupt được kiểm chứng assert/clear trong mô phỏng.
4. CPU PicoRV32 chạy được firmware tự tạo trên map địa chỉ của hệ thống và điều khiển UART/GPIO thành công.

## 4. Bằng chứng
1. Trạng thái giai đoạn: `docs/phase2_status.md`
2. Log testbench ngoại vi + gating: `results/phase2/tb_phase2_mmio_irq_gating.log`
3. VCD testbench ngoại vi + gating: `results/phase2/tb_phase2_mmio_irq_gating.vcd`
4. Log smoke test có CPU: `results/phase2/tb_soc_top_smoke.log`
5. VCD smoke test có CPU: `results/phase2/tb_soc_top_smoke.vcd`
6. Firmware image nạp ROM: `fw/firmware.hex`

## 5. Kế hoạch tuần tới
1. Bắt đầu Giai đoạn 3: viết firmware đầy đủ (UART Hello, GPIO control, SPI interrupt service).
2. Viết testbench SoC đầy đủ với kịch bản kiểm chứng low power có số liệu waveform cụ thể.
3. Chuẩn bị script tổng hợp report tự động từ log mô phỏng để phục vụ báo cáo đồ án.
4. Bổ sung lint/check coding style cho RTL để giảm rủi ro khi sang synthesis.

## 6. Kết luận
Giai đoạn 2 đã đạt mục tiêu kỹ thuật cốt lõi: kiến trúc SoC hoàn chỉnh, RTL tích hợp đầy đủ, clock gating hoạt động và đã có bằng chứng mô phỏng PASS ở cả mức ngoại vi và mức hệ thống có CPU chạy firmware thực tế.