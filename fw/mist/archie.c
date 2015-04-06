#include "stdio.h"
#include "string.h"
#include "hardware.h"

#include "menu.h"
#include "archie.h"
#include "debug.h"

#define CONFIG_FILENAME  "ARCHIE  CFG"

typedef struct {
  unsigned long system_ctrl;  // system control word
  char rom_img[12];           // rom image file name
} archie_config_t;

static archie_config_t config;

fileTYPE floppy;

#define ARCHIE_FILE_TX         0x53
#define ARCHIE_FILE_TX_DAT     0x54
#define ARCHIE_FDC_GET_STATUS  0x55
#define ARCHIE_FDC_TX_DATA     0x56

#define archie_debugf(a, ...) iprintf("\033[1;31mARCHIE: " a "\033[0m\n", ##__VA_ARGS__)
// #define archie_debugf(a, ...)
#define archie_x_debugf(a, ...) iprintf("\033[1;32mARCHIE: " a "\033[0m\n", ##__VA_ARGS__)

enum state { STATE_HRST, STATE_RAK1, STATE_RAK2, STATE_IDLE, 
	     STATE_WAIT4ACK1, STATE_WAIT4ACK2, STATE_HOLD_OFF } kbd_state;

#define HRST    0xff
#define RAK1    0xfe
#define RAK2    0xfd
#define RQPD    0x40         // mask 0xf0
#define PDAT    0xe0         // mask 0xf0
#define RQID    0x20
#define KBID    0x80         // mask 0xc0
#define KDDA    0xc0         // new key down data, mask 0xf0
#define KUDA    0xd0         // new key up data, mask 0xf0
#define RQMP    0x22         // request mouse data
#define MDAT    0x00         // mouse data, mask 0x80
#define BACK    0x3f
#define NACK    0x30         // disable kbd scan, disable mouse
#define SACK    0x31         // enable kbd scan, disable mouse
#define MACK    0x32         // disable kbd scan, enable mouse
#define SMAK    0x33         // enable kbd scan, enable mouse
#define LEDS    0x00         // mask 0xf8
#define PRST    0x21         // nop

#define QUEUE_LEN 8
static unsigned char tx_queue[QUEUE_LEN][2];
static unsigned char tx_queue_rptr, tx_queue_wptr;
#define QUEUE_NEXT(a)  ((a+1)&(QUEUE_LEN-1))

static unsigned long ack_timeout;
static short mouse_x, mouse_y; 

#define FLAG_SCAN_ENABLED  0x01
#define FLAG_MOUSE_ENABLED 0x02
static unsigned char flags;

// #define HOLD_OFF_TIME 2
#ifdef HOLD_OFF_TIME
static unsigned long hold_off_timer;
#endif

static void nice_name(char *dest, char *src) {
  char *c;

  // copy and append nul
  strncpy(dest, src, 8);
  for(c=dest+7;*c==' ';c--); c++;
  *c++ = '.';
  strncpy(c, src+8, 3);
  for(c+=2;*c==' ';c--); c++;
  *c++='\0';
}

static char buffer[17];  // local buffer to assemble file name (8+.+3+\0)

char *archie_get_rom_name(void) {
  nice_name(buffer, config.rom_img);
  return buffer;
}

void archie_save_config(void) {
  fileTYPE file;

  // save configuration data
  if (FileOpen(&file, CONFIG_FILENAME))  {
    archie_debugf("Existing conf file size: %lu", file.size);
    if(file.size != sizeof(archie_config_t)) {
      file.size = sizeof(archie_config_t);
      if (!UpdateEntry(&file))
	return;
    }
  } else {
    archie_debugf("Creating new config");
    strncpy(file.name, CONFIG_FILENAME, 11);
    file.attributes = 0;
    file.size = sizeof(archie_config_t);
    if(!FileCreate(0, &file)) {
      archie_debugf("File creation failed.");
      return;
    }
  }

  // finally write the config
  memcpy(sector_buffer, &config, sizeof(archie_config_t));
  FileWrite(&file, sector_buffer);
}

