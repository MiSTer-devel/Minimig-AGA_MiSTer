////////////////////////////////////////////////////////////////////////////////
// serial.c                                                                   //
// Serial communication functions                                             //
//                                                                            //
// Copyright 2014-     Rok Krajnc                                             //
//                                                                            //
// This file is part of Minimig                                               //
//                                                                            //
// Minimig is free software; you can redistribute it and/or modify            //
// it under the terms of the GNU General Public License as published by       //
// the Free Software Foundation; either version 2 of the License, or          //
// (at your option) any later version.                                        //
//                                                                            //
// Minimig is distributed in the hope that it will be useful,                 //
// but WITHOUT ANY WARRANTY; without even the implied warranty of             //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              //
// GNU General Public License for more details.                               //
//                                                                            //
// You should have received a copy of the GNU General Public License          //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// Changelog                                                                  //
//                                                                            //
// 2014-06-24 - rok.krajnc@gmail.com                                          //
// Initial version                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


#include "stdio.h"
#include "string.h"
#include "serial.h"
#include "hardware.h"
#include "boot.h"
#include "osd.h"


//// defines ////
#define TXBUFLEN 8
#define RXBUFLEN 64
#define STBUFLEN 64

//#define TXP_INC()     {if (++txp >= TXBUFLEN) txp = 0;}
//#define RXP_INC()     {if (++rxp >= RXBUFLEN) rxp = 0;}
#define RX_READY()    (read32(REG_UART_STAT_ADR)&0x1)
#define TX_READY()    (read32(REG_UART_STAT_ADR)&0x8)
#define RX_CHAR()     (read32(REG_UART_RX_ADR))
#define TX_CHAR(c)    (write32(REG_UART_TX_ADR, c))

#define MON_PROMPT "\rmon> "
#define MON_EOL 13
#define MON_ESC 27
#define MON_BS  8
#define MON_BLANK ' '

#define ANSI_ERASE_DISPLAY "\x1b[2J"
#define ANSI_GOTO_00       "\x1b[H"


//// global variables ////
static char txbuf[TXBUFLEN];
static char rxbuf[RXBUFLEN];
static char stbuf[STBUFLEN];
static unsigned char txwp = 0, rxwp = 0;
static unsigned char txrp = 0, rxrp = 0;
static unsigned char txln = 0, rxln = 0;
static int mon_en = 0;
static int mon_step = 0;

//// functions ////

// parses decimal number
char *scand(char *s, int *f)
{
  int sign = 0;
  int d = 0;
  if (*s == '-') {
    sign = 1;
    s++;
  }
  while (*s >= '0' && *s <= '9') {
    d = d * 10 + *s - '0';
    s++;
  }
  *f = sign ? -d : d;
  return s;
}

// parses hex number
char *scanh(char *s, unsigned *f)
{
  int d = 0;
  while ((*s >= '0' && *s <= '9') || (*s >= 'A' && *s <= 'F') || (*s >= 'a' && *s <= 'f')) {
    int t;
    if (*s >= 'a')
      t = *s - 'a' + 10;
    else if (*s >= 'A')
      t = *s - 'A' + 10;
    else
      t = *s - '0';

    d = d * 16 + t;
    s++;
  }
  *f = d;
  return s;
}

// parses decimal or hex number
 char *scani(char *s, int *f)
{
  if (*s == '0' && *(s+1) == 'x') {
    s += 2;
    return scanh(s, (unsigned *)f);
  }
  return scand(s, f);
}

// next_word()
char *next_word(const char *c)
{
  while ((*c!=0) && (*c!=' ')) c++;
  while (*c==' ') c++;
  if (*c==0) return NULL;
  else return c;
}

// txbuf_emit()
static int txbuf_emit(const int wait)
{
  int ret = 0;
  if ((txln > 0) && (TX_READY() || wait)) {
    TX_CHAR(txbuf[txrp]);
    if (++txrp >= TXBUFLEN) txrp = 0;
    txln--;
  } else ret = -1;
  //SPIN(); // just some delay
  return ret;
}

