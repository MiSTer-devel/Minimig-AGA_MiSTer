#include <stdio.h>

#include "usb.h"
#include "max3421e.h"
#include "timer.h"
#include "hidparser.h"
#include "debug.h"
#include "../user_io.h"
#include "../hardware.h"

static unsigned char kbd_led_state = 0;  // default: all leds off
static unsigned char joysticks = 0;      // number of detected usb joysticks

uint8_t hid_get_joysticks(void) {
  return joysticks;
}

//get HID report descriptor 
static uint8_t hid_get_report_descr(usb_device_t *dev, uint8_t i, uint16_t size)  {
  //  hid_debugf("%s(%x, if=%d, size=%d)", __FUNCTION__, dev->bAddress, iface, size);

  uint8_t buf[size];
  usb_hid_info_t *info = &(dev->hid_info);
  uint8_t rcode = usb_ctrl_req( dev, HID_REQ_HIDREPORT, USB_REQUEST_GET_DESCRIPTOR, 0x00, 
			      HID_DESCRIPTOR_REPORT, info->iface[i].iface_idx, size, buf);
 
  if(!rcode) {
    hid_debugf("HID report descriptor:");
    hexdump(buf, size, 0);

    // we got a report descriptor. Try to parse it
    if(parse_report_descriptor(buf, size, &(info->iface[i].conf))) {
      if(info->iface[i].conf.type == CONFIG_TYPE_JOYSTICK) {
	hid_debugf("Detected USB joystick #%d", joysticks);

	info->iface[i].device_type = HID_DEVICE_JOYSTICK;
	info->iface[i].jindex = joysticks++;
      }
    }
  }
    
  return rcode;
}

static uint8_t hid_set_idle(usb_device_t *dev, uint8_t iface, uint8_t reportID, uint8_t duration ) {
  //  hid_debugf("%s(%x, if=%d id=%d, dur=%d)", __FUNCTION__, dev->bAddress, iface, reportID, duration);

  return( usb_ctrl_req( dev, HID_REQ_HIDOUT, HID_REQUEST_SET_IDLE, reportID, 
		       duration, iface, 0x0000, NULL));
}

static uint8_t hid_set_protocol(usb_device_t *dev, uint8_t iface, uint8_t protocol) {
  //  hid_debugf("%s(%x, if=%d proto=%d)", __FUNCTION__, dev->bAddress, iface, protocol);

  return( usb_ctrl_req( dev, HID_REQ_HIDOUT, HID_REQUEST_SET_PROTOCOL, protocol, 
		       0x00, iface, 0x0000, NULL));
}

static uint8_t hid_set_report(usb_device_t *dev, uint8_t iface, uint8_t report_type, uint8_t report_id, 
			      uint16_t nbytes, uint8_t* dataptr ) {
  //  hid_debugf("%s(%x, if=%d data=%x)", __FUNCTION__, dev->bAddress, iface, dataptr[0]);

  return( usb_ctrl_req(dev, HID_REQ_HIDOUT, HID_REQUEST_SET_REPORT, report_id, 
		       report_type, iface, nbytes, dataptr));
}

