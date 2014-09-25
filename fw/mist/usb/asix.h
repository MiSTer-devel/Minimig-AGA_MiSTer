#ifndef ASIX_H
#define ASIX_H

#include <stdbool.h>
#include <inttypes.h>
#include "asix_const.h"

typedef struct {
  ep_t ep[3];
  uint16_t phy_id;
  uint32_t qNextIrqPollTime;     // next irq poll time
  uint8_t ep_int_idx;         // index of interrupt ep
  uint8_t int_poll_ms;        // poll interval in ms
  bool bPollEnable;
  bool linkDetected;
  uint8_t mac[ETH_ALEN];
  uint32_t qNextBulkPollTime;     // next bulk poll time
} usb_asix_info_t;

// interface to usb core
extern const usb_device_class_config_t usb_asix_class;
void usb_asix_xmit(uint16_t len);

#endif // ASIX_H
