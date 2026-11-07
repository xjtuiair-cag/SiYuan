#ifndef	_LOCK_H
#define	_LOCK_H

#include <stdint.h>

#define SUCCESS 0
#define FAIL   -1

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
volatile uint32_t barrier_lock  = 0;

void barrier(uint32_t hartid, uint32_t num_harts)
{
    spin_lock(&barrier_lock);
    barrier_count++;
    spin_unlock(&barrier_lock);

    while (barrier_count < num_harts)
        ;
}
