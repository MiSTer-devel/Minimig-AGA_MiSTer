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


#include "hardware.h"
#include "mmc.h"
#include "fat.h"


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
  DEBUG_FUNC_IN();

    unsigned char n;
    unsigned char ocr[4];

    SPI_slow();     // set slow clock
    DisableCard();  // CS = 1
    //SPI(0xff);      // DI = 1
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
        //timeout = GetTimer(4000); // initialization timeout 4s
        //printf("timeout:%08X\r",timeout);
        timeout = GetTimer(4000); // initialization timeout 4s
        //printf("timeout:%08X\r",timeout);
        if (MMC_Command(CMD8, 0x1AA) == 0x01) // check if the card can operate with 2.7-3.6V power
        {   // SDHC card
            for (n = 0; n < 4; n++)
                ocr[n] = SPI(0xFF); // get the rest of R7 response
            if (ocr[2] == 0x01 && ocr[3] == 0xAA)
            { // the card can work at 2.7-3.6V
                //printf("SDHC card detected\r");
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
                            //printf("CMD58 (READ_OCR) failed!\r");
                            //DisableCard();

                            // set appropriate SPI speed
                            SPI_fast();
                            return(CardType);
                        }
                    }
                    else
                    {
                        //printf("CMD55 (APP_CMD) failed!\r");
                        //DisableCard();
                        return(CARDTYPE_NONE);
                    }
                }
                //printf("SDHC card initialization timed out!\r");
                //DisableCard();
                return(CARDTYPE_NONE);
            }
        }

        // it's not an SDHC card
        if (MMC_Command(CMD55, 0) == 0x01)
        { // CMD55 accepted so it's an SD card (or Kingston 128 MB MMC)
            if (MMC_Command(CMD41, 0) <= 0x01)
            { // SD card detected - wait for the end of initialization
                //printf("SD card detected\r");
                //printf("timeout:%08X\r",GetTimer(0));
                while (!CheckTimer(timeout))
                { // now we must wait until CMD41 returns 0 (or timeout elapses)
                    if (MMC_Command(CMD55, 0) == 0x01)
                    { // CMD55 must precede any ACMD command
                        if (MMC_Command(CMD41, 0) == 0x00)
                        { // initialization completed

                            if (MMC_Command(CMD16, 512) != 0x00) //set block length
                                //printf("CMD16 (SET_BLOCKLEN) failed!\r");
                            //DisableCard();

                            // set appropriate SPI speed
                            SPI_fast();
                            return(CardType);
                        }
                    }
                    else
                    {
                        //printf("CMD55 (APP_CMD) failed!\r");
                        //DisableCard();
                        return(CARDTYPE_NONE);
                    }
                }
                //printf("SD card initialization timed out!\r");
                //DisableCard();
                return(CARDTYPE_NONE);
            }
        }

//        // it's not an SD card
//        //printf("MMC card detected\r");
//        while (!CheckTimer(timeout))
//        { // now we must wait until CMD1 returns 0 (or timeout elapses)
//            if (MMC_Command(CMD1, 0) == 0x00)
//            { // initialization completed
//
//                if (MMC_Command(CMD16, 512) != 0x00) // set block length
//                    //printf("CMD16 (SET_BLOCKLEN) failed!\r");
//
//                //DisableCard();
//
//                // set appropriate SPI speed
//                SPI_fast(); // TODO this is too fast for MMC (20MHz max)
//                CardType = CARDTYPE_MMC;
//
//                return(CardType);
//            }
//        }

        //printf("MMC card initialization timed out!\r");
        //DisableCard();
        return(CARDTYPE_NONE);
    }

    //DisableCard();
    //printf("No memory card detected!\r");
    return(CARDTYPE_NONE);

  DEBUG_FUNC_OUT();
}


// Read single 512-byte block
unsigned char MMC_Read(unsigned long lba, unsigned char *pReadBuffer)
{
  DEBUG_FUNC_IN();

  unsigned long i;

  if (CardType != CARDTYPE_SDHC) { // SDHC cards are addressed in sectors not bytes
    lba = lba << 9; // otherwise convert sector adddress to byte address
  }

  //EnableCard();

  if (MMC_Command(CMD17, lba)) {
    //printf("CMD17 (READ_BLOCK): invalid response 0x%02X (lba=%lu)\r", response, lba);
    //DisableCard();
    return(0);
  }

  // now we are waiting for data token, it takes around 300us
  timeout = 0;
  while ((SPI(0xFF)) != 0xFE) {
    if (timeout++ >= 1000000) { // we can't wait forever
      //printf("CMD17 (READ_BLOCK): no data token! (lba=%lu)\r", lba);
      //DisableCard();
      return(0);
    }
  }

  for (i = 0; i < 128; i++) {
    *(pReadBuffer++) = SPI(0xFF);
    *(pReadBuffer++) = SPI(0xFF);
    *(pReadBuffer++) = SPI(0xFF);
    *(pReadBuffer++) = SPI(0xFF);
  }

  SPI(0xFF); // read CRC lo byte
  SPI(0xFF); // read CRC hi byte

  //DisableCard();
  return(1);

  DEBUG_FUNC_OUT();
}


// MMC command
unsigned char MMC_Command(unsigned char cmd, unsigned long arg)
{
  DEBUG_FUNC_IN();

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
  do {
    response = SPI(0xFF); // get response
  } while (response == 0xFF && Ncr--);

  return response;

  DEBUG_FUNC_OUT();
}


// MMC CRC calc
void MMC_CRC(unsigned char c)
{
  DEBUG_FUNC_IN();

  unsigned char i;

  for (i = 0; i < 8; i++) {
    crc <<= 1;
    if (c & 0x80)   crc ^= 0x09;
    if (crc & 0x80) crc ^= 0x09;
    c <<= 1;
  }

  DEBUG_FUNC_OUT();
}

