#include "npu.h"
#include "uart.h"

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
    write_reg_u64(NPU_BASE_ADDR, 0xA0000000);
    print_uart("[INFO]: init npu success\n");
    return 0;
}

int start_npu(int fd){
    clr_reg(NPU_CTRL, START_OFFSET);
    clr_reg(NPU_CTRL, FETCH_EN_OFFSET);
    set_reg(NPU_CTRL, FETCH_EN_OFFSET);
    print_uart("[INFO]: start npu success\n");
    return 0;

}
int start_conv(int fd){
    set_reg(NPU_CTRL, START_OFFSET);
    clr_reg(NPU_CTRL, START_OFFSET);
    print_uart("[INFO]: start conv success\n");
    return 0;
}

int wait_npu_done(int fd){
    uint32_t state;
    uint32_t addr = NPU_DONE;
    state = *(volatile uint32_t *)addr;
    while (state == 0){
        sleep_us(2000);
        state = *(volatile uint32_t *)addr;
    }
    // clear done state
    write_reg_u32(NPU_DONE, 0x0);
    return 0;
}