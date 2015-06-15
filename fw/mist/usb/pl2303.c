//
// pl2303.c
//
// driver for the pl2303 usb to serial converter
//

// https://github.com/felis/USB_Host_Shield_2.0
// http://lxr.free-electrons.com/source/drivers/usb/serial/pl2303.c

#include <stdio.h>
#include <string.h>  // for memcpy

#include "debug.h"
#include "usb.h"
#include "pl2303.h"
#include "max3421e.h"
#include "user_io.h"

// #define TX_TEST

// this needs to be at least 64 bytes (the max packet size), otherwise we might loose data
// since we cannot prevent the device to return less than these bytes
#define RX_BUF_SIZE 128
static uint8_t rx_buf[RX_BUF_SIZE];
static uint8_t rx_buf_fill;

#define TX_BUF_SIZE 128
static uint8_t tx_buf[TX_BUF_SIZE];
static uint8_t tx_buf_fill;

static uint8_t adapter_count = 0;

// return true if there's a pl2303 present and if that has
// its tx buffer full. This will then stop reading data from the 
// core so it can throttle 
int8_t pl2303_is_blocked(void) {
  // if no adapter is installed then there's no need to throttle
  if(!adapter_count) return 0;
  return(tx_buf_fill == TX_BUF_SIZE);
}

void pl2303_tx_byte(uint8_t byte) {
  if(tx_buf_fill < TX_BUF_SIZE)
    tx_buf[tx_buf_fill++] = byte;
  else 
    iprintf("Drop %d\n", byte);
}

int8_t pl2303_present(void) {
  return(adapter_count != 0);
}

uint8_t pl2303_rx_available(void) {
  return(rx_buf_fill != 0);
}

uint8_t pl2303_rx(void) {
  if(!pl2303_rx_available()) return 0;

  uint8_t retval = rx_buf[0];
  memmove(rx_buf, rx_buf+1, RX_BUF_SIZE-1);
  rx_buf_fill--;
  return retval;
}

#define USB_VENDOR_REQ_OUT   USB_SETUP_HOST_TO_DEVICE|USB_SETUP_TYPE_VENDOR|USB_SETUP_RECIPIENT_DEVICE
#define USB_VENDOR_REQ_IN    USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_VENDOR|USB_SETUP_RECIPIENT_DEVICE

static uint8_t pl2303_SetControlLineState(usb_device_t *dev, uint8_t state) {
  uint8_t ret = usb_ctrl_req(dev, PL2303_REQ_CDCOUT, CDC_SET_CONTROL_LINE_STATE, state, 0, 0, 0, NULL);
  if(ret) pl2303_debugf("%s() failed", __FUNCTION__);
  return ret;
}

static uint8_t pl2303_SetLineCoding(usb_device_t *dev, const line_coding_t *dataptr) {
  uint8_t ret = usb_ctrl_req(dev, PL2303_REQ_CDCOUT, CDC_SET_LINE_CODING, 0, 0, 0, sizeof(line_coding_t), (uint8_t*)dataptr);
  if(ret) pl2303_debugf("%s() failed", __FUNCTION__);
  return ret;
}

static uint8_t pl2303_vendor_read(usb_device_t *dev, uint16_t val, uint8_t* buf ) {
  uint8_t ret = usb_ctrl_req( dev, USB_VENDOR_REQ_IN, 1, val&0xff, val>>8, 0, 1, buf);
  if(ret) pl2303_debugf("vendor in failed");
  return ret;
}

static uint8_t pl2303_vendor_write(usb_device_t *dev, uint16_t val, uint8_t index ) {
  uint8_t ret = usb_ctrl_req( dev, USB_VENDOR_REQ_OUT, 1, val&0xff, val>>8, index, 0, NULL);
  if(ret) pl2303_debugf("vendor out failed");
  return ret;
}


// get access to the first pl2303 device found
static usb_device_t *pl2303_get_dev(void) {
  uint8_t i;
  usb_device_t *devs = usb_get_devices(), *dev = NULL;

  // find first device
  for (i=0; i<USB_NUMDEVICES; i++) 
    if(devs[i].bAddress && (devs[i].class == &usb_pl2303_class)) 
      dev = devs+i;
  
  return dev;
}

