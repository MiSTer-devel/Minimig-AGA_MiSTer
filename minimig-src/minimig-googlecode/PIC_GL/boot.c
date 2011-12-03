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

-- Goran Lubojevic ---
2009-08-30	- boot.c to make more clear code
2009-09-20	- Supporty for new FPGA bin 090911 by yaqube
2009-11-27	- Code cleanup, SendBootFPGACommand function extracted
2009-12-20	- Corrected error display when AR or Rom missing
2009-12-30	- SendFile optimized a bit to save rom
			- ConfigureFpga modified to support any FPGA bin length divisable by eight
2010-01-29	- Added proper FPGA core reset sequence to alow core reloading
2010-08-26	- Added firmwareConfiguration.h
2010-09-12	- Updated reference to global string buffer
*/

#include <pic18.h>
#include <stdio.h>
#include "firmwareConfiguration.h"
#include "hardware.h"
#include "fat16.h"
#include "boot.h"

//global temporary buffer for strings
//defined in main.c
extern unsigned char s[32];


// Infinite loop for error display
void FatalError(unsigned char code)
{
	// code = number of blinks
	unsigned long t;
	unsigned char i;
	while (1)
	{
		i = code;
		do
		{
			t = 38000;
			while (--t) //wait 100ms
			{	DISKLED_ON;		}

			t = 2*38000;
			while (--t) //wait 200ms
			{	DISKLED_OFF;	}
		}
		while (--i);
		
		t = 8*38000;
		while (--t) //wait 900ms
		{	DISKLED_OFF;	}
	}
}


// configure FPGA
unsigned char ConfigureFpga(const unsigned char *FPGAFileName)
{
	unsigned short t;
	unsigned short n;
	unsigned char *ptr;

	// reset FGPA configuration sequence
//	PROG_B_VAL = 0;	// Set PROG_B Low
//	PROG_B = 0;		// Set PROG_B As Input (Disable)
//	PROG_B = 1;		// Set PROG_B As Output (Value is written out)
	ResetFPGA();

	// now wait for INIT to go high
	t = 50000;
	while (!INIT_B)
	{
		if (--t==0)
		{
			#ifdef BOOT_DEBUG
			printf("FPGA init is NOT high!\r\n");
			#endif
			FatalError(3);
		}
	}

	#ifdef BOOT_DEBUG
	printf("FPGA init is high\r\n");
	#endif

	if (DONE)
	{
		#ifdef BOOT_DEBUG
		printf("FPGA done is high before configuration!\r\n");
		#endif

		FatalError(3);
	}

	// open bitstream file
	if (Open(&file, FPGAFileName)==0)
	{
		#ifdef BOOT_DEBUG
		printf("No FPGA configuration file found!\r\n");
		#endif

		FatalError(4);
	}

	#ifdef BOOT_DEBUG
	printf("FPGA bitstream file opened\r\n");
	#endif

	// send all bytes to FPGA in loop
	t = 0;
	n = file.len>>3;
	do
	{
		// read sector if 512 (64*8) bytes done
		if (t%64==0)
		{
			if ((t>>9)&1)
			{	DISKLED_ON;	}
			else
			{	DISKLED_OFF;	}

			putchar('*');

			if (!FileRead(&file))
			{	return(0);	}

			ptr=secbuf;
		}

		// send data in packets of 8 bytes
		ShiftFpga(*(ptr++));
		ShiftFpga(*(ptr++));
		ShiftFpga(*(ptr++));
		ShiftFpga(*(ptr++));
		ShiftFpga(*(ptr++));
		ShiftFpga(*(ptr++));
		ShiftFpga(*(ptr++));
		ShiftFpga(*(ptr++));
		t++;

		// read next sector if 512 (64*8) bytes done
		if (t%64==0)
		{	FileNextSector(&file);	}
	}
	while (t<n);

	#ifdef BOOT_DEBUG
	printf("\r\nFPGA bitstream loaded\r\n");
	#endif

	DISKLED_OFF;

	// check if DONE is high
	if (DONE)
	{	return(1);	}
	else
	{
		#ifdef BOOT_DEBUG
		printf("FPGA done is NOT high!\r\n");
		#endif

		FatalError(5);
	}

	return 0;
}