/* todo: handle parsing in chunks */
static uint8_t usb_hid_parse_conf(usb_device_t *dev, uint8_t conf, uint16_t len) {
  usb_hid_info_t *info = &(dev->hid_info);
  uint8_t rcode;
  bool isGoodInterface = false;

  union buf_u {
    usb_configuration_descriptor_t conf_desc;
    usb_interface_descriptor_t iface_desc;
    usb_endpoint_descriptor_t ep_desc;
    usb_hid_descriptor_t hid_desc;
    uint8_t raw[len];
  } buf, *p;

  // usb_interface_descriptor

  if(rcode = usb_get_conf_descr(dev, len, conf, &buf.conf_desc)) 
    return rcode;

  /* scan through all descriptors */
  p = &buf;
  while(len > 0) {
    switch(p->conf_desc.bDescriptorType) {
    case USB_DESCRIPTOR_CONFIGURATION:
      // hid_debugf("conf descriptor size %d", p->conf_desc.bLength);
      // we already had this, so we simply ignore it
      break;

    case USB_DESCRIPTOR_INTERFACE:
      isGoodInterface = false;
      // hid_debugf("iface descriptor size %d", p->iface_desc.bLength);

      /* check the interface descriptors for supported class */

      // only HID interfaces are supported
      if(p->iface_desc.bInterfaceClass == USB_CLASS_HID) {
	//	puts("iface is HID");

	if(info->bNumIfaces < MAX_IFACES) {
	  // ok, let's use this interface
	  isGoodInterface = true;

	  info->iface[info->bNumIfaces].iface_idx = p->iface_desc.bInterfaceNumber;
	  info->iface[info->bNumIfaces].has_boot_mode = false;
	  info->iface[info->bNumIfaces].is_5200daptor = false;
	  info->iface[info->bNumIfaces].key_state = 0;
	  info->iface[info->bNumIfaces].device_type = HID_DEVICE_UNKNOWN;
	  info->iface[info->bNumIfaces].conf.type = CONFIG_TYPE_NONE;

	  if(p->iface_desc.bInterfaceSubClass == HID_BOOT_INTF_SUBCLASS) {
	    // hid_debugf("Iface %d is Boot sub class", info->bNumIfaces);
	    info->iface[info->bNumIfaces].has_boot_mode = true;
	  }
	  
	  switch(p->iface_desc.bInterfaceProtocol) {
	  case HID_PROTOCOL_NONE:
	    hid_debugf("HID protocol is NONE");
	    break;
	    
	  case HID_PROTOCOL_KEYBOARD:
	    hid_debugf("HID protocol is KEYBOARD");
	    info->iface[info->bNumIfaces].device_type = HID_DEVICE_KEYBOARD;
	    break;
	    
	  case HID_PROTOCOL_MOUSE:
	    hid_debugf("HID protocol is MOUSE");
	    info->iface[info->bNumIfaces].device_type = HID_DEVICE_MOUSE;
	    break;
	    
	  default:
	    hid_debugf("HID protocol is %d", p->iface_desc.bInterfaceProtocol);
	    break;
	  }
	}
      }
      break;

    case USB_DESCRIPTOR_ENDPOINT:
      //      hid_debugf("endpoint descriptor size %d", p->ep_desc.bLength);

      if(isGoodInterface) {

	// only interrupt in endpoints are supported
	if ((p->ep_desc.bmAttributes & 0x03) == 3 && (p->ep_desc.bEndpointAddress & 0x80) == 0x80) {
	  hid_debugf("endpoint %d, interval = %dms", 
		  p->ep_desc.bEndpointAddress & 0x0F, p->ep_desc.bInterval);

	  // Fill in the endpoint info structure
	  uint8_t epidx = info->bNumIfaces;
	  info->iface[epidx].interval = p->ep_desc.bInterval;
	  info->iface[epidx].ep.epAddr	 = (p->ep_desc.bEndpointAddress & 0x0F);
	  info->iface[epidx].ep.maxPktSize = p->ep_desc.wMaxPacketSize[0];
	  info->iface[epidx].ep.epAttribs	 = 0;
	  info->iface[epidx].ep.bmNakPower = USB_NAK_NOWAIT;
	  info->bNumIfaces++;
	}
      }
      break;

    case HID_DESCRIPTOR_HID:
      hid_debugf("hid descriptor size %d", p->ep_desc.bLength);

      if(isGoodInterface) {
	// we need a report descriptor
	if(p->hid_desc.bDescrType == HID_DESCRIPTOR_REPORT) {
	  uint16_t len = p->hid_desc.wDescriptorLength[0] + 
	    256 * p->hid_desc.wDescriptorLength[1];
	  hid_debugf(" -> report descriptor size = %d", len);
	  
	  info->iface[info->bNumIfaces].report_desc_size = len;
	}
      }
      break;

    default:
      hid_debugf("unsupported descriptor type %d size %d", p->raw[1], p->raw[0]);
    }

    // advance to next descriptor
    len -= p->conf_desc.bLength;
    p = (union buf_u*)(p->raw + p->conf_desc.bLength);
  }
  
  if(len != 0) {
    hid_debugf("Config underrun: %d", len);
    return USB_ERROR_CONFIGURAION_SIZE_MISMATCH;
  }

  return 0;
}