static void pl2303_settings_dev(usb_device_t *dev, uint32_t rate, uint8_t bits, uint8_t parity, uint8_t stop) {
  if(!dev) return;

  // build new line coding
  line_coding_t lc;
  lc.dwDTERate   = rate;
  lc.bCharFormat = stop;
  lc.bParityType = parity;
  lc.bDataBits   = bits;

  // check if line coding has changed
  if(memcmp(&lc, &dev->pl2303_info.line_coding, sizeof(line_coding_t)) != 0) {
    memcpy(&dev->pl2303_info.line_coding, &lc, sizeof(line_coding_t));

    if(rate & 0x80000000) 
      pl2303_debugf("Unsupported line coding");
    else {
      pl2303_debugf("New line coding %ld %d/%d/%d", rate, bits, parity, stop);

      uint8_t rcode = pl2303_SetLineCoding(dev, &lc);
      if(rcode) pl2303_debugf("%s() failed #%x", __FUNCTION__, rcode);
    }
  }
}

void pl2303_settings(uint32_t rate, uint8_t bits, uint8_t parity, uint8_t stop) {
  pl2303_settings_dev(pl2303_get_dev(), rate, bits, parity, stop);
}

static int8_t pl2303_tx_dev(usb_device_t *dev, uint8_t *data, uint8_t len) {
  if(!dev) return;

  usb_pl2303_info_t *info = &(dev->pl2303_info);

#ifdef PL2303_STAT
  info->tx_cnt += len;
  pl2303_debugf("tx %d bytes, total = %ld", len, info->tx_cnt);
#else
  pl2303_debugf("tx %d bytes", len);
#endif

  hexdump(data, len, 0);

  // transmit data
  uint8_t rcode = usb_out_transfer(dev, &(info->ep[info->ep_bulk_out_idx]), len, data);
  if(rcode) pl2303_debugf("%s() failed #%x", __FUNCTION__, rcode);

  if(rcode == hrNAK)
    pl2303_debugf("%s() NAK", __FUNCTION__);

  return rcode;
}

void pl2303_tx(uint8_t *data, uint8_t len) {
  pl2303_tx_dev(pl2303_get_dev(), data, len);
}

static uint8_t pl2303_parse_conf0(usb_device_t *dev, uint16_t len) {
  usb_pl2303_info_t *info = &(dev->pl2303_info);
  uint8_t rcode;
  uint8_t epidx = 0;

  union buf_u {
    usb_configuration_descriptor_t conf_desc;
    usb_interface_descriptor_t iface_desc;
    usb_endpoint_descriptor_t ep_desc;
    uint8_t raw[len];
  } buf, *p;

  if(rcode = usb_get_conf_descr(dev, len, 0, &buf.conf_desc)) {
    pl2303_debugf("getting full conf descriptor #0 failed");
    return rcode;
  }

  /* scan through all descriptors */
  p = &buf;
  while(len > 0) {
    if(p->conf_desc.bDescriptorType == USB_DESCRIPTOR_ENDPOINT) {
      if(epidx < 3) {
	
	// Fill in the endpoint info structure
	info->ep[epidx].epAddr	   = (p->ep_desc.bEndpointAddress & 0x0F);
	info->ep[epidx].maxPktSize = p->ep_desc.wMaxPacketSize[0];
	info->ep[epidx].epAttribs  = 0;
	info->ep[epidx].bmNakPower = USB_NAK_NOWAIT;

	// Handle interrupt endpoints
	if ((p->ep_desc.bmAttributes & 0x03) == 3 && 
	    (p->ep_desc.bEndpointAddress & 0x80) == 0x80) {
	  pl2303_debugf("irq endpoint %d, interval = %dms", 
		  p->ep_desc.bEndpointAddress & 0x0F, p->ep_desc.bInterval);

	  // Handling bInterval correctly is rather tricky. The meaning of 
	  // this field differs between low speed/full speed vs. high speed.
	  // We are using a high speed device on a full speed link. Which 
	  // rate is correct then? Furthermore this seems
	  // to be a common problem: http://www.lvr.com/usbfaq.htm
	  info->ep_int_idx = epidx;
	  info->int_poll_ms = p->ep_desc.bInterval;
	}

	if ((p->ep_desc.bmAttributes & 0x03) == 2 && 
	    (p->ep_desc.bEndpointAddress & 0x80) == 0x80) {
	  info->ep_bulk_in_idx = epidx;
	  pl2303_debugf("bulk in endpoint %d", p->ep_desc.bEndpointAddress & 0x0F);
	}

	if ((p->ep_desc.bmAttributes & 0x03) == 2 && 
	    (p->ep_desc.bEndpointAddress & 0x80) == 0x00) {
	  info->ep_bulk_out_idx = epidx;
	  pl2303_debugf("bulk out endpoint %d", p->ep_desc.bEndpointAddress & 0x0F);
	  info->ep[epidx].bmNakPower = USB_NAK_DEFAULT;   // allow retries to avoid data loss
	}
	
	epidx++;
      }
    }
    
    // advance to next descriptor
    len -= p->conf_desc.bLength;
    p = (union buf_u*)(p->raw + p->conf_desc.bLength);
  }
  
  if(len != 0) {
    pl2303_debugf("Config underrun: %d", len);
    return USB_ERROR_CONFIGURAION_SIZE_MISMATCH;
  }

  return 0;
}

