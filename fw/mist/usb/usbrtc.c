//
// usbrtc.c
//
// driver for rtc ds1307 chip connected via i2c-tiny-usb
//

#include <stdio.h>
#include <string.h>  // for memcpy

#include "debug.h"
#include "usb.h"
#include "usbrtc.h"

#define I2C_M_RD                0x01

/* commands via USB, must e.g. match command ids firmware */
#define CMD_ECHO       0
#define CMD_GET_FUNC   1
#define CMD_SET_DELAY  2
#define CMD_GET_STATUS 3
#define CMD_I2C_IO     4
#define CMD_I2C_BEGIN  1  // flag to I2C_IO
#define CMD_I2C_END    2  // flag to I2C_IO

#define STATUS_IDLE          0
#define STATUS_ADDRESS_ACK   1
#define STATUS_ADDRESS_NAK   2

#define DS1307_ADDR    0x68

#define USB_VENDOR_REQ_OUT   USB_SETUP_HOST_TO_DEVICE|USB_SETUP_TYPE_VENDOR|USB_SETUP_RECIPIENT_DEVICE
#define USB_VENDOR_REQ_IN    USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_VENDOR|USB_SETUP_RECIPIENT_DEVICE

/* write a set of bytes to the i2c_tiny_usb device */
static uint8_t i2c_tiny_usb_write(usb_device_t *dev, uint8_t cmd, uint16_t value, uint16_t index) {
  return(usb_ctrl_req( dev, USB_VENDOR_REQ_OUT, cmd, value&0xff, value>>8, index, 0, NULL));
}

static uint8_t i2c_tiny_usb_read(usb_device_t *dev, uint8_t cmd, void *data, uint8_t len) {
  return(usb_ctrl_req( dev, USB_VENDOR_REQ_IN, cmd, 0, 0, 0, len, data));
}

/* get i2c usb interface firmware version */
static uint32_t i2c_tiny_usb_get_func(usb_device_t *dev) {
  uint32_t func;
  
  if(i2c_tiny_usb_read(dev, CMD_GET_FUNC, &func, sizeof(func)) == 0)
    return func;

  return 0;
}

/* get the current transaction status from the i2c_tiny_usb interface */
static uint8_t i2c_tiny_usb_get_status(usb_device_t *dev) {
  uint8_t status;
  
  if(i2c_tiny_usb_read(dev, CMD_GET_STATUS, &status, sizeof(status)) != 0) {
    usbrtc_debugf("%s failed", __FUNCTION__);
    return 0xff;
  }
  
  return status;
}

static uint8_t i2c_tiny_usb_probe(usb_device_t *dev, uint8_t addr) {
  if(usb_ctrl_req( dev, USB_VENDOR_REQ_IN, CMD_I2C_IO + CMD_I2C_BEGIN + CMD_I2C_END, 0, 0, addr, 0, NULL) != 0) {
    usbrtc_debugf("%s failed", __FUNCTION__);
    return 0;
  } 
  
  return(i2c_tiny_usb_get_status(dev) == STATUS_ADDRESS_ACK);
}

/* write command and read an 8 or 16 bit value from the given chip */
static uint8_t i2c_read_with_cmd(usb_device_t *dev, uint8_t addr, uint8_t cmd, void *data, uint8_t length) {
  /* write one byte register address to chip */
  if(usb_ctrl_req(dev, USB_VENDOR_REQ_OUT, 
		  CMD_I2C_IO + CMD_I2C_BEGIN + ((!length)?CMD_I2C_END:0),
		  0, 0, addr, 1, &cmd) != 0) {
    usbrtc_debugf("%s addr out failed", __FUNCTION__);
    return 0;
  } 

  if(i2c_tiny_usb_get_status(dev) != STATUS_ADDRESS_ACK) {
    usbrtc_debugf("%s write command status failed", __FUNCTION__);
    return 0;
  }

  if(usb_ctrl_req(dev, USB_VENDOR_REQ_IN,
		  CMD_I2C_IO + CMD_I2C_END,
		  I2C_M_RD, 0, addr, length, (char*)data) != 0) {
    usbrtc_debugf("%s data in failed", __FUNCTION__);
    return 0;
  } 
  
  if(i2c_tiny_usb_get_status(dev) != STATUS_ADDRESS_ACK) {
    usbrtc_debugf("%s read command status failed", __FUNCTION__);
    return 0;
  }

  return 1;
}

/* write a command byte and a 16 bit value to the i2c client */
static uint8_t i2c_write_cmd_and_data(usb_device_t *dev, uint8_t addr, uint8_t cmd, void *data, uint8_t length) {
  char msg[length+1];

  // copy command and message into one local buffer
  msg[0] = cmd;
  memcpy(msg+1, data, length);

  /* write one byte register address to chip */
  if(usb_ctrl_req(dev, USB_VENDOR_REQ_OUT,  
		  CMD_I2C_IO + CMD_I2C_BEGIN + CMD_I2C_END,
		  0, 0, addr, length+1, msg) != 0) {
    usbrtc_debugf("%s msg out failed", __FUNCTION__);
    return 0;
  } 

  if(i2c_tiny_usb_get_status(dev) != STATUS_ADDRESS_ACK) {
    usbrtc_debugf("%s write command status failed", __FUNCTION__);
    return 0;
  }

  return 1;  
}