static uint8_t usb_hid_init(usb_device_t *dev) {
  hid_debugf("%s(%x)", __FUNCTION__, dev->bAddress);

  uint8_t rcode;
  uint8_t i;
  uint16_t vid, pid;

  usb_hid_info_t *info = &(dev->hid_info);
  
  union {
    usb_device_descriptor_t dev_desc;
    usb_configuration_descriptor_t conf_desc;
  } buf;

  // reset status
  info->bPollEnable = false;
  info->bNumIfaces = 0;

  for(i=0;i<MAX_IFACES;i++) {
    info->iface[i].qNextPollTime = 0;
    info->iface[i].ep.epAddr	 = i;
    info->iface[i].ep.maxPktSize = 8;
    info->iface[i].ep.epAttribs	 = 0;
    info->iface[i].ep.bmNakPower = USB_NAK_MAX_POWER;
  }

  // try to re-read full device descriptor from newly assigned address
  if(rcode = usb_get_dev_descr( dev, sizeof(usb_device_descriptor_t), &buf.dev_desc ))
    return rcode;

  // save vid/pid for automatic hack later
  vid = buf.dev_desc.idVendor;
  pid = buf.dev_desc.idProduct;

  uint8_t num_of_conf = buf.dev_desc.bNumConfigurations;
  //  hid_debugf("number of configurations: %d", num_of_conf);

  for(i=0; i<num_of_conf; i++) {
    if(rcode = usb_get_conf_descr(dev, sizeof(usb_configuration_descriptor_t), i, &buf.conf_desc)) 
      return rcode;
    
    //    hid_debugf("conf descriptor %d has total size %d", i, buf.conf_desc.wTotalLength);

    // parse directly if it already fitted completely into the buffer
    usb_hid_parse_conf(dev, i, buf.conf_desc.wTotalLength);
  }

  // check if we found valid hid interfaces
  if(!info->bNumIfaces) {
    hid_debugf("no hid interfaces found");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }

  // Set Configuration Value
  rcode = usb_set_conf(dev, buf.conf_desc.bConfigurationValue);

  // process all supported interfaces
  for(i=0; i<info->bNumIfaces; i++) {
    // no boot mode, try to parse HID report descriptor
    if(!info->iface[i].has_boot_mode) {
      rcode = hid_get_report_descr(dev, i, info->iface[i].report_desc_size);
      if(rcode) return rcode;

      if(info->iface[i].device_type == CONFIG_TYPE_JOYSTICK) {
	char k;
        
	iprintf("Report: type = %d, id = %d, size = %d\n", 
		info->iface[i].conf.type,
		info->iface[i].conf.report_id,
		info->iface[i].conf.report_size);
	
	for(k=0;k<2;k++)
	  iprintf("Axis%d: %d@%d %d->%d\n", k, 
		  info->iface[i].conf.joystick.axis[k].size,
		  info->iface[i].conf.joystick.axis[k].byte_offset,
		  info->iface[i].conf.joystick.axis[k].logical.min,
		  info->iface[i].conf.joystick.axis[k].logical.max);
	
	for(k=0;k<4;k++)
	  iprintf("Button%d: @%d/%d\n", k,
		  info->iface[i].conf.joystick.button[k].byte_offset,
		  info->iface[i].conf.joystick.button[k].bitmask);
      }
      
      
      // use fixed setup for known interfaces 
      if((vid == 0x0079) && (pid == 0x0011) && (i==0)) {
	iprintf("hacking cheap NES pad\n");
        
        // fixed setup for nes gamepad
        info->iface[0].conf.joystick.button[0].byte_offset = 5;
        info->iface[0].conf.joystick.button[0].bitmask = 32;
        info->iface[0].conf.joystick.button[1].byte_offset = 5;
        info->iface[0].conf.joystick.button[1].bitmask = 64 | 16;
        info->iface[0].conf.joystick.button[2].byte_offset = 6;
        info->iface[0].conf.joystick.button[2].bitmask = 16;
        info->iface[0].conf.joystick.button[3].byte_offset = 6;
        info->iface[0].conf.joystick.button[3].bitmask = 32;
      }

      if((vid == 0x04d8) && (pid == 0xf6ec) && (i==0)) {
	iprintf("hacking 5200daptor\n");
        
	info->iface[0].conf.joystick.button[2].byte_offset = 4;
	info->iface[0].conf.joystick.button[2].bitmask = 0x40;    // "Reset"
	info->iface[0].conf.joystick.button[3].byte_offset = 4;
	info->iface[0].conf.joystick.button[3].bitmask = 0x10;    // "Start"

	info->iface[0].is_5200daptor = true;
      }
    }

    rcode = hid_set_idle(dev, info->iface[i].iface_idx, 0, 0);
    if (rcode && rcode != hrSTALL)
      return rcode;

    // enable boot mode
    if(info->iface[i].has_boot_mode)
      hid_set_protocol(dev, info->iface[i].iface_idx, HID_BOOT_PROTOCOL);
  }
  
  puts("HID configured");

  // update leds
  for(i=0;i<MAX_IFACES;i++)
    if(dev->hid_info.iface[i].device_type == HID_DEVICE_KEYBOARD)
      hid_set_report(dev, dev->hid_info.iface[i].iface_idx, 2, 0, 1, &kbd_led_state);

  info->bPollEnable = true;
  return 0;
}

