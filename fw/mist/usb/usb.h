#ifndef USB_H
#define USB_H

#include <inttypes.h>
#include <stdbool.h>

/* NAK powers. To save space in endpoint data structure, amount of retries */
/* before giving up and returning 0x4 is stored in bmNakPower as a power of 2.*/
/* The actual nak_limit is then calculated as nak_limit = ( 2^bmNakPower - 1) */
#define USB_NAK_MAX_POWER 16	//NAK binary order maximum value
#define USB_NAK_DEFAULT	  14	//default 16K-1 NAKs before giving up
#define USB_NAK_NOWAIT	  1	//Single NAK stops transfer
#define USB_NAK_NONAK	  0	//Do not count NAKs, stop retrying after USB Timeout

typedef struct {
  uint8_t epAddr;	// Endpoint address 
  uint8_t maxPktSize;	// Maximum packet size
  
  union {
    uint8_t epAttribs;
    
    struct {
      // Send toggle, when zero bmSNDTOG0, bmSNDTOG1 otherwise
      uint8_t bmSndToggle: 1;
      // Send toggle, when zero bmRCVTOG0, bmRCVTOG1 otherwise
      uint8_t bmRcvToggle: 1;
      // Binary order for NAK_LIMIT value
      uint8_t bmNakPower:  6;
    };
  };
} ep_t;

#define USB_NUMDEVICES 16      // number of supported USB devices

/* Common setup data constant combinations  */
#define USB_REQ_GET_DESCR     USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_STANDARD|USB_SETUP_RECIPIENT_DEVICE     //get descriptor request type
#define USB_REQ_SET           USB_SETUP_HOST_TO_DEVICE|USB_SETUP_TYPE_STANDARD|USB_SETUP_RECIPIENT_DEVICE     //set request type for all but 'set feature' and 'set interface'
#define USB_REQ_CL_GET_INTF   USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_CLASS|USB_SETUP_RECIPIENT_INTERFACE     //get interface request type

#define USB_SETTLE_DELAY 200   // settle delay in milliseconds
#define USB_XFER_TIMEOUT 5000  // USB transfer timeout in milliseconds, per section 9.2.6.1 of USB 2.0 spec
#define USB_RETRY_LIMIT	3      // retry limit for a transfer

/* USB state machine states */
#define USB_STATE_MASK                                      0xf0

#define USB_STATE_DETACHED                                  0x10
#define USB_DETACHED_SUBSTATE_INITIALIZE                    0x11        
#define USB_DETACHED_SUBSTATE_WAIT_FOR_DEVICE               0x12
#define USB_DETACHED_SUBSTATE_ILLEGAL                       0x13
#define USB_ATTACHED_SUBSTATE_SETTLE                        0x20
#define USB_ATTACHED_SUBSTATE_RESET_DEVICE                  0x30    
#define USB_ATTACHED_SUBSTATE_WAIT_RESET_COMPLETE           0x40
#define USB_ATTACHED_SUBSTATE_WAIT_SOF                      0x50
#define USB_ATTACHED_SUBSTATE_GET_DEVICE_DESCRIPTOR_SIZE    0x60
#define USB_STATE_ADDRESSING                                0x70
#define USB_STATE_CONFIGURING                               0x80
#define USB_STATE_RUNNING                                   0x90

/* USB Setup Packet Structure   */
typedef struct {
  union {                          // offset   description
    uint8_t bmRequestType;         //   0      Bit-map of request type
    struct {
      uint8_t    recipient:  5;    //          Recipient of the request
      uint8_t    type:       2;    //          Type of request
      uint8_t    direction:  1;    //          Direction of data X-fer
    } __attribute__((packed));
  } __attribute__((packed)) ReqType_u;
  uint8_t    bRequest;		   //   1      Request
  union {
    uint16_t    wValue;            //   2/3    Depends on bRequest
    struct {
      uint8_t    wValueLo;
      uint8_t    wValueHi;
    } __attribute__((packed));
  }  __attribute__((packed)) wVal_u;
  uint16_t    wIndex;              //   4      Depends on bRequest
  uint16_t    wLength;             //   6      Depends on bRequest
} __attribute__((packed)) setup_pkt_t;

