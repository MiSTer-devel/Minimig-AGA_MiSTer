#define MCLK 48000000
#define FWS 1 // Flash wait states

#define DISKLED    AT91C_PIO_PA10
#define MMC_CLKEN  AT91C_PIO_PA24
#define MMC_SEL    AT91C_PIO_PA27
#define DIN AT91C_PIO_PA20
#define CCLK AT91C_PIO_PA4
#define PROG_B AT91C_PIO_PA9
#define INIT_B AT91C_PIO_PA7
#define DONE AT91C_PIO_PA8
#define FPGA0 AT91C_PIO_PA26
#define FPGA1 AT91C_PIO_PA25
#define FPGA2 AT91C_PIO_PA15
#define BUTTON AT91C_PIO_PA28

#define DISKLED_ON // *AT91C_PIOA_SODR = DISKLED;
#define DISKLED_OFF // *AT91C_PIOA_CODR = DISKLED;

#define EnableCard()   *(volatile unsigned int *)0x800014=0x11
#define DisableCard()  *(volatile unsigned int *)0x800014=0x10
#define EnableFpga()   *(volatile unsigned int *)0x800014=0x22
#define DisableFpga()  *(volatile unsigned int *)0x800014=0x20
#define EnableOsd()    *(volatile unsigned int *)0x800014=0x44
#define DisableOsd()   *(volatile unsigned int *)0x800014=0x40
#define EnableDMode()  *(volatile unsigned int *)0x800014=0x88
#define DisableDMode() *(volatile unsigned int *)0x800014=0x80

#define SPI_slow()  *(volatile unsigned int *)0x800010=0x3f
#define SPI_fast()  *(volatile unsigned int *)0x800010=0x00
#define SPI(x) (*(volatile unsigned int *)0x800018=x,*(volatile unsigned int *)0x800018)
#define SPI_block(x) (*(volatile unsigned int *)0x80001c=x)
#define RS232  *(volatile unsigned int *)0x800008=
 

//void USART_Init(unsigned long baudrate);
//void USART_Write(unsigned char c);
//
//void SPI_Init(void);
//unsigned char SPI(unsigned char outByte);
//void SPI_Wait4XferEnd(void);
//void EnableCard(void);
//void DisableCard(void);
//void EnableFpga(void);
//void DisableFpga(void);
//void EnableOsd(void);
//void DisableOsd(void);
unsigned long CheckButton(void);
void Timer_Init(void);
unsigned long GetTimer(unsigned long offset);
unsigned long CheckTimer(unsigned long t);
void WaitTimer(unsigned long time);
void _WaitTimer(unsigned long time);

