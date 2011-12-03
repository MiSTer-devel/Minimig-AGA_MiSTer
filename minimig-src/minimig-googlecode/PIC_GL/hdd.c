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

-- Goran Ljubojevic --
2009-11-15	- Copied from ARM Source
2009-11-16	- GetHardfileGeometry fixed signed change
			- BuildHardfileIndex removed - no memory on pic
			- HardFileSeek - removed in favor if standard (fat16.h) - FileSeek(struct fileTYPE *file, unsigned long sector)
2009-11-17	- OpenHardfile modified to current pic code
			- IdentifyDevice modified to current pic code
2009-11-18	- HandleHDD moddified to current pic code
2009-11-21	- Debug info consolidated (spport still not working)
2009-11-22	- Fixed working but slooooow
2009-11-26	- Added Direct transfer mode to FPGA
			- Changed cluster size on card to 32kb to test faster transfer, now works better
2009-12-20	- Added extension check for HD File
2009-12-30	- Added constants for detected ide commands
			- Added ideREGS structure to simplify ide handling code
			- WriteIDERegs replaced WriteTaskFile
			- WriteStatus renamed to WriteIDEStatus
2009-01-24	- ReadHDDSectors, WriteHDDSectors refactored out of HandleHDD
			- Removed variable for handling direct transfer mode, ReadFileEx is used with NULL param for buffer
2010-03-10	- Added Multi block transfer define
			- Added ACMD_SET_MULTIPLE_MODE command (NOT_FINISHED!)
			- Added ACMD_READ_MULTIPLE command (NOT_FINISHED!)
			- Added ACMD_WRITE_MULTIPLE command (NOT_FINISHED!)
2010-08-26	- Added firmwareConfiguration.h
2010-09-07	- Modified maximum sectors per block in Read/Write Multiple command from 0x8008 to 0x8010
2010-10-09	- Multi block transfers work in progress changed to conditional compile
			- NOTE: There is not enough memory for multi block transfers even with other features dissabled
*/

#include <pic18.h>
#include <stdio.h>
#include <string.h>
#include "firmwareConfiguration.h"
#include "config.h"
#include "mmc.h"
#include "fat16.h"
#include "hdd.h"
#include "hardware.h"


// hardfile structure
struct hdfTYPE hdf[2];


// helper function for byte swapping
void SwapBytes(char *ptr, unsigned long len)
{
    char x;
    len >>= 1;
    while (len--)
    {
        x = *ptr;
        *ptr++ = ptr[1];
        *ptr++ = x;
    }
}


// builds Identify Device struct
void IdentifyDevice(struct driveIdentify *id, unsigned char unit)
{
	unsigned long total_sectors = hdf[unit].cylinders * hdf[unit].heads * hdf[unit].sectors;

	// Clear identity 
	memset(id, 0, sizeof(id));

	id->general = 1 << 6;								// hard disk type
	id->noCylinders = hdf[unit].cylinders;				// cyl count
	id->noHeads  = hdf[unit].heads;						// head count
	id->noSectorsPerTrack = hdf[unit].sectors;			// sectors per track
	memcpy(&id->serialNo, "1234567890ABCDEFGHIJ", 20);	// serial number - byte swapped
	memcpy(&id->firmwareRevision, ".100    ", 8);		// firmware version - byte swapped

	// model name - byte swapped
	memcpy(&id->modelNumber,"YAQUBE                                  ", 40);
	// copy file name as model name
	memcpy(&id->modelNumber[8], hdf[unit].file.name, 11);

	SwapBytes(&id->modelNumber, 40);

	#ifdef HDD_MULTIBLOCK_TRANSFER_ENABLE
	id->maxSecTransfer = 0x8010;						//maximum sectors per block in Read/Write Multiple command 
	#endif
	
	id->isValidCHS = 1;
	id->curNoCylinders = hdf[unit].cylinders;
	id->curNoHeads = hdf[unit].heads;
	id->curNoSectorsPerTrack = hdf[unit].sectors;
	id->curCapacityInSectors = total_sectors;
//	id->curCapacityInSectors = hdf[unit].cylinders * hdf[unit].heads * hdf[unit].sectors;
}


