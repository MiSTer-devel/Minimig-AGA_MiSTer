//
// asix.c
//
// http://lxr.free-electrons.com/source/drivers/net/usb/asix.c?v=3.1

#include <stdio.h>
#include <string.h>  // for memcpy

#include "debug.h"
#include "usb.h"
#include "asix.h"
#include "timer.h"
#include "mii.h"
#include "asix_const.h"
#include "max3421e.h"
#include "hardware.h"
#include "tos.h"

#define MAX_FRAMELEN 1536

static unsigned char rx_buf[MAX_FRAMELEN+64];
static uint16_t rx_cnt;

static unsigned char tx_buf[4+MAX_FRAMELEN];
static uint16_t tx_cnt, tx_offset;

static bool eth_present = 0;

// currently only AX88772 is supported as that's the only
// device i have
#define ASIX_TYPE_AX88772 0x01

// list of suppoerted/tested devices
static const struct {
  uint16_t vid;
  uint16_t pid;
  uint8_t type;
} asix_devs[] = {
  // DLink DUB-E100 H/W Ver B1 Alternate
  { 0x2001, 0x3c05, ASIX_TYPE_AX88772 },
  // DLink DUB-E100 H/W Ver C1
  { 0x2001, 0x1a02, ASIX_TYPE_AX88772 },
  // NoName Wii Adapter
  { 0x0b95, 0x7720, ASIX_TYPE_AX88772 },
  { 0, 0, 0 }
};

#define ASIX_REQ_OUT   USB_SETUP_HOST_TO_DEVICE|USB_SETUP_TYPE_VENDOR|USB_SETUP_RECIPIENT_DEVICE
#define ASIX_REQ_IN    USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_VENDOR|USB_SETUP_RECIPIENT_DEVICE

static uint8_t asix_write_cmd(usb_device_t *dev, uint8_t cmd, uint16_t value, uint16_t index,
			      uint16_t size, uint8_t *data) {
  //  asix_debugf("%s() cmd=0x%02x value=0x%04x index=0x%04x size=%d", __FUNCTION__,
  //  	      cmd, value, index, size);

  return(usb_ctrl_req( dev, ASIX_REQ_OUT, cmd, value&0xff, value>>8, index, size, data));
}

static uint8_t asix_read_cmd(usb_device_t  *dev, uint8_t cmd, uint16_t value, uint16_t index,
			     uint16_t size, void *data) {
  //  asix_debugf("asix_read_cmd() cmd=0x%02x value=0x%04x index=0x%04x size=%d",
  //  	      cmd, value, index, size);
 
  return(usb_ctrl_req( dev, ASIX_REQ_IN, cmd, value&0xff, value>>8, index, size, data));
}

static uint8_t asix_write_gpio(usb_device_t *dev, uint16_t value, uint16_t sleep) {
  uint8_t rcode;
  
  asix_debugf("%s() value=0x%04x sleep=%d", __FUNCTION__, value, sleep);

  rcode = asix_write_cmd(dev, AX_CMD_WRITE_GPIOS, value, 0, 0, NULL);
  if(rcode) asix_debugf("Failed to write GPIO value 0x%04x: %02x\n", value, rcode);

  if (sleep) timer_delay_msec(sleep);
  
  return rcode;
}

static uint8_t asix_write_medium_mode(usb_device_t *dev, uint16_t mode) {
  uint8_t rcode;
 
  asix_debugf("asix_write_medium_mode() - mode = 0x%04x", mode);
  rcode = asix_write_cmd(dev, AX_CMD_WRITE_MEDIUM_MODE, mode, 0, 0, NULL);
  if(rcode != 0)
    asix_debugf("Failed to write Medium Mode mode to 0x%04x: %02x", mode, rcode);

  return rcode;
}