// Additional Error Codes
#define USB_ERROR_INVALID_MAX_PKT_SIZE			    0xDA
#define USB_DEV_CONFIG_ERROR_DEVICE_NOT_SUPPORTED           0xDB
#define USB_ERROR_CONFIGURAION_SIZE_MISMATCH                0xDC
#define USB_ERROR_TRANSFER_TIMEOUT			    0xFF

struct usb_device_entry;

typedef struct {
  uint8_t (*init)(struct usb_device_entry *);
  uint8_t (*release)(struct usb_device_entry *);
  uint8_t (*poll)(struct usb_device_entry *);
} usb_device_class_config_t;

#include "hub.h"
#include "hid.h"
#include "asix.h"
#include "storage.h"
#include "usbrtc.h"

// entry used for list of connected devices
typedef struct usb_device_entry {
  const usb_device_class_config_t *class;  // pointer to class hadlers
  ep_t ep0;                            // information about endpoint 0
  uint8_t bAddress;	                   // device address
  uint8_t parent;                          // parent device address
  uint8_t port;
  bool lowspeed;

  union {
    usb_hub_info_t hub_info;
    usb_hid_info_t hid_info;
    usb_asix_info_t asix_info;
    usb_storage_info_t storage_info;
    usb_usbrtc_info_t usbrtc_info;
  };
} usb_device_t;

#define USB_CLASS_USE_CLASS_INFO          0x00    // Use Class Info in the Interface Descriptors
#define USB_CLASS_AUDIO                   0x01    // Audio
#define USB_CLASS_COM_AND_CDC_CTRL        0x02    // Communications and CDC Control
#define USB_CLASS_HID                     0x03    // HID
#define USB_CLASS_PHYSICAL                0x05    // Physical
#define USB_CLASS_IMAGE                   0x06    // Image
#define USB_CLASS_PRINTER                 0x07    // Printer
#define USB_CLASS_MASS_STORAGE            0x08    // Mass Storage
#define USB_CLASS_HUB                     0x09    // Hub
#define USB_CLASS_CDC_DATA                0x0a    // CDC-Data
#define USB_CLASS_SMART_CARD              0x0b    // Smart-Card
#define USB_CLASS_CONTENT_SECURITY        0x0d    // Content Security
#define USB_CLASS_VIDEO                   0x0e    // Video
#define USB_CLASS_PERSONAL_HEALTH         0x0f    // Personal Healthcare
#define USB_CLASS_DIAGNOSTIC_DEVICE       0xdc    // Diagnostic Device
#define USB_CLASS_WIRELESS_CTRL           0xe0    // Wireless Controller
#define USB_CLASS_MISC                    0xef    // Miscellaneous
#define USB_CLASS_APP_SPECIFIC            0xfe    // Application Specific
#define USB_CLASS_VENDOR_SPECIFIC         0xff    // Vendor Specific

/*******************************************************************************/
/***                                                                         ***/
/***                       USB chapter 9 structures                          ***/
/***                                                                         ***/
/*******************************************************************************/

