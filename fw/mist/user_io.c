#include "AT91SAM7S256.h"
#include <stdio.h>
#include <string.h>
#include "hardware.h"
#include "osd.h"

#include "user_io.h"
#include "cdc_control.h"
#include "usb.h"
#include "debug.h"
#include "keycodes.h"
#include "ikbd.h"
#include "fat.h"
#include "spi.h"

#define BREAK  0x8000

extern fileTYPE file;
extern char s[40];

// mouse and keyboard emulation state
typedef enum { EMU_NONE, EMU_MOUSE, EMU_JOY0, EMU_JOY1 } emu_mode_t;
static emu_mode_t emu_mode = EMU_NONE;
static unsigned char emu_state = 0;
static unsigned long emu_timer = 0;
#define EMU_MOUSE_FREQ 5

// keep state over core type and its capabilities
static unsigned char core_type = CORE_TYPE_UNKNOWN;
static char core_type_8bit_with_config_string = 0;

// permanent state of adc inputs used for dip switches
static unsigned char adc_state = 0;
AT91PS_ADC a_pADC = AT91C_BASE_ADC;
AT91PS_PMC a_pPMC = AT91C_BASE_PMC;

// keep state of caps lock
static char caps_lock_toggle = 0;

// mouse position storage for ps2 and minimig rate limitation
#define X 0
#define Y 1
#define MOUSE_FREQ 20   // 20 ms -> 50hz
static int16_t mouse_pos[2] = { 0, 0};
static uint8_t mouse_flags = 0;
static unsigned long mouse_timer;

// set by OSD code to suppress forwarding of those keys to the core which
// may be in use by an active OSD
static char osd_eats_keys = false;

static void PollOneAdc() {
  static unsigned char adc_cnt = 0xff;

  // fetch result from previous run
  if(adc_cnt != 0xff) {
    unsigned int result;

    // wait for end of convertion
    while(!(AT91C_BASE_ADC->ADC_SR & (1 << (4+adc_cnt))));
    
    switch (adc_cnt) {
    case 0: result = AT91C_BASE_ADC->ADC_CDR4; break;
    case 1: result = AT91C_BASE_ADC->ADC_CDR5; break;
    case 2: result = AT91C_BASE_ADC->ADC_CDR6; break;
    case 3: result = AT91C_BASE_ADC->ADC_CDR7; break;
    }
    
    if(result < 128) adc_state |=  (1<<adc_cnt);
    if(result > 128) adc_state &= ~(1<<adc_cnt);
  }
  
  adc_cnt = (adc_cnt + 1)&3;
  
  // Enable desired chanel
  AT91C_BASE_ADC->ADC_CHER = 1 << (4+adc_cnt);
  
  // Start conversion
  AT91C_BASE_ADC->ADC_CR = AT91C_ADC_START;
}

static void InitADC(void) {
  // Enable clock for interface
  AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_ADC;

  // Reset
  AT91C_BASE_ADC->ADC_CR = AT91C_ADC_SWRST;
  AT91C_BASE_ADC->ADC_CR = 0x0;

  // Set maximum startup time and hold time
  AT91C_BASE_ADC->ADC_MR = 0x0F1F0F00 | AT91C_ADC_LOWRES_8_BIT;

  // make sure we get the first values immediately
  PollOneAdc();
  PollOneAdc();
  PollOneAdc();
  PollOneAdc();
}

// poll one adc channel every 25ms
static void PollAdc() {
  static long adc_timer = 0;

  if(CheckTimer(adc_timer)) {
    adc_timer = GetTimer(25);
    PollOneAdc();
  }
}

void user_io_init() {
  InitADC();

  ikbd_init();
}

unsigned char user_io_core_type() {
  return core_type;
}

char minimig_v1() {
  return(core_type == CORE_TYPE_MINIMIG);
}

char minimig_v2() {
  return(core_type == CORE_TYPE_MINIMIG2);
}

char user_io_create_config_name(char *s) {
  char *p = user_io_8bit_get_string(0);  // get core name
  if(p && p[0]) {
    strcpy(s, p);
    while(strlen(s) < 8) strcat(s, " ");
    strcat(s, "CFG");
    
    return 0;
  }
  return 1;
}

char user_io_is_8bit_with_config_string() {
  return core_type_8bit_with_config_string;
}  

void user_io_detect_core_type() {
  EnableIO();
  core_type = SPI(0xff);
  DisableIO();

  if((core_type != CORE_TYPE_DUMB) &&
     (core_type != CORE_TYPE_MINIMIG) &&
     (core_type != CORE_TYPE_MINIMIG2) &&
     (core_type != CORE_TYPE_PACE) &&
     (core_type != CORE_TYPE_MIST) &&
     (core_type != CORE_TYPE_8BIT))
    core_type = CORE_TYPE_UNKNOWN;

  switch(core_type) {
  case CORE_TYPE_UNKNOWN:
    iprintf("Unable to identify core (%x)!\n", core_type);
    break;
    
  case CORE_TYPE_DUMB:
    puts("Identified core without user interface");
    break;
    
  case CORE_TYPE_MINIMIG:
    puts("Identified Minimig V1 core");
    break;

  case CORE_TYPE_MINIMIG2:
    puts("Identified Minimig V2 core");
    break;
    
  case CORE_TYPE_PACE:
    puts("Identified PACE core");
    break;
    
  case CORE_TYPE_MIST:
    puts("Identified MiST core");
    break;

  case CORE_TYPE_8BIT: {
    puts("Identified 8BIT core");

    // forward SD card config to core in case it uses the local
    // SD card implementation
    user_io_sd_set_config();

    // check if core has a config string
    core_type_8bit_with_config_string = (user_io_8bit_get_string(0) != NULL);

    // send a reset
    user_io_8bit_set_status(UIO_STATUS_RESET, UIO_STATUS_RESET);

    // try to load config
    user_io_create_config_name(s);
    if(strlen(s) > 0) {
      iprintf("Loading config %s\n", s);

      if (FileOpen(&file, s))  {
	iprintf("Found config\n");
	if(file.size == 1) {
	  FileRead(&file, sector_buffer);
	  user_io_8bit_set_status(sector_buffer[0], 0xff);
	}
      }
    }

    // release reset
    user_io_8bit_set_status(0, UIO_STATUS_RESET);

  } break;
  }
}

