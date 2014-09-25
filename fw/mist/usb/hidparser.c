// http://www.frank-zhao.com/cache/hid_tutorial_1.php

#include <inttypes.h>
#include <stdbool.h>
#include <stdio.h>

#include "hidparser.h"
#include "debug.h"

#if 0
#define hidp_extreme_debugf(...) hidp_debugf(__VA_ARGS__)
#else
#define hidp_extreme_debugf(...)
#endif

typedef struct {
  uint8_t bSize: 2;
  uint8_t bType: 2;
  uint8_t bTag: 4;
} __attribute__((packed)) item_t;

// flags for joystick components required
#define JOYSTICK_REQ_AXIS_X  0x01
#define JOYSTICK_REQ_AXIS_Y  0x02
#define JOYSTICK_REQ_BTN_0   0x04
#define JOYSTICK_COMPLETE    (JOYSTICK_REQ_AXIS_X | JOYSTICK_REQ_AXIS_Y | JOYSTICK_REQ_BTN_0)

hid_config_t hid_conf[MAX_CONF];

#define USAGE_PAGE_GENERIC_DESKTOP  1
#define USAGE_PAGE_SIMULATION       2
#define USAGE_PAGE_VR               3
#define USAGE_PAGE_SPORT            4
#define USAGE_PAGE_GAMING           5
#define USAGE_PAGE_GENERIC_DEVICE   6
#define USAGE_PAGE_KEYBOARD         7
#define USAGE_PAGE_LEDS             8
#define USAGE_PAGE_BUTTON           9
#define USAGE_PAGE_ORDINAL         10
#define USAGE_PAGE_TELEPHONY       11
#define USAGE_PAGE_CONSUMER        12


#define USAGE_POINTER   1
#define USAGE_MOUSE     2
#define USAGE_JOYSTICK  4
#define USAGE_GAMEPAD   5
#define USAGE_KEYBOARD  6
#define USAGE_KEYPAD    7
#define USAGE_MULTIAXIS 8

#define USAGE_X       48
#define USAGE_Y       49
#define USAGE_Z       50
#define USAGE_WHEEL   56