static uint8_t usb_hid_release(usb_device_t *dev) {
  usb_hid_info_t *info = &(dev->hid_info);

  puts(__FUNCTION__);

  uint8_t i;
  // check if a joystick is released
  for(i=0;i<info->bNumIfaces;i++) {
    if(info->iface[i].device_type == HID_DEVICE_JOYSTICK) {
      uint8_t c_jindex = info->iface[i].jindex;
      hid_debugf("releasing joystick #%d, renumbering", c_jindex);

      // walk through all devices and search for sticks with a higher id

      // search for all joystick interfaces on all hid devices
      usb_device_t *dev = usb_get_devices();
      uint8_t j;
      for(j=0;j<USB_NUMDEVICES;j++) {
	if(dev[j].bAddress && (dev[j].class == &usb_hid_class)) {
	  // search for joystick interfaces
	  uint8_t k;
	  for(k=0;k<MAX_IFACES;k++) {
	    if(dev[j].hid_info.iface[k].device_type == HID_DEVICE_JOYSTICK) {
	      if(dev[j].hid_info.iface[k].jindex > c_jindex) {
		hid_debugf("decreasing jindex of dev #%d from %d to %d", j, 
			dev[j].hid_info.iface[k].jindex, dev[j].hid_info.iface[k].jindex-1);
		dev[j].hid_info.iface[k].jindex--;
	      }
	    }
	  }
	}
      }
      // one less joystick in the system ...
      joysticks--;
    }
  }

  return 0;
}

