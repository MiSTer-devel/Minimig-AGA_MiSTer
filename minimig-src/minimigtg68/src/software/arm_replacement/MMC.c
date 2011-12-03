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
// 2008-10-03      - adaptation for ARM controller
// 2009-07-23      - clean-up and some optimizations

//#include "stdio.h"
//#include "string.h" 
#include "hardware.h"
#include "MMC.h"
#include "FAT.h"

// MMC commandset
#define     CMD0        0x40        /*Resets the multimedia card*/
#define     CMD1        0x41        /*Activates the card's initialization process*/
#define     CMD2        0x42        /*--*/
#define     CMD3        0x43        /*--*/
#define     CMD4        0x44        /*--*/
#define     CMD5        0x45        /*reseved*/
#define     CMD6        0x46        /*reserved*/
#define     CMD7        0x47        /*--*/
#define     CMD8        0x48        /*reserved*/
#define     CMD9        0x49        /*CSD : Ask the selected card to send its card specific data*/
#define     CMD10       0x4a        /*CID : Ask the selected card to send its card identification*/
#define     CMD11       0x4b        /*--*/
#define     CMD12       0x4c        /*--*/
#define     CMD13       0x4d        /*Ask the selected card to send its status register*/
#define     CMD14       0x4e        /*--*/
#define     CMD15       0x4f        /*--*/
#define     CMD16       0x50        /*Select a block length (in bytes) for all following block commands (Read:between 1-512 and Write:only 512)*/
#define     CMD17       0x51        /*Reads a block of the size selected by the SET_BLOCKLEN command, the start address and block length must be set so that the data transferred will not cross a physical block boundry*/
#define     CMD18       0x52        /*--*/
#define     CMD19       0x53        /*reserved*/
#define     CMD20       0x54        /*--*/
#define     CMD21       0x55        /*reserved*/
#define     CMD22       0x56        /*reserved*/
#define     CMD23       0x57        /*reserved*/
#define     CMD24       0x58        /*Writes a block of the size selected by CMD16, the start address must be alligned on a sector boundry, the block length is always 512 bytes*/
#define     CMD25       0x59        /*--*/
#define     CMD26       0x5a        /*--*/
#define     CMD27       0x5b        /*Programming of the programmable bits of the CSD*/
#define     CMD28       0x5c        /*If the card has write protection features, this command sets the write protection bit of the addressed group. The porperties of the write protection are coded in the card specific data (WP_GRP_SIZE)*/
#define     CMD29       0x5d        /*If the card has write protection features, this command clears the write protection bit of the addressed group*/
#define     CMD30       0x5e        /*If the card has write protection features, this command asks the card to send the status of the write protection bits. 32 write protection bits (representing 32 write protect groups starting at the specific address) followed by 16 CRD bits are transferred in a payload format via the data line*/
#define     CMD31       0x5f        /*reserved*/
#define     CMD32       0x60        /*sets the address of the first sector of the erase group*/
#define     CMD33       0x61        /*Sets the address of the last sector in a cont. range within the selected erase group, or the address of a single sector to be selected for erase*/
#define     CMD34       0x62        /*Removes on previously selected sector from the erase selection*/
#define     CMD35       0x63        /*Sets the address of the first erase group within a range to be selected for erase*/
#define     CMD36       0x64        /*Sets the address of the last erase group within a continuos range to be selected for erase*/
#define     CMD37       0x65        /*Removes one previously selected erase group from the erase selection*/
#define     CMD38       0x66        /*Erases all previously selected sectors*/
#define     CMD39       0x67        /*--*/
#define     CMD40       0x68        /*--*/
#define     CMD41       0x69        /*reserved*/
#define     CMD42       0x6a        /*reserved*/
#define     CMD43       0x6b        /*reserved*/
#define     CMD44       0x6c        /*reserved*/
#define     CMD45       0x6d        /*reserved*/
#define     CMD46       0x6e        /*reserved*/
#define     CMD47       0x6f        /*reserved*/
#define     CMD48       0x70        /*reserved*/
#define     CMD49       0x71        /*reserved*/
#define     CMD50       0x72        /*reserved*/
#define     CMD51       0x73        /*reserved*/
#define     CMD52       0x74        /*reserved*/
#define     CMD53       0x75        /*reserved*/
#define     CMD54       0x76        /*reserved*/
#define     CMD55       0x77        /*reserved*/
#define     CMD56       0x78        /*reserved*/
#define     CMD57       0x79        /*reserved*/
#define     CMD58       0x7a        /*reserved*/
#define     CMD59       0x7b        /*Turns the CRC option ON or OFF. A '1' in the CRC option bit will turn the option ON, a '0' will turn it OFF*/
#define     CMD60       0x7c        /*--*/
#define     CMD61       0x7d        /*--*/
#define     CMD62       0x7e        /*--*/
#define     CMD63       0x7f        /*--*/