void archie_send_file(unsigned char id, fileTYPE *file) {
  archie_debugf("Sending file with id %d", id);

  // prepare transmission of new file
  EnableFpga();
  SPI(ARCHIE_FILE_TX);
  SPI(id);
  DisableFpga();

  unsigned long time = GetTimer(0);

  iprintf("[");

  unsigned short i, blocks = file->size/512;
  for(i=0;i<blocks;i++) {
    if(!(i & 127)) iprintf("*");

    FileRead(file, sector_buffer);

    EnableFpga();
    SPI(ARCHIE_FILE_TX_DAT);
    spi_block_write(sector_buffer);
    DisableFpga();
    
    // still bytes to send? read next sector
    if(i != blocks-1)
      FileNextSector(file);
  }

  iprintf("]\n");

  time = GetTimer(0) - time;
  archie_debugf("Uploaded in %lu ms", time >> 20);

  // signal end of transmission
  EnableFpga();
  SPI(ARCHIE_FILE_TX);
  SPI(0x00);
  DisableFpga();
}

void archie_set_rom(fileTYPE *file) {
  if(!file) return;

  archie_debugf("Selected file %.11s with %lu bytes to send", 
		file->name, file->size);

  // save file name
  memcpy(config.rom_img, file->name, 11);

  archie_send_file(0x01, file);
}

static void archie_kbd_enqueue(unsigned char state, unsigned char byte) {
  if(QUEUE_NEXT(tx_queue_wptr) == tx_queue_rptr) {
    archie_debugf("KBD tx queue overflow");
    return;
  }

  archie_debugf("KBD ENQUEUE %x (%x)", byte, state);
  tx_queue[tx_queue_wptr][0] = state;
  tx_queue[tx_queue_wptr][1] = byte;
  tx_queue_wptr = QUEUE_NEXT(tx_queue_wptr);
} 

static void archie_kbd_tx(unsigned char state, unsigned char byte) {
  archie_debugf("KBD TX %x (%x)", byte, state);
  spi_uio_cmd_cont(0x05);
  spi8(byte);
  DisableIO();

  kbd_state = state;
  ack_timeout = GetTimer(10);  // 10ms timeout
}

static void archie_kbd_send(unsigned char state, unsigned char byte) {
  // don't send if we are waiting for an ack
  if((kbd_state != STATE_WAIT4ACK1)&&(kbd_state != STATE_WAIT4ACK2)) 
    archie_kbd_tx(state, byte);
  else
    archie_kbd_enqueue(state, byte);
}

static void archie_kbd_reset(void) {
  archie_debugf("KBD reset");
  tx_queue_rptr = tx_queue_wptr = 0;
  kbd_state = STATE_HRST;
  mouse_x = mouse_y = 0;
  flags = 0;
}

void archie_init(void) {
  fileTYPE file;
  archie_debugf("init");

  // set config defaults
  config.system_ctrl = 0;
  strcpy(config.rom_img, "RISCOS  ROM");

  // try to load config from card
  if(FileOpen(&file, CONFIG_FILENAME)) {
    if(file.size == sizeof(archie_config_t)) {
      FileRead(&file, sector_buffer);
      memcpy(&config, sector_buffer, sizeof(archie_config_t));
    } else
      archie_debugf("Unexpected config size %d != %d", 
		    file.size, sizeof(archie_config_t));
  } else
    archie_debugf("No %.11s config found", CONFIG_FILENAME);

  // upload rom file
  if(FileOpen(&file, config.rom_img))
    archie_set_rom(&file);
  else 
    archie_debugf("ROM %.11s no found", config.rom_img);

  // upload ext file
  if(FileOpen(&file, "RISCOS  EXT")) {
    archie_debugf("Found RISCOS.EXT, uploading it");
    archie_send_file(0x02, &file);
  } else 
    archie_debugf("RISCOS.EXT no found");

  if (FileOpen(&floppy, "FLOPPY0 ADF"))  {
    archie_debugf("Inserted floppy0 with %d bytes", floppy.size);
  }

  archie_kbd_send(STATE_RAK1, HRST);
  ack_timeout = GetTimer(20);  // give archie 20ms to reply
}

void archie_kbd(unsigned short code) {
  archie_debugf("KBD key code %x", code);

  // don't send anything yet if we are still in reset state
  if(kbd_state <= STATE_RAK2) {
    archie_debugf("KBD still in reset");
    return;
  }

  // ignore any key event if key scanning is disabled
  if(!(flags & FLAG_SCAN_ENABLED)) {
    archie_debugf("KBD keyboard scan is disabled!");
    return;
  }

  // select prefix for up or down event
  unsigned char prefix = (code&0x8000)?KUDA:KDDA;

  archie_kbd_send(STATE_WAIT4ACK1, prefix | (code>>4)); 
  archie_kbd_send(STATE_WAIT4ACK2, prefix | (code&0x0f));
}