unsigned long chs2lba(union ideRegsTYPE *ideRegs, unsigned char unit)
{
	unsigned long res;

	// TODO: Optimize calculation
	res = (unsigned long)ideRegs->regs.cylinder;
	res *= (unsigned long)hdf[unit].heads;
	res += (unsigned long)(ideRegs->regs.mode_drive_head & IDEREGS_HEAD_MASK);
	res *= (unsigned long)hdf[unit].sectors;
	res += (unsigned long)ideRegs->regs.sector;
	res -= 1;
	
	// Doesn't work for some strange reason
//	return(cylinder * hdf[unit].heads + head) * hdf[unit].sectors + sector - 1;
    return res;
}


void BeginHDDTransfer(unsigned char cmd, unsigned char status)
{
    EnableFpga();
    SPI(cmd);
    SPI(status);
    SPI(0x00);
    SPI(0x00);
    SPI(0x00);
    SPI(0x00);
}


void WriteIDERegs(union ideRegsTYPE *ideRegs)
{
	unsigned short i;
	
	// Write All IDE regs back to FPGA except for Command
	BeginHDDTransfer(CMD_IDE_REGS_WR, 0x00);
	for (i = 0; i < 7; i++)
	{
		SPI(0);
		SPI(ideRegs->tfr[i]);
	}
	DisableFpga();
}


void WriteIDEStatus(unsigned char status)
{
	BeginHDDTransfer(CMD_IDE_STATUS_WR, status);
    DisableFpga();
}


void NextHDDSector(union ideRegsTYPE *ideRegs, unsigned char unit)
{
	unsigned char head;
	
	// advance to next sector unless the last one is to be transmitted
   	if (ideRegs->regs.count)
	{
		if (ideRegs->regs.sector == hdf[unit].sectors)
		{
			ideRegs->regs.sector = 1;
			head = ideRegs->regs.mode_drive_head & IDEREGS_HEAD_MASK;
			head++;
			if (head == hdf[unit].heads)
			{
				head = 0;
				ideRegs->regs.cylinder++;
			}
			ideRegs->regs.mode_drive_head = (ideRegs->regs.mode_drive_head & (~IDEREGS_HEAD_MASK)) | head;
		}
		else
		{	ideRegs->regs.sector++;	}
	}
}


