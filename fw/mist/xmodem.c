// stty -F /dev/ttyUSB0 speed 115200 raw -echo
// interceptty -o log -l /dev/ttyUSB0

// cat /dev/pts/5
// timeout 5s cat /dev/pts/5; echo 'xtest.img' > /dev/pts/5 ; sx ymodem.h < /dev/pts/5 > /dev/pts/5

//
//
//
//

#include <stdio.h>
#include <string.h>
#include "debug.h"
#include "xmodem.h"
#include "hardware.h"
#include "fat.h"
#include "user_io.h"

typedef enum { IDLE, X_NAME, EXP_SOH1, EXP_SOH, BLKNO, DATA, CHK, U_NAME } state_t;

extern unsigned char sector_buffer[1024];

static state_t state = IDLE;

static unsigned char block;
static unsigned char chk;
static unsigned int count;
static unsigned long timer;

static char filename[11];  // a 8+3 filename
static unsigned long filelen;

static fileTYPE file;
static unsigned char *sector_ptr;
static unsigned short sector_count;

#define SOH 0x01
#define EOT 0x04
#define ACK 0x06
#define NAK 0x15
#define CAN 0x18

// this function is frequently called in debug mode (dip1 on)
void xmodem_poll(void) {
  // USART_Write(unsigned char c)

  if(state == EXP_SOH1) {
    if(CheckTimer(timer)) {

      // send NAK max ten seconds
      if(++count == 10) {
	iprintf("XMODEM start expired\n");
	state = IDLE;
      } else {
	USART_Write(NAK);
	timer = GetTimer(1000);
      }
    }
  } else if(state != IDLE) {
    if(CheckTimer(timer)) {
      iprintf("XMODEM timeout\n");
      state = IDLE;
    }
  }
}

void xmodem_rx_byte(unsigned char byte) {
  switch(state) {

    // idle state
  case IDLE:
    // character x starts xmodem transfer
    if((byte == 'x') || (byte == 'X') ||     // _X_modem
       (byte == 'u') || (byte == 'U')) {     // _U_pload
      timer = GetTimer(2000);

      filename[0] = 0;   // no valid filename yet
      filelen = 0;

      // now expect either x+return or a filename 
      state = ((byte == 'x') || (byte == 'X'))?X_NAME:U_NAME;
      count = 0;
    }
    break;

  case X_NAME:
  case U_NAME:
    if((byte == '\r')||(byte == '\n')) {
      // return starts x/xmodem
      if(state == X_NAME) {
	// start xmodem only if filename and file length were given
	if(filename[0] && filelen) {
	  if(!FileNew(&file, filename, filelen)) {
	    iprintf("XMODEM: file creation failed\n");
	    state = IDLE;
	  } else {
	    // start asking for file
	    timer = GetTimer(1);
	    count = 0;
	    state = EXP_SOH1;
	    block = 1;    // first data block is 1
	    sector_ptr = sector_buffer;
	    sector_count = 0;
	  }
	} else {
	  iprintf("XMODEM: No file name and/or file lenght given\n");
	  state = IDLE;
	}
      } else {
	if(user_io_core_type() != CORE_TYPE_8BIT) 
	  iprintf("UPLOAD: Only suppotred by 8 bit cores\n");
	else {
	  char *p = user_io_8bit_get_string(0);
	  if(!filename[0] || !p || strncmp(p, filename+8, 3) != 0)
	    iprintf("UPLOAD: Core reports file type '%s', but given was '%.3s'\n", p, filename+8);
	  else {
	    if(!FileOpen(&file, filename))
	      iprintf("UPLOAD: File open failed\n");
	    else 
	      user_io_file_tx(&file);
	  }
	}
	state = IDLE;
      }
    } else {
      timer = GetTimer(2000);

      // max 8+3 filename allowed
      if(count < 11) {
	// convert to upper case
	if((byte >= 'a') && (byte <= 'z'))
	  byte = byte - 'a' + 'A';

	// only A-Z/0-9 and _ accpepted
	if(((byte >= 'A')&&(byte <= 'Z')) ||
	   ((byte >= '0')&&(byte <= '9')) ||
	   (byte == '_')) {
	  filename[count++] = byte; 
	}

	// jump to extension if '.' was seen
	if((byte == '.') && (count < 8))
	  while(count < 8)
	    filename[count++] = ' '; 

	// ignore spaces before filename and end file
	// name parsing else
	if((byte == ' ') && (count > 0)) {
	  // fill 8+3 filename to 11 chars
	  if(filename[0]) 
	    while(count < 11)
	      filename[count++] = ' ';
	}
      } else {
	// parsing file length
	if((byte >= '0')&&(byte <= '9'))
	  filelen = (filelen * 10) + (byte - '0');
      }
    }
    break;
    
    // waiting for start of header SOH
  case EXP_SOH1:  // send NAK's while waiting for block 1
  case EXP_SOH:   // don't send NAK's while waiting for other blocks
    if(byte == SOH) {
      timer = GetTimer(1000);   // 1 sec timeout

      state = BLKNO;    // expect block no
      count = 0;
    } else if(byte == EOT) {
      USART_Write(ACK);
      state = IDLE;

      // partially filled sector in buffer?
      if(sector_count) 
	if(!FileWrite(&file, sector_buffer))
	  iprintf("XMODEM: write failed\n");
      
      // close file
      // end writing file, so cluster chain may be trimmed
      if(!FileWriteEnd(&file))
	iprintf("XMODEM: End chain failed\n");
    }
    break;
   
    // waiting for block no
  case BLKNO:
    // first byte = block no
    if((count == 0) && (block == byte)) {
      timer = GetTimer(1000);   // 1 sec timeout
      count = 1;
    }

    // second byte = inverted block no
    else if((count == 1) && (block == 0xff^byte)) {
      timer = GetTimer(1000);   // 1 sec timeout
      count = 0;
      state = DATA;

      chk = 0;
    }

    else {
      USART_Write(NAK);
      state = EXP_SOH;
      count = 0;
    }
    break;

    // rx data
  case DATA:
    timer = GetTimer(1000);

    *sector_ptr++ = byte;
    chk += byte;

    if(++count == 128)
      state = CHK;

    if(filelen && (++sector_count == 512)) {
      if(!FileWrite(&file, sector_buffer))
	iprintf("XMODEM: write failed\n");

      // still more than 512 bytes expected?
      if(filelen > 512) {
	filelen -= 512;

	if(!FileNextSectorExpand(&file))
          iprintf("XMODEM: File next sector failed\n");
      } else {
	filelen = 0;
      }

      sector_count = 0;
      sector_ptr = sector_buffer;
    }
    break;

    // rx chk
  case CHK:
    timer = GetTimer(1000);
    if(chk == byte) {
      USART_Write(ACK);
      block++;
    } else
      USART_Write(NAK);

    state = EXP_SOH;
    count = 0;
    break;

  default:
    break;
  }
}