// special 5200daptor button processing
static void handle_5200daptor(usb_hid_iface_info_t *iface, uint8_t *buf) {

  // list of buttons that are reported as keys
  static const struct {
    uint8_t byte_offset;   // offset of the byte within the report which the button bit is in
    uint8_t mask;          // bitmask of the button bit
    uint8_t key_code[2];   // usb keycodes to be sent for joystick 0 and joystick 1
  } button_map[] = {
    { 4, 0x10, 0x3a, 0x3d }, /* START -> f1/f4 */
    { 4, 0x20, 0x3b, 0x3e }, /* PAUSE -> f2/f5 */
    { 4, 0x40, 0x3c, 0x3f }, /* RESET -> f3/f6 */
    { 5, 0x01, 0x1e, 0x21 }, /*     1 ->  1/4  */
    { 5, 0x02, 0x1f, 0x22 }, /*     2 ->  2/5  */
    { 5, 0x04, 0x20, 0x23 }, /*     3 ->  3/6  */
    { 5, 0x08, 0x14, 0x15 }, /*     4 ->  q/r  */
    { 5, 0x10, 0x1a, 0x17 }, /*     5 ->  w/t  */
    { 5, 0x20, 0x08, 0x1c }, /*     6 ->  e/y  */
    { 5, 0x40, 0x04, 0x09 }, /*     7 ->  a/f  */
    { 5, 0x80, 0x16, 0x0a }, /*     8 ->  s/g  */
    { 6, 0x01, 0x07, 0x0b }, /*     9 ->  d/h  */
    { 6, 0x02, 0x1d, 0x19 }, /*     * ->  z/v  */
    { 6, 0x04, 0x1b, 0x05 }, /*     0 ->  x/b  */
    { 6, 0x08, 0x06, 0x11 }, /*     # ->  c/n  */
    { 0, 0x00, 0x00, 0x00 }  /* ----  end ---- */
  };

  // keyboard events are only generated for the first
  // two joysticks in the system
  if(iface->jindex > 1) return;

  // build map of pressed keys
  uint8_t i;
  uint16_t keys = 0;
  for(i=0;button_map[i].mask;i++) 
    if(buf[button_map[i].byte_offset] & button_map[i].mask)
      keys |= (1<<i);

  // check if keys have changed
  if(iface->key_state != keys) {
    uint8_t buf[6] = { 0,0,0,0,0,0 };
    uint8_t p = 0;

    // report up to 6 pressed keys
    for(i=0;(i<16)&&(p<6);i++) 
      if(keys & (1<<i))
	buf[p++] = button_map[i].key_code[iface->jindex];

    //    iprintf("5200: %d %d %d %d %d %d\n", buf[0],buf[1],buf[2],buf[3],buf[4],buf[5]);

    // generate key events
    user_io_kbd(0x00, buf);

    // save current state of keys
    iface->key_state = keys;
  }
}

