#include <stdint.h>

#define UART_BASE   0x20000000u
#define GPIO_BASE   0x20002000u
#define CMU_BASE    0x20003000u

#define UART_TXDATA   0x00u
#define UART_STATUS   0x04u
#define UART_RXDATA   0x08u

#define GPIO_DATA_OUT 0x00u
#define GPIO_DATA_IN  0x04u
#define GPIO_DIR      0x08u
#define GPIO_TOGGLE   0x0Cu

#define CMU_CLK_EN    0x00u

volatile uint32_t irq_count = 0;

static inline void mmio_write(uint32_t addr, uint32_t value)
{
    *(volatile uint32_t *)(uintptr_t)addr = value;
}

static inline uint32_t mmio_read(uint32_t addr)
{
    return *(volatile uint32_t *)(uintptr_t)addr;
}

// Inline assembly macro to enable interrupts globally (set mstatus.mie bit = bit 3)
// NOTE: IRQs are already unmasked by maskirq instruction in irq_start.S boot sequence.

// PicoRV32 WFI (Wait For Interrupt) custom instruction
// .word 0x10500033 is the encoding for: funct7=0x20 (010_0000), rs2=0x0A (01010), rs1=0x00, funct3=0x0, rd=0x00, opcode=0x0B
#define WFI() \
    asm volatile(".word 0x10500033\n\t")

static void uart_wait_tx_ready(void)
{
    while ((mmio_read(UART_BASE + UART_STATUS) & 0x1u) == 0) {
        // polling TX status: bit 0 = !tx_busy
    }
}

static void uart_putc(char c)
{
    uart_wait_tx_ready();
    mmio_write(UART_BASE + UART_TXDATA, (uint32_t)(uint8_t)c);
}

static void uart_puts(const char *s)
{
    while (*s) {
        uart_putc(*s++);
    }
}

int main(void)
{
    volatile uint32_t i;

    // Enable UART (bit0) + GPIO (bit1) clocks. SPI removed for power optimization.
    mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000003u);

    // GPIO bit0 (foreground) and bit8 (background IRQ indicator) as outputs.
    mmio_write(GPIO_BASE + GPIO_DIR, 0x00000101u);
    mmio_write(GPIO_BASE + GPIO_DATA_OUT, 0x00000001u);

    uart_puts("Phase3 IRQ demo with WFI low-power loop (UART IRQ enabled)\n");

    // Interrupts are already enabled by maskirq instruction in irq_start.S boot.
    // No need to explicitly enable here.

    // ========== FULL WFI LOW-POWER LOOP ==========
    // Phase 1: Brief polling to let firmware settle
    for (i = 0; i < 50u; i++) {
        mmio_write(GPIO_BASE + GPIO_TOGGLE, 0x00000001u);
        asm volatile("nop\n\tnop\n\tnop\n\tnop\n\tnop\n\t");
    }

    // Phase 2: Continuous WFI low-power loop
    // CPU enters idle state, consuming minimal power, awaiting UART RX interrupt.
    // On each UART RX byte (from testbench stimulus):
    //   - IRQ handler (in irq_start.S) toggles GPIO[8] and increments irq_count
    //   - CPU returns to WFI via custom retirq instruction
    // This demonstrates full interrupt-driven, low-power design.
    while (1) {
        WFI();  // CPU idles here until UART IRQ arrives
        // After retirq from IRQ handler, execution returns here
    }
}
