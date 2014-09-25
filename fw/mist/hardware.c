 /*
Copyright 2008, 2009 Jakub Bednarski

This file is part of Minimig

Minimig is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

Minimig is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "AT91SAM7S256.h"
#include "stdio.h"
#include "hardware.h"
#include "user_io.h"

void __init_hardware(void)
{
    *AT91C_WDTC_WDMR = AT91C_WDTC_WDDIS; // disable watchdog
    *AT91C_RSTC_RMR = (0xA5 << 24) | AT91C_RSTC_URSTEN;   // enable external user reset input
    *AT91C_MC_FMR = FWS << 8; // Flash wait states

    // configure clock generator
    *AT91C_CKGR_MOR = AT91C_CKGR_MOSCEN | (40 << 8);  
    while (!(*AT91C_PMC_SR & AT91C_PMC_MOSCS));

    *AT91C_CKGR_PLLR = AT91C_CKGR_OUT_0 | AT91C_CKGR_USBDIV_1 | (25 << 16) | (40 << 8) | 5; // DIV=5 MUL=26 USBDIV=1 (2) PLLCOUNT=40
    while (!(*AT91C_PMC_SR & AT91C_PMC_LOCK));

    *AT91C_PMC_MCKR = AT91C_PMC_PRES_CLK_2; // master clock register: clock source selection
    while (!(*AT91C_PMC_SR & AT91C_PMC_MCKRDY));

    *AT91C_PMC_MCKR = AT91C_PMC_CSS_PLL_CLK | AT91C_PMC_PRES_CLK_2; // master clock register: clock source selection
    while (!(*AT91C_PMC_SR & AT91C_PMC_MCKRDY));

    *AT91C_PIOA_PER = 0xFFFFFFFF; // enable pio on all pins
    *AT91C_PIOA_SODR = DISKLED;   // led off

#ifdef USB_PUP
    // disable usb d+/d- pullups if present
    *AT91C_PIOA_OER = USB_PUP;
    *AT91C_PIOA_PPUDR = USB_PUP;
    *AT91C_PIOA_SODR = USB_PUP;
#endif

    // enable joystick ports
#ifdef JOY0
    *AT91C_PIOA_PPUER = JOY0;
#endif

#ifdef JOY1
    *AT91C_PIOA_PPUER = JOY1;
#endif

#ifdef SD_WP
    // enable SD card signals
    *AT91C_PIOA_PPUER = SD_WP | SD_CD;
#endif

    *AT91C_PIOA_SODR = MMC_SEL | FPGA0 | FPGA1 | FPGA2; // set output data register

    // output enable register
    *AT91C_PIOA_OER = DISKLED | MMC_SEL | FPGA0 | FPGA1 | FPGA2;
    // pull-up disable register
    *AT91C_PIOA_PPUDR = DISKLED | MMC_SEL | FPGA0 | FPGA1 | FPGA2;

#ifdef XILINX_CCLK
    // xilinx interface
    *AT91C_PIOA_SODR  = XILINX_CCLK | XILINX_DIN | XILINX_PROG_B;
    *AT91C_PIOA_OER   = XILINX_CCLK | XILINX_DIN | XILINX_PROG_B;
    *AT91C_PIOA_PPUDR = XILINX_CCLK | XILINX_DIN | XILINX_PROG_B | 
      XILINX_INIT_B | XILINX_DONE;
#endif

#ifdef ALTERA_DCLK
    // altera interface
    *AT91C_PIOA_SODR  = ALTERA_DCLK | ALTERA_DATA0 |  ALTERA_NCONFIG;
    *AT91C_PIOA_OER   = ALTERA_DCLK | ALTERA_DATA0 |  ALTERA_NCONFIG;
    *AT91C_PIOA_PPUDR = ALTERA_DCLK | ALTERA_DATA0 |  ALTERA_NCONFIG |
      ALTERA_NSTATUS | ALTERA_DONE;
#endif

#ifdef MMC_CLKEN
    // MMC_CLKEN may be present 
    // (but is not used anymore, so it's only setup passive)
    *AT91C_PIOA_SODR = MMC_CLKEN;
    *AT91C_PIOA_PPUDR = MMC_CLKEN;
#endif

#ifdef USB_SEL
    *AT91C_PIOA_SODR = USB_SEL;
    *AT91C_PIOA_OER = USB_SEL;
    *AT91C_PIOA_PPUDR = USB_SEL;
#endif

    // Enable peripheral clock in the PMC
    AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_PIOA;
}

void hexdump(void *data, uint16_t size, uint16_t offset) {
  uint8_t i, b2c;
  uint16_t n=0;
  char *ptr = data;

  if(!size) return;

  while(size>0) {
    iprintf("%04x: ", n + offset);

    b2c = (size>16)?16:size;
    for(i=0;i<b2c;i++)      iprintf("%02x ", 0xff&ptr[i]);
    iprintf("  ");
    for(i=0;i<(16-b2c);i++) iprintf("   ");
    for(i=0;i<b2c;i++)      iprintf("%c", isprint(ptr[i])?ptr[i]:'.');
    iprintf("\n");
    ptr  += b2c;
    size -= b2c;
    n    += b2c;
  }
}

// A buffer of 256 bytes makes index handling pretty trivial
volatile static unsigned char tx_buf[256];
volatile static unsigned char tx_rptr, tx_wptr;

volatile static unsigned char rx_buf[256];
volatile static unsigned char rx_rptr, rx_wptr;

void Usart0IrqHandler(void) {
  // Read USART status
  unsigned char status = AT91C_BASE_US0->US_CSR;

  // received something?
  if(status & AT91C_US_RXRDY) {
    // read byte from usart
    unsigned char c = AT91C_BASE_US0->US_RHR;

    // only store byte if rx buffer is not full
    if((unsigned char)(rx_wptr + 1) != rx_rptr) {
      // there's space in buffer: use it
      rx_buf[rx_wptr++] = c;
    }
  }
    
  // ready to transmit further bytes?
  if(status & AT91C_US_TXRDY) {

    // further bytes to send in buffer? 
    if(tx_wptr != tx_rptr)
      // yes, simply send it and leave irq enabled
      AT91C_BASE_US0->US_THR = tx_buf[tx_rptr++];
    else
      // nothing else to send, disable interrupt
      AT91C_BASE_US0->US_IDR = AT91C_US_TXRDY;
  }
}

// check usart rx buffer for data
void USART_Poll(void) {
  while(rx_wptr != rx_rptr) {
    // this can a little be optimized by sending whole buffer parts 
    // at once and not just single bytes. But that's probably not
    // worth the effort.
    char chr = rx_buf[rx_rptr++];

    iprintf("USART RX %d (%c)\n", rx_buf[rx_rptr], rx_buf[rx_rptr]);

    // data available -> send via user_io to core
    user_io_serial_tx(&chr, 1);
  }
}

void USART_Write(unsigned char c) {
#if 0
  while(!(AT91C_BASE_US0->US_CSR & AT91C_US_TXRDY));
  AT91C_BASE_US0->US_THR = c;
#else
  if((AT91C_BASE_US0->US_CSR & AT91C_US_TXRDY) && (tx_wptr == tx_rptr)) {
    // transmitter ready and buffer empty? -> send directly
    AT91C_BASE_US0->US_THR = c;
  } else {
    // transmitter is not ready: block until space in buffer
    while((unsigned char)(tx_wptr + 1) == tx_rptr);

    // there's space in buffer: use it
    tx_buf[tx_wptr++] = c;
  }

  AT91C_BASE_US0->US_IER = AT91C_US_TXRDY;  // enable interrupt
#endif
}

void USART_Init(unsigned long baudrate) {
    // Configure PA5 and PA6 for USART0 use
    AT91C_BASE_PIOA->PIO_PDR = AT91C_PA5_RXD0 | AT91C_PA6_TXD0;

    // Enable the peripheral clock in the PMC
    AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_US0;

    // Reset and disable receiver & transmitter
    AT91C_BASE_US0->US_CR = AT91C_US_RSTRX | AT91C_US_RSTTX | AT91C_US_RXDIS | AT91C_US_TXDIS;

    // Configure USART0 mode
    AT91C_BASE_US0->US_MR = AT91C_US_USMODE_NORMAL | AT91C_US_CLKS_CLOCK | AT91C_US_CHRL_8_BITS | 
      AT91C_US_PAR_NONE | AT91C_US_NBSTOP_1_BIT | AT91C_US_CHMODE_NORMAL;

    // Configure USART0 rate
    AT91C_BASE_US0->US_BRGR = MCLK / 16 / baudrate;

    // Enable receiver & transmitter
    AT91C_BASE_US0->US_CR = AT91C_US_RXEN | AT91C_US_TXEN;

    // tx buffer is initially empty
    tx_rptr = tx_wptr = 0;

    // and so is rx buffer
    rx_rptr = rx_wptr = 0;

    // Set the USART0 IRQ handler address in AIC Source
    AT91C_BASE_AIC->AIC_SVR[AT91C_ID_US0] = (unsigned int)Usart0IrqHandler; 
    AT91C_BASE_AIC->AIC_IECR = (1<<AT91C_ID_US0);

    AT91C_BASE_US0->US_IER = AT91C_US_RXRDY;  // enable rx interrupt
}

void SPI_Init() {
    // Enable the peripheral clock in the PMC
    AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_SPI;

    // Enable SPI interface
    *AT91C_SPI_CR = AT91C_SPI_SPIEN;

    // SPI Mode Register
    *AT91C_SPI_MR = AT91C_SPI_MSTR | AT91C_SPI_MODFDIS  | (0x0E << 16);

    // SPI CS register
    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (48 << 8) | (0x00 << 16) | (0x01 << 24);

    // Configure pins for SPI use
    AT91C_BASE_PIOA->PIO_PDR = AT91C_PA14_SPCK | AT91C_PA13_MOSI | AT91C_PA12_MISO;
}

void EnableFpga()
{
    *AT91C_PIOA_CODR = FPGA0;  // clear output
}

void DisableFpga()
{
    SPI_Wait4XferEnd();
    *AT91C_PIOA_SODR = FPGA0;  // set output
}

void EnableOsd()
{
    *AT91C_PIOA_CODR = FPGA1;  // clear output
}

void DisableOsd()
{
    SPI_Wait4XferEnd();
    *AT91C_PIOA_SODR = FPGA1;  // set output
}

#ifdef FPGA3
void EnableIO() {
    *AT91C_PIOA_CODR = FPGA3;  // clear output
}

void DisableIO() {
    SPI_Wait4XferEnd();
    *AT91C_PIOA_SODR = FPGA3;  // set output
}
#endif

unsigned long CheckButton(void)
{
#ifdef BUTTON
    return((~*AT91C_PIOA_PDSR) & BUTTON);
#else
    return user_io_menu_button();
#endif
}

void timer0_c_irq_handler(void) {
  //* Acknowledge interrupt status
  unsigned int dummy = AT91C_BASE_TC0->TC_SR;

  ikbd_update_time();
}

void Timer_Init(void) {  
  unsigned int dummy;

  //* Open timer0
  AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_TC0;
  
  //* Disable the clock and the interrupts
  AT91C_BASE_TC0->TC_CCR = AT91C_TC_CLKDIS ;
  AT91C_BASE_TC0->TC_IDR = 0xFFFFFFFF ;
  
  //* Clear status bit
  dummy = AT91C_BASE_TC0->TC_SR;

  //* Set the Mode of the Timer Counter
  AT91C_BASE_TC0->TC_CMR = 0x04;  // :1024
  
  //* Enable the clock
  AT91C_BASE_TC0->TC_CCR = AT91C_TC_CLKEN ;
  
  
  
  //* Open Timer 0 interrupt
  
  //* Disable the interrupt on the interrupt controller
  AT91C_BASE_AIC->AIC_IDCR = 1 << AT91C_ID_TC0;
  //* Save the interrupt handler routine pointer and the interrupt priority
  AT91C_BASE_AIC->AIC_SVR[AT91C_ID_TC0] = (unsigned int)timer0_c_irq_handler;
  //* Store the Source Mode Register
  AT91C_BASE_AIC->AIC_SMR[AT91C_ID_TC0] = 1 | AT91C_AIC_SRCTYPE_INT_HIGH_LEVEL;
  //* Clear the interrupt on the interrupt controller
  AT91C_BASE_AIC->AIC_ICCR = 1 << AT91C_ID_TC0;
  
  AT91C_BASE_TC0->TC_IER = AT91C_TC_CPCS;  //  IRQ enable CPC
  AT91C_BASE_AIC->AIC_IECR = 1 << AT91C_ID_TC0;
  
  //* Start timer0
  AT91C_BASE_TC0->TC_CCR = AT91C_TC_SWTRG ;
  
  *AT91C_PITC_PIMR = AT91C_PITC_PITEN | ((MCLK / 16 / 1000 - 1) & AT91C_PITC_PIV); // counting period 1ms
}

// 12 bits accuracy at 1ms = 4096 ms 
unsigned long GetTimer(unsigned long offset)
{
    unsigned long systimer = (*AT91C_PITC_PIIR & AT91C_PITC_PICNT);
    systimer += offset << 20;
    return (systimer); // valid bits [31:20]
}

unsigned long CheckTimer(unsigned long time)
{
    unsigned long systimer = (*AT91C_PITC_PIIR & AT91C_PITC_PICNT);
    time -= systimer;
    return(time > (1UL << 31));
}

void WaitTimer(unsigned long time)
{
    time = GetTimer(time);
    while (!CheckTimer(time));
}

void SPI_slow() {
  AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (SPI_SLOW_CLK_VALUE << 8) | (2 << 24); // init clock 100-400 kHz
}

void SPI_fast() {
  // set appropriate SPI speed for SD/SDHC card (max 25 Mhz)
  AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (SPI_SDC_CLK_VALUE << 8); // 24 MHz SPI clock
}

void SPI_fast_mmc() {
  // set appropriate SPI speed for MMC card (max 20Mhz)
  AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (SPI_MMC_CLK_VALUE << 8); // 16 MHz SPI clock
}

void TIMER_wait(unsigned long ms) {
  WaitTimer(ms);
}

void EnableDMode() {
  *AT91C_PIOA_CODR = FPGA2; // enable FPGA2 output
}

void DisableDMode() {
  *AT91C_PIOA_SODR = FPGA2; // disable FPGA2 output
}

void SPI_block(unsigned short num) {
  unsigned short i;
  unsigned long t;

  for (i = 0; i < num; i++) {
    while (!(*AT91C_SPI_SR & AT91C_SPI_TDRE)); // wait until transmiter buffer is empty
    *AT91C_SPI_TDR = 0xFF; // write dummy spi data
  }
  while (!(*AT91C_SPI_SR & AT91C_SPI_TXEMPTY)); // wait for transfer end
  t = *AT91C_SPI_RDR; // dummy read to empty receiver buffer for new data
}

RAMFUNC void SPI_read(char *addr, uint16_t len) {
  *AT91C_PIOA_SODR = AT91C_PA13_MOSI; // set GPIO output register
  *AT91C_PIOA_OER = AT91C_PA13_MOSI;  // GPIO pin as output
  *AT91C_PIOA_PER = AT91C_PA13_MOSI;  // enable GPIO function
  
  // use SPI PDC (DMA transfer)
  *AT91C_SPI_TPR = (unsigned long)addr;
  *AT91C_SPI_TCR = len;
  *AT91C_SPI_TNCR = 0;
  *AT91C_SPI_RPR = (unsigned long)addr;
  *AT91C_SPI_RCR = len;
  *AT91C_SPI_RNCR = 0;
  *AT91C_SPI_PTCR = AT91C_PDC_RXTEN | AT91C_PDC_TXTEN; // start DMA transfer
  // wait for tranfer end
  while ((*AT91C_SPI_SR & (AT91C_SPI_ENDTX | AT91C_SPI_ENDRX)) != (AT91C_SPI_ENDTX | AT91C_SPI_ENDRX));
  *AT91C_SPI_PTCR = AT91C_PDC_RXTDIS | AT91C_PDC_TXTDIS; // disable transmitter and receiver

  *AT91C_PIOA_PDR = AT91C_PA13_MOSI; // disable GPIO function
}

RAMFUNC void SPI_block_read(char *addr) {
  SPI_read(addr, 512);
}

void SPI_write(char *addr, uint16_t len) {
  // use SPI PDC (DMA transfer)
  *AT91C_SPI_TPR = (unsigned long)addr;
  *AT91C_SPI_TCR = len;
  *AT91C_SPI_TNCR = 0;
  *AT91C_SPI_RCR = 0;
  *AT91C_SPI_PTCR = AT91C_PDC_TXTEN; // start DMA transfer
  // wait for tranfer end
  while (!(*AT91C_SPI_SR & AT91C_SPI_ENDTX));
  *AT91C_SPI_PTCR = AT91C_PDC_TXTDIS; // disable transmitter
}

void SPI_block_write(char *addr) {
  SPI_write(addr, 512);
}

char mmc_inserted() {
  return !(*AT91C_PIOA_PDSR & SD_CD);
}

char mmc_write_protected() {
  return (*AT91C_PIOA_PDSR & SD_WP);
}

