#ifndef HID_H
#define HID_H

#include <stdbool.h>
#include <inttypes.h>
#include "hidparser.h"

#define HID_LED_NUM_LOCK    0x01
#define HID_LED_CAPS_LOCK   0x02
#define HID_LED_SCROLL_LOCK 0x04

/* HID constants. Not part of chapter 9 */
/* Class-Specific Requests */
#define HID_REQUEST_GET_REPORT      0x01
#define HID_REQUEST_GET_IDLE        0x02
#define HID_REQUEST_GET_PROTOCOL    0x03
#define HID_REQUEST_SET_REPORT      0x09
#define HID_REQUEST_SET_IDLE        0x0A
#define HID_REQUEST_SET_PROTOCOL    0x0B

#define HID_DESCRIPTOR_HID		0x21
#define HID_DESCRIPTOR_REPORT		0x22
#define HID_DESRIPTOR_PHY		0x23

/* Protocol Selection */
#define HID_BOOT_PROTOCOL                       0x00
#define HID_RPT_PROTOCOL                        0x01

/* HID Interface Class SubClass Codes */
#define HID_BOOT_INTF_SUBCLASS          0x01

#define HID_PROTOCOL_NONE           0x00
#define HID_PROTOCOL_KEYBOARD       0x01
#define HID_PROTOCOL_MOUSE          0x02

#define HID_REQ_HIDREPORT     USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_STANDARD|USB_SETUP_RECIPIENT_INTERFACE
#define HID_REQ_HIDOUT        USB_SETUP_HOST_TO_DEVICE|USB_SETUP_TYPE_CLASS|USB_SETUP_RECIPIENT_INTERFACE

#define MAX_IFACES  2  // max supported interfaces per device. 2 to support kbd/mouse combos

#define HID_DEVICE_UNKNOWN  0
#define HID_DEVICE_MOUSE    1
#define HID_DEVICE_KEYBOARD 2
#define HID_DEVICE_JOYSTICK 3

typedef struct {
  ep_t ep;    // interrupt endpoint info structure

  uint8_t iface_idx;
  uint16_t report_desc_size;

  uint8_t device_type;
  bool has_boot_mode: 1;     // device supports boot mode
  bool is_5200daptor: 1;     // device is a 5200daptor with special key handling
  uint16_t key_state;        // needed to detect key state changes in 5200daptor
  
  // additional info extracted from the report descriptor
  // (currently only used for joysticks) 
  uint8_t jmap;           // last reported joystick state
  uint8_t jindex;         // joystick index
  hid_config_t conf;

  uint8_t interval;
  uint32_t qNextPollTime;     // next poll time

} usb_hid_iface_info_t;

typedef struct {
  bool	   bPollEnable;	      // poll enable flag
  uint8_t  bNumIfaces;

  usb_hid_iface_info_t iface[MAX_IFACES];
} usb_hid_info_t;

/* HID descriptor */
typedef struct  {
  uint8_t         bLength;
  uint8_t         bDescriptorType;
  uint16_t        bcdHID;                         // HID class specification release
  uint8_t         bCountryCode;
  uint8_t         bNumDescriptors;                // Number of additional class specific descriptors
  uint8_t         bDescrType;                     // Type of class descriptor
  uint8_t         wDescriptorLength[2];           // Total size of the Report descriptor
} __attribute__((packed)) usb_hid_descriptor_t;

// interface to usb core
extern const usb_device_class_config_t usb_hid_class;

void hid_set_kbd_led(unsigned char led, bool on);
uint8_t hid_get_joysticks(void);

#endif // HID_H
