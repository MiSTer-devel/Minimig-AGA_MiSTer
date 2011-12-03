/*------------------------------------------------------------------------------------------*/
/*This is the lowlevel SD-card driver, 														*/
/*in order to function with the allready available software, the routines use the name ATA	*/
/*																							*/
/*Note that this driver is dirty because it polls the drive for it's flags. The 			*/
/*routines in this driver should therefore only be called from a low priority task			*/
/*------------------------------------------------------------------------------------------*/

/*	History:
2005-04-19	-start of project
2005-12-11	-(Dennis) added proper CS handling to enable sharing of SPI bus
-- JB --
2009-03-01	- changed card detection routine (now Kingston 128 MB MMC works correctly)
			- removed CRC7 calculation (only required for CMD0, static value used)
			- lba sector address calculation uses logical operations
			- t_lba variable added for skipping unnecessary reads of the sector which is already in the buffer - results in faster FileSearch()
-- Goran Ljubojevic --
2009-08-29	- Restored CRC7 calculation for SDHC detection
			- SDHC detection
			- SDHC reading/writing
			- CMD definitions moved to header file
			- IO definitions used from hardware.h
2009-11-25	- Added direct to FPGA transfer mode when reading for HDD support
2010-01-24	- Removed MMC_DIRECT_TRANSFER_MODE variable, direct transfer mode is used when read buffer is null
2010-08-26	- Added firmwareConfiguration.h
*/

/*------------------------------------------------------------------------------------------*/

#include <pic18.h>
#include <stdio.h>
#include "firmwareConfiguration.h"
#include "mmc.h"
#include "hardware.h"


/*constants*/
#define		FALSE		0			/*FALSE*/
#define		TRUE		1			/*TRUE*/


// SD Card Specifification V1, V2, SDHC
#define	SD_RAW_SPEC_1		0
#define SD_RAW_SPEC_2		1
#define SD_RAW_SPEC_SDHC	2


// variables
static unsigned char cardType;	// Card Type Detected

unsigned char crc_7;			/*contains CRC value*/

unsigned int timeout;
unsigned char response_1;		/*byte that holds the first response byte*/
unsigned char response_2;		/*byte that holds the second response byte*/
unsigned char response_3;		/*byte that holds the third response byte*/
unsigned char response_4;		/*byte that holds the fourth response byte*/
unsigned char response_5;		/*byte that holds the fifth response byte*/

unsigned long t_lba = -1;		//address of the sector in buffer

/*internal functions*/
void Command_R0(char cmd,unsigned short AdrH,unsigned short AdrL);
void Command_R1(char cmd,unsigned short AdrH,unsigned short AdrL);
void Command_R2(char cmd,unsigned short AdrH,unsigned short AdrL);
void Command_R3(char cmd,unsigned short AdrH,unsigned short AdrL);
void MmcAddCrc7(unsigned char c);


/*************************************************************************************/
/*************************************************************************************/
/*External functions*/
/*************************************************************************************/
/*************************************************************************************/

