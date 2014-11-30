#ifndef STORAGE_H
#define STORAGE_H

#include <stdbool.h>
#include <inttypes.h>

extern uint8_t storage_devices;

#define STORAGE_SUBCLASS_UFI    0x04  // floppy
#define STORAGE_SUBCLASS_SCSI   0x06

#define STORAGE_PROTOCOL_CBI       0x00  // control/bulk/interrupt
#define STORAGE_PROTOCOL_BULK_ONLY 0x50 

#define STORAGE_ERR_SUCCESS					0x00
#define STORAGE_ERR_PHASE_ERROR				0x01
#define STORAGE_ERR_DEVICE_DISCONNECTED		0x11
#define STORAGE_ERR_UNABLE_TO_RECOVER			0x12	// Reset recovery error
#define STORAGE_ERR_GENERAL_USB_ERROR			0xFF

#define STORAGE_CBW_SIGNATURE		0x43425355
#define STORAGE_CSW_SIGNATURE		0x53425355

#define STORAGE_CMD_DIR_OUT		(0 << 7)
#define STORAGE_CMD_DIR_IN		(1 << 7)

// mass storage bulk only interface
#define STORAGE_EP_IN   0
#define STORAGE_EP_OUT  1

#define STORAGE_REQ_MASSOUT       USB_SETUP_HOST_TO_DEVICE|USB_SETUP_TYPE_CLASS|USB_SETUP_RECIPIENT_INTERFACE
#define STORAGE_REQ_MASSIN        USB_SETUP_DEVICE_TO_HOST|USB_SETUP_TYPE_CLASS|USB_SETUP_RECIPIENT_INTERFACE 

// Request Codes
#define STORAGE_REQ_ADSC				0x00		
#define STORAGE_REQ_GET					0xFC		
#define STORAGE_REQ_PUT					0xFD		
#define STORAGE_REQ_GET_MAX_LUN				0xFE		
#define STORAGE_REQ_BOMSR				0xFF	// Bulk-Only Mass Storage Reset		

#define SCSI_CMD_INQUIRY				0x12
#define SCSI_CMD_REPORT_LUNS				0xA0
#define SCSI_CMD_REQUEST_SENSE				0x03
#define SCSI_CMD_FORMAT_UNIT				0x04
#define SCSI_CMD_READ_6					0x08
#define SCSI_CMD_READ_10				0x28
#define SCSI_CMD_READ_CAPACITY_10			0x25
#define SCSI_CMD_TEST_UNIT_READY			0x00
#define SCSI_CMD_WRITE_6				0x0A
#define SCSI_CMD_WRITE_10				0x2A
#define SCSI_CMD_MODE_SENSE_6				0x1A
#define SCSI_CMD_MODE_SENSE_10				0x5A

typedef struct {
  uint8_t  DeviceType          : 5;
  uint8_t  PeripheralQualifier : 3;

  uint8_t  Reserved            : 7;
  uint8_t  Removable           : 1;

  uint8_t  Version;
  
  uint8_t  ResponseDataFormat  : 4;
  uint8_t  Reserved2           : 1;
  uint8_t  NormACA             : 1;
  uint8_t  TrmTsk              : 1;
  uint8_t  AERC                : 1;
  
  uint8_t  AdditionalLength;
  uint8_t  Reserved3[2];
  
  uint8_t  SoftReset           : 1;
  uint8_t  CmdQue              : 1;
  uint8_t  Reserved4           : 1;
  uint8_t  Linked              : 1;
  uint8_t  Sync                : 1;
  uint8_t  WideBus16Bit        : 1;
  uint8_t  WideBus32Bit        : 1;
  uint8_t  RelAddr             : 1;
  
  uint8_t  VendorID[8];
  uint8_t  ProductID[16];
  uint8_t  RevisionID[4];
} __attribute__ ((packed)) inquiry_response_t;

typedef struct {
  uint8_t bResponseCode;
  uint8_t bSegmentNumber;

  uint8_t bmSenseKey            : 4;
  uint8_t bmReserved            : 1;
  uint8_t bmILI                 : 1;
  uint8_t bmEOM                 : 1;
  uint8_t bmFileMark            : 1;
  
  uint8_t Information[4];
  uint8_t bAdditionalLength;
  uint8_t CmdSpecificInformation[4];
  uint8_t bAdditionalSenseCode;
  uint8_t bAdditionalSenseQualifier;
  uint8_t bFieldReplaceableUnitCode;
  uint8_t SenseKeySpecific[3];
} __attribute__ ((packed)) request_sense_response_t;

typedef struct {
  uint32_t dwBlockAddress;
  uint32_t dwBlockLength;
} __attribute__ ((packed)) read_capacity_response_t;

typedef struct {
  uint32_t	dCBWSignature;
  uint32_t	dCBWTag;
  uint32_t	dCBWDataTransferLength;
  uint8_t	bmCBWFlags;

  struct {
    uint8_t bmCBWLUN	: 4; 
    uint8_t bmReserved1	: 4;
  };
  struct {
    uint8_t bmCBWCBLength: 4;
    uint8_t bmReserved2	: 4;
  };
  
  uint8_t		CBWCB[16];
} __attribute__ ((packed)) command_block_wrapper_t;

typedef struct {
  uint32_t	dCSWSignature;
  uint32_t	dCSWTag;
  uint32_t	dCSWDataResidue;
  uint8_t	bCSWStatus;
} __attribute__ ((packed)) command_status_wrapper_t;

typedef struct {
  ep_t ep[2];
  uint8_t max_lun;
  uint8_t last_error;		// Last USB error
  uint8_t state;
  uint32_t qNextPollTime;
  uint32_t capacity;
} usb_storage_info_t;

// interface to usb core
extern const usb_device_class_config_t usb_storage_class;
extern unsigned char usb_storage_read(unsigned long lba, unsigned char *pReadBuffer);
extern unsigned char usb_storage_write(unsigned long lba, unsigned char *pWriteBuffer);

#endif // STORAGE_H