bool parse_report_descriptor(uint8_t *rep, uint16_t rep_size) {
  int8_t app_collection = 0;
  int8_t phys_log_collection = 0;
  uint8_t skip_collection = 0;
  int8_t generic_desktop = -1;   // depth at which first gen_desk was found
  uint8_t collection_depth = 0;

  uint8_t i;

  // 
  uint8_t report_size, report_count, config_idx = 0;
  uint16_t bit_count = 0, usage_count = 0;

  // mask used to check of all required components have been found, so
  // that e.g. both axes and the button of a joystick are ready to be used
  uint8_t setup_complete = 0;

  // joystick/mouse components
  int8_t axis[2] = { -1, -1};
  uint8_t btns = 0;

  for(i=0;i<MAX_CONF;i++)
    hid_conf[i].type = CONFIG_TYPE_NONE;

  while(rep_size) {
    // extract short item
    uint8_t tag = ((item_t*)rep)->bTag;
    uint8_t type = ((item_t*)rep)->bType;
    uint8_t size = ((item_t*)rep)->bSize;

    rep++;
    rep_size--;   // one byte consumed
    
    uint32_t value = 0;
    if(size) {      // size 1/2/3
      value = *rep++;
      rep_size--;
    }

    if(size > 1) {  // size 2/3
      value = (value & 0xff) + ((uint32_t)(*rep++)<<8);
      rep_size--;
    }

    if(size > 2) {  // size 3
      value &= 0xffff;
      value |= ((uint32_t)(*rep++)<<16);
      value |= ((uint32_t)(*rep++)<<24);
      rep_size-=2;
    }

    //    hidp_extreme_debugf("Value = %d (%u)\n", value, value);
    
    // we are currently skipping an unknown/unsupported collection) 
    if(skip_collection) {
      if(!type) {  // main item
	// any new collection increases the depth of collections to skip
	if(tag == 10) {
	  skip_collection++;
	  collection_depth++;
	}

	// any end collection decreases it
	if(tag == 12) {
	  skip_collection--;
	  collection_depth--;

	  // leaving the depth the generic desktop was valid for
	  if(generic_desktop > collection_depth)
	    generic_desktop = -1;
	}
      }

      
    } else {
      //      hidp_extreme_debugf("-> Item tag=%d type=%d size=%d\n", tag, type, size);

      switch(type) {
      case 0:
	// main item
	
	switch(tag) {
	case 8:
	  // 
	  if(btns) {
	    if(hid_conf[config_idx].type == CONFIG_TYPE_JOYSTICK) {
	      // scan for up to four buttons
	      char b;
	      for(b=0;b<4;b++) {
		if(report_count > b) {
		  uint16_t this_bit = bit_count+b;

		  hidp_debugf("BUTTON%d @ %d (byte %d, mask %d)\n", b, 
			      this_bit, this_bit/8, 1 << (this_bit%8));

		  hid_conf[config_idx].joystick.button[b].byte_offset = this_bit/8;
		  hid_conf[config_idx].joystick.button[b].bitmask = 1 << (this_bit%8);
		}
	      }

	      // we found at least one button which is all we want to accept this as a valid 
	      // joystick
	      setup_complete |= JOYSTICK_REQ_BTN_0;
	    }
	  }

	  // 
	  char c;
	  for(c=0;c<2;c++) {
	    if(axis[c] >= 0) {
	      uint16_t cnt = bit_count + report_size * axis[c];
	      hidp_debugf("  (%c-AXIS @ %d (byte %d))\n", 'X'+c,
		     cnt, cnt/8);

	      // only 8 bit axes at byte boundaries are supported for
	      // joysticks
	      if((hid_conf[config_idx].type == CONFIG_TYPE_JOYSTICK) &&
		 (report_size == 8) && ((cnt&7) == 0)) {
		// save in joystick config
		hid_conf[config_idx].joystick.axis_byte_offset[c] = cnt/8;
		if(c==0) setup_complete |= JOYSTICK_REQ_AXIS_X;
		if(c==1) setup_complete |= JOYSTICK_REQ_AXIS_Y;
	      }

	      if(report_size != 8) 
		hidp_debugf("Unsupported report size %d\n", report_size);

	      if((cnt&7) != 0) 
		hidp_debugf("Unsupported bit offset %d\n", cnt&7);
	    }
	  }
	  
	  hidp_extreme_debugf("INPUT(%d)\n", value);

	  // reset for next inputs
	  bit_count += report_count * report_size;
	  usage_count = 0;
	  btns = 0;
	  axis[0] = axis[1] = -1;
	  break;

	case 9:
	  hidp_extreme_debugf("OUTPUT(%d)\n", value);
	  break;

	case 11:
	  hidp_extreme_debugf("FEATURE(%d)\n", value);
	  break;

	case 10:
	  hidp_extreme_debugf("COLLECTION(%d)\n", value);
	  collection_depth++;
	  usage_count = 0;

	  if(value == 1) {	   // app collection
	    hidp_extreme_debugf("  -> application\n");
	    app_collection++;
	  } else if(value == 0) {  // physical collection
	    hidp_extreme_debugf("  -> physical\n");
	    phys_log_collection++;
	  } else if(value == 2) {  // logical collection
	    hidp_extreme_debugf("  -> logical\n");
	    phys_log_collection++;
	  } else {
	    hidp_extreme_debugf("skipping unsupported collection\n");
	    skip_collection++;
	  }
	  break;
	  
	case 12:
	  hidp_extreme_debugf("END_COLLECTION(%d)\n", value);
	  collection_depth--;

	  // leaving the depth the generic desktop was valid for
	  if(generic_desktop > collection_depth)
	    generic_desktop = -1;

	  if(phys_log_collection) {
	    hidp_extreme_debugf("  -> phys/log end\n");
	    phys_log_collection--;
	  } else if(app_collection) {
	    hidp_extreme_debugf("  -> app end\n");
	    app_collection--;
	  } else {
	    hidp_debugf(" -> unexpected\n");
	    return false;
	  }
	  break;

	default:
	  hidp_debugf("unexpected main item %d\n", tag);
	  return false;
	  break;
	}
	break;
	
      case 1:
	// global item
	switch(tag) {
	case 0:
	  hidp_extreme_debugf("USAGE_PAGE(%d/0x%x)\n", value, value);

	  if(value == USAGE_PAGE_KEYBOARD) {
	    hidp_extreme_debugf(" -> Keyboard\n");
	  } else if(value == USAGE_PAGE_GAMING) {
	    hidp_extreme_debugf(" -> Game device\n");
	  } else if(value == USAGE_PAGE_LEDS) {
	    hidp_extreme_debugf(" -> LEDs\n");
	  } else if(value == USAGE_PAGE_CONSUMER) {
	    hidp_extreme_debugf(" -> Consumer\n");
	  } else if(value == USAGE_PAGE_BUTTON) {
	    hidp_extreme_debugf(" -> Buttons\n");
	    btns = 1;
	  } else if(value == USAGE_PAGE_GENERIC_DESKTOP) {
	    hidp_extreme_debugf(" -> Generic Desktop\n");

	    if(generic_desktop < 0)
	      generic_desktop = collection_depth;
	  } else
	    hidp_extreme_debugf(" -> UNSUPPORTED USAGE_PAGE\n");

	  break;
	  
	case 1:
	  hidp_extreme_debugf("LOGICAL_MINIMUM(%d/%d)\n", value, (int8_t)value);
	  break;
	  
	case 2:
	  hidp_extreme_debugf("LOGICAL_MAXIMUM(%d)\n", value);
	  break;

	case 3:
	  hidp_extreme_debugf("PHYSICAL_MINIMUM(%d/%d)\n", value, (int8_t)value);
	  break;
	  
	case 4:
	  hidp_extreme_debugf("PHYSICAL_MAXIMUM(%d)\n", value);
	  break;

	case 5:
	  hidp_extreme_debugf("UNIT_EXPONENT(%d)\n", value);
	  break;

	case 6:
	  hidp_extreme_debugf("UNIT(%d)\n", value);
	  break;

	case 7:
	  hidp_extreme_debugf("REPORT_SIZE(%d)\n", value);
	  report_size = value;
	  break;

	case 8:
	  hidp_extreme_debugf("REPORT_ID(%d)\n", value);
	  hid_conf[config_idx].report_id = value;
	  break;

	case 9:
	  hidp_extreme_debugf("REPORT_COUNT(%d)\n", value);
	  report_count = value;
	  break;
	  
	default:
	  hidp_debugf("unexpected global item %d\n", tag);
	  return false;
	  break;
	}
	break;
	
      case 2:
	// local item
	switch(tag) {
	case 0:
	  // we only support mice, keyboards and joysticks
	  hidp_extreme_debugf("USAGE(%d/0x%x)\n", value, value);

	  if( !collection_depth && (value == USAGE_KEYBOARD)) {
	    // usage(keyboard) is always allowed
	    hidp_debugf(" -> Keyboard\n");
	    hid_conf[config_idx].type = CONFIG_TYPE_KEYBOARD;
	  } else if(!collection_depth && (value == USAGE_MOUSE)) {
	    // usage(mouse) is always allowed
	    hidp_debugf(" -> Mouse\n");
	    hid_conf[config_idx].type = CONFIG_TYPE_MOUSE;
	  } else if(!collection_depth && 
		    ((value == USAGE_GAMEPAD) || (value == USAGE_JOYSTICK))) {
	    hidp_extreme_debugf(" -> Gamepad/Joystick\n");
	    hidp_debugf("Gamepad/Joystick usage found\n");
	    hid_conf[config_idx].type = CONFIG_TYPE_JOYSTICK;
	  } else if(value == USAGE_POINTER && app_collection) {
	    // usage(pointer) is allowed within the application collection

	    hidp_debugf(" -> Pointer\n");

	  } else if((value == USAGE_X || value == USAGE_Y) && app_collection) {
	    // usage(x) and usage(y) are allowed within the app collection
	    hidp_extreme_debugf(" -> axis usage\n");

	    // we support x and y axis on joysticks
	    if(hid_conf[config_idx].type == CONFIG_TYPE_JOYSTICK) {
	      if(value == USAGE_X) {
		hidp_extreme_debugf("JOYSTICK: found x axis @ %d\n", usage_count);
		axis[0] = usage_count;
	      }
	      if(value == USAGE_Y) {
		hidp_extreme_debugf("JOYSTICK: found y axis @ %d\n", usage_count);
		axis[1] = usage_count;
	      }
	    }
	  } else {
	    hidp_extreme_debugf(" -> UNSUPPORTED USAGE\n");
	    //	    return false;
	  }

	  usage_count++;
	  break;
	  
	case 1:
	  hidp_extreme_debugf("USAGE_MINIMUM(%d)\n", value);
	  usage_count -= (value-1);
	  break;
	  
	case 2:
	  hidp_extreme_debugf("USAGE_MAXIMUM(%d)\n", value);
	  usage_count += value;
	  break;
	  
	default:
	  hidp_extreme_debugf("unexpected local item %d\n", tag);
	  //	  return false;
	  break;
	}
	break;
	
      default:
	// reserved
	hidp_extreme_debugf("unexpected resreved item %d\n", tag);
	//	return false;
	break;
      }
    }
  }

  hidp_debugf("total bit count: %d (%d bytes, %d bits)\n", 
	 bit_count, bit_count/8, bit_count%8);

  hid_conf[config_idx].report_size = bit_count/8;

  // check if something useful was detected
  if(hid_conf[config_idx].type == CONFIG_TYPE_JOYSTICK) {
    if(setup_complete == JOYSTICK_COMPLETE) {
      hidp_debugf("Joystick ok\n");
      return true;
    }

    hidp_debugf("Ignoring incomplete joystick %x\n", setup_complete);
  } else
    hidp_debugf("No joystick %d\n", config_idx);

  return false;
}
