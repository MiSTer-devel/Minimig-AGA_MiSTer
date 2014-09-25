#ifndef USBRTC_H
#define USBRTC_H

#include <stdbool.h>
#include <inttypes.h>

typedef struct {
} usb_usbrtc_info_t;

// interface to usb core
extern const usb_device_class_config_t usb_usbrtc_class;

uint8_t usb_rtc_get_time(uint8_t *d);
uint8_t usb_rtc_set_time(uint8_t *d);

#endif // USBRTC_H