struct timeS {
  uint8_t sec_bcd;
  uint8_t min_bcd;
  uint8_t hour_bcd:6;
  uint8_t mode12:1;
  uint8_t dummy:1;
  uint8_t day;
  uint8_t date_bcd;
  uint8_t month_bcd;
  uint8_t year_bcd;
} __attribute__ ((packed));

static uint8_t usb_rtc_init(usb_device_t *dev) {
  usb_usbrtc_info_t *info = &(dev->usbrtc_info);
  uint8_t i, rcode = 0;

  usbrtc_debugf("%s(%d)", __FUNCTION__, dev->bAddress);

  union {
    usb_device_descriptor_t dev_desc;
    usb_configuration_descriptor_t conf_desc;
    struct timeS time;
  } buf;

  // read full device descriptor 
  rcode = usb_get_dev_descr( dev, sizeof(usb_device_descriptor_t), &buf.dev_desc );
  if( rcode ) {
    usbrtc_debugf("failed to get device descriptor");
    return rcode;
  }

  // If device class is not vendor specific return
  if (buf.dev_desc.bDeviceClass != USB_CLASS_VENDOR_SPECIFIC)
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
 
  usbrtc_debugf("vid/pid = %x/%x", buf.dev_desc.idVendor, buf.dev_desc.idProduct);

  if((buf.dev_desc.idVendor != 0x0403) || (buf.dev_desc.idProduct != 0xc631)) {
    usbrtc_debugf("Not a i2c-tiny-usb device");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }
  
  // Set Configuration Value
  rcode = usb_set_conf(dev, buf.conf_desc.bConfigurationValue);
  
  // probe for rtc
  if(!i2c_tiny_usb_probe(dev, DS1307_ADDR)) {
    usbrtc_debugf("No DS1307 rtc detected");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }

  if(!i2c_read_with_cmd(dev, DS1307_ADDR, 0, &buf.time, sizeof(struct timeS))) {
    usbrtc_debugf("Error reading time");
    return USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED;
  }

  if(buf.time.mode12)
    usbrtc_debugf("Warning, clock in AM/PM mode");

  iprintf("time: %02x:%02x:%02x\n", buf.time.hour_bcd, buf.time.min_bcd, buf.time.sec_bcd);
  iprintf("date: %02x.%02x.%02x\n", buf.time.date_bcd, buf.time.month_bcd, buf.time.year_bcd);

  return 0;
}

static uint8_t usb_rtc_release(usb_device_t *dev) {
  usbrtc_debugf("%s()", __FUNCTION__);
  return 0;
}

static uint8_t bcd2bin(uint8_t in) {
  return 10*(in >> 4) + (in & 0x0f);
}

static uint8_t bin2bcd(int8_t in) {
  return 16*(in/10) + (in % 10);
}

uint8_t usb_rtc_get_time(uint8_t *d) {
  uint8_t i;
  usb_device_t *devs = usb_get_devices(), *dev = NULL;

  // find first rtc device
  for (i=0; i<USB_NUMDEVICES; i++) 
    if(devs[i].bAddress && (devs[i].class == &usb_usbrtc_class)) 
      dev = devs+i;
  
  if(!dev) return 0;

  struct timeS time;
  if(!i2c_read_with_cmd(dev, DS1307_ADDR, 0, &time, sizeof(struct timeS))) {
    usbrtc_debugf("Error reading time");
    return 0;
  }
  
  // only set time if rtc is in 24h mode
  if(time.mode12) return 0;

  // copy time/date into target array
  d[0] = bcd2bin(time.year_bcd) + 100;
  d[1] = bcd2bin(time.month_bcd);
  d[2] = bcd2bin(time.date_bcd);
  d[3] = bcd2bin(time.hour_bcd);
  d[4] = bcd2bin(time.min_bcd);
  d[5] = bcd2bin(time.sec_bcd);

  return 1;
}

uint8_t usb_rtc_set_time(uint8_t *d) {
  uint8_t i;
  usb_device_t *devs = usb_get_devices(), *dev = NULL;

  // find first rtc device
  for (i=0; i<USB_NUMDEVICES; i++) 
    if(devs[i].bAddress && (devs[i].class == &usb_usbrtc_class)) 
      dev = devs+i;
  
  if(!dev) return 0;

  // fill ds1307 time structure
  struct timeS time;
  time.dummy = 0;
  time.mode12 = 0;   // 24h mode
  time.year_bcd = bin2bcd(d[0] - 100);
  time.month_bcd = bin2bcd(d[1]);
  time.date_bcd = bin2bcd(d[2]);
  time.hour_bcd = bin2bcd(d[3]);
  time.min_bcd = bin2bcd(d[4]);
  time.sec_bcd = bin2bcd(d[5]);

  if(!i2c_write_cmd_and_data(dev, DS1307_ADDR, 0, &time, sizeof(struct timeS))) {
    usbrtc_debugf("Error writing time");
    return 0;
  }
  
  return 1;
}

const usb_device_class_config_t usb_usbrtc_class = {
  usb_rtc_init, usb_rtc_release, NULL };  
