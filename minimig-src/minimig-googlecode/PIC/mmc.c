/*------------------------------------------------------------------------------------------*/
/*This is the lowlevel SD-card driver, 														*/
/*in order to function with the allready available software, the routines use the name ATA	*/
/*																							*/
/*Note that this driver is dirty because it polls the drive for it's flags. The 			*/
/*routines in this driver should therefore only be called from a low priority task			*/
/*------------------------------------------------------------------------------------------*/

/*	History:
	2005-04-19		-start of project
	2005-12-11		-(Dennis) added proper CS handling to enable sharing of SPI bus
	-- JB --
	2009-03-01		- changed card detection routine (now Kingston 128 MB MMC works correctly)
					- removed CRC7 calculation (only required for CMD0, static value used)
					- lba sector address calculation uses logical operations
					- t_lba variable added for skipping unnecessary reads of the sector which is already in the buffer - results in faster FileSearch()
*/

/*------------------------------------------------------------------------------------------*/

#include <pic18.h>
#include <stdio.h>
#include "mmc.h"
#include "hardware.h"

/*IO definitions*/
#define		MMC_CS	_M_CS

/*constants*/
#define		FALSE		0			/*FALSE*/
#define		TRUE		1			/*TRUE*/
#define		MMCCARD		2
#define		SDCARD		3

/*MMC commandset*/
#define		CMD0		0x40		/*Resets the multimedia card*/
#define		CMD1		0x41		/*Activates the card's initialization process*/
#define		CMD2		0x42		/*--*/
#define		CMD3		0x43		/*--*/
#define		CMD4		0x44		/*--*/
#define		CMD5		0x45		/*reseved*/
#define		CMD6		0x46		/*reserved*/
#define		CMD7		0x47		/*--*/
#define		CMD8		0x48		/*reserved*/
#define		CMD9		0x49		/*CSD : Ask the selected card to send its card specific data*/
#define		CMD10		0x4a		/*CID : Ask the selected card to send its card identification*/
#define		CMD11		0x4b		/*--*/
#define		CMD12		0x4c		/*--*/
#define		CMD13		0x4d		/*Ask the selected card to send its status register*/
#define		CMD14		0x4e		/*--*/
#define		CMD15		0x4f		/*--*/
#define		CMD16		0x50		/*Select a block length (in bytes) for all following block commands (Read:between 1-512 and Write:only 512)*/
#define		CMD17		0x51		/*Reads a block of the size selected by the SET_BLOCKLEN command, the start address and block length must be set so that the data transferred will not cross a physical block boundry*/
#define		CMD18		0x52		/*--*/
#define		CMD19		0x53		/*reserved*/
#define		CMD20		0x54		/*--*/
#define		CMD21		0x55		/*reserved*/
#define		CMD22		0x56		/*reserved*/
#define		CMD23		0x57		/*reserved*/
#define		CMD24		0x58		/*Writes a block of the size selected by CMD16, the start address must be alligned on a sector boundry, the block length is always 512 bytes*/
#define		CMD25		0x59		/*--*/
#define		CMD26		0x5a		/*--*/
#define		CMD27		0x5b		/*Programming of the programmable bits of the CSD*/
#define		CMD28		0x5c		/*If the card has write protection features, this command sets the write protection bit of the addressed group. The porperties of the write protection are coded in the card specific data (WP_GRP_SIZE)*/
#define		CMD29		0x5d		/*If the card has write protection features, this command clears the write protection bit of the addressed group*/
#define		CMD30		0x5e		/*If the card has write protection features, this command asks the card to send the status of the write protection bits. 32 write protection bits (representing 32 write protect groups starting at the specific address) followed by 16 CRD bits are transferred in a payload format via the data line*/
#define		CMD31		0x5f		/*reserved*/
#define		CMD32		0x60		/*sets the address of the first sector of the erase group*/
#define		CMD33		0x61		/*Sets the address of the last sector in a cont. range within the selected erase group, or the address of a single sector to be selected for erase*/
#define		CMD34		0x62		/*Removes on previously selected sector from the erase selection*/
#define		CMD35		0x63		/*Sets the address of the first erase group within a range to be selected for erase*/
#define		CMD36		0x64		/*Sets the address of the last erase group within a continuos range to be selected for erase*/
#define		CMD37		0x65		/*Removes one previously selected erase group from the erase selection*/
#define		CMD38		0x66		/*Erases all previously selected sectors*/
#define		CMD39		0x67		/*--*/
#define		CMD40		0x68		/*--*/
#define		CMD41		0x69		/*reserved*/
#define		CMD42		0x6a		/*reserved*/
#define		CMD43		0x6b		/*reserved*/
#define		CMD44		0x6c		/*reserved*/
#define		CMD45		0x6d		/*reserved*/
#define		CMD46		0x6e		/*reserved*/
#define		CMD47		0x6f		/*reserved*/
#define		CMD48		0x70		/*reserved*/
#define		CMD49		0x71		/*reserved*/
#define		CMD50		0x72		/*reserved*/
#define		CMD51		0x73		/*reserved*/
#define		CMD52		0x74		/*reserved*/
#define		CMD53		0x75		/*reserved*/
#define		CMD54		0x76		/*reserved*/
#define		CMD55		0x77		/*reserved*/
#define		CMD56		0x78		/*reserved*/
#define		CMD57		0x79		/*reserved*/
#define		CMD58		0x7a		/*reserved*/
#define		CMD59		0x7b		/*Turns the CRC option ON or OFF. A '1' in the CRC option bit will turn the option ON, a '0' will turn it OFF*/
#define		CMD60		0x7c		/*--*/
#define		CMD61		0x7d		/*--*/
#define		CMD62		0x7e		/*--*/
#define		CMD63		0x7f		/*--*/