void HandleHDD(unsigned char c1, unsigned char c2)
{
	struct driveIdentify	id;
	unsigned char	*buffer;
	union ideRegsTYPE	ideRegs;
	unsigned short	i;
	unsigned char	unit;

	if (c1 & CMD_IDECMD)
	{
		DISKLED_ON;

		// read task file registers
		BeginHDDTransfer(CMD_IDE_REGS_RD, 0x00);
		for (i = 0; i < 8; i++)
		{
			SPI(0);
			ideRegs.tfr[i] = SPI(0);
		}
		DisableFpga();

		// master/slave selection
		unit = ideRegs.regs.mode_drive_head & IDEREGS_DRIVE_MASK ? 1 : 0;

		if (0 == hdf[unit].file.len)
		{
			// Abort if file length is 0
			#ifdef HDD_DEBUG
			HDD_Debug("Abort if file length is 0\r\nIDE:", ideRegs.tfr);
			#endif

			ideRegs.regs.error = IDE_ERROR_ABRT;
			WriteIDERegs(&ideRegs);
			WriteIDEStatus(IDE_STATUS_END | IDE_STATUS_IRQ | IDE_STATUS_ERR);
		}
		else if ((ideRegs.regs.cmd & 0xF0) == ACMD_RECALIBRATE)
		{
			// Recalibrate 0x10-0x1F (class 3 command: no data)
			#ifdef HDD_DEBUG
			HDD_Debug("Recalibrate\r\n", ideRegs.tfr);
			#endif

			ideRegs.regs.error = 0;
			ideRegs.regs.count = 0;
			ideRegs.regs.sector = 1;
			ideRegs.regs.cylinder = 0;
			ideRegs.regs.mode_drive_head = ideRegs.regs.mode_drive_head & (~IDEREGS_HEAD_MASK);
			WriteIDERegs(&ideRegs);

			WriteIDEStatus(IDE_STATUS_END | IDE_STATUS_IRQ);
		}
		else if (ideRegs.regs.cmd == ACMD_IDENTIFY_DEVICE)
		{
			// Identify Device 0xEC
			#ifdef HDD_DEBUG
			HDD_Debug("Identify Device\r\n", ideRegs.tfr);
			#endif

        	IdentifyDevice(&id, unit);

        	ideRegs.regs.error = 0;
			WriteIDERegs(&ideRegs);

			WriteIDEStatus(IDE_STATUS_RDY); // pio in (class 1) command type

        	// write data command
    		BeginHDDTransfer(CMD_IDE_DATA_WR, 0x00);
        	buffer = (unsigned char*)&id;
        	for(i=0; i < (sizeof(id)); i++)
	        {	SPI(*(buffer++));	}
        	for(; i < 512; i++)
	        {	SPI(0);		}
        	DisableFpga();

        	WriteIDEStatus(IDE_STATUS_END | IDE_STATUS_IRQ);
        }
        else if (ideRegs.regs.cmd == ACMD_INITIALIZE_DEVICE_PARAMETERS)
        {
        	// Initiallize Device Parameters
			#ifdef HDD_DEBUG
			HDD_Debug("Initialize Device Parametars\r\n", ideRegs.tfr);
			#endif

			ideRegs.regs.error = 0;
			WriteIDERegs(&ideRegs);

			WriteIDEStatus(IDE_STATUS_END | IDE_STATUS_IRQ);
        }
		#ifdef HDD_MULTIBLOCK_TRANSFER_ENABLE
        else if (ideRegs.regs.cmd == ACMD_SET_MULTIPLE_MODE)
        {
			#ifdef HDD_DEBUG
        	HDD_Debug("Set Multiple Mode\r\n", ideRegs.regs.count);
			#endif

        	// Read Sector Count in Multi Block Transfer
			hdf[unit].sectors_per_block = ideRegs.regs.count;
			
			WriteIDEStatus(IDE_STATUS_END | IDE_STATUS_IRQ);
        }
		#endif
        else if (ideRegs.regs.cmd == ACMD_READ_SECTORS)
        {
			#ifdef HDD_MULTIBLOCK_TRANSFER_ENABLE
        	ReadHDDSectors(&ideRegs, unit,0);
			#else
        	ReadHDDSectors(&ideRegs, unit);
			#endif
        }
		#ifdef HDD_MULTIBLOCK_TRANSFER_ENABLE
        else if (ideRegs.regs.cmd == ACMD_READ_MULTIPLE)
        {
        	ReadHDDSectors(&ideRegs, unit, 1);
        }
		#endif
        else if (ideRegs.regs.cmd == ACMD_WRITE_SECTORS)
        {
			#ifdef HDD_MULTIBLOCK_TRANSFER_ENABLE
        	WriteHDDSectors(&ideRegs, unit, 0);
			#else
        	WriteHDDSectors(&ideRegs, unit);
			#endif
        }
		#ifdef HDD_MULTIBLOCK_TRANSFER_ENABLE
        else if (ideRegs.regs.cmd == ACMD_WRITE_MULTIPLE)
        {
        	WriteHDDSectors(&ideRegs, unit, 1);
        }
		#endif
        else
        {
			#ifdef HDD_DEBUG
			HDD_Debug("Unknown ATA command\r\nIDE:", ideRegs.tfr);
			#endif

			ideRegs.regs.error = IDE_ERROR_ABRT;
			WriteIDERegs(&ideRegs);
			WriteIDEStatus(IDE_STATUS_END | IDE_STATUS_IRQ | IDE_STATUS_ERR);
        }

        DISKLED_OFF;
    }
}


#ifdef HDD_MULTIBLOCK_TRANSFER_ENABLE