static uint16_t asix_read_medium_status(usb_device_t *dev) {
  uint16_t v;
  
  uint8_t rcode = asix_read_cmd(dev, AX_CMD_READ_MEDIUM_STATUS, 0, 0, 2, (uint8_t*)&v);
  if (rcode != 0) {
    asix_debugf("Error reading Medium Status register: %02x", rcode);
    return rcode;
  }
  return v;
}

static inline uint8_t asix_set_sw_mii(usb_device_t *dev) {
  uint8_t rcode = asix_write_cmd(dev, AX_CMD_SET_SW_MII, 0x0000, 0, 0, NULL);
  if(rcode != 0)
    asix_debugf("Failed to enable software MII access");

  return rcode;
}

static inline uint8_t asix_set_hw_mii(usb_device_t *dev) {
  uint8_t rcode = asix_write_cmd(dev, AX_CMD_SET_HW_MII, 0x0000, 0, 0, NULL);
  if(rcode != 0)
    asix_debugf("Failed to enable hardware MII access");

  return rcode;
}

static inline int8_t asix_get_phy_addr(usb_device_t *dev) {
  uint8_t buf[2];

  uint8_t ret = asix_read_cmd(dev, AX_CMD_READ_PHY_ID, 0, 0, sizeof(buf), &buf);
  
  asix_debugf("%s()", __FUNCTION__);
 
  if (ret != 0) {
    asix_debugf("Error reading PHYID register: %02x", ret);
    return ret;
  }

  asix_debugf("returning 0x%02x%02x", buf[1], buf[0]);

  return buf[1];
}

static uint16_t asix_mdio_read(usb_device_t *dev, uint8_t phy_id, uint8_t loc) {
  uint16_t res;

  asix_set_sw_mii(dev);
  asix_read_cmd(dev, AX_CMD_READ_MII_REG, phy_id, loc, 2, &res);
  asix_set_hw_mii(dev);

  asix_debugf("asix_mdio_read() phy_id=0x%02x, loc=0x%02x, returns=0x%04x", phy_id, loc, res);
  return res;
}

static void asix_mdio_write(usb_device_t *dev, uint8_t phy_id, uint8_t loc, uint16_t val) {
  asix_debugf("asix_mdio_write() phy_id=0x%02x, loc=0x%02x, val=0x%04x", phy_id, loc, val);

  asix_set_sw_mii(dev);
  asix_write_cmd(dev, AX_CMD_WRITE_MII_REG, phy_id, loc, 2, (uint8_t*)&val);
  asix_set_hw_mii(dev);
}

#if 1
/* Get the PHY Identifier from the PHYSID1 & PHYSID2 MII registers */
static uint32_t asix_get_phyid(usb_device_t *dev) {
  usb_asix_info_t *info = &(dev->asix_info);

  int16_t phy_reg;
  uint32_t phy_id;
 
  phy_reg = asix_mdio_read(dev, info->phy_id, MII_PHYSID1);
  if(phy_reg < 0) return 0;

  phy_id = (phy_reg & 0xffff) << 16;
  phy_reg = asix_mdio_read(dev, info->phy_id, MII_PHYSID2);
  if(phy_reg < 0) return 0;

  phy_id |= (phy_reg & 0xffff);
  return phy_id;
}
#else
/* Get the PHY Identifier from the PHYSID1 & PHYSID2 MII registers */
static uint32_t asix_get_phyid(usb_device_t *dev) {
  usb_asix_info_t *info = &(dev->asix_info);
  int16_t phy_reg;
  uint32_t phy_id;
  int i;

  /* Poll for the rare case the FW or phy isn't ready yet.  */
  for (i = 0; i < 100; i++) {
    phy_reg = asix_mdio_read(dev, info->phy_id, MII_PHYSID1);
    if (phy_reg != 0 && phy_reg != 0xFFFF)
      break;
    timer_delay_msec(1);
  }

  if (phy_reg <= 0 || phy_reg == 0xFFFF)
    return 0;

  phy_id = (phy_reg & 0xffff) << 16;
  
  phy_reg = asix_mdio_read(dev, info->phy_id, MII_PHYSID2);
  if (phy_reg < 0)
    return 0;
  
  phy_id |= (phy_reg & 0xffff);
  
  return phy_id;
}
#endif