void user_io_analog_joystick(unsigned char joystick, char valueX, char valueY) {
  if(core_type == CORE_TYPE_8BIT) {
    spi_uio_cmd8_cont(UIO_ASTICK, joystick);
    spi8(valueX);
    spi8(valueY);
    DisableIO();
  }
}

void user_io_digital_joystick(unsigned char joystick, unsigned char map) {
  // if osd is open control it via joystick
  if(osd_eats_keys) {
    static const uint8_t joy2kbd[] = { 
      OSDCTRLMENU, OSDCTRLMENU, OSDCTRLMENU, OSDCTRLSELECT,
      OSDCTRLUP, OSDCTRLDOWN, OSDCTRLLEFT, OSDCTRLRIGHT };
    static uint8_t last_map = 0;

    iprintf("joy to osd\n");
    
    //    OsdKeySet(0x80 | usb2ami[pressed[i]]);

    return;
  }

  //  iprintf("j%d: %x\n", joystick, map);

  // "only" 6 joysticks are supported
  if(joystick >= 6)
    return;

  // mist cores process joystick events for joystick 0 and 1 via the 
  // ikbd
  if((core_type == CORE_TYPE_MINIMIG) || 
     (core_type == CORE_TYPE_MINIMIG2)  || 
     (core_type == CORE_TYPE_PACE)  || 
     ((core_type == CORE_TYPE_MIST) && (joystick >= 2))  || 
     (core_type == CORE_TYPE_8BIT)) {
    // joystick 3 and 4 were introduced later
    spi_uio_cmd8((joystick < 2)?(UIO_JOYSTICK0 + joystick):((UIO_JOYSTICK2 + joystick - 2)), map);
  }

  // atari ST handles joystick 0 and 1 through the ikbd emulated by the io controller
  if((core_type == CORE_TYPE_MIST) && (joystick < 2))
    ikbd_joystick(joystick, map);
}

static char dig2ana(char min, char max) {
  if(min && !max) return -128;
  if(max && !min) return  127;
  return 0;
}

void user_io_joystick(unsigned char joystick, unsigned char map) {
  // digital joysticks also send analog signals
  user_io_digital_joystick(joystick, map);
  user_io_analog_joystick(joystick, 
		       dig2ana(map&JOY_LEFT, map&JOY_RIGHT),
		       dig2ana(map&JOY_UP, map&JOY_DOWN));
}

// transmit serial/rs232 data into core
void user_io_serial_tx(char *chr, uint16_t cnt) {
  spi_uio_cmd_cont(UIO_SERIAL_OUT);
  while(cnt--) spi8(*chr++);
  DisableIO();
}
  
// transmit midi data into core
void user_io_midi_tx(char chr) {
  spi_uio_cmd8(UIO_MIDI_OUT, chr);
}

// send ethernet mac address into FPGA
void user_io_eth_send_mac(uint8_t *mac) {
  uint8_t i;

  spi_uio_cmd_cont(UIO_ETH_MAC);
  for(i=0;i<6;i++) spi8(*mac++);
  DisableIO();
}

// set SD card info in FPGA (CSD, CID)
void user_io_sd_set_config(void) {
  unsigned char data[33];

  // get CSD and CID from SD card
  MMC_GetCID(data);
  MMC_GetCSD(data+16);
  // byte 32 is a generic config byte
  data[32] = MMC_IsSDHC()?1:0;

  // and forward it to the FPGA
  spi_uio_cmd_cont(UIO_SET_SDCONF);
  spi_write(data, sizeof(data));
  DisableIO();

  hexdump(data, sizeof(data), 0);
}

// read 8+32 bit sd card status word from FPGA
uint8_t user_io_sd_get_status(uint32_t *lba) {
  uint32_t s;
  uint8_t c; 

  spi_uio_cmd_cont(UIO_GET_SDSTAT);
  c = spi_in();
  s = spi_in();
  s = (s<<8) | spi_in();
  s = (s<<8) | spi_in();
  s = (s<<8) | spi_in();
  DisableIO();

  if(lba)
    *lba = s;

  return c;
}

// read 32 bit ethernet status word from FPGA
uint32_t user_io_eth_get_status(void) {
  uint32_t s;

  spi_uio_cmd_cont(UIO_ETH_STATUS);
  s = spi_in();
  s = (s<<8) | spi_in();
  s = (s<<8) | spi_in();
  s = (s<<8) | spi_in();
  DisableIO();

  return s;
}

// read ethernet frame from FPGAs ethernet tx buffer
void user_io_eth_receive_tx_frame(uint8_t *d, uint16_t len) {
  spi_uio_cmd_cont(UIO_ETH_FRM_IN);
  while(len--) *d++=spi_in();
  DisableIO();
}

// write ethernet frame to FPGAs rx buffer
void user_io_eth_send_rx_frame(uint8_t *s, uint16_t len) {
  spi_uio_cmd_cont(UIO_ETH_FRM_OUT);
  spi_write(s, len);
  spi8(0);     // one additional byte to allow fpga to store the previous one
  DisableIO();
}

// the physical joysticks (db9 ports at the right device side)
// as well as the joystick emulation are renumbered if usb joysticks
// are present in the system. The USB joystick(s) replace joystick 1
// and 0 and the physical joysticks are "shifted up". 
//
// Since the primary joystick is in port 1 the first usb joystick 
// becomes joystick 1 and only the second one becomes joystick 0
// (mouse port)

