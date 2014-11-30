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
      struct {
	uint8_t byte_offset;
	uint8_t size;          // 8 or 16 bits supported
	struct {
	  uint16_t min;
	  uint16_t max;
	} logical;
      } axis[2];               // x and y axis

      struct {
	uint8_t byte_offset;
	uint8_t bitmask;
      } button[4];             // 4 buttons
    } joystick;
  };
} hid_config_t;

bool parse_report_descriptor(uint8_t *rep, uint16_t rep_size, hid_config_t *conf);

#endif // HIDPARSER_H