void archie_mouse(unsigned char b, char x, char y) {
  archie_debugf("KBD MOUSE X:%d Y:%d B:%d", x, y, b);

  // max values -64 .. 63
  mouse_x += x;
  if(mouse_x >  63) mouse_x =  63;
  if(mouse_x < -64) mouse_x = -64;

  mouse_y -= y;
  if(mouse_y >  63) mouse_y =  63;
  if(mouse_y < -64) mouse_y = -64;

  // don't send anything yet if we are still in reset state
  if(kbd_state <= STATE_RAK2) {
    archie_debugf("KBD still in reset");
    return;
  }

  // ignore any mouse movement if mouse is disabled or if nothing to report
  if((flags & FLAG_MOUSE_ENABLED) && (mouse_x || mouse_y)) {
    // send asap if no pending byte
    if(kbd_state == STATE_IDLE) {
      archie_kbd_send(STATE_WAIT4ACK1, mouse_x & 0x7f); 
      archie_kbd_send(STATE_WAIT4ACK2, mouse_y & 0x7f);
      mouse_x = mouse_y = 0;
    }
  }

  // ignore mouse buttons if key scanning is disabled
  if(flags & FLAG_SCAN_ENABLED) {
    static unsigned char buts = 0;
    
    // state of button 1 has changed
    if((b&1) != (buts&1)) {
      unsigned char prefix = (b&1)?KDDA:KUDA;
      archie_kbd_send(STATE_WAIT4ACK1, prefix | 0x07); 
      archie_kbd_send(STATE_WAIT4ACK2, prefix | 0x00);
    }

    // state of button 2 has changed
    if((b&2) != (buts&2)) {
      unsigned char prefix = (b&2)?KDDA:KUDA;
      archie_kbd_send(STATE_WAIT4ACK1, prefix | 0x07); 
      archie_kbd_send(STATE_WAIT4ACK2, prefix | 0x01);
    }

    buts = b;
  }
}

static void archie_check_queue(void) {
  if(tx_queue_rptr == tx_queue_wptr)
    return;

  archie_kbd_tx(tx_queue[tx_queue_rptr][0], tx_queue[tx_queue_rptr][1]); 
  tx_queue_rptr = QUEUE_NEXT(tx_queue_rptr);
}