static uint8_t joystick_renumber(uint8_t j) {
  uint8_t usb_sticks = hid_get_joysticks();

  // no usb sticks present: no changes are being made
  if(!usb_sticks) return j;

  if(j == 0) {
    // if usb joysticks are present, then physical joystick 0 (mouse port)
    // becomes becomes 2,3,...
    j = usb_sticks + 1;
  } else {
    // if one usb joystick is present, then physical joystick 1 (joystick port)
    // becomes physical joystick 0 (mouse) port. If more than 1 usb joystick
    // is present it becomes 2,3,...
    if(usb_sticks == 1) j = 0;
    else                j = usb_sticks;
  }
  return j;
}

// 16 byte fifo for amiga key codes to limit max key rate sent into the core
#define KBD_FIFO_SIZE  16   // must be power of 2
static unsigned short kbd_fifo[KBD_FIFO_SIZE];
static unsigned char kbd_fifo_r=0, kbd_fifo_w=0;
static long kbd_timer = 0;

static void kbd_fifo_minimig_send(unsigned short code) {
  spi_uio_cmd8((code&OSD)?UIO_KBD_OSD:UIO_KEYBOARD, code & 0xff);
  kbd_timer = GetTimer(10);  // next key after 10ms earliest
}

static void kbd_fifo_enqueue(unsigned short code) {
  // if fifo full just drop the value. This should never happen
  if(((kbd_fifo_w+1)&(KBD_FIFO_SIZE-1)) == kbd_fifo_r)
    return;

  // store in queue
  kbd_fifo[kbd_fifo_w] = code;
  kbd_fifo_w = (kbd_fifo_w + 1)&(KBD_FIFO_SIZE-1);
}

// send pending bytes if timer has run up
static void kbd_fifo_poll() {
  // timer enabled and runnig?
  if(kbd_timer && !CheckTimer(kbd_timer))
    return;
 
  kbd_timer = 0;  // timer == 0 means timer is not running anymore

  if(kbd_fifo_w == kbd_fifo_r)
    return;

  kbd_fifo_minimig_send(kbd_fifo[kbd_fifo_r]);
  kbd_fifo_r = (kbd_fifo_r + 1)&(KBD_FIFO_SIZE-1);
}

void user_io_file_tx(fileTYPE *file) {
  unsigned long bytes2send = file->size;

  /* transmit the entire file using one transfer */

  iprintf("Selected file %s with %lu bytes to send\n", file->name, bytes2send);

  // prepare transmission of new file
  EnableFpga();
  SPI(UIO_FILE_TX);
  SPI(0xff);
  DisableFpga();

#if 1
  while(bytes2send) {
    iprintf(".");

    unsigned short c, chunk = (bytes2send>512)?512:bytes2send;
    char *p;

    FileRead(file, sector_buffer);

    EnableFpga();
    SPI(UIO_FILE_TX_DAT);

    for(p = sector_buffer, c=0;c < chunk;c++)
      SPI(*p++);

    DisableFpga();
    
    bytes2send -= chunk;

    // still bytes to send? read next sector
    if(bytes2send)
      FileNextSector(file);
  }
#else
  {
    int i, j;
    EnableFpga();
    SPI(UIO_FILE_TX_DAT);

    // zx spectrum video:
    // 256*192 pixels = 6144 bytes
    // _"_ = 768 attribute bytes

    for(j=0;j<8;j++) 
      for(i=0;i<32*8;i++) SPI(0xf0);

    for(j=0;j<8;j++) 
      for(i=0;i<32*8;i++) SPI(0xcc);

    for(j=0;j<8;j++) 
      for(i=0;i<32*8;i++) SPI(0x55);

    for(i=0;i<768;i++) SPI(i/3);

    DisableFpga();
  }
#endif

  // signal end of transmission
  EnableFpga();
  SPI(UIO_FILE_TX);
  SPI(0x00);
  DisableFpga();

  iprintf("\n");
}

// 8 bit cores have a config string telling the firmware how
// to treat it
char *user_io_8bit_get_string(char index) {
  unsigned char i, lidx = 0, j = 0;
  static char buffer[32+1];  // max 32 bytes per config item

  // clear buffer
  buffer[0] = 0;

  spi_uio_cmd_cont(UIO_GET_STRING);
  i = spi_in();
  // the first char returned will be 0xff if the core doesn't support
  // config strings. atari 800 returns 0xa4 which is the status byte
  if((i == 0xff) || (i == 0xa4)) {
    DisableIO();
    return NULL;
  }

  //  iprintf("String: ");

  while ((i != 0) && (i!=0xff) && (j<sizeof(buffer))) {
    if(i == ';') {
      if(lidx == index) buffer[j++] = 0;
      lidx++;
    } else {
      if(lidx == index)
	buffer[j++] = i;
    }

    //    iprintf("%c", i);
    i = spi_in();
  }
    
  DisableIO();
  //  iprintf("\n");

  // if this was the last string in the config string list, then it still
  // needs to be terminated
  if(lidx == index)
    buffer[j] = 0;

  // also return NULL for empty strings
  if(!buffer[0]) 
    return NULL;

  return buffer;
}    

unsigned char user_io_8bit_set_status(unsigned char new_status, unsigned char mask) {
  static unsigned char status = 0;

  // if mask is 0 just return the current status 
  if(mask) {
    // keep everything not masked
    status &= ~mask;
    // updated masked bits
    status |= new_status & mask;

    spi_uio_cmd8(UIO_SET_STATUS, status);
  }

  return status;
}

