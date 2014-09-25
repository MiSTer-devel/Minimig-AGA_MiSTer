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

//1GB:
//CSD:
//0000: 00 7f 00 32 5b 59 83 bc f6 db ff 9f 96 40 00 93   ...2[Y.��.�.@.�
//CID:
//0000: 3e 00 00 34 38 32 44 00 00 73 2f 6f 93 00 c7 cd   >..482D..s/o�...


#include "stdio.h"
#include "string.h"
#include "hardware.h"

#include "mmc.h"
#include "fat.h"

// variables
static unsigned char crc;
static unsigned long timeout;
static unsigned char response;
static unsigned char CardType;

// internal functions
static void MMC_CRC(unsigned char c) RAMFUNC;
static unsigned char MMC_Command(unsigned char cmd, unsigned long arg) RAMFUNC;
static unsigned char MMC_CMD12(void);

unsigned char MMC_CheckCard() {
  // check for removal of card
  if((CardType != CARDTYPE_NONE) && !mmc_inserted()) {
    CardType = CARDTYPE_NONE;
    return 0;
  }
  return 1;
}

static RAMFUNC char check_card() {
  // check of card has been removed and try to re-initialize it
  if(CardType == CARDTYPE_NONE) {
    iprintf("Card was removed, try to init it\n");
    
    if(!mmc_inserted())
      return 0;
    
    if(!MMC_Init())
      return 0;
  }
  return 1;
}

// init memory card
unsigned char MMC_Init(void)
{
    unsigned char n;
    unsigned char ocr[4];

    if(!mmc_inserted()) {
      iprintf("No card inserted\r");
      return(CARDTYPE_NONE);
    }

    SPI_slow();     // set slow clock
    DisableCard();  // CS = 1
    SPI(0xff);      // DI = 1
    TIMER_wait(20);  // 20ms delay
    for (n=0; n<10; n++) SPI(0xff); // 80 dummy clocks, DI = 1
    TIMER_wait(20);  // 20ms delay
    EnableCard();

    CardType = CARDTYPE_NONE;

    for(n=0; n<16; n++) {
      TIMER_wait(1);
      if (MMC_Command(CMD0, 0) == 0x01) break; // try to send CMD0 multiple times
    }
    if (n<16) // got CMD0 IDLE response
    { // idle state
        timeout = GetTimer(1000); // initialization timeout 1s, 4s doesn't work with the original arm timer
        if (MMC_Command(CMD8, 0x1AA) == 0x01) // check if the card can operate with 2.7-3.6V power
        {   // SDHC card
            for (n = 0; n < 4; n++)
                ocr[n] = SPI(0xFF); // get the rest of R7 response
            if (ocr[2] == 0x01 && ocr[3] == 0xAA)
            { // the card can work at 2.7-3.6V
                iprintf("SDHC card detected\r");
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
                                iprintf("CMD58 (READ_OCR) failed!\r");
                            DisableCard();

                            // set appropriate SPI speed
                            SPI_fast();

                            return(CardType);
                        }
                    }
                    else
                    {
                        iprintf("CMD55 (APP_CMD) failed!\r");
                        DisableCard();
                        return(CARDTYPE_NONE);
                    }
                }
                iprintf("SDHC card initialization timed out!\r");
                DisableCard();
                return(CARDTYPE_NONE);
            }
        }

        // it's not an SDHC card
        if (MMC_Command(CMD55, 0) == 0x01)
        { // CMD55 accepted so it's an SD card (or Kingston 128 MB MMC)
            if (MMC_Command(CMD41, 0) <= 0x01)
            { // SD card detected - wait for the end of initialization
                iprintf("SD card detected\r");
                while (!CheckTimer(timeout))
                { // now we must wait until CMD41 returns 0 (or timeout elapses)
                    if (MMC_Command(CMD55, 0) == 0x01)
                    { // CMD55 must precede any ACMD command
                        if (MMC_Command(CMD41, 0) == 0x00)
                        { // initialization completed

                            if (MMC_Command(CMD16, 512) != 0x00) //set block length
                                iprintf("CMD16 (SET_BLOCKLEN) failed!\r");
                            DisableCard();

                            // set appropriate SPI speed
#ifdef ARM_FW
                            if (GetSPIMode() == SPIMODE_FAST)
                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (2 << 8); // 24 MHz SPI clock (max 25 MHz for SD card)
                            else
                                AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (6 << 8); // 8 MHz SPI clock (no SPI mod)
                            CardType = CARDTYPE_SD;
#else
                            SPI_fast();
                            CardType = CARDTYPE_SD;
#endif
                            return(CardType);
                        }
                    }
                    else
                    {
                        iprintf("CMD55 (APP_CMD) failed!\r");
                        DisableCard();
                        return(CARDTYPE_NONE);
                    }
                }
                iprintf("SD card initialization timed out!\r");
                DisableCard();
                return(CARDTYPE_NONE);
            }
        }

        // it's not an SD card
        iprintf("MMC card detected\r");
        while (!CheckTimer(timeout))
        { // now we must wait until CMD1 returns 0 (or timeout elapses)
            if (MMC_Command(CMD1, 0) == 0x00)
            { // initialization completed

                if (MMC_Command(CMD16, 512) != 0x00) // set block length
                    iprintf("CMD16 (SET_BLOCKLEN) failed!\r");

                DisableCard();

                // set appropriate SPI speed
#ifdef ARM_FW
                if (GetSPIMode() == SPIMODE_FAST)
                    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (3 << 8); // 16 MHz SPI clock (max 20 MHz for MMC card)
                else
                    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (6 << 8); // 8 MHz SPI clock (no SPI mod)
#else
                SPI_fast_mmc();
#endif
                CardType = CARDTYPE_MMC;

                return(CardType);
            }
        }

        iprintf("MMC card initialization timed out!\r");
        DisableCard();
        return(CARDTYPE_NONE);
    }

    DisableCard();
    iprintf("No memory card detected!\r");
    return(CARDTYPE_NONE); 
}


