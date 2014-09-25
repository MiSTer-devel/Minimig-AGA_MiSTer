#ifndef HIDPARSER_H
#define HIDPARSER_H

#define CONFIG_TYPE_NONE     0
#define CONFIG_TYPE_MOUSE    1
#define CONFIG_TYPE_KEYBOARD 2
#define CONFIG_TYPE_JOYSTICK 3

// currently only joysticks are supported
typedef struct {
  uint8_t type: 2;             // CONFIG_TYPE_...
  uint8_t report_id;
  uint8_t report_size;

  union {
    struct {
      uint8_t axis_byte_offset[2];   // x and y axis
      struct {
	uint8_t byte_offset;
	uint8_t bitmask;
      } button[4];
    } joystick;
  };
} hid_config_t;

#define MAX_CONF 2
extern hid_config_t hid_conf[MAX_CONF];

bool parse_report_descriptor(uint8_t *rep, uint16_t rep_size);

#endif // HIDPARSER_H
