//
// storage.c
//

#include <stdio.h>
#include <string.h>

#include "debug.h"
#include "usb.h"
#include "storage.h"
#include "timer.h"
#include "mii.h"
#include "max3421e.h"
#include "hardware.h"
#include "tos.h"
#include "fat.h"
#include "swap.h"

uint8_t storage_devices = 0;

uint32_t swap32(uint32_t x) {
  return ((x&0x00ff0000)>>8) | ((x&0xff000000)>>24) | 
    ((x&0x000000ff)<<24) | ((x&0x0000ff00)<<8);
}

static uint8_t storage_parse_conf(usb_device_t *dev, uint8_t conf, uint16_t len) {
  usb_storage_info_t *info = &(dev->storage_info);
  uint8_t rcode;
  bool is_good_interface = false;

  union buf_u {
    usb_configuration_descriptor_t conf_desc;
    usb_interface_descriptor_t iface_desc;
    usb_endpoint_descriptor_t ep_desc;
    uint8_t raw[len];
  } buf, *p;

  if(rcode = usb_get_conf_descr(dev, len, conf, &buf.conf_desc)) 
    return rcode;

  /* scan through all descriptors */
  p = &buf;
  while(len > 0) {
    switch(p->conf_desc.bDescriptorType) {

    case USB_DESCRIPTOR_CONFIGURATION:
      break;

    case USB_DESCRIPTOR_INTERFACE:
      // only STORAGE interfaces are supported
      if((p->iface_desc.bInterfaceClass == USB_CLASS_MASS_STORAGE) &&
	 (p->iface_desc.bInterfaceSubClass == STORAGE_SUBCLASS_SCSI) &&
	 (p->iface_desc.bInterfaceProtocol == STORAGE_PROTOCOL_BULK_ONLY)) {
	storage_debugf("iface is MASS_STORAGE/SCSI/BULK_ONLY");
	is_good_interface = true;
      } else {
	storage_debugf("Unsupported class/subclass/proto = %x/%x/%x", 
		       p->iface_desc.bInterfaceClass, p->iface_desc.bInterfaceSubClass,
		       p->iface_desc.bInterfaceProtocol);
	is_good_interface = false;
      }
      break;

    case USB_DESCRIPTOR_ENDPOINT:
      if(is_good_interface) { 
	int8_t epidx = -1;
	
	if((p->ep_desc.bmAttributes & 0x03) == 2) {
	  if((p->ep_desc.bEndpointAddress & 0x80) == 0x80) {
	    storage_debugf("bulk in ep %d, size = %d", p->ep_desc.bEndpointAddress & 0x0F, p->ep_desc.wMaxPacketSize[0]);
	    epidx = STORAGE_EP_IN;
	  } else {
	      storage_debugf("bulk out ep %d, size = %d", p->ep_desc.bEndpointAddress & 0x0F, p->ep_desc.wMaxPacketSize[0]);
	    epidx = STORAGE_EP_OUT;
	  }
	}
	
	if(epidx != -1) {
	  // Fill in the endpoint info structure
	  info->ep[epidx].epAddr     = (p->ep_desc.bEndpointAddress & 0x0F);
	  info->ep[epidx].maxPktSize = p->ep_desc.wMaxPacketSize[0];
	  info->ep[epidx].epAttribs  = 0;
	  info->ep[epidx].bmNakPower = USB_NAK_NOWAIT;
	}
      }
      break;
      
    default:
      storage_debugf("unsupported descriptor type %d size %d", p->raw[1], p->raw[0]);
    }

    // advance to next descriptor
    len -= p->conf_desc.bLength;
    p = (union buf_u*)(p->raw + p->conf_desc.bLength);
  }
  
  if(len != 0) {
    storage_debugf("Config underrun: %d", len);
    return USB_ERROR_CONFIGURAION_SIZE_MISMATCH;
  }

  return is_good_interface?0:USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
}

static uint8_t clear_ep_halt(usb_device_t *dev, uint8_t index) {
  usb_storage_info_t *info = &(dev->storage_info);

  iprintf("clear ep halt for %x\n", info->ep[index].epAddr);

  return usb_ctrl_req(dev, USB_SETUP_HOST_TO_DEVICE | USB_SETUP_TYPE_STANDARD | USB_SETUP_RECIPIENT_ENDPOINT, 
		      USB_REQUEST_CLEAR_FEATURE, USB_FEATURE_ENDPOINT_HALT, 0, info->ep[index].epAddr, 0, NULL);
}