// Read single 512-byte block
RAMFUNC unsigned char MMC_Read(unsigned long lba, unsigned char *pReadBuffer)
{
    // if pReadBuffer is NULL then use direct to the FPGA transfer mode (FPGA2 asserted)

    // check of card has been removed and try to re-initialize it
    if(!check_card()) return 0;

    unsigned long i;
    unsigned char *p;

    if (CardType != CARDTYPE_SDHC) // SDHC cards are addressed in sectors not bytes
        lba = lba << 9; // otherwise convert sector adddress to byte address

    EnableCard();

    if (MMC_Command(CMD17, lba))
    {
      //        iprintf("CMD17 (READ_BLOCK): invalid response 0x%02X (lba=%lu)\r", response, lba);
        DisableCard();
        return(0);
    }

    // now we are waiting for data token, it takes around 300us
    timeout = 0;
    while ((SPI(0xFF)) != 0xFE)
    {
        if (timeout++ >= 1000000) // we can't wait forever
        {
	  //            iprintf("CMD17 (READ_BLOCK): no data token! (lba=%lu)\r", lba);
            DisableCard();
            return(0);
        }
    }

    if (pReadBuffer == 0)
    {   // in this mode we do not receive data, instead the FPGA captures directly the data stream transmitted by the SD/MMC card
        EnableDMode();
        SPI_block(511);
        SPI(0xff); // dummy write for 4096 clocks
        SPI(0xff);
        DisableDMode();
    }
    else
    {
#ifdef SPI_BLOCK_READ
                SPI_block_read(pReadBuffer);
#else
		p=pReadBuffer;
		for (i = 0; i < 128; i++)
		{ 
			*(p++) = SPI(0xFF);
			*(p++) = SPI(0xFF);
			*(p++) = SPI(0xFF);
			*(p++) = SPI(0xFF);
		}
#endif
    }

    SPI(0xFF); // read CRC lo byte
    SPI(0xFF); // read CRC hi byte

    DisableCard();
    return(1);
}