/*variables*/
unsigned int timeout;
unsigned char response_1;		/*byte that holds the first response byte*/
unsigned char response_2;		/*byte that holds the second response byte*/
unsigned char response_3;		/*byte that holds the third response byte*/
unsigned char response_4;		/*byte that holds the fourth response byte*/
unsigned char response_5;		/*byte that holds the fifth response byte*/

unsigned long t_lba = -1;		//address of the sector in buffer

/*internal functions*/
Command_R0(char cmd,unsigned short AdrH,unsigned short AdrL);
Command_R1(char cmd,unsigned short AdrH,unsigned short AdrL);
Command_R2(char cmd,unsigned short AdrH,unsigned short AdrL);
Command_R3(char cmd,unsigned short AdrH,unsigned short AdrL);
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
	MMC_CS = 1;								/*SDcard Disabled*/

	for (lp=0; lp<10; lp++)					/*Set SDcard in SPI-Mode, Reset*/
		SPI(0xFF);							/*10 * 8bits = 80 clockpulses*/

	for (lp=0; lp<56000; lp++);				/*delay for a lot of milliseconds (least 16 bus clock cycles)*/

	MMC_CS = 0;								/*SDcard Enabled*/

	Command_R1(CMD0,0,0);                   /*CMD0: Reset all cards to IDLE state*/
	if (response_1 == 0x01)
	{
		timeout = 0;
		while (1)
		{
			Command_R1(CMD55,0,0);
			if (response_1 & 0x04)  //MMC card responses with invalid command (but not Kingston MMC 128MB)
				break;

			Command_R1(CMD41,0,0);
			if (response_1 & 0x04)  //MMC card responses with invalid command
				break;

			if (response_1 == 0x00)
			{
				printf("SD-card detected\n\r");
				Command_R1(CMD16,0x0000,0x0200); //set block size
				DisableCard();
				SSPCON1 = 0x30; //spiclk = Fosc/4 (max 25 MHz for SD-card)
				return(1);
			}
			timeout++;
			if (timeout == 1000)                        /*timeout mechanism*/
			{
				DisableCard();
				printf("SD-card ACMD41 response timeout...\r");
				return(0);
			}
		}

		/*An MMC-card has been detected, handle accordingly*/
		timeout = 0;
		response_1 = 1;
		while (response_1 != 0)
		{
			Command_R1(CMD1,0,0);           /*activate the cards init process*/
			if (timeout == 1000)                /*timeout mechanism, specs: max 500ms*/
			{
				DisableCard();
				printf("MMC-card CMD1 response timeout...\r");
				return(0);
			}
			timeout++;
		}
		printf("MMC-card detected\n\r");
		DisableCard();
		SSPCON1 = 0x30; //spiclk = Fosc/4 (max 20 MHz for MMC-card)
		return(1);
	}

	DisableCard();
	printf("No card detected!\r");
	return(0);                          /*error, quit routine*/
}

