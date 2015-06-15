#ifndef PL2303_H
#define PL2303_H

#include <stdbool.h>
#include <inttypes.h>

#define PL2303_STAT

#define PL2303_REQ_CDCOUT USB_SETUP_HOST_TO_DEVICE|USB_SETUP_TYPE_CLASS|USB_SETUP_RECIPIENT_INTERFACE

#define PL2303_STOP_BIT_1   0
#define PL2303_STOP_BIT_1_5 1
#define PL2303_STOP_BIT_2   2

#define PL2303_PARITY_NONE  0
#define PL2303_PARITY_ODD   1
#define PL2303_PARITY_EVEN  2
#define PL2303_PARITY_MARK  3
#define PL2303_PARITY_SPACE 4

typedef struct {
  uint32_t	dwDTERate;		// bitrate
  uint8_t	bCharFormat;
  uint8_t	bParityType;
  uint8_t	bDataBits;		// Data bits (5, 6, 7, 8 or 16)
} __attribute__ ((packed)) line_coding_t;

// CDC Commands defined by PSTN 1.2
#define CDC_SET_COMM_FEATURE                            0x02
#define CDC_GET_COMM_FEATURE                            0x03
#define CDC_CLEAR_COMM_FEATURE                          0x04
#define CDC_SET_AUX_LINE_STATE                          0x10
#define CDC_SET_HOOK_STATE                              0x11
#define CDC_PULSE_SETUP                                 0x12
#define CDC_SEND_PULSE                                  0x13
#define CDC_SET_PULSE_TIME                              0x14
#define CDC_RING_AUX_JACK                               0x15
#define CDC_SET_LINE_CODING                             0x20
#define CDC_GET_LINE_CODING                             0x21
#define CDC_SET_CONTROL_LINE_STATE                      0x22
#define CDC_SEND_BREAK                                  0x23
#define CDC_SET_RINGER_PARMS                            0x30
#define CDC_GET_RINGER_PARMS                            0x31
#define CDC_SET_OPERATION_PARMS                         0x32
#define CDC_GET_OPERATION_PARMS                         0x33
#define CDC_SET_LINE_PARMS                              0x34
#define CDC_GET_LINE_PARMS                              0x35
#define CDC_DIAL_DIGITS                                 0x36

typedef enum { PL2303_TYPE_UNKNOWN, PL2303_TYPE_0, PL2303_TYPE_1, PL2303_TYPE_HX } pl2303_type_t;

typedef struct {
  ep_t ep[3];
  pl2303_type_t type;
  uint32_t qNextBulkPollTime;    // next bulk poll time
  uint32_t qNextIrqPollTime;     // next irq poll time
  uint8_t ep_int_idx;            // index of interrupt ep
  uint8_t ep_bulk_in_idx;        // 
  uint8_t ep_bulk_out_idx;       //
  uint8_t int_poll_ms;           // poll interval in ms
  line_coding_t line_coding;     // current line coding
  bool bPollEnable;
#ifdef PL2303_STAT
  uint32_t tx_cnt, rx_cnt;
#endif
} usb_pl2303_info_t;

// interface to usb core
extern const usb_device_class_config_t usb_pl2303_class;

// interface to higher levels
int8_t pl2303_present(void);
void pl2303_settings(uint32_t rate, uint8_t bits, uint8_t parity, uint8_t stop);
void pl2303_tx(uint8_t *data, uint8_t len);
void pl2303_tx_byte(uint8_t byte);
uint8_t pl2303_rx_available(void);
uint8_t pl2303_rx(void);
int8_t pl2303_is_blocked(void);

#endif // PL2303_H
