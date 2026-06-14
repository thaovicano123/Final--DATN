# Tổng Hợp Ý Tưởng, Tiến Độ và Trạng Thái Flow Dự Án SoC PicoRV32

## 1. Mục tiêu và ý tưởng tổng thể
Dự án của bạn là xây dựng một SoC nhỏ gọn, tối ưu công suất và có thể đi đến mức layout ASIC hoàn chỉnh bằng flow LibreLane/OpenROAD trên công nghệ Sky130. Nền tảng tính toán chính là PicoRV32, một lõi RISC-V nhỏ gọn, dễ tích hợp, phù hợp với mục tiêu diện tích thấp và khả năng kiểm soát clock gating tốt.

Ý tưởng cốt lõi của đề tài gồm bốn phần:
- xây dựng một SoC tối giản nhưng đủ chức năng, với CPU PicoRV32 làm trung tâm;
- tích hợp các ngoại vi cơ bản qua bus MMIO gồm UART và GPIO;
- thêm khối ROM/RAM để chạy firmware và kiểm chứng chức năng;
- áp dụng clock gating và luồng P&R phân cấp để giảm công suất và dễ harden từng khối riêng lẻ.

Về mặt triển khai, kiến trúc dự án đã được chia theo các lớp rõ ràng:
- RTL và testbench nằm trong `rtl/` và `tb/`;
- firmware và linker script nằm trong `fw/`;
- luồng ASIC và các config block/top-level nằm trong `librelane/`;
- tài liệu phân tích kiến trúc, tiến độ và checklist nằm trong `docs/` và các file tổng hợp ở root.

## 2. Kiến trúc hệ thống hiện tại
SoC hiện tại không chỉ là một lõi CPU đơn lẻ mà là một hệ thống hoàn chỉnh gồm nhiều khối chức năng đã được kết nối và kiểm chứng ở mức mô phỏng cũng như mức P&R block-level.

Các khối chính hiện có:
- PicoRV32: lõi xử lý trung tâm;
- bus decoder: giải mã địa chỉ MMIO;
- CMU: quản lý clock gating;
- UART, GPIO: các ngoại vi giao tiếp cơ bản;
- ROM và RAM: vùng nhớ cho firmware và dữ liệu;
- top-level `soc_top_asic`: nơi tích hợp tất cả macro và logic còn lại để đi tới GDS cuối.

Luồng thiết kế hiện đã đi theo hướng hierarchical P&R, tức là thay vì đẩy toàn bộ design vào một flow phẳng, bạn harden từng khối thành macro trước, sau đó tích hợp các macro đó vào top-level. Đây là hướng đi đúng cho một SoC có nhiều khối đã ổn định và có mục tiêu signoff rõ ràng.

## 3. Tiến độ hiện tại trong flow
### 3.1. Những phần đã hoàn thành
Phần RTL và mô phỏng chức năng đã đi qua giai đoạn rủi ro lớn nhất.

- RTL của SoC đã hoàn chỉnh ở mức kiến trúc chính.
- Firmware đã build và test thành công ở nhiều chế độ, bao gồm kịch bản cơ bản, IRQ và clock gating.
- Các lỗi logic trước đây như IRQ, polarity clock gating và decode MMIO đã được ghi nhận và xử lý.
- Block-level P&R cho UART, GPIO, RAM, ROM đã được thực hiện, giúp bạn có các hard macro riêng cho từng khối.
- Macro LEF/GDS đã được gom lại để chuẩn bị cho top-level hierarchical flow.
- Có file đặt macro top-level là `librelane/soc_top_asic/macro_placement.cfg`.
- Top-level đã được cấu hình để tham chiếu các macro này và chạy theo flow tích hợp.

### 3.2. Đang ở đâu trong flow
Hiện tại dự án đang ở giai đoạn **Top-Level Integration / P&R cho `soc_top_asic`**.

Nếu nhìn theo tiến trình chuẩn của ASIC flow, bạn đã đi qua:
1. RTL design.
2. Simulation / firmware verification.
3. Block-level hardening.
4. Macro collection và top-level setup.
5. Top-level P&R.

