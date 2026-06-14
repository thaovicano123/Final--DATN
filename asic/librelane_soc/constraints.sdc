# ==============================================================================
# SDC Constraints cho LibreLane SoC (PicoRV32 Low-Power)
# Tần số mục tiêu: 20 MHz (Chu kỳ 50ns)
# Tối ưu cho thiết kế tiêu thụ dòng rò thấp (Low-Leakage / Low-Power)
# ==============================================================================

# 1. Định nghĩa Clock
set clk_name clk
set clk_port_name clk
set clk_period 50.0

create_clock -name $clk_name -period $clk_period [get_ports $clk_port_name]

# Độ rung pha (Jitter) và độ dốc (Transition)
# Đặt uncertainty tách biệt cho Setup và Hold
set_clock_uncertainty -setup 2.5 [get_clocks $clk_name]
set_clock_uncertainty -hold 0.25 [get_clocks $clk_name]
set_clock_transition 0.5 [get_clocks $clk_name]

# 2. Định nghĩa Input/Output Delays
# Đặt trễ I/O bằng khoảng 20% chu kỳ clock (10ns), chừa 80% (40ns) cho internal paths
set io_delay 10.0

# Input delays
set_input_delay $io_delay -clock [get_clocks $clk_name] [get_ports {resetn}]
set_input_delay $io_delay -clock [get_clocks $clk_name] [get_ports {uart_rx}]
set_input_delay $io_delay -clock [get_clocks $clk_name] [get_ports {gpio_in[*]}]

# Output delays
set_output_delay $io_delay -clock [get_clocks $clk_name] [get_ports {uart_tx}]
set_output_delay $io_delay -clock [get_clocks $clk_name] [get_ports {gpio_out[*]}]

# 3. Driving Cells & Load (Mô phỏng thực tế vật lý)
# Giả sử ngõ ra kéo một tải điện dung điển hình (10fF)
set_load 0.010 [all_outputs]

# 4. Ràng buộc quan trọng cho Clock Gating (Low-Power)
# Đảm bảo tín hiệu enable đến ICG cells phải thỏa mãn timing so với clock,
# nếu không sẽ sinh ra xung nhiễu (glitch) phá hỏng logic của module.
set_clock_gating_check -setup 0.5 -hold 0.2 [get_clocks $clk_name]

# Bỏ qua timing trên chân reset
set_false_path -from [get_ports resetn]