static unsigned char MMC_GetCXD(unsigned char cmd, unsigned char *ptr) {
  int i;
  EnableCard();
  
  if (MMC_Command(cmd,0)) {
    iprintf("CMD%d (GET_C%cD): invalid response 0x%02X \r", 
	    (cmd==CMD9)?9:10, (cmd==CMD9)?'S':'I', response);
    DisableCard();
    return(0);
  }
  
  // now we are waiting for data token, it takes around 300us
  timeout = 0;
  while ((SPI(0xFF)) != 0xFE) {
    if (timeout++ >= 1000000) { // we can't wait forever
      iprintf("CMD%d (GET_C%cD): no data token!\r", 
	      (cmd==CMD9)?9:10, (cmd==CMD9)?'S':'I');
      DisableCard();
      return(0);
    }
  }
  
  for (i = 0; i < 16; i++)
    ptr[i]=SPI(0xFF);
  
  DisableCard();
  
  return(1);
}

// Read CSD register
unsigned char MMC_GetCSD(unsigned char *csd) {
  return MMC_GetCXD(CMD9, csd);
}

// Read CID register
unsigned char MMC_GetCID(unsigned char *cid) {
  return MMC_GetCXD(CMD10, cid);
}

// MMC get capacity
unsigned long MMC_GetCapacity()
{
	unsigned long result=0;
	unsigned char CSDData[16];
 
	MMC_GetCSD(CSDData);

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

    // check of card has been removed and try to re-initialize it
    if(!check_card()) return 0;

    unsigned long i;
    unsigned char *p;

    if (CardType != CARDTYPE_SDHC) // SDHC cards are addressed in sectors not bytes
        lba = lba << 9; // otherwise convert sector adddress to byte address
    EnableCard();

    if (MMC_Command(CMD18, lba))
    {
        iprintf("CMD18 (READ_MULTIPLE_BLOCK): invalid response 0x%02X (lba=%u)\r", response, lba);
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
                iprintf("CMD18 (READ_MULTIPLE_BLOCK): no data token! (lba=%u)\r", lba);
                DisableCard();
                return(0);
            }
        }

        if (pReadBuffer == 0)
        {   // in this mode we do not receive data, instead the FPGA captures directly the data stream transmitted by the SD/MMC card
            EnableDMode();
            SPI_block(511);
            SPI(0xff); // dummy write for 4096 clocks
            SPI(0xff);
            DisableDMode();
        }
        else
        {
#ifdef SPI_BLOCK_READ
                        SPI_block_read(pReadBuffer);
#else
			p=pReadBuffer;
			for (i = 0; i < 128; i++)
			{ 
				*(p++) = SPI(0xFF);
				*(p++) = SPI(0xFF);
				*(p++) = SPI(0xFF);
				*(p++) = SPI(0xFF);
			}
#endif

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

    // check of card has been removed and try to re-initialize it
    if(!check_card()) return 0;

   if (CardType != CARDTYPE_SDHC) // SDHC cards are addressed in sectors not bytes
        lba = lba << 9; // otherwise convert sector adddress to byte address

    EnableCard();

    if (MMC_Command(CMD24, lba))
    {
        iprintf("CMD24 (WRITE_BLOCK): invalid response 0x%02X (lba=%lu)\r", response, lba);
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
        iprintf("CMD24 (WRITE_BLOCK): invalid status 0x%02X (lba=%lu)\r", response, lba);
        DisableCard();
        return(0);
    }

    timeout = 0;
    while ((SPI(0xFF)) == 0x00) // wait until the card is not busy
    {
        if (timeout++ >= 1000000)
        {
            iprintf("CMD24 (WRITE_BLOCK): busy wait timeout! (lba=%lu)\r", lba);
            DisableCard();
            return(0);
        }
    }

    DisableCard();
    return(1);
}


// MMC command
static RAMFUNC unsigned char MMC_Command(unsigned char cmd, unsigned long arg)
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


// stop multi block data transmission
static unsigned char MMC_CMD12(void)
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
            iprintf("CMD12 (STOP_TRANSMISSION): busy wait timeout!\r");
            DisableCard();
            return(0);
        }
}
    return response;
}


// MMC CRC calc
static RAMFUNC void MMC_CRC(unsigned char c)
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

unsigned char MMC_IsSDHC(void) {
  return(CardType == CARDTYPE_SDHC);
}
