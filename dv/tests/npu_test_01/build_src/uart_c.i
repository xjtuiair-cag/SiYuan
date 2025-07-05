# 1 "src/uart.c"
# 1 "/home/shenghuan/Projects/github/SiYuan/dv/tests/npu_test_01//"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "src/uart.c"
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
# 2 "src/uart.c" 2

void write_reg_u8(uintptr_t addr, uint8_t value)
{
    volatile uint8_t *loc_addr = (volatile uint8_t *)addr;
    *loc_addr = value;
}

uint8_t read_reg_u8(uintptr_t addr)
{
    return *(volatile uint8_t *)addr;
}

int is_transmit_empty()
{
    return read_reg_u8(0x10000000 + 20) & 0x20;
}

void write_serial(char a)
{
    while (is_transmit_empty() == 0) {};

    write_reg_u8(0x10000000 + 0, a);
}

void init_uart(uint32_t freq, uint32_t baud)
{
    uint32_t divisor = freq / (baud << 4);

    write_reg_u8(0x10000000 + 4, 0x00);
    write_reg_u8(0x10000000 + 12, 0x80);
    write_reg_u8(0x10000000 + 0, divisor);
    write_reg_u8(0x10000000 + 4, (divisor >> 8) & 0xFF);
    write_reg_u8(0x10000000 + 12, 0x03);
    write_reg_u8(0x10000000 + 8, 0xC7);
    write_reg_u8(0x10000000 + 16, 0x20);
}

void print_uart(const char *str)
{
    const char *cur = &str[0];
    while (*cur != '\0')
    {
        write_serial((uint8_t)*cur);
        ++cur;
    }
}

uint8_t bin_to_hex_table[16] = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

void bin_to_hex(uint8_t inp, uint8_t res[2])
{
    res[1] = bin_to_hex_table[inp & 0xf];
    res[0] = bin_to_hex_table[(inp >> 4) & 0xf];
    return;
}

void print_uart_int(uint32_t addr)
{
    int i;
    for (i = 3; i > -1; i--)
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(hex[0]);
        write_serial(hex[1]);
    }
}

void print_uart_addr(uint64_t addr)
{
    int i;
    for (i = 7; i > -1; i--)
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
        uint8_t hex[2];
        bin_to_hex(cur, hex);
        write_serial(hex[0]);
        write_serial(hex[1]);
    }
}

void print_uart_byte(uint8_t byte)
{
    uint8_t hex[2];
    bin_to_hex(byte, hex);
    write_serial(hex[0]);
    write_serial(hex[1]);
}
