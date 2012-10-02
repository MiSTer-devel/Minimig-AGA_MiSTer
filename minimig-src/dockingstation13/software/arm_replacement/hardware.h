//#define MCLK 48000000
//#define FWS 1 // Flash wait states
//
//#define DISKLED    AT91C_PIO_PA10
//#define MMC_CLKEN  AT91C_PIO_PA24
//#define MMC_SEL    AT91C_PIO_PA27
//#define DIN AT91C_PIO_PA20
//#define CCLK AT91C_PIO_PA4
//#define PROG_B AT91C_PIO_PA9
//#define INIT_B AT91C_PIO_PA7
//#define DONE AT91C_PIO_PA8
//#define FPGA0 AT91C_PIO_PA26
//#define FPGA1 AT91C_PIO_PA25
//#define FPGA2 AT91C_PIO_PA15
//#define BUTTON AT91C_PIO_PA28

#define DISKLED_ON // *AT91C_PIOA_SODR = DISKLED;
#define DISKLED_OFF // *AT91C_PIOA_CODR = DISKLED;

#define EnableCard()  *(unsigned short *)0xda4004=0x02
#define DisableCard() *(unsigned short *)0xda4004=0x03
#define EnableFpga()  *(unsigned short *)0xda4004=0x10
#define DisableFpga() *(unsigned short *)0xda4004=0x11
#define EnableOsd()   *(unsigned short *)0xda4004=0x20
#define DisableOsd()  *(unsigned short *)0xda4004=0x21
#define EnableDMode() *(unsigned short *)0xda4004=0x40
#define DisableDMode() *(unsigned short *)0xda4004=0x41

#define SPI_slow()  *(unsigned short *)0xda4008=0x20
#define SPI_fast()  *(unsigned short *)0xda4008=0x01   //14MHz/2
#define SPI  *(unsigned char *)0xda4000=
#define RDSPI  *(unsigned char *)0xda4001
#define RS232  *(unsigned char *)0xda8001=
 

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


