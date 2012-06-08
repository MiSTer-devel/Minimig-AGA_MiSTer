/* system.c */
/* 2012, rok.krajnc@gmail.com */


#include "system.h"


// heap management
extern int *_heap_start;
extern int *_heap_end;
int *heap_cur = NULL;

void *hmalloc(int size)
{
  int *new, *old;

  if(heap_cur == NULL) {
    // heap doesn't exists yet
    heap_cur = (int *)&_heap_start;
  }

  new = (int *)((int)heap_cur + size);

  if(new > (int *)&_heap_end) {
    //uprintf("hmalloc fail (%x > %x)\n\r", new, (int *)&_heap_end);
    return NULL;
  }
  // TODO: more checkings if needed
  // heap bottom, top should be defined and checked

  old = heap_cur;
  heap_cur = new;

  //uprintf("hmalloc(%x), address: old 0x%x, new: 0x%x\n\r", size, old, new);

  return old;
}


// sys jump
void sys_jump(unsigned long addr)
{
  //disable_ints();
  __asm__("l.sw  0x4(r1),r9");
  __asm__("l.jalr  %0" : : "r" (addr));
  __asm__("l.nop");
  __asm__("l.lwz r9,0x4(r1)");
}

