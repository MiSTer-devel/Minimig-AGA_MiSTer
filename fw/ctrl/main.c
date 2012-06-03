/* main.c */

// read & write to mem
#define read8(adr)          (*((volatile unsigned char *)(adr)))
#define read16(adr)         (*((volatile unsigned short *)(adr)))
#define read32(adr)         (*((volatile unsigned int *)(adr)))
#define write8(adr, data)   (*((volatile unsigned char *)(adr)) = (data))
#define write16(adr, data)  (*((volatile unsigned short *)(adr)) = (data))
#define write32(adr, data)  (*((volatile unsigned int *)(adr)) = (data))

volatile int data_bss;
volatile int data_data = 0x123;

unsigned long SwapBBBB(unsigned long i)
{
  return ((i&0x00ff0000)>>8) | ((i&0xff000000)>>24) | ((i&0x000000ff)<<24) | ((i&0x0000ff00)<<8);
}

unsigned int SwapBB(unsigned int i)
{
  return ((i&0x000000ff)<<8) | ((i&0x0000ff00)>>8);
}

unsigned long SwapWW(unsigned long i)
{
  //return ((i&0x0000ffff)<<16) | ((i&0xffff0000)>>16);
  return ((i<<16) | (i>>16));
}

int main()
{
  volatile int i;

  // test word swapping
  volatile int swapWW;
  swapWW = 0x01234567;
  swapWW = SwapWW(swapWW);

  // test byte swapping1
  volatile int swapBB;
  swapBB = 0x01234567;
  swapBB = SwapBB(swapBB);

  // test byte swapping2
  volatile int swapBBBB;
  swapBBBB = 0x01234567;
  swapBBBB = SwapBBBB(swapBBBB);

  // test SPI CS
  write32(0x800014, 0x01); // select first
  write32(0x800014, 0x02); // select second
  write32(0x800014, 0x03); // select first & second
  write32(0x800014, 0x10); // deselect first, keep rest
  write32(0x800014, 0xcc); // select third, and fourth, keep rest

  // test slow SPI
  write32(0x800018, 0x55); // write 0x55 @ 400kHz
  volatile int s1 = read32(0x800018);

  // test fast SPI
  write32(0x800010, 0x00); // set divider to 0
  write32(0x800018, 0xaa); // write 0xaa @ 25MHz
  volatile int s2 = read32(0x800018);

  // test two fast SPI writes
  write32(0x800018, 0x12);
  write32(0x800018, 0xfe);

  // test block transfer
  write32(0x80001c, 511);
  write32(0x800018, 0xff);
  read32(0x800018);

  // test timer
  write32(0x80000c, 0x123);
  volatile int t = read32(0x80000c);

  // test UART
  char * txt = "test";
  char * c = txt;
  int t1, t2;
  do {
    write32(0x800008, *c++);
    write32(0x80000c, 0);
    while(read32(0x80000c) < 1000);
  } while (*c != '\0');

  // random read writes
  i = read32(0x1008);

  write32(0x1000, 0x1);
  write32(0x1004, 0x2);  

  // test minimig reset
  write32(0x800004, 0x1);

  // test real reset
  write32(0x800000, 0x1);


  while(1);
}