Bước hiện tại là bước 5, và cụ thể hơn là đã đi rất sâu vào P&R, gần đến signoff phần vật lý. Theo log mới nhất, flow đã chạm tới khoảng **Stage 59 - IR Drop Report** rồi dừng vì lỗi nguồn/PDN.

Nói ngắn gọn, dự án của bạn không còn ở mức “thiết kế RTL” nữa mà đã ở mức “tích hợp vật lý cuối” của chip.

## 4. Những lỗi đã được ghi nhận và tình trạng của chúng
### 4.1. Lỗi đã giải quyết
#### 4.1.1. Lỗi RTL và mô phỏng trước đây
Trong giai đoạn trước, project từng gặp một số vấn đề logic và tích hợp, chủ yếu liên quan đến:
- IRQ vector và luồng xử lý ngắt;
- polarity clock gating;
- decode MMIO và tích hợp bus;
- một số vấn đề liên quan tới dữ liệu firmware và wrapper mô phỏng.

Các lỗi này đã được xử lý và không còn là điểm chặn flow hiện tại.

#### 4.1.2. Lỗi block-level P&R
Khi chạy P&R cho từng block riêng lẻ, có những trường hợp area quá chật, density cao hoặc layout chưa đủ khoảng trống cho placement/routing.

Đặc biệt, một số block phải điều chỉnh die area, mật độ đặt cell và các tham số P&R để pass ổn định. Kết quả là:
- UART, SPI, GPIO, RAM, ROM đều đã có run block-level thành công;
- macro harden của các khối này đã sẵn sàng cho top-level.

#### 4.1.3. Lỗi lint Verilator ở top-level
Trước đó, run top-level bị lỗi `PINNOTFOUND` do Verilator không nhận diện được parameter của `soc_rom` và `soc_ram` khi lint.

Trạng thái hiện tại: lỗi này đã được gỡ bằng cách làm cho lint có thể thấy phần khai báo parameter của các module liên quan. Đây không còn là lỗi chặn chính nữa.

### 4.2. Lỗi còn tồn đọng ở lần chạy mới nhất
#### 4.2.1. Lỗi PDN / IR drop trên VPWR
Đây là lỗi quan trọng nhất và là nguyên nhân chính khiến flow dừng lại.

Log cho thấy:
- `PSM-0069 Check connectivity failed on VPWR`;
- nhiều cảnh báo `Unconnected shape on net VPWR`;
- nhiều cảnh báo `Unconnected instance .../VPWR`.

Điều đó có nghĩa là lưới nguồn `VPWR` chưa được nối kín hoặc chưa được triển khai đúng cho toàn bộ macro/top-level. Khi kiểm tra PDN và IR drop, OpenROAD phát hiện một số shape và instance nguồn không liên thông đúng cách nên dừng flow.

#### 4.2.2. Cảnh báo macro thiếu liberty model
Flow có cảnh báo `LEF master gpio_mmio has no liberty cell`.

Ý nghĩa của cảnh báo này là macro đang có LEF/GDS, nhưng phần timing/power model tương ứng chưa được gắn đầy đủ hoặc chưa được flow nhận đúng. Cảnh báo này chưa phải là lỗi dừng flow ngay, nhưng nếu không xử lý thì có thể ảnh hưởng đến STA và signoff sau này.

#### 4.2.3. Cảnh báo SDC chưa được khai báo rõ
Log cũng báo:
- `PNR_SDC_FILE is not defined`;
- `SIGNOFF_SDC_FILE is not defined`.

Flow đang dùng fallback SDC. Điều này có nghĩa là top-level chưa có constraint file được khai báo đầy đủ cho P&R và signoff, nên timing analysis chưa thật sự chặt chẽ.

#### 4.2.4. Cảnh báo macro placement theo kiểu cũ
LibreLane báo rằng `MACRO_PLACEMENT_CFG` là cách khai báo deprecated và khuyến nghị dùng `MACROS`.