static uint8_t usb_hid_poll(usb_device_t *dev) {
  usb_hid_info_t *info = &(dev->hid_info);
  int8_t i;

  if (!info->bPollEnable)
    return 0;
  
  for(i=0;i<info->bNumIfaces;i++) {
    usb_hid_iface_info_t *iface = info->iface+i;
    
    if(iface->device_type != HID_DEVICE_UNKNOWN) {

      if (iface->qNextPollTime <= timer_get_msec()) {
	//      hid_debugf("poll %d...", iface->ep.epAddr);
      
	uint16_t read = iface->ep.maxPktSize;
	uint8_t buf[iface->ep.maxPktSize];
	uint8_t rcode = 
	  usb_in_transfer(dev, &(iface->ep), &read, buf);
	
	if (rcode) {
	  if (rcode != hrNAK)
	    hid_debugf("%s() error: %d", __FUNCTION__, rcode);
	} else {
	  
	  // successfully received some bytes
	  if(iface->has_boot_mode) {
	    if(iface->device_type == HID_DEVICE_MOUSE) {
	      // boot mouse needs at least three bytes
	      if(read >= 3) {
		// forward all three bytes to the user_io layer
		user_io_mouse(buf[0], buf[1], buf[2]);
	      }
	    }
	    
	    if(iface->device_type == HID_DEVICE_KEYBOARD) {
	      // boot kbd needs at least eight bytes
	      if(read >= 8) {
		user_io_kbd(buf[0], buf+2);
	      }
	    }
	  }
	  
	  if(iface->device_type == HID_DEVICE_JOYSTICK) {
	    hid_config_t *conf = &iface->conf;
	    if(read >= conf->report_size) {
	      uint8_t jmap = 0;
	      uint16_t a[2];
	      uint8_t idx, i;
	      
	      // hid_debugf("Joystick data:"); hexdump(buf, read, 0);

	      // two axes ...
	      for(i=0;i<2;i++) {
		a[i] = buf[conf->joystick.axis[i].byte_offset];
		if(conf->joystick.axis[i].size == 16)
		  a[i] += (buf[conf->joystick.axis[i].byte_offset+1])<<8;

		// scale to 0 -> 255 range. 99% of the joysticks already deliver that
		if((conf->joystick.axis[i].logical.min != 0) ||
		   (conf->joystick.axis[i].logical.max != 255)) {
		  a[i] = ((a[i] - conf->joystick.axis[i].logical.min) * 255)/
		    (conf->joystick.axis[i].logical.max - 
		     conf->joystick.axis[i].logical.min);
		}
	      }

	      if(a[0] <  64) jmap |= JOY_LEFT;
	      if(a[0] > 192) jmap |= JOY_RIGHT;
	      if(a[1] <  64) jmap |= JOY_UP;
	      if(a[1] > 192) jmap |= JOY_DOWN;
	      
	      //	      iprintf("JOY X:%d Y:%d\n", a[0], a[1]);
	      
	      // ... and four buttons
	      for(i=0;i<4;i++)
		if(buf[conf->joystick.button[i].byte_offset] & 
		   conf->joystick.button[i].bitmask) jmap |= (JOY_BTN1<<i);
	      
	      //	      iprintf("JOY D:%d\n", jmap);

	      // swap joystick 0 and 1 since 1 is the one 
	      // used primarily on most systems
	      idx = iface->jindex;
	      if(idx == 0)      idx = 1;
	      else if(idx == 1) idx = 0;
	      
	      // check if joystick state has changed
	      if(jmap != iface->jmap) {
		//	      iprintf("jmap %d changed to %x\n", idx, jmap);
		
		// and feed into joystick input system
		user_io_digital_joystick(idx, jmap);
		iface->jmap = jmap;
	      }
	      
	      // also send analog values
	      user_io_analog_joystick(idx, a[0]-128, a[1]-128);

	      // do special 5200daptor treatment
	      if(iface->is_5200daptor)
		handle_5200daptor(iface, buf);
	    }
	  }
	}
	iface->qNextPollTime += iface->interval;   // poll at requested rate
      }
    }
  }

  return 0;
}

void hid_set_kbd_led(unsigned char led, bool on) {
  // check if led state has changed
  if( (on && !(kbd_led_state&led)) || (!on && (kbd_led_state&led))) {
    if(on) kbd_led_state |=  led;
    else   kbd_led_state &= ~led;

    // search for all keyboard interfaces on all hid devices
    usb_device_t *dev = usb_get_devices();
    int i;
    for(i=0;i<USB_NUMDEVICES;i++) {
      if(dev[i].bAddress && (dev[i].class == &usb_hid_class)) {
	// search for keyboard interfaces
	int j;
	for(j=0;j<MAX_IFACES;j++)
	  if(dev[i].hid_info.iface[j].device_type == HID_DEVICE_KEYBOARD)
	    hid_set_report(dev+i, dev[i].hid_info.iface[j].iface_idx, 2, 0, 1, &kbd_led_state);
      }
    }
  }
}

const usb_device_class_config_t usb_hid_class = {
  usb_hid_init, usb_hid_release, usb_hid_poll };  

