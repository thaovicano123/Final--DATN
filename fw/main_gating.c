#include <stdint.h>

#define GPIO_BASE   0x20002000u
#define CMU_BASE    0x20003000u

#define CMU_CLK_EN    0x00u

#define GPIO_DATA_OUT 0x00u
#define GPIO_DATA_IN  0x04u
#define GPIO_DIR      0x08u
#define GPIO_TOGGLE   0x0Cu


static inline void mmio_write(uint32_t addr, uint32_t value)
{
    *(volatile uint32_t *)(uintptr_t)addr = value;
}

static inline uint32_t mmio_read(uint32_t addr)
{
    return *(volatile uint32_t *)(uintptr_t)addr;
}

static void busy_delay(volatile uint32_t count)
{
    volatile uint32_t i;
    for (i = 0; i < count; i++) {
        (void)mmio_read(GPIO_BASE + GPIO_DATA_IN);
    }
}

int main(void)
{
    volatile uint32_t i;

    // Phase A: enable both UART (bit0) and GPIO (bit1) clocks
    mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000003u);

    // Configure GPIO bit0 output
    mmio_write(GPIO_BASE + GPIO_DIR, 0x00000001u);
    mmio_write(GPIO_BASE + GPIO_DATA_OUT, 0x00000000u);
    
    // Phase A: toggle GPIO 24 times to demonstrate all clocks active
    for (i = 0; i < 24u; i++) {
        mmio_write(GPIO_BASE + GPIO_TOGGLE, 0x00000001u);
        busy_delay(40u);
    }

    // Phase B: disable all peripheral clocks (power gating demo)
    mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000000u);
    busy_delay(3500u);

    // Phase C: re-enable only GPIO clock (bit1)
    mmio_write(CMU_BASE + CMU_CLK_EN, 0x00000002u);
    for (i = 0; i < 24u; i++) {
        mmio_write(GPIO_BASE + GPIO_TOGGLE, 0x00000001u);
        busy_delay(40u);
    }

    while (1) {
        mmio_write(GPIO_BASE + GPIO_TOGGLE, 0x00000001u);
        busy_delay(500u);
    }
}
