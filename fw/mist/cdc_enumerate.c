//*----------------------------------------------------------------------------
//*      ATMEL Microcontroller Software Support  -  ROUSSET  -
//*----------------------------------------------------------------------------
//* The software is delivered "AS IS" without warranty or condition of any
//* kind, either express, implied or statutory. This includes without
//* limitation any warranty or condition with respect to merchantability or
//* fitness for any particular purpose, or against the infringements of
//* intellectual property rights of others.
//*----------------------------------------------------------------------------
//* File Name           : cdc_enumerate.c
//* Object              : Handle CDC enumeration
//*
//* 1.0 Apr 20 200 	: ODi Creation
//* 1.1 14/Sep/2004 JPP : Minor change
//* 1.1 15/12/2004  JPP : suppress warning
//*----------------------------------------------------------------------------

// 12. Apr. 2006: added modification found in the mikrocontroller.net gcc-Forum 
//                additional line marked with /* +++ */
// 1. Sept. 2006: fixed case: board.h -> Board.h

#include "AT91SAM7S256.h"
#include <string.h>

#include "cdc_enumerate.h"
#include "hardware.h"
#include "debug.h"

typedef unsigned char  uchar;
typedef unsigned short ushort;
typedef unsigned int   uint;

#define MIN(a, b) (((a) < (b)) ? (a) : (b))

#define WORD(a) (a)&0xff, ((a)>>8)&0xff

// Private members
unsigned int  currentRcvBank;

const char langDescriptor[] = {
  /* Language descriptor */
  0x04,         // length of descriptor in bytes
  0x03,         // descriptor type
  WORD(0x0409)  // language index (0x0409 = US-English)
};

const char devDescriptor[] = {
  /* Device descriptor */
  0x12,   // bLength
  0x01,   // bDescriptorType
  WORD(0x0110),   // bcdUSBL
  0x02,   // bDeviceClass:    CDC class code
  0x00,   // bDeviceSubclass: CDC class sub code
  0x00,   // bDeviceProtocol: CDC Device protocol
  0x08,   // bMaxPacketSize0
  WORD(0x1c40), // idVendorL
  WORD(0x0537), // idProductL
  WORD(0x0001), // bcdDeviceL
  0x01,   // iManufacturer
  0x02,   // iProduct
  0x00,   // SerialNumber
  0x01    // bNumConfigs
};

const char cfgDescriptor[] = {
	/* ============== CONFIGURATION 1 =========== */
	/* Configuration 1 descriptor */
	0x09,   // CbLength
	0x02,   // CbDescriptorType
	WORD(0x43),   // CwTotalLength 2 EP + Control
	0x02,   // CbNumInterfaces
	0x01,   // CbConfigurationValue
	0x00,   // CiConfiguration
	0xC0,   // CbmAttributes 0xA0
	200,    // CMaxPower = 400mA

	/* Communication Class Interface Descriptor Requirement */
	0x09, // bLength
	0x04, // bDescriptorType
	0x00, // bInterfaceNumber
	0x00, // bAlternateSetting
	0x01, // bNumEndpoints
	0x02, // bInterfaceClass
	0x02, // bInterfaceSubclass
	0x00, // bInterfaceProtocol
	0x00, // iInterface

	/* Header Functional Descriptor */
	0x05, // bFunction Length
	0x24, // bDescriptor type: CS_INTERFACE
	0x00, // bDescriptor subtype: Header Func Desc
	WORD(0x0110), // bcdCDC:1.1

	/* ACM Functional Descriptor */
	0x04, // bFunctionLength
	0x24, // bDescriptor Type: CS_INTERFACE
	0x02, // bDescriptor Subtype: ACM Func Desc
	0x00, // bmCapabilities

	/* Union Functional Descriptor */
	0x05, // bFunctionLength
	0x24, // bDescriptorType: CS_INTERFACE
	0x06, // bDescriptor Subtype: Union Func Desc
	0x00, // bMasterInterface: Communication Class Interface
	0x01, // bSlaveInterface0: Data Class Interface

	/* Call Management Functional Descriptor */
	0x05, // bFunctionLength
	0x24, // bDescriptor Type: CS_INTERFACE
	0x01, // bDescriptor Subtype: Call Management Func Desc
	0x00, // bmCapabilities: D1 + D0
	0x01, // bDataInterface: Data Class Interface 1

	/* Endpoint 1 descriptor */
	0x07,   // bLength
	0x05,   // bDescriptorType
	0x83,   // bEndpointAddress, Endpoint 03 - IN
	0x03,   // bmAttributes      INT
	WORD(0x08),   // wMaxPacketSize
	0xFF,   // bInterval

	/* Data Class Interface Descriptor Requirement */
	0x09, // bLength
	0x04, // bDescriptorType
	0x01, // bInterfaceNumber
	0x00, // bAlternateSetting
	0x02, // bNumEndpoints
	0x0A, // bInterfaceClass
	0x00, // bInterfaceSubclass
	0x00, // bInterfaceProtocol
	0x00, // iInterface

	/* First alternate setting */
	/* Endpoint 1 descriptor */
	0x07,   // bLength
	0x05,   // bDescriptorType
	0x01,   // bEndpointAddress, Endpoint 01 - OUT
	0x02,   // bmAttributes      BULK
	WORD(AT91C_EP_OUT_SIZE),   // wMaxPacketSize
	0x00,   // bInterval

	/* Endpoint 2 descriptor */
	0x07,   // bLength
	0x05,   // bDescriptorType
	0x82,   // bEndpointAddress, Endpoint 02 - IN
	0x02,   // bmAttributes      BULK
	WORD(AT91C_EP_IN_SIZE),   // wMaxPacketSize
	0x00    // bInterval
};