// txbuf_put()
static int txbuf_put(const char c)
{
  int ret = 0;
  if (txln < TXBUFLEN) {
    txbuf[txwp] = c;
    if (++txwp >= TXBUFLEN) txwp = 0;
    txln++;
  } else ret = -1;
  txbuf_emit(1); // TODO debug why NOT sending the char immediately doesn't work properly!
  return ret;
}

// txbuf_puts()
static int txbuf_puts(const char* const s)
{
  const char* p = s;
  int ret = 0;
  while (*p != '\0') {
    ret = txbuf_put(*(p++));
  }
  return ret;
}

// mon_illcmd()
static void mon_illcmd()
{
  rxwp = 0;
  txbuf_puts("Unknown command. Enter 'h' for help.\r");
  txbuf_puts(MON_PROMPT);
}

// mon_usage()
//static void mon_usage()
//{
//  rxwp = 0;
//  // usage msg
//  txbuf_puts("\r");
//  txbuf_puts("\x1b[1mMINIMIG-DE1 Monitor\x1b[0m\r\n");
//  txbuf_puts("2014, rok.krajnc@gmail.com\r\n\r\n");
//  txbuf_puts("Commands:\r\n");
//  txbuf_puts("- \x1b[1mu \x1b[0m FILE LEN - upload file to SD card\r");
//  txbuf_puts("- \x1b[1mcw\x1b[0m ADR VAL  - write 32bit VAL to ADR in ctrl space \r");
//  txbuf_puts("- \x1b[1mcr\x1b[0m ADR      - read 32bit ADR in ctrl space\r");
//  txbuf_puts("- \x1b[1maw\x1b[0m ADR VAL  - write 16bit VAL to ADR in Amiga space \r");
//  txbuf_puts("- \x1b[1mar\x1b[0m ADR      - read 16bit ADR in Amiga space\r");
//  txbuf_puts("- \x1b[1me \x1b[0m          - exit\r");
//  txbuf_puts("- \x1b[1mr \x1b[0m          - reboot\r");
//  txbuf_puts("- \x1b[1mh \x1b[0m          - this help message");
//  txbuf_puts(MON_PROMPT);
//}
static void mon_usage()
{
  rxwp = 0;
  // usage msg
  txbuf_puts("\r");
  txbuf_puts("MINIMIG-DE1 Monitor\r");
  txbuf_puts("2014, rok.krajnc@gmail.com\r\r");
  txbuf_puts("Commands:\r");
  txbuf_puts("- u  FILE LEN - upload file to SD card\r");
  txbuf_puts("- cw ADR VAL  - write 32bit VAL to ADR in ctrl space \r");
  txbuf_puts("- cr ADR      - read 32bit ADR in ctrl space\r");
  txbuf_puts("- aw ADR VAL  - write 16bit VAL to ADR in Amiga space \r");
  txbuf_puts("- ar ADR      - read 16bit ADR in Amiga space\r");
  txbuf_puts("- e           - exit\r");
  txbuf_puts("- r           - reboot\r");
  txbuf_puts("- h           - this help message\r");
  txbuf_puts(MON_PROMPT);
}

// mon_parsecmd()
static int mon_parsecmd()
{
  char rx;
  int ret = 0;

  if(RX_READY()) {
    rx = RX_CHAR();
    switch (rx) {
      case MON_EOL:
        txbuf_put(rx);
        //txbuf_put('\n');
        if (rxwp) {
          while (rxbuf[rxwp-1]==MON_BLANK) rxwp--;
          rxbuf[rxwp++] = '\0';
          ret = 1;
        }
        else txbuf_puts(MON_PROMPT);
        break;
      case MON_BS:
        if (rxwp > 0) {
          txbuf_put(rx);
          txbuf_put(' ');
          txbuf_put(rx);
          rxwp--;
        }
        break;
      case MON_ESC:
        rxwp = 0;
        txbuf_puts(MON_PROMPT);
        break;
      default:
        if (rxwp < RXBUFLEN) {
          txbuf_put(rx);
          rxbuf[rxwp++] = rx;
        }
    }
  }
  return ret;
}

