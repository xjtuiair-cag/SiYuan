#ifndef	_PLIC_H
#define	_PLIC_H

#define HART_ID 0

#define PLIC_BASE   0xC000000
#define SOURCE_NUM  64
#define TARGET_NUM  8

#define PRIO_REG_BASE       (PLIC_BASE + 0x0)
#define IP_REG_BASE         (PLIC_BASE + 0x1000)
#define EN_BITS_REG_BASE    (PLIC_BASE + 0x2000 + HART_ID*0x80*2)
#define PRIO_THRESH_BASE    (PLIC_BASE + 0x200000 + HART_ID*0x1000*2)

#endif  /*_PLIC_H */
