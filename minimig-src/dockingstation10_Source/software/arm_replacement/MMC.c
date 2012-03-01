/*
Copyright 2005, 2006, 2007 Dennis van Weeren
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

// --== based on the work by Dennis van Weeren and Jan Derogee ==--
// 2008-10-03 - adaptation for ARM controller
// 2009-07-23 - clean-up and some optimizations
// 2009-11-22 - multiple sector read implemented


// FIXME - get capacity from SD card

//#include "AT91SAM7S256.h"
//#include "stdio.h"
//#include "string.h"
#include "hardware.h"
#include "mmc.h"
#include "fat.h"
//#include "firmware.h"

// variables
unsigned char crc;
unsigned long timeout;
unsigned char response;
unsigned char CardType;

unsigned char CSDData[16];

// internal functions
void MMC_CRC(unsigned char c);
unsigned char MMC_Command(unsigned char cmd, unsigned long arg);
unsigned char MMC_CMD12(void);

// init memory card
unsigned char MMC_Init(void)
{
    unsigned char n;
    unsigned char ocr[4];

//    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (120 << 8) | (2 << 24); // init clock 100-400 kHz
//    *AT91C_PIOA_SODR = MMC_SEL;  // set output (MMC chip select disabled)
	SPI_slow();
	EnableCard();

    for (n = 10; n > 0; n--)
        SPI(0xFF); // 80 dummy clocks

    WaitTimer(20); // 20ms delay

//    *AT91C_PIOA_CODR = MMC_SEL; // clear output (MMC chip select enabled)

    CardType = CARDTYPE_NONE;

    if (MMC_Command(CMD0, 0) == 0x01)
    { // idle state
        timeout = GetTimer(1000); // initialization timeout 1000 ms
        if (MMC_Command(CMD8, 0x1AA) == 0x01) // check if the card can operate with 2.7-3.6V power
        {   // SDHC card
            for (n = 0; n < 4; n++)
                ocr[n] = SPI(0xFF); // get the rest of R7 response
            if (ocr[2] == 0x01 && ocr[3] == 0xAA)
            { // the card can work at 2.7-3.6V
                printf("SDHC card detected\r");
                while (!CheckTimer(timeout))
                { // now we must wait until CMD41 returns 0 (or timeout elapses)
                    if (MMC_Command(CMD55, 0) == 0x01)
                    { // CMD55 must precede any ACMD command
                        if (MMC_Command(CMD41, 1 << 30) == 0x00) // ACMD41 with HCS bit
                        { // initialization completed
                            if (MMC_Command(CMD58, 0) == 0x00)
                            { // check CCS (Card Capacity Status) bit in the OCR
                                for (n = 0; n < 4; n++)
                                    ocr[n] = SPI(0xFF);

                                CardType = (ocr[0] & 0x40) ? CARDTYPE_SDHC : CARDTYPE_SD; // if CCS set then the card is SDHC compatible
                            }
                            else
                                printf("CMD58 (READ_OCR) failed!\r");

                            DisableCard();

                            // set appropriate SPI speed
//                            if (GetSPIMode() == SPIMODE_FAST)
//                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (2 << 8); // 24 MHz SPI clock (max 25 MHz for SDHC card)
								SPI_fast();
//                            else
//                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (6 << 8); // 8 MHz SPI clock (no SPI mod)
//								SPI_slow();
                            return(CardType);
                        }
                    }
                    else
                    {
                        printf("CMD55 (APP_CMD) failed!\r");
                        DisableCard();
                        return(CARDTYPE_NONE);
                    }
                }
                printf("SDHC card initialization timed out!\r");
                DisableCard();
                return(CARDTYPE_NONE);
            }
        }

        // it's not an SDHC card
        if (MMC_Command(CMD55, 0) == 0x01)
        { // CMD55 accepted so it's an SD card (or Kingston 128 MB MMC)
            if (MMC_Command(CMD41, 0) <= 0x01)
            { // SD card detected - wait for the end of initialization
                printf("SD card detected\r");
                while (!CheckTimer(timeout))
                { // now we must wait until CMD41 returns 0 (or timeout elapses)
                    if (MMC_Command(CMD55, 0) == 0x01)
                    { // CMD55 must precede any ACMD command
                        if (MMC_Command(CMD41, 0) == 0x00)
                        { // initialization completed

                            if (MMC_Command(CMD16, 512) != 0x00) //set block length
                                printf("CMD16 (SET_BLOCKLEN) failed!\r");

                            DisableCard();

                            // set appropriate SPI speed
//                            if (GetSPIMode() == SPIMODE_FAST)
//                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (2 << 8); // 24 MHz SPI clock (max 25 MHz for SD card)
								SPI_fast();
//                            else
//                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (6 << 8); // 8 MHz SPI clock (no SPI mod)
//								SPI_slow();
                            CardType = CARDTYPE_SD;

                            return(CardType);
                        }
                    }
                    else
                    {
                        printf("CMD55 (APP_CMD) failed!\r");
                        DisableCard();
                        return(CARDTYPE_NONE);
                    }
                }
                printf("SD card initialization timed out!\r");
                DisableCard();
                return(CARDTYPE_NONE);
            }
        }

        // it's not an SD card
        printf("MMC card detected\r");
        while (!CheckTimer(timeout))
        { // now we must wait until CMD1 returns 0 (or timeout elapses)
            if (MMC_Command(CMD1, 0) == 0x00)
            { // initialization completed

                if (MMC_Command(CMD16, 512) != 0x00) // set block length
                    printf("CMD16 (SET_BLOCKLEN) failed!\r");

                DisableCard();

                // set appropriate SPI speed
//                if (GetSPIMode() == SPIMODE_FAST)
//                    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (3 << 8); // 16 MHz SPI clock (max 20 MHz for MMC card)
					SPI_fast();
//                else
//                    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (6 << 8); // 8 MHz SPI clock (no SPI mod)
//					SPI_slow();

                CardType = CARDTYPE_MMC;

                return(CardType);
            }
        }

        printf("MMC card initialization timed out!\r");
        DisableCard();
        return(CARDTYPE_NONE);
    }

    DisableCard();
    printf("No memory card detected!\r");
    return(CARDTYPE_NONE); 
}

// Read single 512-byte block
#pragma section_code_init
unsigned char MMC_Read(unsigned long lba, unsigned char *pReadBuffer)
{
// if pReadBuffer is NULL then use direct to the FPGA transfer mode (FPGA2 asserted)

    unsigned long i;
//    unsigned long t;
	unsigned char *p;

    if (CardType != CARDTYPE_SDHC) // SDHC cards are addressed in sectors not bytes
        lba = lba << 9; // otherwise convert sector adddress to byte address

    EnableCard();

    if (MMC_Command(CMD17, lba))
    {
        printf("CMD17 (READ_BLOCK): invalid response 0x%02X (lba=%lu)\r", response, lba);
        DisableCard();
        return(0);
    }

    // now we are waiting for data token, it takes around 300us
    timeout = 0;
    while ((SPI(0xFF)) != 0xFE)
    {
        if (timeout++ >= 1000000) // we can't wait forever
        {
            printf("CMD17 (READ_BLOCK): no data token! (lba=%lu)\r", lba);
            DisableCard();
            return(0);
        }
    }

    if (pReadBuffer == 0)
    {   // in this mode we do not receive data, instead the FPGA captures directly the data stream transmitted by the SD/MMC card
		EnableDMode();
		SPI(0xFF); // dummy write for 4096 clocks
		i = RDSPI; // wait until SPI ready
		DisableDMode();
    }
    else
    {
		p=pReadBuffer;
		for (i = 0; i < 128; i++)
		{ 
			*(p++) = SPI(0xFF);
			*(p++) = SPI(0xFF);
			*(p++) = SPI(0xFF);
			*(p++) = SPI(0xFF);
		}
    }

    SPI(0xFF); // read CRC lo byte
    SPI(0xFF); // read CRC hi byte

    DisableCard();
    return(1);
}
#pragma section_no_code_init

// Read CSD register
unsigned char MMC_GetCSD()
{
	int i;
    EnableCard();

    if (MMC_Command(CMD9,0))
    {
        printf("CMD9 (GET_CSD): invalid response 0x%02X \r", response);
        DisableCard();
        return(0);
    }

    // now we are waiting for data token, it takes around 300us
    timeout = 0;
    while ((SPI(0xFF)) != 0xFE)
    {
        if (timeout++ >= 1000000) // we can't wait forever
        {
            printf("CMD9 (READ_BLOCK): no data token!\r");
            DisableCard();
            return(0);
        }
    }

	for (i = 0; i < 16; i++)
		CSDData[i]=SPI(0xFF);

    SPI(0xFF); // read CRC lo byte
    SPI(0xFF); // read CRC hi byte

    DisableCard();
    return(1);
}


unsigned long MMC_GetCapacity()
{
	unsigned long result=0;
	MMC_GetCSD();
//	switch(CardType)
//	{
//		case CARDTYPE_SDHC:
//			result=(CSDData[7]&0x3f)<<26;
//			result|=CSDData[8]<<18;
//			result|=CSDData[9]<<10;
//			result+=1024;
//			return(result);
//			break;
//		default:
//			int blocksize=CSDData[5]&15;	// READ_BL_LEN
//			blocksize=1<<(blocksize-9);		// Now a scalar:  physical block size / 512.
//			result=(CSDData[6]&3)<<10;
//			result|=CSDData[7]<<2;
// 			result|=(CSDData[8]>>6)&3;		// result now contains C_SIZE
//			int cmult=(CSDData[9]&3)<<1;
//			cmult|=(CSDData[10]>>7) & 1;
//			++result;
//			result<<=cmult+2;
//			return(result);
//			break;
//	}
    if ((CSDData[0] & 0xC0)==0x40)   //CSD Version 2.0 - SDHC
    {
			result=(CSDData[7]&0x3f)<<26;
			result|=CSDData[8]<<18;
			result|=CSDData[9]<<10;
			result+=1024;
			return(result);
	}
	else
	{    
			int blocksize=CSDData[5]&15;	// READ_BL_LEN
			blocksize=1<<(blocksize-9);		// Now a scalar:  physical block size / 512.
			result=(CSDData[6]&3)<<10;
			result|=CSDData[7]<<2;
 			result|=(CSDData[8]>>6)&3;		// result now contains C_SIZE
			int cmult=(CSDData[9]&3)<<1;
			cmult|=(CSDData[10]>>7) & 1;
			++result;
			result<<=cmult+2;
			return(result);
    }
}


// read multiple 512-byte blocks
unsigned char MMC_ReadMultiple(unsigned long lba, unsigned char *pReadBuffer, unsigned long nBlockCount)
{
// if pReadBuffer is NULL then use direct to the FPGA transfer mode (FPGA2 asserted)

    unsigned long i;
//    unsigned long t;
	unsigned char *p;
//                printf("CMD18 (READ_MULTIPLE_BLOCK)");
    if (CardType != CARDTYPE_SDHC) // SDHC cards are addressed in sectors not bytes
        lba = lba << 9; // otherwise convert sector adddress to byte address
    EnableCard();

    if (MMC_Command(CMD18, lba))
    {
        printf("CMD18 (READ_MULTIPLE_BLOCK): invalid response 0x%02X (lba=%lu)\r", response, lba);
        DisableCard();
        return(0);
    }

    while (nBlockCount--)
    {
        // now we are waiting for data token, it takes around 300us
        timeout = 0;
        while ((SPI(0xFF)) != 0xFE)
        {
            if (timeout++ >= 1000000) // we can't wait forever
            {
                printf("CMD18 (READ_MULTIPLE_BLOCK): no data token! (lba=%lu)\r", lba);
                DisableCard();
                return(0);
            }
        }

        if (pReadBuffer == 0)
        {   // in this mode we do not receive data, instead the FPGA captures directly the data stream transmitted by the SD/MMC card
			EnableDMode();
			SPI(0xFF); // dummy write for 4096 clocks
			i = RDSPI; // wait until SPI ready
			DisableDMode();
        }
        else
        {
			p=pReadBuffer;
			for (i = 0; i < 128; i++)
			{ 
				*(p++) = SPI(0xFF);
				*(p++) = SPI(0xFF);
				*(p++) = SPI(0xFF);
				*(p++) = SPI(0xFF);
			}

            pReadBuffer += 512; // point to next sector
        }

        SPI(0xFF); // read CRC lo byte
        SPI(0xFF); // read CRC hi byte
    }

    MMC_CMD12(); // stop multi block transmission

    DisableCard();
    return(1);
}

// write 512-byte block
unsigned char MMC_Write(unsigned long lba, unsigned char *pWriteBuffer)
{
    unsigned long i;

   if (CardType != CARDTYPE_SDHC) // SDHC cards are addressed in sectors not bytes
        lba = lba << 9; // otherwise convert sector adddress to byte address

    EnableCard();

    if (MMC_Command(CMD24, lba))
    {
        printf("CMD24 (WRITE_BLOCK): invalid response 0x%02X (lba=%lu)\r", response, lba);
        DisableCard();
        return(0);
    }

    SPI(0xFF); // one byte gap
    SPI(0xFE); // send Data Token

    // send sector bytes
    for (i = 0; i < 512; i++)
         SPI(*(pWriteBuffer++));

    SPI(0xFF); // send CRC lo byte
    SPI(0xFF); // send CRC hi byte

    response = SPI(0xFF); // read packet response
    // Status codes
    // 010 = Data accepted
    // 101 = Data rejected due to CRC error
    // 110 = Data rejected due to write error
    response &= 0x1F;
    if (response != 0x05)
    {
        printf("CMD24 (WRITE_BLOCK): invalid status 0x%02X (lba=%lu)\r", response, lba);
        DisableCard();
        return(0);
    }

    timeout = 0;
    while ((SPI(0xFF)) == 0x00) // wait until the card is not busy
    {
        if (timeout++ >= 1000000)
        {
            printf("CMD24 (WRITE_BLOCK): busy wait timeout! (lba=%lu)\r", lba);
            DisableCard();
            return(0);
        }
    }

    DisableCard();
    return(1);
}

#pragma section_code_init
unsigned char MMC_Command(unsigned char cmd, unsigned long arg)
{
    unsigned char c;

    crc = 0;
    SPI(0xFF); // flush SPI-bus

    SPI(cmd);
    MMC_CRC(cmd);

    c = (unsigned char)(arg >> 24);
    SPI(c);
    MMC_CRC(c);

    c = (unsigned char)(arg >> 16);
    SPI(c);
    MMC_CRC(c);

    c = (unsigned char)(arg >> 8);
    SPI(c);
    MMC_CRC(c);

    c = (unsigned char)(arg);
    SPI(c);
    MMC_CRC(c);

    crc <<= 1;
    crc++;
    SPI(crc);

    unsigned char Ncr = 100;  // Ncr = 0..8 (SD) / 1..8 (MMC)
    do
        response = SPI(0xFF); // get response
    while (response == 0xFF && Ncr--);

    return response;
}
#pragma section_no_code_init

// stop multi block data transmission
unsigned char MMC_CMD12(void)
{
    SPI(CMD12); // command
    SPI(0x00);
    SPI(0x00);
    SPI(0x00);
    SPI(0x00);
    SPI(0x00); // dummy CRC7
    SPI(0xFF); // skip stuff byte

    unsigned char Ncr = 100;  // Ncr = 0..8 (SD) / 1..8 (MMC)
    do
    {    response = SPI(0xFF); // get response
//        RS232(response);
   } while (response == 0xFF && Ncr--);

    timeout = 0;
    while ((SPI(0xFF)) == 0x00) // wait until the card is not busy
    {   // RS232('+');
        if (timeout++ >= 1000000)
        {
            printf("CMD12 (STOP_TRANSMISSION): busy wait timeout!\r");
            DisableCard();
            return(0);
        }
}
    return response;
}
#pragma section_code_init
void MMC_CRC(unsigned char c)
{
    unsigned char i;

    for (i = 0; i < 8; i++)
    {
        crc <<= 1;
        if (c & 0x80)
            crc ^= 0x09;
        if (crc & 0x80)
            crc ^= 0x09;
        c <<= 1;
    }
}
#pragma section_no_code_init




