static uint8_t mass_storage_reset(usb_device_t *dev) {
  usb_storage_info_t *info = &(dev->storage_info);
  info->last_error = usb_ctrl_req(dev, STORAGE_REQ_MASSOUT, STORAGE_REQ_BOMSR, 0, 0, 0, 0, NULL);

  if(info->last_error)
    iprintf("reset error = %d\n", info->last_error);

  return info->last_error;
}

static uint8_t get_max_lun(usb_device_t *dev, uint8_t *plun) {
  usb_storage_info_t *info = &(dev->storage_info);
  info->last_error = usb_ctrl_req(dev, STORAGE_REQ_MASSIN, STORAGE_REQ_GET_MAX_LUN, 0, 0, 0, 1, plun);

  timer_delay_msec(10);
  
  if (info->last_error == hrSTALL) {
    storage_debugf("%s() stall", __FUNCTION__);
    *plun = 0;
    info->last_error = clear_ep_halt(dev, STORAGE_EP_IN);
    return 0;
  }

  if(info->last_error)
    storage_debugf("%s() failed", __FUNCTION__);

  return info->last_error;
}

static uint8_t handle_usb_error(usb_device_t *dev, uint8_t index) {
  usb_storage_info_t *info = &(dev->storage_info);
  uint8_t count = 3;

  while(info->last_error && count) {
    switch(info->last_error) {
    case hrSUCCESS:
      return 0;

    case hrJERR: 
      info->last_error = 0;
      return STORAGE_ERR_DEVICE_DISCONNECTED;

    case hrSTALL:
      info->last_error = clear_ep_halt(dev, index);
      break;
      
    default:
      return STORAGE_ERR_GENERAL_USB_ERROR;
    }
    count --;
  } // while

  if(!count)
    iprintf("handle_us_error retry timeout\n");

  return STORAGE_ERR_SUCCESS;
}

// send with retry and timeout
static uint8_t storage_out(usb_device_t *dev, ep_t *ep, uint16_t nbytes, uint8_t* data) {
  uint8_t rcode;
  uint16_t cnt = 0;

  do {
    rcode = usb_out_transfer(dev, ep, nbytes, data);
    if(rcode == hrNAK) timer_delay_msec(1);
    cnt++;
  } while(rcode == hrNAK);

  if(rcode == hrSTALL)
    iprintf("out transfer stalled\n");

  if(cnt > 1)
    iprintf("ok %d\n", cnt);

  if(rcode) iprintf("out error after %d retries: %d (%d bytes)\n", cnt-1, rcode, nbytes);

  return rcode;
}

// receive with retry and timeout
static uint8_t storage_in(usb_device_t *dev, ep_t *ep, uint16_t *nbytes, uint8_t* data) {
  //  return usb_in_transfer(dev, ep, nbytes, data);
  uint8_t rcode;
  uint16_t count;
  uint16_t cnt = 0;

  do {
    count = *nbytes;
    rcode = usb_in_transfer(dev, ep, &count, data);
    if(rcode == hrNAK) timer_delay_msec(1);
    cnt++;
  } while(rcode == hrNAK);

  if(rcode == hrSTALL)
    iprintf("in transfer stalled\n");

  if(rcode) iprintf("in error after %d retries: %d\n", cnt-1, rcode); 

  *nbytes = count;
  return rcode;
}