static uint8_t asix_sw_reset(usb_device_t *dev, uint8_t flags) {
  uint8_t rcode;
  
  rcode = asix_write_cmd(dev, AX_CMD_SW_RESET, flags, 0, 0, NULL);
  if (rcode != 0)
    asix_debugf("Failed to send software reset: %02x", rcode);
  else
    timer_delay_msec(150);

  return rcode;
}
 
static uint16_t asix_read_rx_ctl(usb_device_t *dev) {
  // this only works on little endian which the arm is
  uint16_t v;
  uint8_t rcode = asix_read_cmd(dev, AX_CMD_READ_RX_CTL, 0, 0, 2, &v);
  if(rcode != 0) {
    asix_debugf("Error reading RX_CTL register: %02x", rcode);
    return rcode;
  }

  return v;
}

static uint16_t asix_write_rx_ctl(usb_device_t *dev, uint16_t mode) {
  uint8_t rcode = asix_write_cmd(dev, AX_CMD_WRITE_RX_CTL, mode, 0, 0, NULL);
  if(rcode != 0)
    asix_debugf("Error writing RX_CTL register: %02x", rcode);

  return rcode;
}

/**
 * mii_nway_restart - restart NWay (autonegotiation) for this interface
 * @mii: the MII interface
 *
 * Returns 0 on success, negative on error.
 */
void mii_nway_restart(usb_device_t *dev) {
  usb_asix_info_t *info = &(dev->asix_info);

  /* if autoneg is off, it's an error */
  uint16_t bmcr = asix_mdio_read(dev, info->phy_id, MII_BMCR);
  if(bmcr & BMCR_ANENABLE) {
    bmcr |= BMCR_ANRESTART;
    asix_mdio_write(dev, info->phy_id, MII_BMCR, bmcr);
  } else
    asix_debugf("%s() failed", __FUNCTION__);
}

static uint8_t asix_parse_conf(usb_device_t *dev, uint8_t conf, uint16_t len) {
  usb_asix_info_t *info = &(dev->asix_info);
  uint8_t rcode;
  uint8_t epidx = 0;

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
    if(p->conf_desc.bDescriptorType == USB_DESCRIPTOR_ENDPOINT) {
      if(epidx < 3) {
	
	// Handle interrupt endpoints
	if ((p->ep_desc.bmAttributes & 0x03) == 3 && 
	    (p->ep_desc.bEndpointAddress & 0x80) == 0x80) {
	  asix_debugf("irq endpoint %d, interval = %dms", 
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
	  asix_debugf("bulk in endpoint %d", p->ep_desc.bEndpointAddress & 0x0F);
	}

	if ((p->ep_desc.bmAttributes & 0x03) == 2 && 
	    (p->ep_desc.bEndpointAddress & 0x80) == 0x00) {
	  asix_debugf("bulk out endpoint %d", p->ep_desc.bEndpointAddress & 0x0F);
	}
	
	// Fill in the endpoint info structure
	info->ep[epidx].epAddr	 = (p->ep_desc.bEndpointAddress & 0x0F);
	info->ep[epidx].maxPktSize = p->ep_desc.wMaxPacketSize[0];
	info->ep[epidx].epAttribs	 = 0;
	info->ep[epidx].bmNakPower = USB_NAK_NOWAIT;
	epidx++;
      }
    }
    
    // advance to next descriptor
    len -= p->conf_desc.bLength;
    p = (union buf_u*)(p->raw + p->conf_desc.bLength);
  }
  
  if(len != 0) {
    asix_debugf("Config underrun: %d\n", len);
    return USB_ERROR_CONFIGURAION_SIZE_MISMATCH;
  }

  return 0;
}