void user_io_poll() {

  if(user_io_dip_switch1()) {
    // check of core has changed from a good one to a not supported on
    // as this likely means that the user is reloading the core via jtag
    unsigned char ct;
    static unsigned char ct_cnt = 0;
    
    EnableIO();
    ct = SPI(0xff);
    DisableIO();
    SPI(0xff);      // needed for old minimig core
    
    if(ct == core_type) 
      ct_cnt = 0;        // same core type, everything is fine
    else {
      // core type has changed
      if(++ct_cnt == 255) {
	// wait for a new valid core id to appear
	while((ct &  0xf0) != 0xa0) {
	  EnableIO();
	  ct = SPI(0xff);
	  DisableIO();
	  SPI(0xff);      // needed for old minimig core
	}

	// reset io controller to cope with new core
	*AT91C_RSTC_RCR = 0xA5 << 24 | AT91C_RSTC_PERRST | AT91C_RSTC_PROCRST; // restart
	for(;;);
      }
    }
  }

  if((core_type != CORE_TYPE_MINIMIG) &&
     (core_type != CORE_TYPE_MINIMIG2) &&
     (core_type != CORE_TYPE_PACE) &&
     (core_type != CORE_TYPE_MIST) &&
     (core_type != CORE_TYPE_8BIT)) {
    return;  // no user io for the installed core
  }

  if(core_type == CORE_TYPE_MIST) {
    char redirect = tos_get_cdc_control_redirect();

    ikbd_poll();

    // check for input data on usart
    USART_Poll();
      
    unsigned char c = 0;

    // check for incoming serial data. this is directly forwarded to the
    // arm rs232 and mixes with debug output. Useful for debugging only of
    // e.g. the diagnostic cartridge    
    spi_uio_cmd_cont(UIO_SERIAL_IN);
    while(spi_in()) {
      c = spi_in();
      if(c != 0xff) 
	putchar(c);
      
      // forward to USB if redirection via USB/CDC enabled
      if(redirect == CDC_REDIRECT_RS232)
	cdc_control_tx(c);
    }
    DisableIO();
    
    // check for incoming parallel/midi data
    if((redirect == CDC_REDIRECT_PARALLEL) || (redirect == CDC_REDIRECT_MIDI)) {
      spi_uio_cmd_cont((redirect == CDC_REDIRECT_PARALLEL)?UIO_PARALLEL_IN:UIO_MIDI_IN);
      // character 0xff is returned if FPGA isn't configured
      c = 0;
      while(spi_in() && (c!= 0xff)) {
	c = spi_in();
	cdc_control_tx(c);
      }
      DisableIO();
      
      // always flush when doing midi to reduce latencies
      if(redirect == CDC_REDIRECT_MIDI)
	cdc_control_flush();
    }
  }

  // poll db9 joysticks
  static int joy0_state = JOY0;
  if((*AT91C_PIOA_PDSR & JOY0) != joy0_state) {
    joy0_state = *AT91C_PIOA_PDSR & JOY0;
    
    unsigned char joy_map = 0;
    if(!(joy0_state & JOY0_UP))    joy_map |= JOY_UP;
    if(!(joy0_state & JOY0_DOWN))  joy_map |= JOY_DOWN;
    if(!(joy0_state & JOY0_LEFT))  joy_map |= JOY_LEFT;
    if(!(joy0_state & JOY0_RIGHT)) joy_map |= JOY_RIGHT;
    if(!(joy0_state & JOY0_BTN1))  joy_map |= JOY_BTN1;
    if(!(joy0_state & JOY0_BTN2))  joy_map |= JOY_BTN2;

    user_io_joystick(joystick_renumber(0), joy_map);
  }
  
  static int joy1_state = JOY1;
  if((*AT91C_PIOA_PDSR & JOY1) != joy1_state) {
    joy1_state = *AT91C_PIOA_PDSR & JOY1;
    
    unsigned char joy_map = 0;
    if(!(joy1_state & JOY1_UP))    joy_map |= JOY_UP;
    if(!(joy1_state & JOY1_DOWN))  joy_map |= JOY_DOWN;
    if(!(joy1_state & JOY1_LEFT))  joy_map |= JOY_LEFT;
    if(!(joy1_state & JOY1_RIGHT)) joy_map |= JOY_RIGHT;
    if(!(joy1_state & JOY1_BTN1))  joy_map |= JOY_BTN1;
    if(!(joy1_state & JOY1_BTN2))  joy_map |= JOY_BTN2;
    
    user_io_joystick(joystick_renumber(1), joy_map);
  }

  // frequently poll the adc the switches 
  // and buttons are connected to
  PollAdc();
  
  static unsigned char key_map = 0;
  unsigned char map = 0;
  if(adc_state & 1) map |= SWITCH2;
  if(adc_state & 2) map |= SWITCH1;

  if(adc_state & 4) map |= BUTTON1;
  if(adc_state & 8) map |= BUTTON2;
  
  if(map != key_map) {
    key_map = map;

    spi_uio_cmd8(UIO_BUT_SW, map);
  }

  // mouse movement emulation is continous 
  if(emu_mode == EMU_MOUSE) {
    if(CheckTimer(emu_timer)) {
      emu_timer = GetTimer(EMU_MOUSE_FREQ);
      
      if(emu_state & JOY_MOVE) {
	unsigned char b = 0;
	char x = 0, y = 0;
	if((emu_state & (JOY_LEFT | JOY_RIGHT)) == JOY_LEFT)  x = -1; 
	if((emu_state & (JOY_LEFT | JOY_RIGHT)) == JOY_RIGHT) x = +1; 
	if((emu_state & (JOY_UP   | JOY_DOWN))  == JOY_UP)    y = -1; 
	if((emu_state & (JOY_UP   | JOY_DOWN))  == JOY_DOWN)  y = +1; 
	
	if(emu_state & JOY_BTN1) b |= 1;
	if(emu_state & JOY_BTN2) b |= 2;
	
	user_io_mouse(b, x, y);
      }
    }
  }

  if((core_type == CORE_TYPE_MINIMIG) ||
     (core_type == CORE_TYPE_MINIMIG2)) {
    kbd_fifo_poll();

    // frequently check mouse for events
    if(CheckTimer(mouse_timer)) {
      mouse_timer = GetTimer(MOUSE_FREQ);

      // has ps2 mouse data been updated in the meantime
      if(mouse_flags & 0x80) {
	spi_uio_cmd_cont(UIO_MOUSE);

	// ----- X axis -------
	if(mouse_pos[X] < -128) {
	  spi8(-128);
	  mouse_pos[X] += 128;
	} else if(mouse_pos[X] > 127) {
	  spi8(127);
	  mouse_pos[X] -= 127;
	} else {
	  spi8(mouse_pos[X]);
	  mouse_pos[X] = 0;
	}

	// ----- Y axis -------
	if(mouse_pos[Y] < -128) {
	  spi8(-128);
	  mouse_pos[Y] += 128;
	} else if(mouse_pos[Y] > 127) {
	  spi8(127);
	  mouse_pos[Y] -= 127;
	} else {
	  spi8(mouse_pos[Y]);
	  mouse_pos[Y] = 0;
	}

	spi8(mouse_flags & 0x03);
	DisableIO();

	// reset flags
	mouse_flags = 0;
      }
    }


  }

  if(core_type == CORE_TYPE_MIST) {
    // do some tos specific monitoring here
    tos_poll();
  }

  if(core_type == CORE_TYPE_8BIT) {
    unsigned char c = 1, f, p=0;

    // check for serial data to be sent

    // check for incoming serial data. this is directly forwarded to the
    // arm rs232 and mixes with debug output.
    spi_uio_cmd_cont(UIO_SIO_IN);
    // status byte is 1000000A with A=1 if data is available
    if((f = spi_in(0)) == 0x81) {
      iprintf("\033[1;36m");
      
      // character 0xff is returned if FPGA isn't configured
      while((f == 0x81) && (c!= 0xff) && (c != 0x00) && (p < 8)) {
	c = spi_in();
	if(c != 0xff && c != 0x00) 
	  iprintf("%c", c);

	f = spi_in();
	p++;
      }
      iprintf("\033[0m");
    }
    DisableIO();

    // sd card emulation
    {
      static char buffer[512];
      static uint32_t buffer_lba = 0xffffffff;
      uint32_t lba;
      uint8_t c = user_io_sd_get_status(&lba);

      // valid sd commands start with "5x" to avoid problems with
      // cores that don't implement this command
      if((c & 0xf0) == 0x50) {

	// debug: If the io controller reports and non-sdhc card, then
	// the core should never set the sdhc flag
	if((c & 3) && !MMC_IsSDHC() && (c & 0x04))
	  iprintf("WARNING: SDHC access to non-sdhc card\n");
 	
	// check if core requests configuration
	if(c & 0x08) {
	  iprintf("core requests SD config\n");
	  user_io_sd_set_config();
	}

	// check if system is trying to access a sdhc card from 
	// a sd/mmc setup

	// check if an SDHC card is inserted
	if(MMC_IsSDHC()) {
	  static char using_sdhc = 1;

	  // SD request and 
	  if((c & 0x03) && !(c & 0x04)) {
	    if(using_sdhc) {
	      // we have not been using sdhc so far? 
	      // -> complain!
	      ErrorMessage(" This core does not support\n"
			   " SDHC cards. Using them may\n"
			   " lead to data corruption.\n\n"
			   " Please use an SD card <2GB!", 0);
	      using_sdhc = 0;
	    }
	  } else
	    // SDHC request from core is always ok
	    using_sdhc = 1;
	}

	if((c & 0x03) == 0x02) {
	  // only write if the inserted card is not sdhc or
	  // if the core uses sdhc
	  if((!MMC_IsSDHC()) || (c & 0x04)) {  
	    uint8_t wr_buf[512];

	    if(user_io_dip_switch1())
	      iprintf("SD WR %d\n", lba);

	    // if we write the sector stored in the read buffer, then
	    // update the read buffer with the new contents
	    if(buffer_lba == lba) 
	      memcpy(buffer, wr_buf, 512);

	      buffer_lba = 0xffffffff;

	    // Fetch sector data from FPGA ...
	    spi_uio_cmd_cont(UIO_SECTOR_WR);
	    spi_block_read(wr_buf);
	    DisableIO();

	    // ... and write it to disk
	    DISKLED_ON;
	    MMC_Write(lba, wr_buf);
	    DISKLED_OFF;
	  }
	}

	if((c & 0x03) == 0x01) {
	  // sector read
	  // read sector from sd card if it is not already present in
	  // the buffer
	  if(buffer_lba != lba) {
	    DISKLED_ON;
	    if(MMC_Read(lba, buffer))
	      buffer_lba = lba;

	    DISKLED_OFF;
	  }

	  if(user_io_dip_switch1())
	    iprintf("SD RD %d\n", lba);
	  
	  if(buffer_lba == lba) {
	    // data is now stored in buffer. send it to fpga
	    spi_uio_cmd_cont(UIO_SECTOR_RD);
	    spi_block_write(buffer);
	    DisableIO();

	    // the end of this transfer acknowledges the FPGA internal
	    // sd card emulation
	  }

	  // just load the next sector now, so it may be prefetched
	  // for the next request already
	  DISKLED_ON;
	  if(MMC_Read(lba+1, buffer))
	    buffer_lba = lba+1;

	  DISKLED_OFF;
	}
      }
    }

    // frequently check ps2 mouse for events
    if(CheckTimer(mouse_timer)) {
      mouse_timer = GetTimer(MOUSE_FREQ);

      // has ps2 mouse data been updated in the meantime
      if(mouse_flags & 0x08) {
	unsigned char ps2_mouse[3];

	// PS2 format: 
	// YOvfl, XOvfl, dy8, dx8, 1, mbtn, rbtn, lbtn
	// dx[7:0]
	// dy[7:0]
	ps2_mouse[0] = mouse_flags;

	// ------ X axis -----------
	// store sign bit in first byte
	ps2_mouse[0] |= (mouse_pos[X] < 0)?0x10:0x00;
	if(mouse_pos[X] < -255) {
	  // min possible value + overflow flag
	  ps2_mouse[0] |= 0x40;
	  ps2_mouse[1] = -128;
	} else if(mouse_pos[X] > 255) {
	  // max possible value + overflow flag
	  ps2_mouse[0] |= 0x40;
	  ps2_mouse[1] = 255;
	} else 
	  ps2_mouse[1] = mouse_pos[X];

	// ------ Y axis -----------
	// store sign bit in first byte
	ps2_mouse[0] |= (mouse_pos[Y] < 0)?0x20:0x00;
	if(mouse_pos[Y] < -255) {
	  // min possible value + overflow flag
	  ps2_mouse[0] |= 0x80;
	  ps2_mouse[2] = -128;
	} else if(mouse_pos[Y] > 255) {
	  // max possible value + overflow flag
	  ps2_mouse[0] |= 0x80;
	  ps2_mouse[2] = 255;
	} else 
	  ps2_mouse[2] = mouse_pos[Y];
	
	// collect movement info and send at predefined rate
	iprintf("PS2 MOUSE: %x %d %d\n", 
		ps2_mouse[0], ps2_mouse[1], ps2_mouse[2]);

	spi_uio_cmd_cont(UIO_MOUSE);
	spi8(ps2_mouse[0]);
	spi8(ps2_mouse[1]);
	spi8(ps2_mouse[2]);
	DisableIO();

	// reset counters
	mouse_flags = 0;
	mouse_pos[X] = mouse_pos[Y] = 0;
      }
    }

    // --------------- THE FOLLOWING IS DEPRECATED AND WILL BE REMOVED ------------
    // ------------------------ USE SD CARD EMULATION INSTEAD ---------------------

    // raw sector io for the atari800 core which include a full
    // file system driver usually implemented using a second cpu
    static unsigned long bit8_status = 0;
    unsigned long status;

    /* read status byte */
    EnableFpga();
    SPI(UIO_GET_STATUS);
    status = SPI(0);
    status = (status << 8) | SPI(0);
    status = (status << 8) | SPI(0);
    status = (status << 8) | SPI(0);
    DisableFpga();

    if(status != bit8_status) {
      unsigned long sector = (status>>8)&0xffffff;
      char buffer[512];

      bit8_status = status;
      
      // sector read testing 
      DISKLED_ON;

      // sector read
      if(((status & 0xff) == 0xa5) || ((status & 0x3f) == 0x29)) {

	// extended command with 26 bits (for 32GB SDHC)
	if((status & 0x3f) == 0x29) sector = (status>>6)&0x3ffffff;

	bit8_debugf("SECIO rd %ld", sector);

	if(MMC_Read(sector, buffer)) {
	  // data is now stored in buffer. send it to fpga
	  EnableFpga();
	  SPI(UIO_SECTOR_SND);     // send sector data IO->FPGA
	  spi_block_write(buffer);
	  DisableFpga();
	} else
	  bit8_debugf("rd %ld fail", sector);
      }

      // sector write
      if(((status & 0xff) == 0xa6) || ((status & 0x3f) == 0x2a)) {

	// extended command with 26 bits (for 32GB SDHC)
	if((status & 0x3f) == 0x2a) sector = (status>>6)&0x3ffffff;

	bit8_debugf("SECIO wr %ld", sector);

	// read sector from FPGA
	EnableFpga();
	SPI(UIO_SECTOR_RCV);     // receive sector data FPGA->IO
	spi_block_read(buffer);
	DisableFpga();

	if(!MMC_Write(sector, buffer)) 
	  bit8_debugf("wr %ld fail", sector);
      }

      DISKLED_OFF;
    }
  }
}

