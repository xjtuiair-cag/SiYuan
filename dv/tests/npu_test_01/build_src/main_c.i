# 1 "src/main.c"
# 1 "/home/shenghuan/Projects/github/SiYuan/dv/tests/npu_test_01//"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "src/main.c"
# 14 "src/main.c"
# 1 "include/uart.h" 1




typedef signed char int8_t;
typedef short int int16_t;
typedef int int32_t;

typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long int uint64_t;

typedef unsigned long int uintptr_t;
# 31 "include/uart.h"
void init_uart();

void print_uart(const char* str);

void print_uart_int(uint32_t addr);

void print_uart_addr(uint64_t addr);

void print_uart_byte(uint8_t byte);
# 15 "src/main.c" 2
# 1 "include/npu.h" 1




typedef signed char int8_t;
typedef short int int16_t;
typedef int int32_t;

typedef unsigned char uint8_t;
typedef unsigned short int uint16_t;
typedef unsigned int uint32_t;
typedef unsigned long int uint64_t;

typedef unsigned long int uintptr_t;
# 32 "include/npu.h"
int init_npu();
int start_npu();
int start_conv();
int wait_npu_done();
# 16 "src/main.c" 2


int main()
{
    init_uart(50000000, 115200);
    print_uart("Hello World!\r\n");

    init_npu();
    start_npu();
    start_conv();
    wait_npu_done();
    print_uart("Convolution Finish!\r\n");

    while (1);
}