/* USB standard request code */
#define STD_GET_STATUS_ZERO           0x0080
#define STD_GET_STATUS_INTERFACE      0x0081
#define STD_GET_STATUS_ENDPOINT       0x0082

#define STD_CLEAR_FEATURE_ZERO        0x0100
#define STD_CLEAR_FEATURE_INTERFACE   0x0101
#define STD_CLEAR_FEATURE_ENDPOINT    0x0102

#define STD_SET_FEATURE_ZERO          0x0300
#define STD_SET_FEATURE_INTERFACE     0x0301
#define STD_SET_FEATURE_ENDPOINT      0x0302

#define STD_SET_ADDRESS               0x0500
#define STD_GET_DESCRIPTOR            0x0680
#define STD_SET_DESCRIPTOR            0x0700
#define STD_GET_CONFIGURATION         0x0880
#define STD_SET_CONFIGURATION         0x0900
#define STD_GET_INTERFACE             0x0A81
#define STD_SET_INTERFACE             0x0B01
#define STD_SYNCH_FRAME               0x0C82

/* CDC Class Specific Request Code */
#define GET_LINE_CODING               0x21A1
#define SET_LINE_CODING               0x2021
#define SET_CONTROL_LINE_STATE        0x2221


typedef struct {
	unsigned int dwDTERRate;
	char bCharFormat;
	char bParityType;
	char bDataBits;
} AT91S_CDC_LINE_CODING, *AT91PS_CDC_LINE_CODING;

AT91S_CDC_LINE_CODING line = {
	115200, // baudrate
	0,      // 1 Stop Bit
	0,      // None Parity
	8};     // 8 Data bits

static void AT91F_CDC_Enumerate(void);

static void tx(char c) {
  while(!(AT91C_BASE_US0->US_CSR & AT91C_US_TXRDY));
  AT91C_BASE_US0->US_THR = c;
}

static void tx_str(char *str) {
  while(*str) tx(*str++);
}

static void tx_hex(char *str, unsigned int num) {
  const char c[] = "0123456789abcdef";
  int s = 28;

  tx_str(str);

  while(s >= 0) {
    tx(c[(num >> s)&0x0f]);
    s -= 4;
  }

  tx('\n');
  tx('\r');
}