static uint8_t transaction(usb_device_t *dev, command_block_wrapper_t *cbw, uint16_t size, void *buf) {
  usb_storage_info_t *info = &(dev->storage_info);
  uint16_t read;
  uint8_t ret;

  info->last_error = storage_out(dev, &(info->ep[STORAGE_EP_OUT]), sizeof(command_block_wrapper_t), (uint8_t*)cbw);
  if(info->last_error)
    iprintf("last_erro = %d\n", info->last_error);

  if((ret= handle_usb_error(dev, STORAGE_EP_OUT))) {
    storage_debugf("Sending CBW failed");
    return ret;
  }

  if (size && buf) {
    if (cbw->bmCBWFlags & STORAGE_CMD_DIR_IN) {
      read = size;
      info->last_error = storage_in(dev, &(info->ep[STORAGE_EP_IN]), &read, (uint8_t*)buf);

      if(info->last_error == hrSTALL)
	info->last_error = clear_ep_halt(dev, STORAGE_EP_IN);

      if(info->last_error) {
	iprintf("read error: %d\n", info->last_error);
	//	hexdump(buf, (read>32)?32:read, 0);
      }
    } else {
      storage_debugf("%s(%d)", __FUNCTION__, size);
      hexdump(cbw, sizeof(*cbw), 0);

      //      iprintf("TX %d (%d)\n", size, info->ep[STORAGE_EP_OUT].maxPktSize);

      while(size) {
	read = (size > info->ep[STORAGE_EP_OUT].maxPktSize)?info->ep[STORAGE_EP_OUT].maxPktSize:size;
	info->last_error = storage_out(dev, &(info->ep[STORAGE_EP_OUT]), read, (uint8_t*)buf);

	if(info->last_error == hrSTALL) {
	  info->last_error = clear_ep_halt(dev, STORAGE_EP_OUT);

	  mass_storage_reset(dev);

	  iprintf("err after stall: %d\n", info->last_error);

	  timer_delay_msec(1000);

	  size = 0;

	} else {
	  buf += read;
	  size -= read;
	}
      }

      if(info->last_error != 0) {
	iprintf("write failed: %d\n", info->last_error);
	//	hexdump(buf, (read>32)?32:read, 0);
      }
    }
  }

  if(handle_usb_error(dev, (cbw->bmCBWFlags & STORAGE_CMD_DIR_IN) ? STORAGE_EP_IN: STORAGE_EP_OUT)) {
    storage_debugf("response failed");
    return STORAGE_ERR_GENERAL_USB_ERROR;
  }

  command_status_wrapper_t csw;
  uint8_t retry = 3;
  
  do {
    read = sizeof(command_status_wrapper_t);
    info->last_error = storage_in(dev, &(info->ep[STORAGE_EP_IN]), &read, (uint8_t*)&csw);

    if((ret = handle_usb_error(dev, STORAGE_EP_IN))) {
      storage_debugf("command status read failed");
      return ret;
    }
    
    retry--;
  } while(ret && retry);
  
  //  storage_debugf("status = %d:", csw.bCSWStatus);
  //  hexdump(&csw, sizeof(csw), 0);

  if(ret) iprintf("still error\n");

  return csw.bCSWStatus;
}

static uint8_t scsi_command_in(usb_device_t *dev, uint8_t lun, uint16_t bsize, uint8_t *buf,
			       uint8_t cmd, uint8_t cblen) {
  uint8_t i;
  command_block_wrapper_t cbw; 

  memset(&cbw, 0, sizeof(cbw));
	
  cbw.dCBWSignature		= STORAGE_CBW_SIGNATURE;
  cbw.dCBWTag			= 0xdeadbeef;
  cbw.dCBWDataTransferLength	= bsize;
  cbw.bmCBWFlags		= STORAGE_CMD_DIR_IN;
  cbw.bmCBWLUN			= lun;
  cbw.bmCBWCBLength		= cblen;

  cbw.CBWCB[0] = cmd;
  cbw.CBWCB[4] = bsize;

  return transaction(dev, &cbw, bsize, buf);
}

static uint8_t inquiry(usb_device_t *dev, uint8_t lun, inquiry_response_t *buf) {
  return scsi_command_in(dev, lun, sizeof(inquiry_response_t), (uint8_t*)buf, SCSI_CMD_INQUIRY, 6);
}

static uint8_t request_sense(usb_device_t *dev, uint8_t lun, request_sense_response_t *buf) {
  return scsi_command_in(dev, lun, sizeof(request_sense_response_t), (uint8_t*)buf, SCSI_CMD_REQUEST_SENSE, 6);
}

static uint8_t read_capacity(usb_device_t *dev, uint8_t lun, read_capacity_response_t *buf) {
  return scsi_command_in(dev, lun, sizeof(read_capacity_response_t), (uint8_t*)buf, SCSI_CMD_READ_CAPACITY_10, 10);
}

static uint8_t test_unit_ready(usb_device_t *dev, uint8_t lun) {
  //  return scsi_command_out(dev, lun, 0, NULL, SCSI_CMD_TEST_UNIT_READY, 6);
}