// Read HDD Sectors
void ReadHDDSectors(union ideRegsTYPE *ideRegs, unsigned char unit, unsigned char multi)
{
	unsigned short	i;
	unsigned long	lba;

	WriteIDEStatus(IDE_STATUS_RDY);		// pio in (class 1) command type

	lba = chs2lba(ideRegs, unit);
	FileSeek(&hdf[unit].file, lba);

	#ifdef HDD_DEBUG
	HDD_Debug("Read\r\n", ideRegs->tfr);
	printf("CHS: %d.%d.%d\r\n", ideRegs->regs.cylinder, ideRegs->regs.mode_drive_head & IDEREGS_HEAD_MASK, ideRegs->regs.sector);
	printf("Read LBA:0x%08lX/SC:0x%02X\r\n", lba, ideRegs->tfr[2]);
	#endif
	
	// Wait for IDE cmd
	while (!(GetFPGAStatus()& CMD_IDECMD));

	#ifdef ALOW_MMC_DIRECT_TRANSFER_MODE

	FileReadEx(&hdf[unit].file, NULL);

	#else

	// Read sector to buffer
	FileRead(&hdf[unit].file);
	
	// Send Sector to FPGA
	BeginHDDTransfer(CMD_IDE_DATA_WR, 0x00);
	for(i=0; i < 512; i++)
	{	SPI(secbuf[i]);	}
	DisableFpga();
	
	#endif
	
	// decrease sector count
	ideRegs->regs.count--;

	// advance to next sector unless the last one is to be transmitted
	NextHDDSector(ideRegs,unit);

	WriteIDERegs(ideRegs);
	WriteIDEStatus((ideRegs->regs.count ? 0 : IDE_STATUS_END) | IDE_STATUS_IRQ);
}


// Write HDD sectors
void WriteHDDSectors(union ideRegsTYPE *ideRegs, unsigned char unit, unsigned char multi)
{
	unsigned short	i;
	unsigned long	lba;

    // pio out (class 2) command type
	WriteIDEStatus(IDE_STATUS_REQ);

	// write sectors
	lba = chs2lba(ideRegs, unit);
	FileSeek(&hdf[unit].file, lba);
    
	#ifdef HDD_DEBUG
	HDD_Debug("Write\r\n", ideRegs->tfr);
	printf("Write LBA:0x%08lX/SC:0x%02X\r\n", lba, ideRegs->tfr[2]);
	#endif

    // cmd request and drive number
    while (!(GetFPGAStatus()& CMD_IDEDAT));

    // Read Sector from FPGA
	BeginHDDTransfer(CMD_IDE_DATA_RD, 0x00);
    for (i = 0; i < 512; i++)
    {  	secbuf[i] = SPI(0xFF);		}
    DisableFpga();

    // Write sector to file
	FileWrite(&hdf[unit].file);	

    // decrease sector count
	ideRegs->regs.count--;
    // advance to next sector unless the last one is to be transmitted
	NextHDDSector(ideRegs,unit);

	WriteIDERegs(ideRegs);
	WriteIDEStatus((ideRegs->regs.count ? 0 : IDE_STATUS_END) | IDE_STATUS_IRQ);
}

#else

// Read HDD Sectors
void ReadHDDSectors(union ideRegsTYPE *ideRegs, unsigned char unit)
{
	unsigned short	i;
	unsigned long	lba;

	WriteIDEStatus(IDE_STATUS_RDY);		// pio in (class 1) command type

	lba = chs2lba(ideRegs, unit);
	FileSeek(&hdf[unit].file, lba);

	#ifdef HDD_DEBUG
	HDD_Debug("Read\r\n", ideRegs->tfr);
	printf("CHS: %d.%d.%d\r\n", ideRegs->regs.cylinder, ideRegs->regs.mode_drive_head & IDEREGS_HEAD_MASK, ideRegs->regs.sector);
	printf("Read LBA:0x%08lX/SC:0x%02X\r\n", lba, ideRegs->tfr[2]);
	#endif
	
	// Wait for IDE cmd
	while (!(GetFPGAStatus()& CMD_IDECMD));

	#ifdef ALOW_MMC_DIRECT_TRANSFER_MODE
		FileReadEx(&hdf[unit].file, NULL);
	#else
		// Read sector to buffer
		FileRead(&hdf[unit].file);
		
		// Send Sector to FPGA
		BeginHDDTransfer(CMD_IDE_DATA_WR, 0x00);
		for(i=0; i < 512; i++)
		{	SPI(secbuf[i]);	}
		DisableFpga();
	#endif
	
	// decrease sector count
	ideRegs->regs.count--;

	// advance to next sector unless the last one is to be transmitted
	NextHDDSector(ideRegs,unit);

	WriteIDERegs(ideRegs);
	WriteIDEStatus((ideRegs->regs.count ? 0 : IDE_STATUS_END) | IDE_STATUS_IRQ);
}