static void usb_irq_handler(void) {
  AT91_REG isr = AT91C_BASE_UDP->UDP_ISR & AT91C_BASE_UDP->UDP_IMR;

  //  tx_hex("i: ", isr);

  // handle all known interrupt sources
  if(isr & AT91C_UDP_ENDBUSRES) {
    AT91C_BASE_UDP->UDP_ICR = AT91C_UDP_ENDBUSRES;
    
    //    tx_str("USB bus reset\r\n");
    
    // reset all endpoints
    AT91C_BASE_UDP->UDP_RSTEP  = (unsigned int)-1;
    AT91C_BASE_UDP->UDP_RSTEP  = 0;
    // Enable the function
    AT91C_BASE_UDP->UDP_FADDR = AT91C_UDP_FEN;
    // Configure endpoint 0
    AT91C_BASE_UDP->UDP_CSR[0] = (AT91C_UDP_EPEDS | AT91C_UDP_EPTYPE_CTRL);
    
    // enable ep0 interrupt
    AT91C_BASE_UDP->UDP_IER = AT91C_UDP_EPINT0;
  }

  // data received for endpoint 0
  if(isr & AT91C_UDP_EPINT0) {
    AT91C_BASE_UDP->UDP_ICR = AT91C_UDP_EPINT0;
    AT91F_CDC_Enumerate();
  }

  // clear all remaining irqs
  AT91C_BASE_UDP->UDP_ICR = AT91C_BASE_UDP->UDP_ISR;
}

//*----------------------------------------------------------------------------
//* \fn    AT91F_CDC_Open
//* \brief
//*----------------------------------------------------------------------------
void usb_cdc_open(void) {
  // Set the PLL USB Divider
  AT91C_BASE_CKGR->CKGR_PLLR |= AT91C_CKGR_USBDIV_1 ;
  
  // Specific Chip USB Initialisation
  // Enables the 48MHz USB clock UDPCK and System Peripheral USB Clock
  AT91C_BASE_PMC->PMC_SCER = AT91C_PMC_UDP;
  AT91C_BASE_PMC->PMC_PCER = (1 << AT91C_ID_UDP);
  
  // Enable UDP PullUp (USB_DP_PUP) : enable & Clear of the corresponding PIO
  // Set in PIO mode and Configure in Output with pullup
  AT91C_BASE_PIOA->PIO_PER = USB_PUP;
  AT91C_BASE_PIOA->PIO_OER = USB_PUP;
  AT91C_BASE_PIOA->PIO_CODR = USB_PUP;

  currentRcvBank       = AT91C_UDP_RX_DATA_BK0;

  /* Enable usb_interrupt */
  AT91C_AIC_SMR[AT91C_ID_UDP] = AT91C_AIC_SRCTYPE_INT_HIGH_LEVEL | 4;
  AT91C_AIC_SVR[AT91C_ID_UDP] = (unsigned int)usb_irq_handler;
  *AT91C_AIC_IECR = (1 << AT91C_ID_UDP);
}

//*----------------------------------------------------------------------------
//* \fn    usb_cdc_is_configured
//* \brief Test if the device is configured
//*----------------------------------------------------------------------------
uchar usb_cdc_is_configured(void) {
  return AT91C_BASE_UDP->UDP_GLBSTATE & AT91C_UDP_CONFG;
}

//*----------------------------------------------------------------------------
//* \fn    usb_cdc_read
//* \brief Read available data from Endpoint OUT
//*----------------------------------------------------------------------------
uint16_t usb_cdc_read(char *pData, uint16_t length) {
  uint16_t packetSize, nbBytesRcv = 0;
  
  if ( !usb_cdc_is_configured() )
    return 0;

  if ( AT91C_BASE_UDP->UDP_CSR[AT91C_EP_OUT] & currentRcvBank ) {
    packetSize = MIN(AT91C_BASE_UDP->UDP_CSR[AT91C_EP_OUT] >> 16, length);
    length -= packetSize;
    
    if (packetSize < AT91C_EP_OUT_SIZE)
      length = 0;
    
    while(packetSize--)
      pData[nbBytesRcv++] = AT91C_BASE_UDP->UDP_FDR[AT91C_EP_OUT];
    
    AT91C_BASE_UDP->UDP_CSR[AT91C_EP_OUT] &= ~(currentRcvBank);

    // toggle banks
    if(currentRcvBank == AT91C_UDP_RX_DATA_BK0)
      currentRcvBank = AT91C_UDP_RX_DATA_BK1;
    else
      currentRcvBank = AT91C_UDP_RX_DATA_BK0;
  }

  return nbBytesRcv;
}