/*Enable the MMC/SD card correctly*/
unsigned char MMC_Init(void)
{
	unsigned short lp;

	SSPCON1 = 0x32; //spiclk = Fosc/64 (init clock 100-400 kHz)

	_M_CD = 1;								/*enable clock*/
	_M_CS = 1;								/*SDcard Disabled*/
	
	for (lp=0; lp<10; lp++)					/*Set SDcard in SPI-Mode, Reset*/
	{	SPI(0xFF);	}						/*10 * 8bits = 80 clockpulses*/

	for (lp=0; lp<56000; lp++);				/*delay for a lot of milliseconds (least 16 bus clock cycles)*/

	_M_CS = 0;								/*SDcard Enabled*/

	// Reset Card Type defaults to MMC
	cardType = 0x00;
	
	/*CMD0: Reset all cards to IDLE state*/
	Command_R1(CMD0,0,0);
	if (response_1 != 0x01)
	{
		/*error, quit routine*/
		#ifdef DEBUG_SDMMC
		printf("No card detected!\r\n");
		#endif
		DisableCard();
		return(FALSE);
	}

	// Check for SD Card V2
	Command_R3(CMD8, 0x0000, 0x01aa);		// Voltage 2.7V - 3.6V, 0xaa test pattern
	if(0 == (response_1 & 0x04))
	{
		if(0x01 == response_4 && 0xAA==response_5)
		{	
			#ifdef DEBUG_SDMMC
			printf("SD card V2 detected, possible SDHC\r\n");
			#endif
			cardType |= (1 << SD_RAW_SPEC_2);
		}
		else
		{
			// Error detecting card type
			#ifdef DEBUG_SDMMC
			printf("Error detecting SD V2 card\r\n");
			#endif
			DisableCard();
			return(FALSE);
		}
	}
	else
	{
		// Check for SD card V1
		Command_R1(CMD55,0,0);
		Command_R1(CMD41,0,0);
		if(0 == (response_1 & 0x04))
		{
			#ifdef DEBUG_SDMMC
			printf("SD card V1 detected, possible SDHC\r\n");
			#endif
			cardType |= (1 << SD_RAW_SPEC_1);
		}
		else
		{
			/*An MMC-card has been detected, handle accordingly*/
			#ifdef DEBUG_SDMMC
			printf("MMC-card detected\r\n");
			#endif
		}
	}
	
	// Wait for card to get ready
	timeout = 0;
	while (1)
	{
		if(cardType & ((1<<SD_RAW_SPEC_1) | (1<<SD_RAW_SPEC_2)))
		{
			// When SD Card detected
			lp = 0x0;
			if(cardType & (1<<SD_RAW_SPEC_2))
			{	lp = 0x4000;	}
			
			// Activate SD card init process
			Command_R1(CMD55,0,0);
			Command_R1(CMD41,lp,0);
		}
		else
		{
			// Activate the MMC cards init process
			Command_R1(CMD1,0,0);
		}
		
		// Check if card is idle
		if (response_1 == 0x00)
		{	break;	}

		timeout++;
		if (timeout == 1000)                        /*timeout mechanism*/
		{
			#ifdef DEBUG_SDMMC
			printf("SD/MMC ACMD41/CMD1 response timeout...\r\n");
			#endif
			DisableCard();
			return(FALSE);
		}
	}

	// Check for SDHC card
	if(cardType & (1<<SD_RAW_SPEC_2))
	{
		// Get operating conditions
		Command_R3(CMD58, 0, 0);
		if(response_1)
		{
			DisableCard();
			return(FALSE);
		}
		
		if(response_2 & 0x40)
		{	
			#ifdef DEBUG_SDMMC
			printf("SDHC Card confirmed\r\n");
			#endif
			cardType |= (1 << SD_RAW_SPEC_SDHC);
		}
	}

	//set block size to 512 bytes
	timeout = 0;
	while(1)
	{
		Command_R1(CMD16,0x0000,0x0200);
		if(response_1 == 0)
		{	break;	}
		
		timeout++;
		if(timeout == 100)
		{
			#ifdef DEBUG_SDMMC
			printf("Set block size to 512 timeout.\r\n");
			#endif
			DisableCard();
			return(FALSE);
		}
	}
	

	DisableCard();
	
	// TODO: Change speed for card access
//	SSPCON1 = 0x30; //spiclk = Fosc/4 (max 20 MHz for MMC-card)
	SSPCON1 = 0x30; //spiclk = Fosc/4 (max 25 MHz for SD-card)
	return(TRUE);
}

