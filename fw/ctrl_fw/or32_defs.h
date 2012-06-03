#ifndef __OR32_DEFS_H
#define __OR32_DEFS_H

#define OR32_STACK_SIZE           0x1000

#define OR32_RESET_VECTOR_ROM     0x004
#define OR32_INT_VECTOR_ROM       0x020
#define OR32_TICK_VECTOR_ROM      0x014
#define OR32_TRAP_VECTOR_ROM      0x038

#define OR32_RESET_VECTOR_RAM     0x004
#define OR32_INT_VECTOR_RAM       0x01c
#define OR32_TICK_VECTOR_RAM      0x010
#define OR32_TRAP_VECTOR_RAM      0x034

#define OR32_IN_CLK               50000000
#define OR32_TICKS_PER_SEC        100

#endif /* __OR32_DEFS_H */

