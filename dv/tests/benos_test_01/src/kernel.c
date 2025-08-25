#include "uart.h"
void kernel_main(void)
{
	init_uart(50000000, 115200);
	// print_uart("H\r\n");
    print_uart("Hello World!\r\n");
    print_uart("Welcome to SiYuan!\r\n");

	while (1) {
		;
	}
}