static uint8_t read(usb_device_t *dev, uint8_t lun, 
		    uint32_t addr, uint16_t bsize, char *buf) {
  command_block_wrapper_t cbw; 
  uint8_t i;
  
  bzero(&cbw, sizeof(cbw));

  cbw.dCBWSignature             = STORAGE_CBW_SIGNATURE;
  cbw.dCBWTag                   = 0xdeadbeef;
  cbw.dCBWDataTransferLength    = bsize;
  cbw.bmCBWFlags                = STORAGE_CMD_DIR_IN;
  cbw.bmCBWLUN                  = lun;
  cbw.bmCBWCBLength             = 10;

  cbw.CBWCB[0] = SCSI_CMD_READ_10;
  cbw.CBWCB[8] = 1;
  cbw.CBWCB[5] = (addr & 0xff);
  cbw.CBWCB[4] = ((addr >> 8) & 0xff);
  cbw.CBWCB[3] = ((addr >> 16) & 0xff);
  cbw.CBWCB[2] = ((addr >> 24) & 0xff);
  
  return transaction(dev, &cbw, bsize, buf);
}

static uint8_t write(usb_device_t *dev, uint8_t lun, 
		    uint32_t addr, uint16_t bsize, char *buf) {
  command_block_wrapper_t cbw; 
  uint8_t i;
  
  bzero(&cbw, sizeof(cbw));

  cbw.dCBWSignature             = STORAGE_CBW_SIGNATURE;
  cbw.dCBWTag                   = 0xdeadbeef;
  cbw.dCBWDataTransferLength    = bsize;
  cbw.bmCBWFlags                = STORAGE_CMD_DIR_OUT;
  cbw.bmCBWLUN                  = lun;
  cbw.bmCBWCBLength             = 10;

  cbw.CBWCB[0] = SCSI_CMD_WRITE_10;
  cbw.CBWCB[8] = 1;
  cbw.CBWCB[5] = (addr & 0xff);
  cbw.CBWCB[4] = ((addr >> 8) & 0xff);
  cbw.CBWCB[3] = ((addr >> 16) & 0xff);
  cbw.CBWCB[2] = ((addr >> 24) & 0xff);
  
  return transaction(dev, &cbw, bsize, buf);
}

static uint8_t usb_storage_init(usb_device_t *dev) {
  usb_storage_info_t *info = &(dev->storage_info);
  uint8_t i, rcode = 0;

  for(i=0;i<2;i++)
    info->ep[i].epAddr = 0;

  info->state = 0;

  storage_debugf("%s(%d)", __FUNCTION__, dev->bAddress);

  union {
    usb_device_descriptor_t dev_desc;
    usb_configuration_descriptor_t conf_desc;
    inquiry_response_t inquiry_rsp;
    read_capacity_response_t read_cap_rsp;
    uint8_t data[12];
  } buf;

  // read full device descriptor 
  rcode = usb_get_dev_descr( dev, sizeof(usb_device_descriptor_t), &buf.dev_desc );
  if( rcode ) {
    storage_debugf("failed to get device descriptor");
    return rcode;
  }

  if((buf.dev_desc.bDeviceClass != USB_CLASS_USE_CLASS_INFO) && 
     (buf.dev_desc.bDeviceClass != USB_CLASS_MASS_STORAGE)) {
    storage_debugf("Unsupported device class %x", buf.dev_desc.bDeviceClass);
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }

  uint8_t num_of_conf = buf.dev_desc.bNumConfigurations;
  storage_debugf("number of configurations: %d", num_of_conf);

  // scan all configurations for a usable one
  int8_t good_conf = -1;
  for(i=0; (i < num_of_conf)&&(good_conf == -1); i++) {
    if(rcode = usb_get_conf_descr(dev, sizeof(usb_configuration_descriptor_t), i, &buf.conf_desc)) 
      return rcode;
    
    storage_debugf("conf descriptor %d has total size %d", i, buf.conf_desc.wTotalLength);

    // parse directly if it already fitted completely into the buffer
    if((rcode = storage_parse_conf(dev, i, buf.conf_desc.wTotalLength)) == 0)
      good_conf = buf.conf_desc.bConfigurationValue;
    else
      storage_debugf("parse conf failed");
  }

  if(!good_conf) {
    storage_debugf("no good configuration");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }

  // Set Configuration Value
  storage_debugf("good conf = %d", good_conf);
  rcode = usb_set_conf(dev, good_conf);

  mass_storage_reset(dev);

  // found a usb mass storage device. now try to talk to it
  rcode = get_max_lun(dev, &info->max_lun);
  if(rcode == 0)
    storage_debugf("Max lun: %d", info->max_lun);

  // request basic infos ...
  rcode = inquiry(dev, 0, &buf.inquiry_rsp);
  if(rcode) {
    storage_debugf("Inquiry failed");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }

  iprintf("STORAGE: Vendor:    %.8s\n", buf.inquiry_rsp.VendorID);
  iprintf("STORAGE: Product:   %.16s\n", buf.inquiry_rsp.ProductID);
  iprintf("STORAGE: Rev:       %.4s\n", buf.inquiry_rsp.RevisionID);
  iprintf("STORAGE: Removable: %s\n", buf.inquiry_rsp.Removable?"yes":"no");

  rcode = read_capacity(dev, 0, &buf.read_cap_rsp);
  if(rcode) {
    storage_debugf("Read capacity failed");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }

  info->capacity = swap32(buf.read_cap_rsp.dwBlockAddress);
  iprintf("STORAGE: Capacity:     %ld blocks\n", info->capacity);
  iprintf("STORAGE: Block length: %ld bytes\n", swap32(buf.read_cap_rsp.dwBlockLength));

  if(swap32(buf.read_cap_rsp.dwBlockLength) != 512) {
    storage_debugf("Sector size != 512");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }

  storage_devices++;
  storage_debugf("supported device, total USB storage devices now %d", storage_devices);

  // this device has just been setup
  info->state = 1;
  info->qNextPollTime = timer_get_msec() + 1000;
  //  info->qNextTimer = timer_get_msec() + 100; // ready after 1 sek

  //   iprintf("Test unit ready returns: %d\n", test_unit_ready(dev, 0));

  return 0;
}