// Read single block (with block-size set by CMD16 to 512 by default)
// if DIRECT TRANSFER MODE is allowed MMC_Read() function activates special FPGA chip select line
// which allows direct transfer of data from the SD card to the FPGA (only reads are supported)
// this only happends when ReadData buffer pointer is NULL
unsigned char MMC_Read(unsigned long lba, unsigned char *ReadData)
{
	unsigned short upper_lba, lower_lba;
	unsigned char i;
	unsigned char *p;

	
	#ifdef ALOW_MMC_DIRECT_TRANSFER_MODE

		// When direct tranfer mode sector is not read in buffer
		if(NULL != ReadData)
		{
			if (lba == t_lba)
			{	return(TRUE);	}
			t_lba = lba;
		}

	#else

		if (lba == t_lba)
		{	return(TRUE);	}
		t_lba = lba;

	#endif

	// SDHC uses LBA instead of byte address
	if(0 == (cardType & (1<<SD_RAW_SPEC_SDHC)))
	{
		// Not SDHC calculate byte address
		/* since the MMC and SD cards are byte addressable and the FAT relies on a sector address
		(where a sector is 512 bytes long), we must multiply by 512 in order to get the byte address */
		lba = lba<<9;
	}

	#ifdef DEBUG_SDMMC
	printf("Reading LBA 0x%08lX\r\n", lba);
	#endif
	
	upper_lba = (unsigned short)(lba>>16);
	lower_lba = (unsigned short)lba;

	EnableCard();

	Command_R1(CMD17, upper_lba, lower_lba);

	/*exit if invalid response*/
	if (response_1 !=0)
	{
		#ifdef DEBUG_SDMMC
		printf("MMC CMD17: invalid response %02X\r\n",response_1);
		#endif
		DisableCard();
		return(FALSE);
	}

	/*wait for start of data transfer with timeout*/
	timeout = 0;
	while(SPI(0xFF) != 0xFE)
	{
		if (timeout++ >= 50000)
		{
			#ifdef DEBUG_SDMMC
			printf("MMC CMD17: no data token\r\n");
			#endif
			DisableCard();
			return(FALSE);
		}
	}

	#ifdef ALOW_MMC_DIRECT_TRANSFER_MODE

		if(NULL == ReadData)
		{
			// Enable Line for direct tranfer to FPGA 
			_F_CS2 = 0;
	
			i=128;
			do
			{
				SSPBUF = 0xff;
				while (!BF);
	
				SSPBUF = 0xff;
				while (!BF);
				
				SSPBUF = 0xff;
				while (!BF);
				
				SSPBUF = 0xff;
				while (!BF);
			}
			while(--i);
	
			// Disable Line for direct tranfer to FPGA 
			_F_CS2 = 1;
		}
		else
		{
			/*read data and exit OK*/
			p=ReadData;
			i=128;
			do
			{
				SSPBUF = 0xff;
				while (!BF);
				*(p++) = SSPBUF;
				SSPBUF = 0xff;
				while (!BF);
				*(p++) = SSPBUF;
				SSPBUF = 0xff;
				while (!BF);
				*(p++) = SSPBUF;
				SSPBUF = 0xff;
				while (!BF);
				*(p++) = SSPBUF;
			}
			while(--i);
		}

	#else

		/*read data and exit OK*/
		p=ReadData;
		i=128;
		do
		{
			SSPBUF = 0xff;
			while (!BF);
			*(p++) = SSPBUF;
			SSPBUF = 0xff;
			while (!BF);
			*(p++) = SSPBUF;
			SSPBUF = 0xff;
			while (!BF);
			*(p++) = SSPBUF;
			SSPBUF = 0xff;
			while (!BF);
			*(p++) = SSPBUF;
		}
		while(--i);

	#endif

	SPI(0xff);	//Read CRC lo byte
	SPI(0xff);	//Read CRC hi byte

	DisableCard();
	return(TRUE);
}



/*Write: 512 Byte-Mode, this will not work (read MMC and SD-card specs) with any other sector/block size then 512*/
unsigned char MMC_Write(unsigned long lba, unsigned char *WriteData)
{
	unsigned short upper_lba, lower_lba;
	unsigned char i;
	unsigned char *p;

	t_lba = lba;

	// SDHC uses LBA instead of byte address
	if(0 == (cardType & (1<<SD_RAW_SPEC_SDHC)))
	{
		// Not SDHC calculate byte address
		/* since the MMC and SD cards are byte addressable and the FAT relies on a sector address
		(where a sector is 512 bytes long), we must multiply by 512 in order to get the byte address */
		lba = lba<<9;
	}

	#ifdef DEBUG_SDMMC
	printf("Writing LBA 0x%08lX\r\n", lba);
	#endif

	upper_lba = (unsigned short)(lba>>16);
	lower_lba = (unsigned short)lba;

	EnableCard();

	Command_R1(CMD24, upper_lba, lower_lba);
	/*exit if invalid response*/
	if (response_1 !=0)
	{
		#ifdef DEBUG_SDMMC
		printf("MMC CMD24: invalid response %02X\r\n",response_1);
		#endif
		DisableCard();
		return(FALSE);
	}

	SPI(0xFF);	//One byte gap
	SPI(0xFE);	//Send Data token

	//Send bytes for sector
	p = WriteData;
	i = 128;
	do
	{
		SSPBUF = *(p++);
		while (!BF);
		SSPBUF = *(p++);
		while (!BF);
		SSPBUF = *(p++);
		while (!BF);
		SSPBUF = *(p++);
		while (!BF);
	}
	while (--i);

	SPI(0xFF);	//Send CRC lo byte
	SPI(0xFF);	//Send CRC hi byte

	i = SPI(0xFF);	//Read packet response
	//Status codes
	//: 010 = Data accepted
	//: 101 = Data rejected due to CRC error
	//: 110 = Data rejected due to write error
	i &= 0b00011111;
	if (i != 0b00000101)
	{
		#ifdef DEBUG_SDMMC
		printf("MMC CMD24: write error %02X\r\n",i);
		#endif
		DisableCard();
		return(FALSE);
	}

	timeout = 0;
	while (SPI(0xFF) == 0x00)	/*wait until the card has finished writing the data*/
	{
		if (timeout++ >= 50000)
		{
			#ifdef DEBUG_SDMMC
			printf("MMC CMD24: busy wait timeout\r\n");
			#endif
			DisableCard();
			return(FALSE);
		}
	}
	DisableCard();
	return(TRUE);
}