#ifdef TX_TEST
uint8_t tx_test = 0;
#endif

static uint8_t pl2303_init(usb_device_t *dev) {
  usb_pl2303_info_t *info = &(dev->pl2303_info);
  uint8_t i, rcode = 0;

  pl2303_debugf("%s(%d)", __FUNCTION__, dev->bAddress);

  // reset status
  info->qNextIrqPollTime = 0;
  info->qNextBulkPollTime = 0;
  info->bPollEnable = false;

  // buffer should be empty
  tx_buf_fill = rx_buf_fill = 0;

#ifdef PL2303_STAT
  info->tx_cnt = info->rx_cnt = 0;
#endif

  union {
    usb_device_descriptor_t dev_desc;
    usb_configuration_descriptor_t conf_desc;
    uint8_t raw[0];
  } buf;

  // read full device descriptor 
  rcode = usb_get_dev_descr( dev, sizeof(usb_device_descriptor_t), &buf.dev_desc );
  if( rcode ) {
    pl2303_debugf("failed to get device descriptor");
    return rcode;
  }

  pl2303_debugf("vid/pid = %x/%x", buf.dev_desc.idVendor, buf.dev_desc.idProduct);

  if(buf.dev_desc.bDeviceClass == 0x02 ) {
    info->type = PL2303_TYPE_0;
    pl2303_debugf("TYPE_0");
  } else if(buf.dev_desc.bMaxPacketSize0 == 0x40 ) {
    info->type = PL2303_TYPE_HX;
    pl2303_debugf("TYPE_HX");
  } else if(buf.dev_desc.bDeviceClass == 0x00) {
    info->type = PL2303_TYPE_1;
    pl2303_debugf("TYPE_1");
  } else if(buf.dev_desc.bDeviceClass == 0xff) {
    info->type = PL2303_TYPE_1;
    pl2303_debugf("TYPE_1");
  }

  // TODO: implement list of vids/pids
  if((buf.dev_desc.idVendor != 0x067b) || (buf.dev_desc.idProduct != 0x2303)) {
    pl2303_debugf("Not a pl2303 device");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }

  // use first config (actually there is only one)
  if(rcode = usb_get_conf_descr(dev, sizeof(usb_configuration_descriptor_t), 0, &buf.conf_desc)) {
    pl2303_debugf("failed getting conf descriptor #0");
    return rcode;
  }
    
  // parse directly if it already fitted completely into the buffer
  if((rcode = pl2303_parse_conf0(dev, buf.conf_desc.wTotalLength)) != 0) {
    pl2303_debugf("parse conf failed");
    return rcode;
  }
  
  // Set Configuration Value
  pl2303_debugf("setting configuration: %d", buf.conf_desc.bConfigurationValue);
  rcode = usb_set_conf(dev, buf.conf_desc.bConfigurationValue);

  pl2303_vendor_read( dev, 0x8484, buf.raw );
  pl2303_vendor_write( dev, 0x0404, 0 );
  pl2303_vendor_read( dev, 0x8484, buf.raw );
  pl2303_vendor_read( dev, 0x8383, buf.raw );
  pl2303_vendor_read( dev, 0x8484, buf.raw );
  pl2303_vendor_write( dev, 0x0404, 1 );
  pl2303_vendor_read( dev, 0x8484, buf.raw);
  pl2303_vendor_read( dev, 0x8383, buf.raw);
  pl2303_vendor_write( dev, 0, 1 );
  pl2303_vendor_write( dev, 1, 0 );
  if( info->type == PL2303_TYPE_HX ) pl2303_vendor_write( dev, 2, 0x44 );
  else                               pl2303_vendor_write( dev, 2, 0x24 );

  /* reset upstream data pipes */
  pl2303_vendor_write(dev, 8, 0);
  pl2303_vendor_write(dev, 9, 0);

  // Set DTR = 1
  rcode = pl2303_SetControlLineState(dev, 1);
  if(rcode) {
    pl2303_debugf("SetControlLineState");
    return rcode;
  }

  // default: 9600 8N1
  pl2303_settings_dev(dev, 9600, 8, PL2303_PARITY_NONE, PL2303_STOP_BIT_1);
  
  info->bPollEnable = true;
  
#ifdef TX_TEST
  tx_test = 0;
#endif
  
  adapter_count++;
  return 0;
}

static uint8_t pl2303_release(usb_device_t *dev) {
  pl2303_debugf("%s()", __FUNCTION__);
  adapter_count--;
  return 0;
}

