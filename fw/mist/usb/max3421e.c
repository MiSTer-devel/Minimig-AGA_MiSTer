#include <stdio.h>

#include "max3421e.h"
#include "timer.h"
#include "spi.h"

void max3421e_write_u08(uint8_t reg, uint8_t data) {
  //  iprintf("write %x %x\n", reg, data);

  spi_start(0);
  spi_xmit(reg | MAX3421E_WRITE);
  spi_xmit(data);
  spi_end();
}

uint8_t max3421e_read_u08(uint8_t reg) {
  spi_start(0);
  spi_xmit(reg);
  uint8_t ret = spi_xmit(0);
  spi_end();
  return ret;
}

uint8_t *max3421e_write(uint8_t reg, uint8_t n, uint8_t* data) {

  spi_start(0);
  spi_xmit(reg | MAX3421E_WRITE);

  SPI_write(data, n);
  spi_end();

  return data+n;
}

// discard data if NULL ptr was provided
uint8_t *max3421e_read(uint8_t reg, uint8_t n, uint8_t* data) {
  spi_start(0);
  spi_xmit(reg);

  if(data) 
    SPI_read(data, n);
  else
    //    SPI_Write(0, n);  // spi write sends something, but we don't care
    while(n--) spi_xmit(0);

  spi_end();

  return data+n;
}

static uint8_t vbusState = MAX3421E_STATE_SE0;

uint16_t max3421e_reset() {
  uint16_t i = 0;

  /* reset chip */
  max3421e_write_u08( MAX3421E_USBCTL, MAX3421E_CHIPRES );
  max3421e_write_u08( MAX3421E_USBCTL, 0 );

  /* wait for pll to synchronize */
  while( ++i ) {
    if(( max3421e_read_u08( MAX3421E_USBIRQ ) & MAX3421E_OSCOKIRQ )) {
      return i;
    }
  }
  return 0;
}

void max3421e_busprobe() {
  iprintf("busprobe()\n");

  uint8_t bus_sample = max3421e_read_u08( MAX3421E_HRSL );	// Get J,K status
  bus_sample &= ( MAX3421E_JSTATUS | MAX3421E_KSTATUS );	// zero the rest of the byte
  switch( bus_sample ) {					// start full-speed or low-speed host 
  case MAX3421E_JSTATUS:
    if( !(max3421e_read_u08( MAX3421E_MODE ) & MAX3421E_LOWSPEED) ) {
      max3421e_write_u08( MAX3421E_MODE, MAX3421E_MODE_FS_HOST );
      vbusState = MAX3421E_STATE_FSHOST;
    } else {
      max3421e_write_u08( MAX3421E_MODE, MAX3421E_MODE_LS_HOST);
      vbusState = MAX3421E_STATE_LSHOST;
    }
    break;
    
  case MAX3421E_KSTATUS:
    if( !(max3421e_read_u08( MAX3421E_MODE ) & MAX3421E_LOWSPEED) ) {
      max3421e_write_u08( MAX3421E_MODE, MAX3421E_MODE_LS_HOST );
      vbusState = MAX3421E_STATE_LSHOST;
    } else {
      max3421e_write_u08( MAX3421E_MODE, MAX3421E_MODE_FS_HOST );
      vbusState = MAX3421E_STATE_FSHOST;
    }
    break;

  case MAX3421E_SE1:						// illegal state
    vbusState = MAX3421E_STATE_SE1;
    break;

  case MAX3421E_SE0:					        // disconnected state
    max3421e_write_u08( MAX3421E_MODE, MAX3421E_DPPULLDN | MAX3421E_DMPULLDN | MAX3421E_HOST | MAX3421E_SEPIRQ);
    vbusState = MAX3421E_STATE_SE0;
    break;
  }
}

void max3421e_init() {
  iprintf("max3421e_init()\n");

  timer_init();
  spi_init();

  // switch to full duplex mode
  max3421e_write_u08(MAX3421E_PINCTL, MAX3421E_FDUPSPI | MAX3421E_INTLEVEL);

  // read and output version
  iprintf("Chip revision: %x\n", max3421e_read_u08(MAX3421E_REVISION));

  if( max3421e_reset() == 0 ) {
    iprintf("pll init failed\n");
    return;
  }

  // enable pulldowns, set host mode
  max3421e_write_u08( MAX3421E_MODE, MAX3421E_DPPULLDN | MAX3421E_DMPULLDN | MAX3421E_HOST );
  
  // enable interrupts
  //  max3421e_write_u08( MAX3421E_HIEN, MAX3421E_CONDETIE| MAX3421E_FRAMEIE );
  max3421e_write_u08( MAX3421E_HIEN, MAX3421E_CONDETIE );

  /* check if device is connected */

  // sample USB bus
  max3421e_write_u08( MAX3421E_HCTL,MAX3421E_SAMPLEBUS );
  
  // wait for sample operation to finish
  while(!(max3421e_read_u08( MAX3421E_HCTL ) & MAX3421E_SAMPLEBUS ));
  
  // check if anything is connected
  max3421e_busprobe();

  // clear connection detect interrupt                 
  max3421e_write_u08( MAX3421E_HIRQ, MAX3421E_CONDETIRQ );

  // enable interrupts
  max3421e_write_u08( MAX3421E_CPUCTL, MAX3421E_IE );
  return;
}

#include "timer.h"

uint8_t max3421e_poll() {
  uint8_t hirq = max3421e_read_u08( MAX3421E_HIRQ );

#if 0
  static msec_t next = 0;
  if(timer_get_msec() > next) {
    iprintf("irq src=%x, bus state %x\n", hirq, vbusState);
    iprintf("host result %x\n", max3421e_read_u08( MAX3421E_HRSL));

    next = timer_get_msec() + 10000;
  }
#endif

  if( hirq & MAX3421E_CONDETIRQ ) {
    iprintf("=> CONDETIRQ\n");
    max3421e_busprobe();
    max3421e_write_u08( MAX3421E_HIRQ, MAX3421E_CONDETIRQ );
  }

  if( hirq & MAX3421E_BUSEVENTIRQ) {
    iprintf("=> BUSEVENTIRQ\n");
    max3421e_write_u08( MAX3421E_HIRQ, MAX3421E_BUSEVENTIRQ );
  }

  if( hirq & MAX3421E_SNDBAVIRQ) {
    //    iprintf("=> MAX3421E_SNDBAVIRQ\n");
    max3421e_write_u08( MAX3421E_HIRQ, MAX3421E_SNDBAVIRQ);
  }

  if( hirq & MAX3421E_FRAMEIRQ) {
    //    iprintf("=> MAX3421E_FRAMEIRQ\n");
    max3421e_write_u08( MAX3421E_HIRQ, MAX3421E_FRAMEIRQ);
  }

#if 0  
  int i;
  for(i=0;i<8;i++) {
    if(hirq & 1<<i) {
      iprintf("ack irq %d\n", 1<<i); 
      //      max3421e_write_u08( MAX3421E_HIRQ, i );
    }
  }
#endif

  return vbusState; 
}