Đây không phải lỗi chặn ngay, nhưng là dấu hiệu cho thấy config top-level cần được cập nhật để phù hợp hơn với flow hiện tại và giảm rủi ro khi tool thay đổi hành vi.

#### 4.2.5. Cảnh báo clock fanout lớn
Net `clk` có fanout rất lớn.

Đây là cảnh báo thường gặp ở SoC nhiều khối, đặc biệt khi tích hợp nhiều macro. Nó chưa gây fail ngay, nhưng có thể ảnh hưởng đến CTS, skew và timing closure nếu không được theo dõi trong các bước tiếp theo.

## 5. Tình trạng hiện tại của flow theo góc nhìn kỹ thuật
Nếu tóm tắt theo chuỗi nguyên nhân - kết quả, tình trạng hiện tại là:

1. RTL đã ổn định.
2. Firmware và mô phỏng chức năng đã pass.
3. Block-level hardening đã làm xong.
4. Top-level đã có macro placement và macro artifacts.
5. Top-level P&R đã chạy tới giai đoạn rất muộn.
6. Flow hiện dừng vì **VPWR connectivity / PDN** trong bước IR drop report.

Nói cách khác, project đã vượt qua phần rủi ro logic và đang kẹt ở phần rủi ro vật lý cuối cùng.

## 6. Công việc tiếp theo cần làm để tiếp tục flow
Đây là thứ tự công việc nên ưu tiên nếu mục tiêu là chạy tiếp được top-level P&R:

### 6.1. Sửa lỗi VPWR connectivity / PDN
Đây là việc cần làm đầu tiên vì nó là lỗi chặn trực tiếp.

Bạn cần kiểm tra:
- macro LEF/GDS có pin nguồn đúng tên không;
- hướng đặt macro và cách nối power rail có bị lệch không;
- file macro placement có tạo ra vùng nguồn bị ngắt quãng hay không;
- config PDN top-level đã cover đầy đủ các vùng macro chưa.

Mục tiêu là làm cho lưới `VPWR` liên tục và không còn shape/instance bị “unconnected”.

### 6.2. Bổ sung SDC rõ ràng cho top-level
Sau khi xử lý nguồn, nên điền rõ:
- `PNR_SDC_FILE`;
- `SIGNOFF_SDC_FILE`.

Việc này giúp timing analysis không còn phải dùng fallback mặc định, đồng thời chuẩn hóa flow cho bước CTS và signoff.

### 6.3. Cập nhật config macro theo cách mới nếu cần
Vì LibreLane đã cảnh báo `MACRO_PLACEMENT_CFG` là deprecated, bạn nên cân nhắc chuyển sang cơ chế `MACROS` nếu flow hiện tại hỗ trợ đầy đủ.

Điều này giúp config sạch hơn và giảm nguy cơ lỗi khi tool hoặc wrapper thay đổi.

### 6.4. Kiểm tra timing model của các macro
Với các macro như `gpio_mmio`, cần xác nhận rằng timing/liberty model đã có đủ để top-level STA hoạt động tốt.

Nếu thiếu `.lib`, flow vẫn có thể đi một đoạn, nhưng signoff timing sẽ không đáng tin cậy.

### 6.5. Chạy lại top-level P&R sau khi sửa PDN
Khi VPWR connectivity pass và constraint đã đủ, flow sẽ có cơ hội đi tiếp qua:
- IR drop report;
- CTS;
- detailed routing;
- signoff;
- xuất kết quả cuối cùng của `soc_top_asic`.

## 7. Kết luận ngắn
Bạn đã hoàn thành phần nền tảng quan trọng nhất của dự án: RTL, firmware, verification và block-level hardening. Hiện tại project đang ở giai đoạn top-level ASIC integration, và lỗi chặn chính là lỗi nguồn/PDN trên `VPWR` khi chạy IR drop.

Điều đó có nghĩa là dự án đã đi rất gần đến mốc hoàn thiện flow vật lý. Việc cần làm tiếp theo không còn là sửa logic thiết kế nữa, mà là xử lý lớp vật lý cuối cùng để top-level P&R có thể chạy tới signoff.
