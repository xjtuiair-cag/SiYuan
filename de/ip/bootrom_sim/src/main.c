#include "uart.h"
int main()
{
    init_uart(50000000, 115200);
    print_uart("Hello World!\r\n");

    return 0;
}