/* Device descriptor structure */
typedef struct {
  uint8_t  bLength;            // Length of this descriptor.
  uint8_t  bDescriptorType;    // DEVICE descriptor type (USB_DESCRIPTOR_DEVICE).
  uint16_t bcdUSB;	       // USB Spec Release Number (BCD).
  uint8_t  bDeviceClass;       // Class code (assigned by the USB-IF). 0xFF-Vendor specific.
  uint8_t  bDeviceSubClass;    // Subclass code (assigned by the USB-IF).
  uint8_t  bDeviceProtocol;    // Protocol code (assigned by the USB-IF). 0xFF-Vendor specific.
  uint8_t  bMaxPacketSize0;    // Maximum packet size for endpoint 0.
  uint16_t idVendor;	       // Vendor ID (assigned by the USB-IF).
  uint16_t idProduct;	       // Product ID (assigned by the manufacturer).
  uint16_t bcdDevice;	       // Device release number (BCD).
  uint8_t  iManufacturer;      // Index of String Descriptor describing the manufacturer.
  uint8_t  iProduct;           // Index of String Descriptor describing the product.
  uint8_t  iSerialNumber;      // Index of String Descriptor with the device's serial number.
  uint8_t  bNumConfigurations; // Number of possible configurations.
} __attribute__((packed)) usb_device_descriptor_t;

/* Configuration descriptor structure */
typedef struct {
  uint8_t bLength;             // Length of this descriptor.
  uint8_t bDescriptorType;     // CONFIGURATION descriptor type (USB_DESCRIPTOR_CONFIGURATION).
  uint16_t wTotalLength;       // Total length of all descriptors for this configuration.
  uint8_t bNumInterfaces;      // Number of interfaces in this configuration.
  uint8_t bConfigurationValue; // Value of this configuration (1 based).
  uint8_t iConfiguration;      // Index of String Descriptor describing the configuration.
  uint8_t bmAttributes;        // Configuration characteristics.
  uint8_t bMaxPower;           // Maximum power consumed by this configuration.
} __attribute__((packed)) usb_configuration_descriptor_t;

/* Interface descriptor structure */
typedef struct {
  uint8_t bLength;               // Length of this descriptor.
  uint8_t bDescriptorType;       // INTERFACE descriptor type (USB_DESCRIPTOR_INTERFACE).
  uint8_t bInterfaceNumber;      // Number of this interface (0 based).
  uint8_t bAlternateSetting;     // Value of this alternate interface setting.
  uint8_t bNumEndpoints;         // Number of endpoints in this interface.
  uint8_t bInterfaceClass;       // Class code (assigned by the USB-IF).  0xFF-Vendor specific.
  uint8_t bInterfaceSubClass;    // Subclass code (assigned by the USB-IF).
  uint8_t bInterfaceProtocol;    // Protocol code (assigned by the USB-IF).  0xFF-Vendor specific.
  uint8_t iInterface;            // Index of String Descriptor describing the interface.
} __attribute__((packed)) usb_interface_descriptor_t;

/* Endpoint descriptor structure */
typedef struct {
  uint8_t bLength;               // Length of this descriptor.
  uint8_t bDescriptorType;       // ENDPOINT descriptor type (USB_DESCRIPTOR_ENDPOINT).
  uint8_t bEndpointAddress;      // Endpoint address. Bit 7 indicates direction (0=OUT, 1=IN).
  uint8_t bmAttributes;          // Endpoint transfer type.
  uint8_t wMaxPacketSize[2];     // Maximum packet size.
  uint8_t bInterval;             // Polling interval in frames.
} __attribute__((packed)) usb_endpoint_descriptor_t;

/* Standard Device Requests */
#define USB_REQUEST_GET_STATUS                  0       // Standard Device Request - GET STATUS
#define USB_REQUEST_CLEAR_FEATURE               1       // Standard Device Request - CLEAR FEATURE
#define USB_REQUEST_SET_FEATURE                 3       // Standard Device Request - SET FEATURE
#define USB_REQUEST_SET_ADDRESS                 5       // Standard Device Request - SET ADDRESS
#define USB_REQUEST_GET_DESCRIPTOR              6       // Standard Device Request - GET DESCRIPTOR
#define USB_REQUEST_SET_DESCRIPTOR              7       // Standard Device Request - SET DESCRIPTOR
#define USB_REQUEST_GET_CONFIGURATION           8       // Standard Device Request - GET CONFIGURATION
#define USB_REQUEST_SET_CONFIGURATION           9       // Standard Device Request - SET CONFIGURATION
#define USB_REQUEST_GET_INTERFACE               10      // Standard Device Request - GET INTERFACE
#define USB_REQUEST_SET_INTERFACE               11      // Standard Device Request - SET INTERFACE
#define USB_REQUEST_SYNCH_FRAME                 12      // Standard Device Request - SYNCH FRAME

