#include <stdint.h>

// ============================================================================
// LibreLane SoC — Main Firmware (GPIO Demo, Low-Power Ready)
// Firmware chính cho demo GPIO toggle + UART IRQ awareness.
// IRQ handler thực tế nằm trong irq_start.S (assembly).
// ============================================================================

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

// Global variable: UART RX interrupt count (updated by IRQ handler in irq_start.S)
volatile uint32_t irq_count = 0;

static inline void mmio_write(uint32_t addr, uint32_t value)
{
    *(volatile uint32_t *)(uintptr_t)addr = value;
}

static inline uint32_t mmio_read(uint32_t addr)
{
    return *(volatile uint32_t *)(uintptr_t)addr;
}

int main(void)
{
    volatile uint32_t i;

    // Enable peripheral gated clocks: UART (bit 0) + GPIO (bit 1)
    mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000003u);

    // Configure GPIO: bits [7:0] as outputs
    mmio_write(GPIO_BASE + GPIO_DIR, 0x000000FFu);

    // ========================================
    // Low-Power Operation:
    // - UART IRQ configured (irq_rx → CPU irq[0])
    // - CPU interrupts enabled (ENABLE_IRQ=1, PROGADDR_IRQ=0x10)
    // - IRQ handler in irq_start.S handles UART RX:
    //     toggles GPIO[8], increments irq_count,
    //     reads UART_RXDATA to auto-clear IRQ.
    // - In deployment: CPU executes WFI to sleep until IRQ.
    // ========================================

    // Demo loop: toggle GPIO to show CPU is alive
    while (1) {
        // Toggle GPIO[7:0]
        mmio_write(GPIO_BASE + GPIO_TOGGLE, 0x000000FFu);

        // Delay (in real low-power mode, this would be WFI instead)
        for (i = 0; i < 1000u; i++) {
            asm volatile("nop");
        }
    }

    return 0;
}