//*----------------------------------------------------------------------------
//* \fn    AT91F_CDC_Write
//* \brief Send through endpoint 2
//*----------------------------------------------------------------------------

static void wait4tx(char ep) {
  long to = GetTimer(2);  // wait max 2ms for tx to succeed
  
  // wait for host to acknowledge data reception
  while ( !(AT91C_BASE_UDP->UDP_CSR[ep] & AT91C_UDP_TXCOMP) ) 
    if(CheckTimer(to)) return;

  // clear flag (clear irq)
  AT91C_BASE_UDP->UDP_CSR[ep] &= ~AT91C_UDP_TXCOMP;

  // wait for register clear to succeed
  while (AT91C_BASE_UDP->UDP_CSR[ep] & AT91C_UDP_TXCOMP);
}

// copy bytes to the endpoint fifo and start transmission
static uint ep_tx(char ep, const char *pData, uint length) {
  uint b2c = MIN(length, ep?AT91C_EP_IN_SIZE:8);
  uint retval = b2c;

  // copy all bytes into send buffer
  while (b2c--) AT91C_BASE_UDP->UDP_FDR[ep] = *pData++;
  AT91C_BASE_UDP->UDP_CSR[ep] |= AT91C_UDP_TXPKTRDY;

  return retval;
}

uint usb_cdc_write(const char *pData, uint length) {
  if(usb_cdc_is_configured()) {

    while(length) {
      uint sent = ep_tx(AT91C_EP_IN, pData, length);
      length -= sent;
      pData += sent;
      
      wait4tx(AT91C_EP_IN);
    }
  }

  return length;
}

//*----------------------------------------------------------------------------
//* \fn    AT91F_USB_SendData
//* \brief Send Data through the control endpoint
//*----------------------------------------------------------------------------
static void AT91F_USB_SendData(const char *pData, uint length) {
  AT91_REG csr;

  do {
    long to = GetTimer(2);  // wait max 2ms for tx to succeed

    uint sent = ep_tx(0, pData, length);
    length -= sent;
    pData += sent;
    
    // wait for transmission with timeout
    do {
      csr = AT91C_BASE_UDP->UDP_CSR[0];
      
      // Data IN stage has been stopped by a status OUT
      if (csr & AT91C_UDP_RX_DATA_BK0) {
	AT91C_BASE_UDP->UDP_CSR[0] &= ~(AT91C_UDP_RX_DATA_BK0);
	return;
      }
    } while (( !(csr & AT91C_UDP_TXCOMP) ) && !CheckTimer(to));

    // clear flag (clear irq)
    AT91C_BASE_UDP->UDP_CSR[0] &= ~AT91C_UDP_TXCOMP;

    // wait for register clear to succeed
    while (AT91C_BASE_UDP->UDP_CSR[0] & AT91C_UDP_TXCOMP);

  } while (length);
}

static void AT91F_USB_SendStr(const char *str, uint max) {
  uchar len = 2*strlen(str)+2;
  char cmd[len], *p;

  cmd[0] = len;
  cmd[1] = 0x03;

  p = cmd+2;
  while(*str) {
    *p++ = *str++;
    *p++ = 0;
  }

  AT91F_USB_SendData(cmd, MIN(len, max));
}

//*----------------------------------------------------------------------------
//* \fn    AT91F_USB_SendZlp
//* \brief Send zero length packet through the control endpoint
//*----------------------------------------------------------------------------
void AT91F_USB_SendZlp() {
  AT91C_BASE_UDP->UDP_CSR[0] |= AT91C_UDP_TXPKTRDY;
  wait4tx(0);
}

//*----------------------------------------------------------------------------
//* \fn    AT91F_USB_SendStall
//* \brief Stall the control endpoint
//*----------------------------------------------------------------------------
static void AT91F_USB_SendStall() {
  AT91C_BASE_UDP->UDP_CSR[0] |= AT91C_UDP_FORCESTALL;
  while ( !(AT91C_BASE_UDP->UDP_CSR[0] & AT91C_UDP_ISOERROR) );
  AT91C_BASE_UDP->UDP_CSR[0] &= ~(AT91C_UDP_FORCESTALL | AT91C_UDP_ISOERROR);
  while (AT91C_BASE_UDP->UDP_CSR[0] & (AT91C_UDP_FORCESTALL | AT91C_UDP_ISOERROR));
}