// external references
extern unsigned char DIRECT_TRANSFER_MODE;

// variables
unsigned char crc;
unsigned long timeout;
unsigned char response;
unsigned char CardType;

// internal functions
void MMC_CRC(unsigned char c);
unsigned char MMC_Command(unsigned char cmd, unsigned long arg);

// init memory card
unsigned char MMC_Init(void)
{
    unsigned char n;
//    unsigned char ocr[4];

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
        printf("timeout:%08X  ",timeout);
        timeout = GetTimer(1000); // initialization timeout 1000 ms
        printf("timeout:%08X  ",timeout);
//        if (MMC_Command(CMD8, 0x1AA) == 0x01) // check if the card can operate with 2.7-3.6V power
//        {   // SDHC card
//            for (n = 0; n < 4; n++)
//                ocr[n] = SPI(0xFF); // get the rest of R7 response
//            if (ocr[2] == 0x01 && ocr[3] == 0xAA)
//            { // the card can work at 2.7-3.6V
//                printf("SDHC card detected\r");
//                while (!CheckTimer(timeout))
//                { // now we must wait until CMD41 returns 0 (or timeout elapses)
//                    if (MMC_Command(CMD55, 0) == 0x01)
//                    { // CMD55 must precede any ACMD command
//                        if (MMC_Command(CMD41, 1 << 30) == 0x00) // ACMD41 with HCS bit
//                        { // initialization completed
//                            if (MMC_Command(CMD58, 0) == 0x00)
//                            { // check CCS (Card Capacity Status) bit in the OCR
//                                for (n = 0; n < 4; n++)
//                                    ocr[n] = SPI(0xFF);
//
//                                CardType = (ocr[0] & 0x40) ? CARDTYPE_SDHC : CARDTYPE_SD; // if CCS set then the card is SDHC compatible
//                            }
//                            else
//                                printf("CMD58 (READ_OCR) failed!\r");
//
//                            DisableCard();
//
////                            // set appropriate SPI speed
////                            if (GetSPIMode() == SPIMODE_FAST)
////                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (2 << 8); // 24 MHz SPI clock (max 25 MHz for SDHC card)
//				SPI_fast();
////                            else
////                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (6 << 8); // 8 MHz SPI clock (no SPI mod)
//
//                            return(CardType);
//                        }
//                    }
//                    else
//                    {
//                        printf("CMD55 (APP_CMD) failed!\r");
//                        DisableCard();
//                        return(CARDTYPE_NONE);
//                    }
//                }
//                printf("SDHC card initialization timed out!\r");
//                DisableCard();
//                return(CARDTYPE_NONE);
//            }
//        }

        // it's not an SDHC card
        if (MMC_Command(CMD55, 0) == 0x01)
        { // CMD55 accepted so it's an SD card (or Kingston 128 MB MMC)
            if (MMC_Command(CMD41, 0) <= 0x01)
            { // SD card detected - wait for the end of initialization
                printf("SD card detected\r");
				printf("timeout:%08X  ",GetTimer(0));
                while (!CheckTimer(timeout))
                { // now we must wait until CMD41 returns 0 (or timeout elapses)
                printf("*");
                    if (MMC_Command(CMD55, 0) == 0x01)
                    { // CMD55 must precede any ACMD command
                        if (MMC_Command(CMD41, 0) == 0x00)
                        { // initialization completed

                            if (MMC_Command(CMD16, 512) != 0x00) //set block length
                                printf("CMD16 (SET_BLOCKLEN) failed!\r");

                            DisableCard();

//                            // set appropriate SPI speed
//                            if (GetSPIMode() == SPIMODE_FAST)
								SPI_fast();
//                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (2 << 8); // 24 MHz SPI clock (max 25 MHz for SD card)
//                            else
//                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (6 << 8); // 8 MHz SPI clock (no SPI mod)

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

//                // set appropriate SPI speed
//                if (GetSPIMode() == SPIMODE_FAST)
//                    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (3 << 8); // 16 MHz SPI clock (max 20 MHz for MMC card)
//                else
//                    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (6 << 8); // 8 MHz SPI clock (no SPI mod)

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
unsigned long MMC_Read(unsigned long lba, unsigned char *pReadBuffer)
{
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
    if (DIRECT_TRANSFER_MODE)
    {   // in this mode we do not receive data, instead the FPGA captures directly the data stream transmitted by the SD/MMC card
		EnableDMode();
//		for (i = 0; i < 128; i++)
//		{ 
//			SPI(0xFF);
//			SPI(0xFF);
//			SPI(0xFF);
//			SPI(0xFF);
//		}
		SPI(0xFF); // dummy write for 4104 clocks
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

// write 512-byte block
unsigned long MMC_Write(unsigned long lba, unsigned char *pWriteBuffer)
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




















