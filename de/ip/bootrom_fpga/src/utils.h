#pragma once
#include <stdint.h>

void write_reg(uintptr_t addr, uint32_t value);

uint32_t read_reg(uintptr_t addr);

void write_reg_u64(uintptr_t addr, uint64_t value);

void write_reg_u32(uintptr_t addr, uint32_t value);
