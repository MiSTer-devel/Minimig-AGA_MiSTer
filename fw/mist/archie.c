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

#define ARCHIE_FILE_TX     0x53
#define ARCHIE_FILE_TX_DAT 0x54

#define archie_debugf(a, ...) iprintf("\033[1;31mARCHIE: " a "\033[0m\n", ##__VA_ARGS__)

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

void archie_set_rom(fileTYPE *file) {
  if(!file) return;

  archie_debugf("Selected file %.11s with %lu bytes to send", 
		file->name, file->size);

  // save file name
  memcpy(config.rom_img, file->name, 11);

  // prepare transmission of new file
  EnableFpga();
  SPI(ARCHIE_FILE_TX);
  SPI(0xff);
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

static void archie_kbd_enqueue(unsigned char state, unsigned char byte) {
  if(QUEUE_NEXT(tx_queue_wptr) == tx_queue_rptr) {
    archie_debugf("tx queue overflow");
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
  archie_debugf("reset kbd");
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
      archie_debugf("Unexpected config size %d != %d", file.size, sizeof(archie_config_t));
  } else
    archie_debugf("No %.11s config found", CONFIG_FILENAME);

  // upload rom file
  if(FileOpen(&file, config.rom_img))
    archie_set_rom(&file);
  else 
    archie_debugf("ROM %.11s no found", config.rom_img);

  archie_kbd_send(STATE_RAK1, HRST);
}

void archie_kbd(unsigned short code) {
  archie_debugf("key code %x", code);

  // ignore any key event if key scanning is disabled
  if(!(flags & FLAG_SCAN_ENABLED)) {
    archie_debugf("keyboard scan is disabled!");
    return;
  }

  // select prefix for up or down event
  unsigned char prefix = (code&0x8000)?KUDA:KDDA;

  archie_kbd_send(STATE_WAIT4ACK1, prefix | (code>>4)); 
  archie_kbd_send(STATE_WAIT4ACK2, prefix | (code&0x0f));
}

void archie_mouse(unsigned char b, char x, char y) {
  archie_debugf("MOUSE X:%d Y:%d B:%d", x, y, b);

  // max values -64 .. 63
  mouse_x += x;
  if(mouse_x >  63) mouse_x =  63;
  if(mouse_x < -64) mouse_x = -64;

  mouse_y -= y;
  if(mouse_y >  63) mouse_y =  63;
  if(mouse_y < -64) mouse_y = -64;

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

void archie_poll(void) {

#ifdef HOLD_OFF_TIME
  if((kbd_state == STATE_HOLD_OFF) && CheckTimer(hold_off_timer)) {
    archie_debugf("resume after hold off");
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
      break;

      // arm sends reset ack 1
    case RAK1:
      if(kbd_state == STATE_RAK1)
	archie_kbd_send(STATE_RAK2, RAK1);
      else 
	kbd_state = STATE_HRST;
      break;

      // arm sends reset ack 2
    case RAK2:
      if(kbd_state == STATE_RAK2) 
	archie_kbd_send(STATE_IDLE, RAK2);
      else 
	kbd_state = STATE_HRST;
      break;

      // arm request keyboard id
    case RQID:
      archie_kbd_send(STATE_IDLE, KBID | 1);
      break;

      // arm acks first byte
    case BACK:
      if(kbd_state != STATE_WAIT4ACK1) 
	archie_debugf("unexpected BACK");

#ifdef HOLD_OFF_TIME
      // wait some time before sending next byte
      archie_debugf("starting hold off");
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
	archie_debugf("Enabling key scanning");
	flags |= FLAG_SCAN_ENABLED;
      }

      if(((data == NACK) || (data == MACK)) && (flags & FLAG_SCAN_ENABLED)) {
	archie_debugf("Disabling key scanning");
	flags &= ~FLAG_SCAN_ENABLED;
      }

      if(((data == MACK) || (data == SMAK)) && !(flags & FLAG_MOUSE_ENABLED)) {
	archie_debugf("Enabling mouse");
	flags |= FLAG_MOUSE_ENABLED;
      }

      if(((data == NACK) || (data == SACK)) && (flags & FLAG_MOUSE_ENABLED)) {
	archie_debugf("Disabling mouse");
	flags &= ~FLAG_MOUSE_ENABLED;
      }
      
      // wait another 10ms before sending next byte
#ifdef HOLD_OFF_TIME
      archie_debugf("starting hold off");
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