char user_io_dip_switch1() {
  return((adc_state & 2)?1:0);
}

char user_io_menu_button() {
  return((adc_state & 4)?1:0);
}

char user_io_user_button() {
  return((adc_state & 8)?1:0);
}

static void send_keycode(unsigned short code) {
  if((core_type == CORE_TYPE_MINIMIG) ||
     (core_type == CORE_TYPE_MINIMIG2)) {
    // amiga has "break" marker in msb
    if(code & BREAK) code = (code & 0xff) | 0x80;

    // send immediately if possible
    if(CheckTimer(kbd_timer) &&(kbd_fifo_w == kbd_fifo_r) )
      kbd_fifo_minimig_send(code);
    else
      kbd_fifo_enqueue(code);
  }

  if(core_type == CORE_TYPE_MIST) {
    // atari has "break" marker in msb
    if(code & BREAK) code = (code & 0xff) | 0x80;

    ikbd_keyboard(code);
  }

  if(core_type == CORE_TYPE_8BIT) {
    // send ps2 keycodes for those cores that prefer ps2
    spi_uio_cmd_cont(UIO_KEYBOARD);

    // "pause" has a complex code 
    if((code&0xff) == 0x77) {

      // pause does not have a break code
      if(!(code & BREAK)) {

	// Pause key sends E11477E1F014E077
	static const unsigned char c[] = { 0xe1, 0x14, 0x77, 0xe1, 0xf0, 0x14, 0xf0, 0x77, 0x00 };
	const unsigned char *p = c;
	
	iprintf("PS2 KBD ");
	while(*p) {
	  iprintf("%x ", *p);
	  spi8(*p++);
	}
	iprintf("\n");
      }
    } else {
      iprintf("PS2 KBD ");
      if(code & EXT)   iprintf("e0 ");
      if(code & BREAK) iprintf("f0 ");
      iprintf("%x\n", code & 0xff);
      
      if(code & EXT)    // prepend extended code flag if required
	spi8(0xe0);
      
      if(code & BREAK)  // prepend break code if required
	spi8(0xf0);
      
      spi8(code & 0xff);  // send code itself
    }

    DisableIO();
  }
}

