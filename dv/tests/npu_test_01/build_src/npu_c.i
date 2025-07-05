# 1 "src/npu.c"
# 1 "/home/shenghuan/Projects/github/SiYuan/dv/tests/npu_test_01//"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "src/npu.c"
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
# 2 "src/npu.c" 2
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
# 3 "src/npu.c" 2

void write_reg_u64(uintptr_t addr, uint64_t value)
{
    volatile uint64_t *loc_addr = (volatile uint64_t *)addr;
    *loc_addr = value;
}
void write_reg_u32(uintptr_t addr, uint32_t value)
{
    volatile uint32_t *loc_addr = (volatile uint32_t *)addr;
    *loc_addr = value;
}

void sleep_us(int us)
{
    for (int i=0;i<us;i++) {}
}

static inline void clr_reg(uint32_t addr, int loc){
    uint32_t mask = 0x1 << loc;
    uint32_t val = *(volatile uint32_t *)addr;
    write_reg_u32(addr, val & (~mask));
}

static inline void set_reg(uint32_t addr, int loc){
    uint32_t mask = 0x1 << loc;
    uint32_t val = *(volatile uint32_t *)addr;
    write_reg_u32(addr, val | mask);
}
int init_npu(){
    write_reg_u64(0x2000 + 48, 0xA0000000);
    print_uart("[INFO]: init npu success\n");
    return 0;
}

int start_npu(int fd){
    clr_reg(0x2000 + 32, 0x0);
    clr_reg(0x2000 + 32, 0x3);
    set_reg(0x2000 + 32, 0x3);
    print_uart("[INFO]: start npu success\n");
    return 0;

}
int start_conv(int fd){
    set_reg(0x2000 + 32, 0x0);
    clr_reg(0x2000 + 32, 0x0);
    print_uart("[INFO]: start conv success\n");
    return 0;
}

int wait_npu_done(int fd){
    uint32_t state;
    uint32_t addr = 0x2000 + 80;
    state = *(volatile uint32_t *)addr;
    while (state == 0){
        sleep_us(2000);
        state = *(volatile uint32_t *)addr;
    }

    write_reg_u32(0x2000 + 80, 0x0);
    return 0;
}
