# Block Area Budget Playbook (Pre-Top-Level)

Muc tieu: toi uu area tung block de khi vao top-level khong bi thieu area, nhung van giu pass timing/DRV/DRC/LVS.

## 1) Nguyen tac khoi tao budget

- Khoa moi block theo bo tieu chi chat luong:
  - flow__errors__count = 0
  - design__max_slew_violation__count = 0
  - design__max_cap_violation__count = 0 (dac biet corner max_ss_100C_1v60)
  - timing__setup_vio__count = 0, timing__hold_vio__count = 0
  - magic__drc_error__count = 0, design__lvs_error__count = 0
- Toi uu area theo vong lap nho (moi lan giam 5-12% canh die/core).
- Neu phat sinh max cap/slew hoac setup/hold vio: quay lai run truoc do va mo rong 1 nac.

## 2) Baseline tu cac run da co

| Block | Run tham chieu | Die bbox | Core area | Stdcell util |
|---|---|---|---:|---:|
| UART | RUN_2026-05-17_23-38-02 | 180 x 180 | 18955.7 | 0.064 |
| SPI  | RUN_SPI_RETUNE_CAPFIX  | 210 x 210 | 28163.3 | 0.258 |
| GPIO | RUN_2026-05-18_00-17-23 | 180 x 180 | 18955.7 | 0.362 |

Nhan xet nhanh:
- UART dang du area rat nhieu (util thap).
- SPI van co du dia de giam area nhe.
- GPIO kha can bang, co the giam nhe them 1 buoc.

## 3) De xuat vong toi uu A1 (an toan)

- UART A1: DIE 150x150, CORE 130x130
- SPI A1: DIE 190x190, CORE 170x170
- GPIO A1: DIE 170x170, CORE 150x150

Sau A1, chi giam tiep A2 neu tat ca metric signoff van sach.

## 4) Budget top-level theo macro die

Cong thuc nhanh:
- A_macro_sum = tong dien tich die cac hard macro
- A_place_guard = A_macro_sum x (1.30 den 1.45)  # halo + channel + de route
- Chon core top-level >= A_place_guard + phan stdcell top-level con lai

Uoc tinh nhanh voi A1 (UART/SPI/GPIO):
- A_macro_sum = 150^2 + 190^2 + 170^2 = 87500 um^2
- A_place_guard (x1.35) = 118125 um^2
- Side tuong duong ~ 344 um (chi tinh 3 peripheral macro)

Luu y:
- Top-level con phu thuoc lon vao RAM/ROM macro + PicoRV32 + channel giua macro.
- Neu RAM/ROM dung hard macro, can cong them dung kich thuoc LEF/GDS cua tung memory.

## 5) Checklist truoc khi chot block

- max_cap @ max_ss = 0
- max_slew tat ca corner = 0
- setup/hold vio = 0
- DRC/LVS clean
- critical_disconnected_pin = 0
- Ghi lai run lock trong file LOCKED_RUN.md cua block

## 6) Trinh tu khuyen nghi

1. Chay A1 cho UART -> danh gia.
2. Chay A1 cho SPI -> danh gia.
3. Chay lai GPIO voi A1 hien tai -> danh gia.
4. Lap bang budget top-level voi kich thuoc macro da lock cuoi cung.
5. Cap nhat DIE/CORE top-level theo budget + margin truoc khi full P&R.