void user_io_mouse(unsigned char b, char x, char y) {

  // send mouse data as minimig expects it
  if((core_type == CORE_TYPE_MINIMIG) || 
     (core_type == CORE_TYPE_MINIMIG2)) {
    mouse_pos[X] += x;
    mouse_pos[Y] += y;
    mouse_flags |= 0x80 | (b&3); 
  }

  // 8 bit core expects ps2 like data
  if(core_type == CORE_TYPE_8BIT) {
    mouse_pos[X] += x;
    mouse_pos[Y] -= y;  // ps2 y axis is reversed over usb
    mouse_flags |= 0x08 | (b&3); 
  }

  // send mouse data as mist expects it
  if(core_type == CORE_TYPE_MIST)
    ikbd_mouse(b, x, y);
}

// check if this is a key that's supposed to be suppressed
// when emulation is active
static unsigned char is_emu_key(unsigned char c) {
  static const unsigned char m[] = { JOY_RIGHT, JOY_LEFT, JOY_DOWN, JOY_UP };

  if(emu_mode == EMU_NONE)
    return 0;

  // direction keys R/L/D/U
  if(c >= 0x4f && c <= 0x52)
    return m[c-0x4f];

  return 0;
}  

/* usb modifer bits: 
      0     1     2    3    4     5     6    7
   LCTRL LSHIFT LALT LGUI RCTRL RSHIFT RALT RGUI
*/
#define EMU_BTN1  0  // left control
#define EMU_BTN2  1  // left shift
#define EMU_BTN3  2  // left alt
#define EMU_BTN4  3  // left gui (usually windows key)