// Write HDD sectors
void WriteHDDSectors(union ideRegsTYPE *ideRegs, unsigned char unit)
{
	unsigned short	i;
	unsigned long	lba;

    // pio out (class 2) command type
	WriteIDEStatus(IDE_STATUS_REQ);

	// write sectors
	lba = chs2lba(ideRegs, unit);
	FileSeek(&hdf[unit].file, lba);
    
	#ifdef HDD_DEBUG
	HDD_Debug("Write\r\n", ideRegs->tfr);
	printf("Write LBA:0x%08lX/SC:0x%02X\r\n", lba, ideRegs->tfr[2]);
	#endif

    // cmd request and drive number
    while (!(GetFPGAStatus()& CMD_IDEDAT));

    // Read Sector from FPGA
	BeginHDDTransfer(CMD_IDE_DATA_RD, 0x00);
    for (i = 0; i < 512; i++)
    {  	secbuf[i] = SPI(0xFF);		}
    DisableFpga();

    // Write sector to file
	FileWrite(&hdf[unit].file);	

    // decrease sector count
	ideRegs->regs.count--;
    // advance to next sector unless the last one is to be transmitted
	NextHDDSector(ideRegs,unit);
	WriteIDERegs(ideRegs);
	
	WriteIDEStatus((ideRegs->regs.count ? 0 : IDE_STATUS_END) | IDE_STATUS_IRQ);
}

#endif


// this function comes from WinUAE, should return the same CHS as WinUAE
void GetHardfileGeometry(struct hdfTYPE *pHDF)
{
	unsigned long total;
	unsigned long i, head, cyl, spt;
	unsigned long sptt[] = { 63, 127, 255 };

	if (0 == pHDF->file.len)
	{	return;		}

	total = pHDF->file.len >> 9;		//total = pHDF->file.len / 512

	for (i = 0; i < 3; i++)
	{
		spt = sptt[i];
		for (head = 4; head <= 16; head++)
		{
			cyl = total / (head * spt);
			//if (pHDF->file.len <= (512 * 1024 * 1024))	// Strange But not Working
			if (pHDF->file.len <= 536870912)				//(pHDF->file.len <= 512 * 1024 * 1024)
			{
				if (cyl <= 1023)
				{	break;	}
			}
			else
			{
				if (cyl < 16383)
				{	break;	}
				if (cyl < 32767 && head >= 5)
				{	break;	}
				if (cyl <= 65535)
				{	break;	}
			}
		}
		if (head <= 16)
		{	break;	}
	}

	pHDF->cylinders = (unsigned short)cyl;
	pHDF->heads = (unsigned short)head;
	pHDF->sectors = (unsigned short)spt;
}


unsigned char OpenHardfile(unsigned char unit, unsigned char *name)
{
	if (name[0] && (0 == strncmp(&name[8],defHardDiskExt,3)))
	{
		#ifdef HDD_DEBUG
		printf("\r\nTrying to open hard file: %s\r\n", name);
		#endif

		if (Open(&hdf[unit].file, name))
		{
			GetHardfileGeometry(&hdf[unit]);

			#ifdef HDD_DEBUG
			printf("HARDFILE %d:\r\n", unit);
			printf("file: \"%s\"\r\n", hdf[unit].file.name);
			printf("size: 0x%08lX (0x%08lX MB)\r\n", hdf[unit].file.len, hdf[unit].file.len >> 20);
			printf("CHS: %d.%d.%d", hdf[unit].cylinders, hdf[unit].heads, hdf[unit].sectors);
			printf(" (%lu MB)\r", ((((unsigned long) hdf[unit].cylinders) * hdf[unit].heads * hdf[unit].sectors) >> 11));
			#endif

			// Hard file found
			hdf[unit].present = 1;
			return 1;
		}
	}

	// Not Found
	hdf[unit].present = 0;
    return 0;
}

#ifdef HDD_DEBUG

void HDD_Debug(const char *msg, unsigned char *tfr)
{
	int i;
//	printf("\r\n");
	printf(msg);
	for(i=0; i < 7; i++)
	{	printf("0x%02X ", *(tfr++));	}
	printf("0x%02X\r\n", *(tfr++));
}

#endif