#define USB_FEATURE_ENDPOINT_HALT               0       // CLEAR/SET FEATURE - Endpoint Halt
#define USB_FEATURE_DEVICE_REMOTE_WAKEUP        1       // CLEAR/SET FEATURE - Device remote wake-up
#define USB_FEATURE_TEST_MODE                   2       // CLEAR/SET FEATURE - Test mode

/* Setup Data Constants */
#define USB_SETUP_HOST_TO_DEVICE                0x00    // Device Request bmRequestType transfer direction - host to device transfer
#define USB_SETUP_DEVICE_TO_HOST                0x80    // Device Request bmRequestType transfer direction - device to host transfer
#define USB_SETUP_TYPE_STANDARD                 0x00    // Device Request bmRequestType type - standard
#define USB_SETUP_TYPE_CLASS                    0x20    // Device Request bmRequestType type - class
#define USB_SETUP_TYPE_VENDOR                   0x40    // Device Request bmRequestType type - vendor
#define USB_SETUP_RECIPIENT_DEVICE              0x00    // Device Request bmRequestType recipient - device
#define USB_SETUP_RECIPIENT_INTERFACE           0x01    // Device Request bmRequestType recipient - interface
#define USB_SETUP_RECIPIENT_ENDPOINT            0x02    // Device Request bmRequestType recipient - endpoint
#define USB_SETUP_RECIPIENT_OTHER               0x03    // Device Request bmRequestType recipient - other

/* USB descriptors  */
#define USB_DESCRIPTOR_DEVICE           0x01    // bDescriptorType for a Device Descriptor.
#define USB_DESCRIPTOR_CONFIGURATION    0x02    // bDescriptorType for a Configuration Descriptor.
#define USB_DESCRIPTOR_STRING           0x03    // bDescriptorType for a String Descriptor.
#define USB_DESCRIPTOR_INTERFACE        0x04    // bDescriptorType for an Interface Descriptor.
#define USB_DESCRIPTOR_ENDPOINT         0x05    // bDescriptorType for an Endpoint Descriptor.
#define USB_DESCRIPTOR_DEVICE_QUALIFIER 0x06    // bDescriptorType for a Device Qualifier.
#define USB_DESCRIPTOR_OTHER_SPEED      0x07    // bDescriptorType for a Other Speed Configuration.
#define USB_DESCRIPTOR_INTERFACE_POWER  0x08    // bDescriptorType for Interface Power.

void usb_init();
void usb_poll();
void usb_SetHubPreMask(void);
void usb_ResetHubPreMask(void);

uint8_t usb_set_addr( usb_device_t *, uint8_t );
uint8_t usb_ctrl_req( usb_device_t *, uint8_t bmReqType, 
		      uint8_t bRequest, uint8_t wValLo, uint8_t wValHi, 
		      uint16_t wInd, uint16_t nbytes, uint8_t* dataptr);
uint8_t usb_get_dev_descr( usb_device_t *, uint16_t nbytes, usb_device_descriptor_t* dataptr );
uint8_t usb_get_conf_descr( usb_device_t *, uint16_t nbytes, uint8_t conf, usb_configuration_descriptor_t* dataptr );
uint8_t usb_set_conf( usb_device_t *dev, uint8_t conf_value );
uint8_t usb_in_transfer( usb_device_t *, ep_t *ep, uint16_t *nbytesptr, uint8_t* data);
uint8_t usb_out_transfer( usb_device_t *, ep_t *ep, uint16_t nbytes, uint8_t* data );
uint8_t usb_release_device(uint8_t parent, uint8_t port);
usb_device_t *usb_get_devices();

#endif // USB_H