unsigned short keycode(unsigned char in) {
  if((core_type == CORE_TYPE_MINIMIG) ||
     (core_type == CORE_TYPE_MINIMIG2)) 
    return usb2ami[in];
  
  // atari st and the 8 bit core (currently only used for atari 800)
  // use the same key codes
  if(core_type == CORE_TYPE_MIST)
    return usb2atari[in];

  if(core_type == CORE_TYPE_8BIT)
    return usb2ps2[in];

  return MISS;
}

void check_reset(unsigned char modifiers) {
  if((core_type == CORE_TYPE_MINIMIG) ||
     (core_type == CORE_TYPE_MINIMIG2)) {
    if(modifiers == 0x45) // ctrl - alt - alt
      OsdReset(RESET_NORMAL);
  }
}

unsigned short modifier_keycode(unsigned char index) {
  /* usb modifer bits: 
        0     1     2    3    4     5     6    7
      LCTRL LSHIFT LALT LGUI RCTRL RSHIFT RALT RGUI
  */

  if((core_type == CORE_TYPE_MINIMIG) ||
     (core_type == CORE_TYPE_MINIMIG2)) {
    static const unsigned short amiga_modifier[] = 
      { 0x63, 0x60, 0x64, 0x66, 0x63, 0x61, 0x65, 0x67 };
    return amiga_modifier[index];
  }
  if(core_type == CORE_TYPE_MIST) {
    static const unsigned short atari_modifier[] = 
      { 0x1d, 0x2a, 0x38, MISS, 0x1d, 0x36, 0x38, MISS };
    return atari_modifier[index];
  } 

  if(core_type == CORE_TYPE_8BIT) {
    static const unsigned short ps2_modifier[] = 
      { 0x14, 0x12, 0x11, EXT|0x1f, EXT|0x14, 0x59, EXT|0x11, EXT|0x27 };
    return ps2_modifier[index];
  } 

  return MISS;
}

void user_io_osd_key_enable(char on) {
  osd_eats_keys = on;
}

static char key_used_by_osd(unsigned short s) {
  // this key is only used in OSD and has no keycode
  if((s & OSD_LOC) && !(s & 0xff))  return true; 

  // no keys are suppressed if the OSD is inactive
  if(!osd_eats_keys) return false;

  // in atari mode eat all keys if the OSD is online,
  // else none as it's up to the core to forward keys
  // to the OSD
  return((core_type == CORE_TYPE_MIST) ||
	 (core_type == CORE_TYPE_8BIT));
}