char UploadKickstart(const unsigned char *name)
{
	if (!Open(&file,name))
	{
		sprintf(s, "No \"%s\" file!", name);
		BootPrint(s);
		return 40;
	}

	if (file.len==0x80000)
	{
		//512KB Kickstart ROM
		BootPrint("Uploading 512KB Kickstart...");
		BootUpload(&file,0xF8,0x08);
	}
	else if (file.len==0x40000)
	{
		//256KB Kickstart ROM
		BootPrint("Uploading 256KB Kickstart...");
		BootUpload(&file,0xF8,0x04);
	}
	else
	{
		BootPrint("Unsupported Kickstart ROM file size!");
		return 41;
	}

	return 0;
}


char UploadActionReplay(const unsigned char *name)
{
	if (!Open(&file,name))
	{
		sprintf(s, "No \"%s\" file!", name);
		BootPrint(s);
		return 40;
	}

	if (file.len==0x40000)
	{
		BootPrint("\nUploading Action Replay ROM...");
		BootUpload(&file,0x40,0x04);
		ClearMemory(0x44,0x04);
	}
	else
	{
		BootPrint("\nUnsupported AR3.ROM file size!!!");
		return 41;
	}

	return 0;
}




char BootPrint(const char* text)
{
	char c1,c2,c3,c4;
	char cmd;
	const char* p;
	unsigned char n;

	//calculating string length
	p = text;
	n = 0;
	while (*(p++) != 0)
	{	n++;	}

	cmd = 1;
	while (1)
	{
		EnableFpga();
		c1 = SPI(0x10); //track read command
		c2 = SPI(0x01); //disk presentt
		SPI(0);
		SPI(0);
		c3 = SPI(0);
		c4 = SPI(0);

		#ifdef BOOT_DEBUG
		printf("CMD%d:%02X,%02X,%02X,%02X\r\n", cmd, c1, c2, c3, c4);
		#endif

		if (c1 & CMD_RDTRK)
		{
			if (cmd)
			{//command phase
				if (c3==0x80 && c4==0x06)	//command packet size must be 12 bytes
				{
					cmd = 0;
					SPI(FPGA_CMD_HDR0); //command header
					SPI(FPGA_CMD_HDR1);
					SPI(0x00); //cmd: 0x0001 = print texts
					SPI(0x01);
					//data packet size in bytes
					SPI(0x00);
					SPI(0x00);
					SPI(0x00);
					SPI(n+2); // +2 because only even byte count is possible to send and we have to send termination zero byte
					//don't care
					SPI(0x00);
					SPI(0x00);
					SPI(0x00);
					SPI(0x00);
				}
				else break;
			}
			else
			{
				//data phase
				if (c3==0x80 && c4==((n+2)>>1))
				{
					p = text;
					n = c4<<1;
					while (n--)
					{
						c4 = *p;
						SPI(c4);
						if (c4) //if current character is not zero go to next one
							p++;
					}
					DisableFpga();
					return 1;
				}
				else break;
			}
		}
		DisableFpga();
	}
	DisableFpga();
	return 0;
}



