#include "uart.h"
#include "regmap.h"
volatile uint32_t * done_addr = (uint32_t *)0x42000000;
void kernel_main(void)
{
	init_uart(50000000, 115200);

    print_uart("Hello World!\r\n");
    print_uart("Welcome to SiYuan!\r\n");

	// finish
	*done_addr = 0; // finish and no error

	while (1) {
		;
	}
}