//*----------------------------------------------------------------------------
//* \fn    AT91F_CDC_Enumerate
//* \brief This function is a callback invoked when a SETUP packet is received
//*----------------------------------------------------------------------------

static void AT91F_USB_SendWord(ushort data) {
  AT91F_USB_SendData((char *) &data, sizeof(data));
}

static void AT91F_CDC_Enumerate(void) {
  uchar bmRequestType, bRequest, bConf;
  ushort wValue, wIndex, wLength, wStatus;

  //  tx_hex("1: ", AT91C_BASE_UDP->UDP_CSR[0]);

  // setup packet available?
  if ( !(AT91C_BASE_UDP->UDP_CSR[0] & AT91C_UDP_RXSETUP) ) {

    // discard any pending payload
    AT91C_BASE_UDP->UDP_CSR[0] &= ~(AT91C_UDP_RX_DATA_BK0 | AT91C_UDP_RX_DATA_BK1);

    //    tx('x');
    return;
  }
  
  bmRequestType = AT91C_BASE_UDP->UDP_FDR[0];
  bRequest      = AT91C_BASE_UDP->UDP_FDR[0];
  wValue        = (AT91C_BASE_UDP->UDP_FDR[0] & 0xFF) | (AT91C_BASE_UDP->UDP_FDR[0] << 8);
  wIndex        = (AT91C_BASE_UDP->UDP_FDR[0] & 0xFF) | (AT91C_BASE_UDP->UDP_FDR[0] << 8);
  wLength       = (AT91C_BASE_UDP->UDP_FDR[0] & 0xFF) | (AT91C_BASE_UDP->UDP_FDR[0] << 8);
  
  // check direction bit (bit 7 set -> device to host)
  if (bmRequestType & 0x80) {
    AT91C_BASE_UDP->UDP_CSR[0] |= AT91C_UDP_DIR;
    while ( !(AT91C_BASE_UDP->UDP_CSR[0] & AT91C_UDP_DIR) );
  }
  
  AT91C_BASE_UDP->UDP_CSR[0] &= ~AT91C_UDP_RXSETUP;
  while ( (AT91C_BASE_UDP->UDP_CSR[0]  & AT91C_UDP_RXSETUP)  );
  
  // Handle supported standard device request Cf Table 9-3 in USB specification Rev 1.1
  switch ((bRequest << 8) | bmRequestType) {
  case STD_GET_DESCRIPTOR:
    if (wValue == 0x100)       // Return Device Descriptor
      AT91F_USB_SendData(devDescriptor, MIN(sizeof(devDescriptor), wLength));
    else if (wValue == 0x200)  // Return Configuration Descriptor
      AT91F_USB_SendData(cfgDescriptor, MIN(sizeof(cfgDescriptor), wLength));
    else if (wValue == 0x300)  // Return Language Descriptor
      AT91F_USB_SendData(langDescriptor, MIN(sizeof(langDescriptor), wLength));
    else if (wValue == 0x301)  // Return Manufacturer String Descriptor
      AT91F_USB_SendStr("Till Harbaum", wLength);
    else if (wValue == 0x302)  // Return Product String Descriptor
      AT91F_USB_SendStr("MIST Board", wLength);
    else
      AT91F_USB_SendStall();
    break;

  case STD_SET_ADDRESS:
    //    tx_hex("address set ", wValue);
    AT91F_USB_SendZlp();
    AT91C_BASE_UDP->UDP_FADDR = (AT91C_UDP_FEN | wValue);
    AT91C_BASE_UDP->UDP_GLBSTATE  = (wValue) ? AT91C_UDP_FADDEN : 0;
    break;

  case STD_SET_CONFIGURATION:
    //    tx_hex("config selected ", wValue);
    AT91F_USB_SendZlp();
    AT91C_BASE_UDP->UDP_GLBSTATE  = (wValue) ? AT91C_UDP_CONFG : AT91C_UDP_FADDEN;
    AT91C_BASE_UDP->UDP_CSR[1] = (wValue) ? (AT91C_UDP_EPEDS | AT91C_UDP_EPTYPE_BULK_OUT) : 0;
    AT91C_BASE_UDP->UDP_CSR[2] = (wValue) ? (AT91C_UDP_EPEDS | AT91C_UDP_EPTYPE_BULK_IN)  : 0;
    AT91C_BASE_UDP->UDP_CSR[3] = (wValue) ? (AT91C_UDP_EPEDS | AT91C_UDP_EPTYPE_ISO_IN)   : 0;
    break;

  case STD_GET_CONFIGURATION:
    bConf = AT91C_BASE_UDP->UDP_GLBSTATE & AT91C_UDP_CONFG?1:0;
    AT91F_USB_SendData(&bConf, 1);
    break;

  case STD_GET_STATUS_ZERO:
  case STD_GET_STATUS_INTERFACE:
    AT91F_USB_SendWord(0);
    break;

  case STD_GET_STATUS_ENDPOINT:
    wIndex &= 0x0F;
    if ((AT91C_BASE_UDP->UDP_GLBSTATE & AT91C_UDP_CONFG) && (wIndex <= 3))
      AT91F_USB_SendWord((AT91C_BASE_UDP->UDP_CSR[wIndex] & AT91C_UDP_EPEDS) ? 0 : 1);
    else if ((AT91C_BASE_UDP->UDP_GLBSTATE & AT91C_UDP_FADDEN) && (wIndex == 0)) 
      AT91F_USB_SendWord((AT91C_BASE_UDP->UDP_CSR[wIndex] & AT91C_UDP_EPEDS) ? 0 : 1);
    else
      AT91F_USB_SendStall();
    break;

  case STD_SET_FEATURE_ENDPOINT:
    wIndex &= 0x0F;
    if ((wValue == 0) && wIndex && (wIndex <= 3)) {
      AT91C_BASE_UDP->UDP_CSR[wIndex] = 0;
      AT91F_USB_SendZlp();
    } else
      AT91F_USB_SendStall();
    break;

  case STD_SET_FEATURE_ZERO:
  case STD_CLEAR_FEATURE_ZERO:
    AT91F_USB_SendStall();
    break;

  case STD_SET_FEATURE_INTERFACE:
  case STD_CLEAR_FEATURE_INTERFACE:
    AT91F_USB_SendZlp();
    break;

  case STD_CLEAR_FEATURE_ENDPOINT:
    wIndex &= 0x0F;
    if ((wValue == 0) && wIndex && (wIndex <= 3)) {
      if (wIndex == 1)
	AT91C_BASE_UDP->UDP_CSR[1] = (AT91C_UDP_EPEDS | AT91C_UDP_EPTYPE_BULK_OUT);
      else if (wIndex == 2)
	AT91C_BASE_UDP->UDP_CSR[2] = (AT91C_UDP_EPEDS | AT91C_UDP_EPTYPE_BULK_IN);
      else if (wIndex == 3)
	AT91C_BASE_UDP->UDP_CSR[3] = (AT91C_UDP_EPEDS | AT91C_UDP_EPTYPE_ISO_IN);
      AT91F_USB_SendZlp();
    } else
      AT91F_USB_SendStall();
    break;
    
    // handle CDC class requests
  case SET_LINE_CODING:
    // simply drop all incoming payload
    while ( !(AT91C_BASE_UDP->UDP_CSR[0] & AT91C_UDP_RX_DATA_BK0) );
    AT91C_BASE_UDP->UDP_CSR[0] &= ~(AT91C_UDP_RX_DATA_BK0);
    AT91F_USB_SendZlp();
    break;

  case GET_LINE_CODING:
    AT91F_USB_SendData((char *) &line, MIN(sizeof(line), wLength));
    break;

  case SET_CONTROL_LINE_STATE:
    AT91F_USB_SendZlp();
    break;

  default:
    AT91F_USB_SendStall();
    break;
  }
}