void archie_handle_kbd(void) {

#ifdef HOLD_OFF_TIME
  if((kbd_state == STATE_HOLD_OFF) && CheckTimer(hold_off_timer)) {
    archie_debugf("KBD resume after hold off");
    kbd_state = STATE_IDLE;
    archie_check_queue();
  }
#endif

  // timeout waiting for ack?
  if((kbd_state == STATE_WAIT4ACK1) || (kbd_state == STATE_WAIT4ACK2)) {
    if(CheckTimer(ack_timeout)) {
      if(kbd_state == STATE_WAIT4ACK1)
	archie_debugf(">>>> KBD ACK TIMEOUT 1ST BYTE <<<<");
      if(kbd_state == STATE_WAIT4ACK2)
	archie_debugf(">>>> KBD ACK TIMEOUT 2ND BYTE <<<<");

      kbd_state = STATE_IDLE;
    }
  }

  // timeout in reset sequence?
  if(kbd_state <= STATE_RAK2) {
    if(CheckTimer(ack_timeout)) {
      archie_debugf("KBD timeout in reset state");
      
      archie_kbd_send(STATE_RAK1, HRST);
      ack_timeout = GetTimer(20);  // 20ms timeout
    }
  }

  spi_uio_cmd_cont(0x04);
  if(spi_in() == 0xa1) {
    unsigned char data = spi_in();
    DisableIO();
    
    archie_debugf("KBD RX %x", data);

    switch(data) {
      // arm requests reset
    case HRST:
      archie_kbd_reset();
      archie_kbd_send(STATE_RAK1, HRST);
      ack_timeout = GetTimer(20);  // 20ms timeout
      break;

      // arm sends reset ack 1
    case RAK1:
      if(kbd_state == STATE_RAK1) {
	archie_kbd_send(STATE_RAK2, RAK1);
	ack_timeout = GetTimer(20);  // 20ms timeout
      } else 
	kbd_state = STATE_HRST;
      break;

      // arm sends reset ack 2
    case RAK2:
      if(kbd_state == STATE_RAK2) { 
	archie_kbd_send(STATE_IDLE, RAK2);
	ack_timeout = GetTimer(20);  // 20ms timeout
      } else 
	kbd_state = STATE_HRST;
      break;

      // arm request keyboard id
    case RQID:
      archie_kbd_send(STATE_IDLE, KBID | 1);
      break;

      // arm acks first byte
    case BACK:
      if(kbd_state != STATE_WAIT4ACK1) 
	archie_debugf("KBD unexpected BACK");

#ifdef HOLD_OFF_TIME
      // wait some time before sending next byte
      archie_debugf("KBD starting hold off");
      kbd_state = STATE_HOLD_OFF;
      hold_off_timer = GetTimer(10);
#else
      kbd_state = STATE_IDLE;
      archie_check_queue();
#endif
      break;

      // arm acks second byte
    case NACK:
    case SACK:
    case MACK:
    case SMAK:

      if(((data == SACK) || (data == SMAK)) && !(flags & FLAG_SCAN_ENABLED)) {
	archie_debugf("KBD Enabling key scanning");
	flags |= FLAG_SCAN_ENABLED;
      }

      if(((data == NACK) || (data == MACK)) && (flags & FLAG_SCAN_ENABLED)) {
	archie_debugf("KBD Disabling key scanning");
	flags &= ~FLAG_SCAN_ENABLED;
      }

      if(((data == MACK) || (data == SMAK)) && !(flags & FLAG_MOUSE_ENABLED)) {
	archie_debugf("KBD Enabling mouse");
	flags |= FLAG_MOUSE_ENABLED;
      }

      if(((data == NACK) || (data == SACK)) && (flags & FLAG_MOUSE_ENABLED)) {
	archie_debugf("KBD Disabling mouse");
	flags &= ~FLAG_MOUSE_ENABLED;
      }
      
      // wait another 10ms before sending next byte
#ifdef HOLD_OFF_TIME
      archie_debugf("KBD starting hold off");
      kbd_state = STATE_HOLD_OFF;
      hold_off_timer = GetTimer(10);
#else
      kbd_state = STATE_IDLE;
      archie_check_queue();
#endif
      break;
    }
  } else
    DisableIO();
}

static unsigned char fdc_buffer[1024];

void archie_handle_fdc(void) {
  static unsigned char old_status[4] = {0,0,0,0};
  unsigned char status[4];

  // read status
  EnableFpga();
  SPI(ARCHIE_FDC_GET_STATUS);
  status[0] = SPI(0);
  status[1] = SPI(0);
  status[2] = SPI(0);
  status[3] = SPI(0);
  DisableFpga();

  if(memcmp(status, old_status, 4) != 0) {
    archie_x_debugf("status changed to %x %x %x %x", 
		  status[0], status[1], status[2], status[3]);
    memcpy(old_status, status, 4);

    // top four bits must be magic marker 1010
    if(((status[0] & 0xf0) == 0xa0) && (status[0] & 1)) {
      archie_x_debugf("DIO: BUSY with commmand %lx", status[1]);
	  
      // check for read sector command
      if((status[1] & 0xe0) == 0x80) {	
	if(status[0] & 2) {
	  int floppy_map = status[3] >> 4;
	  int side = (status[2]&0x80)?0:1;
	  int track = status[2] & 0x7f;
	  int sector = status[3] & 0x0f;
	  unsigned long lba = 2 * (10*track + 5*side + sector);

	  // floppy 0 is expected to be used
	  if(floppy_map != 0x0e) 
	    archie_x_debugf("DIO: unexpected floppy %x", floppy_map); 
	  else {
	    archie_x_debugf("DIO: sector read SD%d T%d S%d -> %ld", 
			    side, track, sector, lba);

	    // read two consecutive sectors 
	    FileSeek(&floppy, lba, SEEK_SET);
	    FileRead(&floppy, fdc_buffer);
	    FileNextSector(&floppy);
	    FileRead(&floppy, fdc_buffer+512);
	    
	    EnableFpga();
	    SPI(ARCHIE_FDC_TX_DATA);
	    spi_write(fdc_buffer, 1024);
	    DisableFpga();

	    hexdump(fdc_buffer, 1024, 0);
	  }
	}
      }
    }
  }
}

void archie_poll(void) {
  archie_handle_kbd();
  archie_handle_fdc();
}