/*Read single block (with block-size set by CMD16 to 512 by default)*/
unsigned char MMC_Read(unsigned long lba, unsigned char *ReadData)
{
	unsigned short upper_lba, lower_lba;
	unsigned char i;
	unsigned char *p;

	if (lba == t_lba)
		return(TRUE);

	t_lba = lba;

	lba = lba<<9;								/*calculate byte address*/
	upper_lba = (unsigned short)(lba>>16);
	lower_lba = (unsigned short)lba;

	EnableCard();

	Command_R1(CMD17, upper_lba, lower_lba);

	/*exit if invalid response*/
	if (response_1 !=0)
	{
		printf("MMC CMD17: invalid response %02X\r",response_1);
		DisableCard();
		return(FALSE);
	}

	/*wait for start of data transfer with timeout*/
	timeout = 0;
	while(SPI(0xFF) != 0xFE)
	{
		if (timeout++ >= 50000)
		{
			printf("MMC CMD17: no data token\r");
			DisableCard();
			return(FALSE);
		}
	}

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

	/* since the MMC and SD cards are byte addressable and the FAT relies on a sector address
	(where a sector is 512 bytes long), we must multiply by 512 in order to get the byte address */
	lba = lba<<9;
	upper_lba = (unsigned short)(lba>>16);
	lower_lba = (unsigned short)lba;

	EnableCard();

	Command_R1(CMD24, upper_lba, lower_lba);
	/*exit if invalid response*/
	if (response_1 !=0)
	{
		printf("MMC CMD24: invalid response %02X\r",response_1);
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
		printf("MMC CMD24: write error %02X\r",i);
		DisableCard();
		return(FALSE);
	}

	timeout = 0;
	while (SPI(0xFF) == 0x00)	/*wait until the card has finished writing the data*/
	{
		if (timeout++ >= 50000)
		{
			printf("MMC CMD24: busy wait timeout\r");
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
Command_R0(char cmd, unsigned short AdrH, unsigned short AdrL)
{
	SPI(0xFF);						/*flush SPI-bus*/
	SPI(cmd);
	SPI((unsigned char)(AdrH>>8));	/*use upper 8 bits (everything behind the comma is discarded)*/
	SPI((unsigned char)AdrH);		/*use lower 8 bits (shows the remaining part of the devision)*/
	SPI((unsigned char)(AdrL>>8));	/*use upper 8 bits (everything behind the comma is discarded)*/
	SPI((unsigned char)(AdrL));		/*use lower 8 bits (shows the remaining part of the devision)*/
	SPI(0x95);						/*valid CRC is only required for CMD0*/
};

/*Send a command to the SDcard, a one byte response is expected*/
Command_R1(char cmd, unsigned short AdrH, unsigned short AdrL)
{
	unsigned char i = 100;
	Command_R0(cmd, AdrH, AdrL);	/*send command*/
	do
		response_1 = SPI(0xFF);			/*return the reponse in the correct register*/
	while (response_1==0xFF && --i);
}

/*Send a command to the SDcard, a two byte response is expected*/
Command_R2(char cmd, unsigned short AdrH, unsigned short AdrL)
{
	unsigned char i = 100;
	Command_R0(cmd, AdrH, AdrL);	/*send command*/
	do
		response_1 = SPI(0xFF);			/*return the reponse in the correct register*/
	while (response_1==0xFF && --i);

	response_2 = SPI(0xFF);
}

/*Send a command to the SDcard, a five byte response is expected*/
Command_R3(char cmd, unsigned short AdrH, unsigned short AdrL)
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



