// this function sends given file to minimig's memory
// base - memory base address (bits 23..16)
// size - memory size (bits 23..16)
char BootUpload(struct fileTYPE *file, unsigned char base, unsigned char size)
{
	char c1,c2,c3,c4;
	char cmd;

	cmd = 1;
	while (1)
	{
		EnableFpga();
		c1 = SPI(0x10); //track read command
		c2 = SPI(0x01); //disk present
		SPI(0);
		SPI(0);
		c3 = SPI(0);
		c4 = SPI(0);

		#ifdef BOOT_DEBUG
		printf("CMD%d:%02X,%02X,%02X,%02X\r\n", cmd, c1, c2, c3, c4);
		#endif

		if (c1 & CMD_RDTRK)
		{
			if (cmd)
			{//command phase
				if (c3==0x80 && c4==0x06)	//command packet size 12 bytes
				{
					cmd = 0;

					//cmd: 0x0002 = upload memory
					//Param 1 - memory base address
					//Param 2 - memory size
					SendBootFPGACommand(0x02, base, size);
				}
				else break;
			}
			else
			{
				//data phase
				DisableFpga();
				
				#ifdef BOOT_DEBUG
				printf("Uploading ROM file\r\n");
				#endif
				
				//send rom image to FPGA
				SendFile(file);
				
				#ifdef BOOT_DEBUG
				printf("\r\nROM file uploaded\r\n");
				#endif
				
				return 0;
			}
		}
		DisableFpga();
	}
	DisableFpga();
	return -1;
}

/*load kickstart rom*/
void SendFile(struct fileTYPE *file)
{
	unsigned char c1,c2;
	unsigned char j;
	unsigned short n;
	unsigned char *p;

	n = file->len/512;	//sector count (rounded up)
	while (n--)
	{
		// read sector from mmc
		FileRead(file);

		// read command from FPGA
		while (!(GetFPGAStatus()& CMD_RDTRK));

		putchar('*');

		/*send sector to fpga*/
		EnableFpga();
		c1 = SPI(0);
		c2 = SPI(0);
		SPI(0);
		SPI(0);
		SPI(0);
		SPI(0);

		p=secbuf;
		j=255;
		do
		{
			//SPI(*(p++));
			SSPBUF = *(p++);
			while (!BF);

			//SPI(*(p++));
			SSPBUF = *(p++);
			while (!BF);
		}
		while (j--);
		DisableFpga();

		FileNextSector(file);
	}
}


void BootExit(void)
{
	char c1,c2,c3,c4;

	while (1)
	{
		EnableFpga();
		c1 = SPI(0x10); //track read command
		c2 = SPI(0x01); //disk present
		SPI(0);
		SPI(0);
		c3 = SPI(0);
		c4 = SPI(0);

		#ifdef BOOT_DEBUG
		printf("CMD%d:%02X,%02X,%02X,%02X\r\n", 3, c1, c2, c3, c4);
		#endif
		
		if (c1 & CMD_RDTRK)
		{
			//command packet size 12 bytes
			if (c3==0x80 && c4==0x06)
			{
				//cmd: 0x0003 = restart
				//Param 1 - don't care
				//Param 2 - don't care
				SendBootFPGACommand(0x03, 0x00, 0x00);
			}
			DisableFpga();
			return;
		}
		DisableFpga();
	}
}

void ClearMemory(unsigned char base, unsigned char size)
{
	unsigned char c1, c2, c3, c4;

	while (1)
	{
		EnableFpga();
		c1 = SPI(0x10); //track read command
		c2 = SPI(0x01); //disk present
		SPI(0);
		SPI(0);
		c3 = SPI(0);
		c4 = SPI(0);

		#ifdef BOOT_DEBUG
		printf("CMD%d:%02X,%02X,%02X,%02X\r\n", 4, c1, c2, c3, c4);
		#endif

		if (c1 & CMD_RDTRK)
		{
			if (c3==0x80 && c4==0x06)	//command packet size 12 bytes
			{
				//cmd: 0x0004 = clear memory
				//Param 1 - memory base address
				//Param 2 - memory size
				SendBootFPGACommand(0x04, base, size);
			}
			DisableFpga();
			return;
		}
		DisableFpga();
	}
}


void SendBootFPGACommand(unsigned char cmd, unsigned char p1, unsigned char p2)
{
	//command header
	SPI(FPGA_CMD_HDR0);
	SPI(FPGA_CMD_HDR1);
	//cmd
	SPI(0x00);
	SPI(cmd);

	//Command Param 1
	SPI(0x00);
	SPI(p1);
	SPI(0x00);
	SPI(0x00);

	//Command Param 2
	SPI(0x00);
	SPI(p2);
	SPI(0x00);
	SPI(0x00);
}