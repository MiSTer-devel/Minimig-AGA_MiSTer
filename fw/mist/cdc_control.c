/*
  cdc_control.c

*/

#include "cdc_enumerate.h"
#include "cdc_control.h"
#include "hardware.h"
#include "user_io.h"
#include "tos.h"
#include "debug.h"

static char buffer[32];
static unsigned char fill = 0;
static unsigned long flush_timer = 0;

extern const char version[];

void cdc_control_open(void) {
  iprintf("CDC control open\n");

  usb_cdc_open();
}

// send everything in buffer 
void cdc_control_flush(void) {
  if(fill) usb_cdc_write(buffer, fill);
  fill = 0;
}

void cdc_control_tx(char c) {
  // buffer full? flush it!
  if(fill == sizeof(buffer))
    cdc_control_flush();

  flush_timer = GetTimer(100);
  buffer[fill++] = c;
}

static void cdc_puts(char *str) {
  unsigned char i=0;
  
  while(*str) {
    if(*str == '\n')
      cdc_control_tx('\r');

    cdc_control_tx(*str++);
  }

  cdc_control_tx('\r');
  cdc_control_tx('\n');

  cdc_control_flush();
}

void cdc_control_poll(void) {
  // flush out queue every now and then
  if(flush_timer && CheckTimer(flush_timer)) {
    cdc_control_flush();
    flush_timer = 0;
  }

  // low level usb handling happens inside usb_cdc_poll
  if(usb_cdc_poll()) {
    uint16_t read, i;
    char data[AT91C_EP_OUT_SIZE];

    // check for user input
    if((read = usb_cdc_read(data, AT91C_EP_OUT_SIZE)) != 0) {
      
      switch(tos_get_cdc_control_redirect()) {
      case CDC_REDIRECT_RS232:
	iprintf("RS232 forward:\n");
	hexdump(data, read, 0);

	user_io_serial_tx(data, read);
	break;
	
      case CDC_REDIRECT_CONTROL:
	for(i=0;i<read;i++) {
	  // force lower case
	  if((data[i] >= 'A') && (data[i] <= 'Z'))
	    data[i] = data[i] - 'A' + 'a';
	  
	  switch(data[i]) {
	  case '\r':
	    cdc_puts("\n\033[7m <<< MIST board controller >>> \033[0m");
	    cdc_puts("Firmware version ATH" VDATE);
	    cdc_puts("Commands:");
	    cdc_puts("\033[7mR\033[0meset");
	    cdc_puts("\033[7mC\033[0moldreset");
	    cdc_puts("\033[7mD\033[0mebug output redirect");
	    cdc_puts("R\033[7mS\033[0m232 redirect");
	    cdc_puts("\033[7mP\033[0marallel redirect");
	    cdc_puts("\033[7mM\033[0mIDI redirect");
	    cdc_puts("");
	    break;
	    
	  case 'r':
	    cdc_puts("Reset ...");
	    tos_reset(0);
	    break;
	    
	  case 'c':
	    cdc_puts("Coldreset ...");
	    tos_reset(1);
	    break;
	    
	  case 'd':
	    cdc_puts("Debug output redirect enabled");
	    tos_set_cdc_control_redirect(CDC_REDIRECT_DEBUG);
	    break;
	    
	  case 's':
	    cdc_puts("RS232 redirect enabled");
	    tos_set_cdc_control_redirect(CDC_REDIRECT_RS232);
	    break;
	    
	  case 'p':
	    cdc_puts("Parallel redirect enabled");
	    tos_set_cdc_control_redirect(CDC_REDIRECT_PARALLEL);
	    break;
	    
	  case 'm':
	    cdc_puts("MIDI redirect enabled");
	    tos_set_cdc_control_redirect(CDC_REDIRECT_MIDI);
	    break;
	    
	  }
	  break;
	}
  
	default:
	  break;
      }
    }
  }
}