static uint8_t usb_asix_init(usb_device_t *dev) {
  usb_asix_info_t *info = &(dev->asix_info);
  uint8_t i, rcode = 0;

  // only one ethernet dongle is supported at a time
  if(eth_present)
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;

  // reset status
  info->qNextIrqPollTime = info->qNextBulkPollTime = 0;
  info->bPollEnable = false;
  info->linkDetected = false;

  for(i=0;i<3;i++) {
    info->ep[i].epAddr	   = 1;
    info->ep[i].maxPktSize = 8;
    info->ep[i].epAttribs  = 0;
    info->ep[i].bmNakPower = USB_NAK_NOWAIT;
  }

  asix_debugf("%s(%d)", __FUNCTION__, dev->bAddress);

  union {
    usb_device_descriptor_t dev_desc;
    usb_configuration_descriptor_t conf_desc;
  } buf;

  // read full device descriptor 
  rcode = usb_get_dev_descr( dev, sizeof(usb_device_descriptor_t), &buf.dev_desc );
  if( rcode ) {
    asix_debugf("failed to get device descriptor");
    return rcode;
  }

  // If device class is not vendor specific return
  if (buf.dev_desc.bDeviceClass != USB_CLASS_VENDOR_SPECIFIC)
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
 
  asix_debugf("vid/pid = %x/%x", buf.dev_desc.idVendor, buf.dev_desc.idProduct);

  // search for vid/pid in supported device list
  for(i=0;asix_devs[i].type && 
	((asix_devs[i].vid != buf.dev_desc.idVendor) || 
	 (asix_devs[i].pid != buf.dev_desc.idProduct));i++);

  if(!asix_devs[i].type) {
    asix_debugf("Not a supported ASIX device");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }
    
  // Set Configuration Value
  //  iprintf("conf value = %d\n", buf.conf_desc.bConfigurationValue);
  rcode = usb_set_conf(dev, buf.conf_desc.bConfigurationValue);
  
  uint8_t num_of_conf = buf.dev_desc.bNumConfigurations;
  //  iprintf("number of configurations: %d\n", num_of_conf);

  for(i=0; i<num_of_conf; i++) {
    if(rcode = usb_get_conf_descr(dev, sizeof(usb_configuration_descriptor_t), i, &buf.conf_desc)) 
      return rcode;
    
    //    iprintf("conf descriptor %d has total size %d\n", i, buf.conf_desc.wTotalLength);

    // extract number of interfaces
    //    iprintf("number of interfaces: %d\n", buf.conf_desc.bNumInterfaces);
    
    // parse directly if it already fitted completely into the buffer
    if((rcode = asix_parse_conf(dev, i, buf.conf_desc.wTotalLength)) != 0) {
      asix_debugf("parse conf failed");
      return rcode;
    }
  }

  asix_debugf("supported device");

  if ((rcode = asix_write_gpio(dev, AX_GPIO_RSE | AX_GPIO_GPO_2 | AX_GPIO_GPO2EN, 5)) < 0) {
    asix_debugf("GPIO write failed");
    return rcode;
  }
    
  /* 0x10 is the phy id of the embedded 10/100 ethernet phy */
  int8_t embd_phy = ((asix_get_phy_addr(dev) & 0x1f) == 0x10 ? 1 : 0);
  asix_debugf("embedded phy = %d", embd_phy);
  if((rcode = asix_write_cmd(dev, AX_CMD_SW_PHY_SELECT, embd_phy, 0, 0, NULL)) != 0) {
    asix_debugf("Select PHY #1 failed");
    return rcode;
  }

  if ((rcode = asix_sw_reset(dev, AX_SWRESET_IPPD | AX_SWRESET_PRL)) != 0) {
    asix_debugf("reset(AX_SWRESET_IPPD | AX_SWRESET_PRL) failed");
    return rcode;
  }

  if ((rcode = asix_sw_reset(dev, AX_SWRESET_CLEAR)) != 0) {
    asix_debugf("reset(AX_SWRESET_CLEAR) failed");
    return rcode;
  }

  if ((rcode = asix_sw_reset(dev, embd_phy?AX_SWRESET_IPRL:AX_SWRESET_PRTE)) != 0) {
    asix_debugf("reset(AX_SWRESET_IPRL/PRTE) failed");
    return rcode;
  }

  uint16_t rx_ctl = asix_read_rx_ctl(dev);
  asix_debugf("RX_CTL is 0x%04x after software reset", rx_ctl);

  if((rcode = asix_write_rx_ctl(dev, 0x0000)) != 0) {
    asix_debugf("write_rx_ctl(0) failed");
    return rcode;
  }

  rx_ctl = asix_read_rx_ctl(dev);
  asix_debugf("RX_CTL is 0x%04x setting to 0x0000", rx_ctl);

  /* Get the MAC address */
  if ((rcode = asix_read_cmd(dev, AX_CMD_READ_NODE_ID,
			   0, 0, ETH_ALEN, info->mac)) != 0) {
    asix_debugf("Failed to read MAC address: %d", rcode);
    return rcode;
  }

  iprintf("ASIX: MAC %02x:%02x:%02x:%02x:%02x:%02x\n", 
	  info->mac[0], info->mac[1], info->mac[2], 
	  info->mac[3], info->mac[4], info->mac[5]); 

  // tell fpga about the mac address
  user_io_eth_send_mac(info->mac);

  info->phy_id = asix_get_phy_addr(dev);

  uint32_t phyid = asix_get_phyid(dev);
  iprintf("ASIX: PHYID=0x%08x\n", phyid);

  if ((rcode = asix_sw_reset(dev, AX_SWRESET_PRL)) != 0) {
    asix_debugf("reset(AX_SWRESET_PRL) failed");
    return rcode;
  }
  
  if ((rcode = asix_sw_reset(dev, AX_SWRESET_IPRL | AX_SWRESET_PRL)) != 0) {
    asix_debugf("reset(AX_SWRESET_IPRL | AX_SWRESET_PRL) failed");
    return rcode;
  }
  
  asix_mdio_write(dev, info->phy_id, MII_BMCR, BMCR_RESET);
  asix_mdio_write(dev, info->phy_id, MII_ADVERTISE, ADVERTISE_ALL | ADVERTISE_CSMA);

  mii_nway_restart(dev);

  if ((rcode = asix_write_medium_mode(dev, AX88772_MEDIUM_DEFAULT)) != 0) {
    asix_debugf("asix_write_medium_mode(AX88772_MEDIUM_DEFAULT) failed\n");
    return rcode;
  }

  if ((rcode = asix_write_cmd(dev, AX_CMD_WRITE_IPG0,
			      AX88772_IPG0_DEFAULT | AX88772_IPG1_DEFAULT,
			      AX88772_IPG2_DEFAULT, 0, NULL)) != 0) {
    asix_debugf("Write IPG,IPG1,IPG2 failed: %d", rcode);
    return rcode;
  }
 
  /* Set RX_CTL to default values with 2k buffer, and enable cactus */
  if ((rcode = asix_write_rx_ctl(dev, AX_DEFAULT_RX_CTL)) != 0)
    return rcode;

  rx_ctl = asix_read_rx_ctl(dev);
  asix_debugf("RX_CTL is 0x%04x after all initializations\n", rx_ctl);

  rx_ctl = asix_read_medium_status(dev);
  asix_debugf("Medium Status is 0x%04x after all initializations\n", rx_ctl);

  info->bPollEnable = true;

  rx_cnt = tx_cnt = 0;  // reset buffers

  // finally inform core about ethernet support
  tos_update_sysctrl(tos_system_ctrl() | TOS_CONTROL_ETHERNET);

  eth_present = 1;

  return 0;
}