// mon_decodecmd()
static void mon_decodecmd()
{
  char* s;
  int adr;
  int len;
  int val;
  char fname[32];

  switch (rxbuf[0]) {
    case 'h':
      // help
      if (rxbuf[1]==0 || rxbuf[1]=='\n' || rxbuf[1]=='\r') {
        mon_usage();
      } else mon_illcmd();
      break;
    case 'r':
      // reboot
      if (rxbuf[1]==0 || rxbuf[1]=='\n' || rxbuf[1]=='\r') {
        RST_system();
      } else mon_illcmd();
      break;
    case 'e':
      // exit mon
      if (rxbuf[1]==0 || rxbuf[1]=='\n' || rxbuf[1]=='\r') {
        rxwp = rxrp = txwp = txrp = txln = 0;
        mon_step = 0;
        mon_en = 0;
      } else mon_illcmd();
      break;
    case 'c':
      // ctrl read/write
      if (rxbuf[1] == 'w') {
        // write
        if ((s = next_word(rxbuf)) == NULL) { mon_illcmd(); break;}
        scani(s, &adr);
        adr = adr&0xfffffffc;
        if ( (s = next_word(s)) == NULL ) { mon_illcmd(); break;}
        scani(s, &val);
        write32(adr, val);
        rxwp = 0;
      } else if (rxbuf[1] == 'r') {
        // read
        if ((s = next_word(rxbuf)) == NULL) { mon_illcmd(); break;}
        scani(s, &adr);
        adr = adr&0xfffffffc;
        val = read32(adr);
        sprintf(stbuf, "0x%8x = 0x%8x (b%32b)\r\n", adr, val, val);
        txbuf_puts(stbuf);
        rxwp = 0;
      } else mon_illcmd();
      break;
    case 'a':
      // amiga read/write
      if (rxbuf[1] == 'w') {
        // write
        if ((s = next_word(rxbuf)) == NULL) { mon_illcmd(); break;}
        scani(s, &adr);
        adr = adr&0xfffffffc;
        if ( (s = next_word(s)) == NULL ) { mon_illcmd(); break;}
        scani(s, &val);
        EnableOsd();
        rstval = rstval | SPI_CPU_HLT;
        SPI(rstval);
        DisableOsd();
        MEM_UPLOAD_INIT(adr);
        MEM_WRITE16(val);
        MEM_UPLOAD_FINI();
        EnableOsd();
        rstval = rstval & ~SPI_CPU_HLT;
        SPI(rstval);
        DisableOsd();
        rxwp = 0;
      } else if (rxbuf[1] == 'r') {
        // read
        printf("Amiga mem read currently unimplemented.\r");
        rxwp = 0;
      } else mon_illcmd();
      break;
    case 'u':
      // file upload
      if ((s = next_word(rxbuf)) == NULL) { mon_illcmd(); break;}
      //scani(s, fname);
      printf("File upload currently unimplemented.\r");
      rxwp = 0;
      break;
  }
}

// HandleSerial()
void HandleSerial()
{
  int cmd=0;
  char rx;

  txbuf_emit(1);

  // wait for monitor enabled, in that case parse commands
  if (mon_en) {
    cmd = mon_parsecmd();
    if (cmd) mon_decodecmd();
  } else {
    if (RX_READY()) {
      rx = RX_CHAR();
      switch (mon_step) {
        case 0 :
          if (rx == 'm') mon_step++;
          else mon_step = 0;
          break;
        case 1 :
          if (rx == 'o') mon_step++;
          else mon_step = 0;
          break;
        case 2 :
          if (rx == 'n') mon_step++;
          else mon_step = 0;
          break;
        case 3 :
          if ((rx == '\r') || (rx == '\n')) mon_step++;
          else mon_step = 0;
          break;
        case 4 :
          if ((rx == '\r') || (rx == '\n')) {
            mon_en = 1;
            rxwp = rxrp = 0;
            rxbuf[rxwp] = '\0';
            txwp = txrp = 0;
            txbuf[txwp] = '\0';
            //txbuf_puts(ANSI_ERASE_DISPLAY);
            //txbuf_puts(ANSI_GOTO_00);
            txbuf_put('\r');
            txbuf_puts(MON_PROMPT);
            mon_step++;
          } else mon_step = 0;
          break;
      }
      txbuf_emit(1);
    }
  }
}
 