/*************************************************************************************/
/*Internal functions*/
/*************************************************************************************/

/*Send a command to the SDcard*/
void Command_R0(char cmd, unsigned short AdrH, unsigned short AdrL)
{
	crc_7=0;
	SPI(0xFF);						/*flush SPI-bus*/
	
	SPI(cmd);
	MmcAddCrc7(cmd);						/*update CRC*/

	SPI((unsigned char)(AdrH>>8));			/*use upper 8 bits (everything behind the comma is discarded)*/
	MmcAddCrc7((unsigned char)(AdrH>>8));	/*update CRC*/
	
	SPI((unsigned char)AdrH);				/*use lower 8 bits (shows the remaining part of the devision)*/
	MmcAddCrc7((unsigned char)AdrH);		/*update CRC*/
	
	SPI((unsigned char)(AdrL>>8));			/*use upper 8 bits (everything behind the comma is discarded)*/
	MmcAddCrc7((unsigned char)(AdrL>>8));	/*update CRC*/

	SPI((unsigned char)(AdrL));				/*use lower 8 bits (shows the remaining part of the devision)*/
	MmcAddCrc7((unsigned char)AdrL);		/*update CRC*/

	crc_7<<=1;								/*shift all bits 1 position to the left, to free position 0*/
	crc_7++;								/*set LSB to '1'*/

	SPI(crc_7);								/*valid CRC is required for CMD0*/
};

/*Send a command to the SDcard, a one byte response is expected*/
void Command_R1(char cmd, unsigned short AdrH, unsigned short AdrL)
{
	unsigned char i = 100;
	Command_R0(cmd, AdrH, AdrL);	/*send command*/
	do
		response_1 = SPI(0xFF);			/*return the reponse in the correct register*/
	while (response_1==0xFF && --i);
}

/*Send a command to the SDcard, a two byte response is expected*/
void Command_R2(char cmd, unsigned short AdrH, unsigned short AdrL)
{
	unsigned char i = 100;
	Command_R0(cmd, AdrH, AdrL);	/*send command*/
	do
		response_1 = SPI(0xFF);			/*return the reponse in the correct register*/
	while (response_1==0xFF && --i);

	response_2 = SPI(0xFF);
}

/*Send a command to the SDcard, a five byte response is expected*/
void Command_R3(char cmd, unsigned short AdrH, unsigned short AdrL)
{
	unsigned char i = 100;
	Command_R0(cmd, AdrH, AdrL);	/*send command*/
	do
		response_1 = SPI(0xFF);			/*return the reponse in the correct register*/
	while (response_1==0xFF && --i);

	response_2 = SPI(0xFF);
	response_3 = SPI(0xFF);
	response_4 = SPI(0xFF);
	response_5 = SPI(0xFF);
}

/*calculate CRC7 checksum*/
void MmcAddCrc7(unsigned char c)
{
	unsigned char i;
	
	i=8;
	do
	{
		crc_7<<=1;
		if(c&0x80)
			crc_7^=0x09;
		if(crc_7&0x80)
			crc_7^=0x09;
		c<<=1;
	}
	while(--i);
}