static uint8_t usb_asix_release(usb_device_t *dev) {
  asix_debugf("%s()", __FUNCTION__);

  // remove/disable ethernet support
  tos_update_sysctrl(tos_system_ctrl() & (~TOS_CONTROL_ETHERNET));
  eth_present = 0;

  return 0;
}

void usb_asix_xmit(uint16_t len) {
  asix_debugf("out %d", len);

  *(uint16_t*)tx_buf = len;
  *(uint16_t*)(tx_buf+2) = ~len;

  tx_cnt = len+4;
  tx_offset = 0;
}

static uint8_t usb_asix_poll(usb_device_t *dev) {
  usb_asix_info_t *info = &(dev->asix_info);
  uint8_t rcode = 0;

  if (!info->bPollEnable)
    return 0;

  // poll interrupt endpoint
  if (info->qNextIrqPollTime <= timer_get_msec()) {
    uint16_t read = info->ep[info->ep_int_idx].maxPktSize;
    uint8_t buf[info->ep[info->ep_int_idx].maxPktSize];
    uint8_t rcode = usb_in_transfer(dev, &(info->ep[info->ep_int_idx]), &read, buf);
    
    if (rcode) {
      if (rcode != hrNAK)
	iprintf("%s() error: %x\n", __FUNCTION__, rcode);
    } else {
      //            iprintf("ASIX: int %d bytes\n", read);
      //            hexdump(buf, read, 0);

      // primary or secondary link detected?
      bool link_detected = ((buf[2] & 3) != 0); 

      if(link_detected != info->linkDetected) {
	if(link_detected) {
	  iprintf("ASIX: Link detected\n");	  
	} else
	  iprintf("ASIX: Link lost\n");
	
	info->linkDetected = link_detected;
      }
    }
    info->qNextIrqPollTime = timer_get_msec() + info->int_poll_ms;
  }

  // Do RX/TX handling at 100Hz
  if (info->qNextBulkPollTime <= timer_get_msec()) {
    uint8_t rcode;
    static uint32_t old_status = 0;
    uint32_t status = user_io_eth_get_status();

    if(status != old_status) {
      asix_debugf("status changed to cmd %x, eq=%d, prx=%d, ptx=%d, len=%d",
		  status >> 24, (status & 0x4000)?1:0, (status & 0x2000)?1:0,
		  (status & 0x1000)?1:0, status & 0xffff);
      old_status = status;
    }
    
    // --------- poll FPGA for data to be transmitted ------------
    
    // no transmission in progress?
    if(!tx_cnt) {
      if((status >> 24) == 0xa5) {
	uint16_t len = status & 0xffff;
	
	if(len <= MAX_FRAMELEN) {
	  //	  iprintf("TX %d\n", len);
	  
	  // read frame into local tx buffer, leave 4 bytes space for
	  // axis packet header marker
	  user_io_eth_receive_tx_frame(tx_buf+4, len);
	  
	  //	  hexdump(tx_buf+4, len, 0);
	  
	  // schedule packet for transmissoin
	  usb_asix_xmit(len);
	}
      }
    }
    
    // check if there's something to transmit
    if(tx_cnt) {
      uint16_t bytes2send = (tx_cnt-tx_offset > info->ep[2].maxPktSize)?
	info->ep[2].maxPktSize:(tx_cnt-tx_offset);
      
      //  asix_debugf("bulk out %d of %d (ep %d), off %d", 
      //      bytes2send, tx_cnt, info->ep[2].maxPktSize, tx_offset);  
      rcode = usb_out_transfer(dev, &(info->ep[2]), bytes2send, tx_buf + tx_offset);
      //      asix_debugf("%s() error: %x", __FUNCTION__, rcode);  

      tx_offset += bytes2send;
      
      // mark buffer as free after last pkt was sent
      if(bytes2send != info->ep[2].maxPktSize)
	tx_cnt = 0;
    }

    // poll for rx if receive irq has been cleared (PRX==0)
    if(!(status & 0x2000)) {
      // Try to read from bulk in endpoint (ep 2). Raw packets are received this way.
      // The last USB packet being part of an ethernet frame is marked by being shorter
      // than the USB FIFO size. If the last packet is exaclty if FIFO size, then an
      // additional 0 byte packet is appended
      uint16_t read = info->ep[1].maxPktSize;
      
      // the rx buffer size (1536+64) can hold an additional maxPktSize (64),
      // so a transfer still fits into the buffer or there's already 
      // a full frame present. If it's full we drop all data. This will leave 
      // the buffered packet incomplete which isn't a problem since
      // the packet was too long, anyway.
      uint8_t *data = (rx_cnt < MAX_FRAMELEN)?(rx_buf + rx_cnt):NULL;
      rcode = usb_in_transfer(dev, &(info->ep[1]), &read, data);
      
      if (rcode) {
	if (rcode != hrNAK)
	  asix_debugf("%s() error: %x", __FUNCTION__, rcode);
      } else {
	rx_cnt += read;

	// check if packet has a valid header
	uint16_t len0 = *(uint16_t*)rx_buf;
	uint16_t len1 = ~(*(uint16_t*)(rx_buf+2));

	if(len0 != len1) {
	  asix_debugf("dropping malformed packet (len %d:%d)\n", len0, len1);
	  rx_cnt = 0;
	} else if(rx_cnt-4 >= len0) {
	  bool ok2fwd = 0;

	  // enough room to store the entire packet

	  // process packet
	  //	  iprintf("RX %d\n", len0);
	  //	  hexdump(rx_buf+4, len0, 0);
	  //	  hexdump(rx_buf+4, 32, 0);

	  uint16_t frame_size = len0;
	  if(frame_size < 64) frame_size = 64;

	  // do some sanity checks on frame
	  //	  iprintf("RX mac = %02x:%02x:%02x:%02x:%02x:%02x\n",
	  //		  rx_buf[4]&0xff,rx_buf[5]&0xff,rx_buf[6]&0xff,
	  //		  rx_buf[7]&0xff,rx_buf[8]&0xff,rx_buf[9]&0xff);

	  /* check for own or braodcast mac */
	  if(!memcmp(rx_buf+4, info->mac, ETH_ALEN)) {
	    //	    iprintf("MY MAC!!\n");
	    ok2fwd = 1;  // forward packet into core
	  }
	  
	  if((rx_buf[4] == 0xff)&&(rx_buf[5] == 0xff)&&(rx_buf[6] == 0xff)&&
	     (rx_buf[7] == 0xff)&&(rx_buf[8] == 0xff)&&(rx_buf[9] == 0xff)) {
	    //	    iprintf("BROADCAST MAC %x/%x\n", rx_buf[16], rx_buf[17]);

	    // accept broadcasts only for arp
	    if((rx_buf[16] == 0x08) && (rx_buf[17] == 0x06))
	      ok2fwd = 1;  // forward packet into core
	  }

	  // forward frame to FPGA
	  if(ok2fwd)
	    user_io_eth_send_rx_frame(rx_buf+4, frame_size);
	  else
	    iprintf("ASIX: frame dropped\n");

	  if((rx_cnt-4 > len0) && (rx_cnt < MAX_FRAMELEN+64)) {
	    // packets are 16 bit padded
	    if(len0 & 1) len0++;
	    
	    // remove len0+4 bytes from buffer
	    memcpy(rx_buf, rx_buf + len0 + 4, MAX_FRAMELEN + 64 - len0 - 4);
	    rx_cnt -= len0 + 4;
	    
	    //	    asix_debugf("bytes left in buffer: %d", rx_cnt);
	  } else
	    rx_cnt = 0;
	}
      }
    }    

    // bulk ep polling at fixed 500Hz
    info->qNextBulkPollTime = timer_get_msec() + 2;
  }

  return rcode;
}

const usb_device_class_config_t usb_asix_class = {
  usb_asix_init, usb_asix_release, usb_asix_poll };  