static uint8_t usb_storage_release(usb_device_t *dev) {
  storage_debugf("%s()", __FUNCTION__);
  storage_devices--;

  return 0;
}

static uint8_t usb_storage_poll(usb_device_t *dev) {
  usb_storage_info_t *info = &(dev->storage_info);
  uint8_t rcode = 0;

#if 0
  if (info->qNextPollTime <= timer_get_msec()) {
    if(info->state == 1) {
      char b[512];
      iprintf("r 5831435\n");
      usb_storage_read(5831435, b);
      iprintf("w 5831435\n");
      usb_storage_write(5831435, b);
      iprintf("w 5831435\n");
      usb_storage_write(5831435, b);
      iprintf("w 5831435\n");
      usb_storage_write(5831435, b);

      //      fat_switch_to_usb();  // redirect file io to usb
      info->state = 2;
    }
  }
#endif

  return rcode;
}

unsigned char usb_storage_read(unsigned long lba, unsigned char *pReadBuffer) {
  uint8_t i, rcode = 0;
  usb_device_t *devs = usb_get_devices(), *dev = NULL;

  // find first storage device
  for (i=0; i<USB_NUMDEVICES; i++) 
    if(devs[i].bAddress && (devs[i].class == &usb_storage_class)) 
      dev = devs+i;

  if(!dev) return 0;

  if(lba >= dev->storage_info.capacity) {
    storage_debugf("exceed device limits");
    return 0;
  }

  //   iprintf("USB Read %d\n", lba);

  rcode = read(dev, 0, lba, 512, pReadBuffer);
  if(rcode) {
    storage_debugf("Read sector %d failed", lba);
    return 0;
  }
  return 1;
}

unsigned char usb_storage_write(unsigned long lba, unsigned char *pWriteBuffer) {
  uint8_t i, rcode = 0;
  usb_device_t *devs = usb_get_devices(), *dev = NULL;

  // find first storage device
  for (i=0; i<USB_NUMDEVICES; i++) 
    if(devs[i].bAddress && (devs[i].class == &usb_storage_class)) 
      dev = devs+i;

  if(!dev) return 0;

  if(lba >= dev->storage_info.capacity) {
    storage_debugf("exceed device limits");
    return 0;
  }

  //  iprintf("USB Write %d\n", lba);
  rcode = write(dev, 0, lba, 512, pWriteBuffer);
  if(rcode) {
    storage_debugf("Write sector %d failed", lba);
    return 0;
  }
  
  return 1;
}

const usb_device_class_config_t usb_storage_class = {
  usb_storage_init, usb_storage_release, usb_storage_poll };  