static uint8_t pl2303_poll(usb_device_t *dev) {
  usb_pl2303_info_t *info = &(dev->pl2303_info);
  uint8_t rcode = 0;
  
  if (!info->bPollEnable)
    return 0;
  
#if 1 // no need to use the irq channel ...
  // poll interrupt endpoint
  if (info->qNextIrqPollTime <= timer_get_msec()) {
    uint16_t read = info->ep[info->ep_int_idx].maxPktSize;
    uint8_t buf[info->ep[info->ep_int_idx].maxPktSize];
    uint8_t rcode = usb_in_transfer(dev, &(info->ep[info->ep_int_idx]), &read, buf);
    
    if (rcode) {
      if (rcode != hrNAK)
	pl2303_debugf("%s() int error: %x", __FUNCTION__, rcode);
    } else {
      pl2303_debugf("int %d bytes", read);
      hexdump(buf, read, 0);
    }
    info->qNextIrqPollTime = timer_get_msec() + info->int_poll_ms;
  }
#endif

  // Do TX/RX handling at 100Hz
  if(info->qNextBulkPollTime <= timer_get_msec()) {

#ifdef TX_TEST
    if(tx_test < 26) {
      // do some tests (needs a loopback connector)
      uint8_t buffer[30]; 
      memset(buffer, 'A'+tx_test, sizeof(buffer));
      
      // send and retry on failure
      pl2303_tx_dev(dev, buffer, sizeof(buffer));
      tx_test++;
    }
#endif

    // transmit anything that's in the local transmit buffer
    if(tx_buf_fill) {
      pl2303_tx_dev(dev, tx_buf, tx_buf_fill);
      tx_buf_fill = 0;
    }

    // only receive if still enough space in rx buffer for a max sized packet
    if(rx_buf_fill+info->ep[info->ep_bulk_in_idx].maxPktSize < RX_BUF_SIZE) {
      uint16_t read = info->ep[info->ep_bulk_in_idx].maxPktSize;
      rcode = usb_in_transfer(dev, &(info->ep[info->ep_bulk_in_idx]), &read, rx_buf+rx_buf_fill);
      if(rcode) {
	if (rcode != hrNAK)
	  pl2303_debugf("%s() rx error: %x", __FUNCTION__, rcode);
      } else {
#ifdef PL2303_STAT
	info->rx_cnt += read;
	pl2303_debugf("rx %d bytes, total = %ld", read, info->rx_cnt);
#else
	pl2303_debugf("rx %d bytes", read);
#endif

	hexdump(rx_buf+rx_buf_fill, read, 0);
	rx_buf_fill += read;
      }
    }

    // get current serial status
    serial_status_t stat;
    if(user_io_serial_status(&stat, 0x90)) {
      { static serial_status_t old_stat;
	if(memcmp(&stat, &old_stat, sizeof(stat)) != 0) { 
	  pl2303_debugf("stat changed:");
	  hexdump(&stat, sizeof(stat), 0);
	  memcpy(&old_stat, &stat, sizeof(stat));
	}
      }

      // is data to be sent?
      if(rx_buf_fill) {
#define BUFFER_SIZE 8  // max 15
	// check if fifo is empty (the empty fifo can hold up to 15 entries)
	if(stat.fifo_stat & 4) {
	  //	  iprintf("space: %d\n", stat.fifo_stat>>4);
	  uint8_t buffer_space = stat.fifo_stat>>4; // BUFFER_SIZE

	  // send as many bytes as possible from buffer into core ...
	  uint8_t bytes2send = (rx_buf_fill < buffer_space)?rx_buf_fill:buffer_space;
	  pl2303_debugf("forward %d bytes into core", bytes2send);
	  user_io_serial_tx(rx_buf, bytes2send);
	  // ... and remove sent data from buffer
	  memmove(rx_buf, rx_buf+bytes2send, RX_BUF_SIZE-bytes2send);
	  rx_buf_fill -= bytes2send;

	  //	  if(user_io_serial_status(&stat, 0x90)) {
	  //	    iprintf("After %d: %d\n", bytes2send, stat.fifo_stat>>4);
	  //	  }
	}
      }

      // set new com paramters (will be ignored if they stay the same)
      pl2303_settings_dev(dev, stat.bitrate, stat.datasize, stat.parity, stat.stopbits);
    } else {
      if(rx_buf_fill) {
	// just throw all data at the core as we have no insight in its buffer state
	user_io_serial_tx(rx_buf, rx_buf_fill);
	rx_buf_fill = 0;
      }
    }

    // bulk ep polling at fixed 100Hz
    info->qNextBulkPollTime = timer_get_msec() + 10;
  }
}

const usb_device_class_config_t usb_pl2303_class = {
  pl2303_init, pl2303_release, pl2303_poll };  
