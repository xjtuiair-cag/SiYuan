// +FHDR------------------------------------------------------------------------
// Copyright ownership belongs to CAG laboratory, Institute of Artificial
// Intelligence and Robotics, Xi'an Jiaotong University, shall not be used in
// commercial ways without permission.
// -----------------------------------------------------------------------------
// FILE NAME  : main.c
// DEPARTMENT : CAG of IAIR
// AUTHOR     : XXXX
// AUTHOR'S EMAIL :XXXX@mail.xjtu.edu.cn
// -----------------------------------------------------------------------------
// Ver 1.0  2019--01--01 initial version.
// -----------------------------------------------------------------------------

#include "uart.h"
#include "dma.h"
#include "regmap.h"
#include <stdint.h>

#define SUCCESS 0
#define FAIL   -1
#define QSIZE 512
#define LOOPS 50
#define SIZE 32        // 32x32 matrix
#define N_HARTS 4
// --------------------------
// 自旋锁：AMOSWAP
// --------------------------
static inline void spin_lock(volatile uint32_t *lock)
{
    uint32_t tmp;
    do {
        __asm__ __volatile__(
            "amoswap.w.aq %0, %1, (%2)"
            : "=&r"(tmp)
            : "r"(1), "r"(lock)
            : "memory"
        );
    } while (tmp != 0);
}
static inline void spin_unlock(volatile uint32_t *lock)
{
    __asm__ __volatile__(
        "amoswap.w.rl x0, x0, (%0)"
        : : "r"(lock) : "memory"
    );
}
// --------------------------
// 多核 Barrier
// --------------------------
volatile uint32_t barrier_count = 0;
volatile uint32_t barrier_gen   = 0;
volatile uint32_t barrier_lock  = 0;

static inline void mem_fence(void) {
    __asm__ __volatile__("fence rw, rw" ::: "memory");
}

void barrier(uint32_t hartid, uint32_t num_harts)
{
    // 保证进入 barrier 前的写可见
    mem_fence();

    // 记录当前代数
    uint32_t my_gen;

    // 进入临界区，更新计数与可能的代切换
    spin_lock(&barrier_lock);
    my_gen = barrier_gen;
    barrier_count++;
    if (barrier_count == num_harts) {
        // 最后一个到达：重置计数并推进代数（清 0 机制在这里）
        barrier_count = 0;
        barrier_gen = barrier_gen + 1;
        // 释放锁后其他核会看到新的 barrier_gen，并可继续下一个周期
        spin_unlock(&barrier_lock);
    } else {
        // 不是最后一个，释放锁并等待代数变化
        spin_unlock(&barrier_lock);

        // 等待直到代数被最后一个核推进
        while (barrier_gen == my_gen) {
            // 可选：轻量 busy-wait hint（减少功耗/总线）
            // __asm__ __volatile__("wfi" ::: "memory"); // 若平台支持，可减少总线压力
            // 若平台不支持 wfi 在自旋中可加入空循环或 nop
        }
    }

    // 保证离开 barrier 后能看到来自其他核的更新
    mem_fence();
}

// define matrix
int A[SIZE][SIZE];
int B[SIZE][SIZE];
int C[SIZE][SIZE];
volatile int finished_harts = 0;
uint32_t lock;

int matrix_test(int hartid, uint32_t num_harts)
{
    // 初始化矩阵 (hart0 完成)
    if (hartid == 0)
    {
        for (int i = 0; i < SIZE; i++)
            for (int j = 0; j < SIZE; j++)
            {
                A[i][j] = i + j;
                B[i][j] = i - j;
                C[i][j] = 0;
            }
    }

    barrier(hartid,num_harts);

    // 每个 hart 负责一部分 row
    int rows_per_hart = SIZE / num_harts;
    int start = hartid * rows_per_hart;
    int end = start + rows_per_hart;

    for (int i = start; i < end; i++)
        for (int j = 0; j < SIZE; j++)
            C[i][j] = A[i][j] + B[i][j];

    // 通知任务完成
    spin_lock(&lock);
    finished_harts++;
    spin_unlock(&lock);

    barrier(hartid,num_harts);

    // hart0 进行结果检查
    if (hartid == 0)
    {
        if (finished_harts != num_harts)
            return FAIL;

        for (int i = 0; i < SIZE; i++)
            for (int j = 0; j < SIZE; j++)
                if (C[i][j] != (A[i][j] + B[i][j]))
                    return FAIL;

        return SUCCESS;
    }

    return SUCCESS;
}




int main(uint32_t hartid, uint32_t num_harts)
{
    // if (hartid == 0) {
    //     init_uart(50000000, 115200);
    // }
    // barrier(hartid, num_harts);
    // SMP test case 5 : TEST matrix add
    // print_uart("---------SMP TEST CASE 5: test matrix add--------!\r\n");
    uint32_t error = matrix_test(hartid, num_harts);
    volatile uint32_t * done_addr = (uint32_t *)REGMAP_ARG00;
    // finish 
    if (hartid == 0) {
	    *done_addr = error; // if error = 0, TEST pass, othewise TEST fail
    }

    return 0;
}
