/*
Copyright 2005, 2006, 2007 Dennis van Weeren

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

Hardware control routines

27-11-2005	-started coding
29-01-2006	-done a lot of work
31-01-2006	-added key repeat
06-02-2006	-took out all button handling stuff

-- Goran Ljubojevic --
2009-11-13	- OsdCommand added
2009-11-21	- small cleanup
2009-12-20	- systimer reset on every hardware init to support propper timings on reset
2009-12-30	- Support for new FPGA firmware added in header file
			- GetFPGAStatus function added
2010-01-29	- ResetFPGA() macro added to header file.
2010-08-21	- YQ100818 FPGA core support
2010-08-26	- Added firmwareConfiguration.h
2010-09-09	- Added _SPI macro to help save space on multiple SPI calls
*/

#include <pic18.h>
#include "firmwareConfiguration.h"
#include "hardware.h"

/*local functions*/
//void ScanKeys(void);

// system timer
unsigned short systimer;

/*initialize hardware*/
void HardwareInit(void)
{
	/*disable analog inputs*/
	ADCON1 = 0b00000110;

	/*initalize output register*/
	PORTA = 0b00100011;
	PORTB = 0b01100000;
	PORTC = 0b00010001;

	/*enable PORTB weak pullup*/
	RBPU = 0;

	/*initialize SPI*/
	SSPSTAT = 0x00;
	SSPCON1 = 0x32; //changed from 1/16 to 1/64

	/*initialize input/ouput configuration*/
	TRISA = 0b11001100;
	TRISB = 0b00001011;
	TRISC = 0b10010000;

	/*initialize serial port*/
	/*SPBRG = 129;*/	/*9600 BAUD @ 20MHz*/
	SPBRG = 10;	/*115200 BAUD @ 20MHz*/
	TXSTA = 0x24;
	RCSTA = 0x90;

	/*init timer0, internal clk, prescaler 1:256*/
	T0CON = 0xc7;

	/*enable interrupt for timer 0*/
	TMR0IE = 1;
	GIE = 1;
	
	// Clear sys timer
	systimer = 0;
}

/*interrupt service routine*/
void interrupt intservice(void)
{
	/*clear timer 0 interrupt flag*/
	TMR0IF = 0;

	/*set timer to timeout every 10ms
	@20Mhz --> instruction = 200ns
	200ns * 256 * 195  =  10ms*/
	TMR0 -= 195;

	/*increment system timer*/
	systimer++;
}

/*get system timer + offset (handy for lots of things)*/
unsigned short GetTimer(unsigned short offset)
{
	unsigned short r;

	/*get system time SAFELY*/
	GIE = 0;
	r = systimer;
	GIE = 1;

	/*add offset*/
	r += offset;

	return(r);
}

/*check if timer is past given time in <t>
t may be maximum 30000 ticks in the future*/
unsigned char CheckTimer(unsigned short t)
{
	// calculate difference
	GIE = 0;
	t -= systimer;
	GIE = 1;

	// check if <t> has passed
	if (t>30000)
	{	return(1);	}
	else
	{	return(0);	}
}

void WaitTimer(unsigned short time)
{
    time = GetTimer(time);
    while (!CheckTimer(time));
}


/*SPI-bus*/
unsigned char SPI(unsigned char d)
{
	SSPBUF = d;
	while (!BF);			/*Wait untill controller is ready*/
	return(SSPBUF);			/*Return with received value*/
}

// OSD Send Command
unsigned char OsdCommand(unsigned char d)
{
	unsigned char c;

	EnableOsd();
	c = SPI(d);
	DisableOsd();
	
	return c;
}

/*FPGA configuration serial interface*/
void ShiftFpga(unsigned char data)
{
	/*bit 0*/
	DIN = 0;
	CCLK = 0;
	if (data&0x80)
		DIN = 1;
	CCLK = 1;

	/*bit 1*/
	DIN = 0;
	CCLK = 0;
	if (data&0x40)
		DIN = 1;
	CCLK = 1;

	/*bit 2*/
	DIN = 0;
	CCLK = 0;
	if (data&0x20)
		DIN = 1;
	CCLK = 1;

	/*bit 3*/
	DIN = 0;
	CCLK = 0;
	if (data&0x10)
		DIN = 1;
	CCLK = 1;

	/*bit 4*/
	DIN = 0;
	CCLK = 0;
	if (data&0x08)
		DIN = 1;
	CCLK = 1;

	/*bit 5*/
	DIN = 0;
	CCLK = 0;
	if (data&0x04)
		DIN = 1;
	CCLK = 1;

	/*bit 6*/
	DIN = 0;
	CCLK = 0;
	if (data&0x02)
		DIN = 1;
	CCLK = 1;

	/*bit 7*/
	DIN = 0;
	CCLK = 0;
	if (data&0x01)
		DIN = 1;
	CCLK = 1;
}

unsigned char GetFPGAStatus(void)
{
	unsigned char status;

	EnableFpga();
	status = SPI(0);
	SPI(0);
	SPI(0);
	SPI(0);
	SPI(0);
	SPI(0);
	DisableFpga();
	return status;
} 


/*put out a chacter to the serial port*/
void putch(unsigned char ch)
{
	while(TRMT == 0);
	TXREG = ch;
}




