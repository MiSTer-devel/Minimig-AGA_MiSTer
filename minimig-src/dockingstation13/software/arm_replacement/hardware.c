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

//#include "stdio.h"
#include "hardware.h"


//void __init_hardware(void)
//{
//    *AT91C_WDTC_WDMR = AT91C_WDTC_WDDIS; // disable watchdog
//    *AT91C_RSTC_RMR = (0xA5 << 24) | AT91C_RSTC_URSTEN;   // enable external user reset input
//    *AT91C_MC_FMR = FWS << 8; // Flash wait states
//
//    // configure clock generator
//    *AT91C_CKGR_MOR = AT91C_CKGR_MOSCEN | (40 << 8);  
//    while (!(*AT91C_PMC_SR & AT91C_PMC_MOSCS));
//
//    *AT91C_CKGR_PLLR = AT91C_CKGR_OUT_0 | AT91C_CKGR_USBDIV_1 | (25 << 16) | (40 << 8) | 5; // DIV=5 MUL=26 USBDIV=1 (2) PLLCOUNT=40
//    while (!(*AT91C_PMC_SR & AT91C_PMC_LOCK));
//
//    *AT91C_PMC_MCKR = AT91C_PMC_PRES_CLK_2; // master clock register: clock source selection
//    while (!(*AT91C_PMC_SR & AT91C_PMC_MCKRDY));
//
//    *AT91C_PMC_MCKR = AT91C_PMC_CSS_PLL_CLK | AT91C_PMC_PRES_CLK_2; // master clock register: clock source selection
//    while (!(*AT91C_PMC_SR & AT91C_PMC_MCKRDY));
//
//    *AT91C_PIOA_PER = 0xFFFFFFFF; // enable pio
//    *AT91C_PIOA_CODR = DISKLED; // clear output data register
//    *AT91C_PIOA_SODR = MMC_SEL | MMC_CLKEN | CCLK | DIN | PROG_B | FPGA0 | FPGA1 | FPGA2; // set output data register
//
//    // output enable register
//    *AT91C_PIOA_OER = DISKLED | MMC_SEL | CCLK | DIN | PROG_B | FPGA0 | FPGA1 | FPGA2;
//    // pull-up disable register
//    *AT91C_PIOA_PPUDR = DISKLED | MMC_SEL | MMC_CLKEN  | CCLK | DIN | PROG_B | FPGA0 | FPGA1 | FPGA2;
//
//    // Enable peripheral clock in the PMC
//    AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_PIOA;
//}

//void USART_Init(unsigned long baudrate)
//{
//    // Configure PA5 and PA6 for USART0 use
//    AT91C_BASE_PIOA->PIO_PDR = AT91C_PA5_RXD0 | AT91C_PA6_TXD0;
//
//    // Enable the peripheral clock in the PMC
//    AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_US0;
//
//    // Reset and disable receiver & transmitter
//    AT91C_BASE_US0->US_CR = AT91C_US_RSTRX | AT91C_US_RSTTX | AT91C_US_RXDIS | AT91C_US_TXDIS;
//
//    // Configure USART0 mode
//    AT91C_BASE_US0->US_MR = AT91C_US_USMODE_NORMAL | AT91C_US_CLKS_CLOCK | AT91C_US_CHRL_8_BITS | AT91C_US_PAR_NONE | AT91C_US_NBSTOP_1_BIT | AT91C_US_CHMODE_NORMAL;
//
//    // Configure USART0 rate
//    AT91C_BASE_US0->US_BRGR = MCLK / 16 / baudrate;
//
//    // Enable receiver & transmitter
//    AT91C_BASE_US0->US_CR = AT91C_US_RXEN | AT91C_US_TXEN;
//}

//void USART_Write(unsigned char c)
//{
//    while (!(AT91C_BASE_US0->US_CSR & AT91C_US_TXEMPTY));
//    AT91C_BASE_US0->US_THR = c;
//}

//signed int fputc(unsigned char c, FILE *pStream)
//{
//    if ((pStream == stdout) || (pStream == stderr))
//    {
//        USART_Write((unsigned char)c);
//        return c;
//    }
//
//    return EOF;
//}

//void SPI_Init()
//{
//    // Enable the peripheral clock in the PMC
//    AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_SPI;
//
//    // Enable SPI interface
//    *AT91C_SPI_CR = AT91C_SPI_SPIEN;
//
//    // SPI Mode Register
//    *AT91C_SPI_MR = AT91C_SPI_MSTR | AT91C_SPI_MODFDIS  | (0x0E << 16);
//
//    // SPI CS register
//    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (48 << 8) | (0x00 << 16) | (0x01 << 24);
//
//    // Configure pins for SPI use
//    AT91C_BASE_PIOA->PIO_PDR = AT91C_PA14_SPCK | AT91C_PA13_MOSI | AT91C_PA12_MISO;
//}

//#pragma section_code_init
//#pragma inline
//unsigned char SPI(unsigned char outByte)
//{
//    unsigned long t = *AT91C_SPI_RDR;
//    while (!(*AT91C_SPI_SR & AT91C_SPI_TDRE));
//    *AT91C_SPI_TDR = outByte;
//    while (!(*AT91C_SPI_SR & AT91C_SPI_RDRF));
//    return((unsigned char)*AT91C_SPI_RDR);
//}
//#pragma noinline

//#pragma inline
//void SPI_Wait4XferEnd()
//{
//    while (!(*AT91C_SPI_SR & AT91C_SPI_TXEMPTY));
//}
//#pragma noinline

//#pragma inline
//void EnableCard()
//{
//    *AT91C_PIOA_CODR = MMC_SEL;  // clear output (MMC chip select enabled)
//}
//#pragma noinline
//
//#pragma inline
//void DisableCard()
//{
//    SPI_Wait4XferEnd();
//    *AT91C_PIOA_SODR = MMC_SEL;  // set output (MMC chip select disabled)
//    SPI(0xFF);
//    SPI_Wait4XferEnd();
//}
//#pragma noinline
//#pragma section_no_code_init
//
//void EnableFpga()
//{
//    *AT91C_PIOA_CODR = FPGA0;  // clear output
//}
//
//void DisableFpga()
//{
//    SPI_Wait4XferEnd();
//    *AT91C_PIOA_SODR = FPGA0;  // set output
//}
//
//void EnableOsd()
//{
//    *AT91C_PIOA_CODR = FPGA1;  // clear output
//}
//
//void DisableOsd()
//{
//    SPI_Wait4XferEnd();
//    *AT91C_PIOA_SODR = FPGA1;  // set output
//}

unsigned long CheckButton(void)
{
//    return((~*AT91C_PIOA_PDSR) & BUTTON);
		return(0);
}

//void Timer_Init(void)
//{
//    *AT91C_PITC_PIMR = AT91C_PITC_PITEN | ((MCLK / 16 / 1000 - 1) & AT91C_PITC_PIV); // counting period 1ms
//}
//
unsigned long GetTimer(unsigned long offset)
{
    unsigned long systimer = (*(unsigned short *)0xDEE010);
    systimer = systimer<< 16;
    systimer += offset << 16;
    return (systimer); // valid bits [31:16]
}

unsigned long CheckTimer(unsigned long time)
{
    unsigned long systimer = (*(unsigned short *)0xDEE010);
    systimer = systimer<< 16;
//        printf("systimer:%08X  ",systimer);
    time -= systimer;
    if(time & 0x80000000)
		return(1);
    return(0);
//    return(time > systimer);
}

void WaitTimer(unsigned long time)
{
    time = GetTimer(time);
    while (!CheckTimer(time));
}