void user_io_kbd(unsigned char m, unsigned char *k) {
  if((core_type == CORE_TYPE_MINIMIG) ||
     (core_type == CORE_TYPE_MINIMIG2) ||
     (core_type == CORE_TYPE_MIST) ||
     (core_type == CORE_TYPE_8BIT)) {

    static unsigned char modifier = 0, pressed[6] = { 0,0,0,0,0,0 };
    int i, j;
    
    // modifier keys are used as buttons in emu mode
    if(emu_mode != EMU_NONE) {
      char last_btn = emu_state & (JOY_BTN1 | JOY_BTN2 | JOY_BTN3 | JOY_BTN4);
      if(m & (1<<EMU_BTN1)) emu_state |=  JOY_BTN1;
      else                  emu_state &= ~JOY_BTN1;
      if(m & (1<<EMU_BTN2)) emu_state |=  JOY_BTN2;
      else                  emu_state &= ~JOY_BTN2;
      if(m & (1<<EMU_BTN3)) emu_state |=  JOY_BTN3;
      else                  emu_state &= ~JOY_BTN3;
      if(m & (1<<EMU_BTN4)) emu_state |=  JOY_BTN4;
      else                  emu_state &= ~JOY_BTN4;
      
      // check if state of mouse buttons has changed
      // (on a mouse only two buttons are supported)
      if((last_btn  & (JOY_BTN1 | JOY_BTN2)) != 
	 (emu_state & (JOY_BTN1 | JOY_BTN2))) {
	if(emu_mode == EMU_MOUSE) {
	  unsigned char b;
	  if(emu_state & JOY_BTN1) b |= 1;
	  if(emu_state & JOY_BTN2) b |= 2;
	  user_io_mouse(b, 0, 0);
	}
      }
	
      // check if state of joystick buttons has changed
      if(last_btn != (emu_state & (JOY_BTN1|JOY_BTN2|JOY_BTN3|JOY_BTN4))) {
	if(emu_mode == EMU_JOY0) 
	  user_io_joystick(joystick_renumber(0), emu_state);
	
	if(emu_mode == EMU_JOY1) 
	  user_io_joystick(joystick_renumber(1), emu_state);
      }
    }
    
    // handle modifier keys
    if(m != modifier) {
      for(i=0;i<8;i++) {
	// Do we have a downstroke on a modifier key?
	if((m & (1<<i)) && !(modifier & (1<<i))) {
	  // check for special events in modifier presses
	  check_reset(m);

	  // shift keys are used for mouse joystick emulation in emu mode
	  if(((i != EMU_BTN1) && (i != EMU_BTN2) &&
	      (i != EMU_BTN3) && (i != EMU_BTN4)) || (emu_mode == EMU_NONE))
	    if(modifier_keycode(i) != MISS)
	      send_keycode(modifier_keycode(i));
	}
	if(!(m & (1<<i)) && (modifier & (1<<i)))
	  if(((i != EMU_BTN1) && (i != EMU_BTN2) &&
	      (i != EMU_BTN3) && (i != EMU_BTN4)) || (emu_mode == EMU_NONE))
	    if(modifier_keycode(i) != MISS)
	      send_keycode(BREAK | modifier_keycode(i));
      }
      
      modifier = m;
    }
    
    // check if there are keys in the pressed list which aren't 
    // reported anymore
    for(i=0;i<6;i++) {
      unsigned short code = keycode(pressed[i]);
      
      if(pressed[i] && code != MISS) {
	for(j=0;j<6 && pressed[i] != k[j];j++);
	
	// don't send break for caps lock
	if(j == 6) {
	  // special OSD key handled internally 
	  OsdKeySet(0x80 | usb2ami[pressed[i]]);

	  if(!key_used_by_osd(code)) {
	    if(is_emu_key(pressed[i])) {
	      emu_state &= ~is_emu_key(pressed[i]);
	    
	      if(emu_mode == EMU_JOY0) 
		user_io_joystick(joystick_renumber(0), emu_state);
	      
	      if(emu_mode == EMU_JOY1) 
		user_io_joystick(joystick_renumber(1), emu_state);

	    } else if(!(code & CAPS_LOCK_TOGGLE) &&
		      !(code & NUM_LOCK_TOGGLE))
	      send_keycode(BREAK | code);	
	  }
	}
      }  
    }
    
    for(i=0;i<6;i++) {
      unsigned short code = keycode(k[i]);

      if(k[i] && (k[i] <= KEYCODE_MAX) && code != MISS) {
	// check if this key is already in the list of pressed keys
	for(j=0;j<6 && k[i] != pressed[j];j++);

	if(j == 6) {
	  // special OSD key handled internally 
	  OsdKeySet(usb2ami[k[i]]); 

	  // no further processing of any key that is currently 
	  // redirected to the OSD
	  if(!key_used_by_osd(code)) {
	    if (is_emu_key(k[i])) {
	      emu_state |= is_emu_key(k[i]);

	      // joystick emulation is also affected by the presence of
	      // usb joysticks
	      if(emu_mode == EMU_JOY0) 
		user_io_joystick(joystick_renumber(0), emu_state);
	      
	      if(emu_mode == EMU_JOY1) 
		user_io_joystick(joystick_renumber(1), emu_state);

	    } else if(!(code & CAPS_LOCK_TOGGLE)&&
		      !(code & NUM_LOCK_TOGGLE)) 
	      send_keycode(code);
	    else {
	      if(code & CAPS_LOCK_TOGGLE) {
		// send alternating make and break codes for caps lock
		send_keycode((code & 0xff) | (caps_lock_toggle?BREAK:0));
		caps_lock_toggle = !caps_lock_toggle;
		
		hid_set_kbd_led(HID_LED_CAPS_LOCK, caps_lock_toggle);
	      }
	      if(code & NUM_LOCK_TOGGLE) {
		// num lock has four states indicated by leds:
		// all off: normal
		// num lock on, scroll lock on: mouse emu
		// num lock on, scroll lock off: joy0 emu
		// num lock off, scroll lock on: joy1 emu
		
		if(emu_mode == EMU_MOUSE)
		  emu_timer = GetTimer(EMU_MOUSE_FREQ);
		
		emu_mode = (emu_mode+1)&3;
		if(emu_mode == EMU_MOUSE || emu_mode == EMU_JOY0) 
		  hid_set_kbd_led(HID_LED_NUM_LOCK, true);
		else
		  hid_set_kbd_led(HID_LED_NUM_LOCK, false);
		
		if(emu_mode == EMU_MOUSE || emu_mode == EMU_JOY1) 
		  hid_set_kbd_led(HID_LED_SCROLL_LOCK, true);
		else
		  hid_set_kbd_led(HID_LED_SCROLL_LOCK, false);
	      }
	    }
	  }
	}
      }
    }
    
  for(i=0;i<6;i++) 
    pressed[i] = k[i];
  }
}

