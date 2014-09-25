#include <stdio.h>

#include "timer.h"
#include "max3421e.h"
#include "usb.h"

static uint8_t usb_task_state;
static uint8_t bmHubPre;

static usb_device_t dev[USB_NUMDEVICES];

void usb_reset_state() {
  puts(__FUNCTION__);
  bmHubPre	 = 0;
}

usb_device_t *usb_get_devices() {
  return dev;
}

void usb_init() {
  puts(__FUNCTION__);

  max3421e_init();   // init underlaying hardware layer

  usb_task_state = USB_DETACHED_SUBSTATE_INITIALIZE; 

  uint8_t i;
  for(i=0;i<USB_NUMDEVICES;i++)
    dev[i].bAddress = 0;

  usb_reset_state();
}

uint8_t usb_set_address(usb_device_t *dev, ep_t *ep, 
			uint16_t *nak_limit) {
  //  iprintf("  %s(addr=%x, ep=%d)\n", __FUNCTION__, addr, ep);
  *nak_limit = (1UL << ( ( ep->bmNakPower > USB_NAK_MAX_POWER ) ? 
			 USB_NAK_MAX_POWER : ep->bmNakPower) ) - 1;
  
  /*
    iprintf("\nAddress: %x\n", addr);
    iprintf(" EP: %d\n", ep);
    iprintf(" NAK Power: %d\n",(*ppep)->bmNakPower);
    iprintf(" NAK Limit: %d\n", nak_limit);
  */
  
  max3421e_write_u08( MAX3421E_PERADDR, dev->bAddress); // set peripheral address
  
  uint8_t mode = max3421e_read_u08( MAX3421E_MODE );
  
  // Set bmLOWSPEED and bmHUBPRE in case of low-speed device, 
  // reset them otherwise
  max3421e_write_u08( MAX3421E_MODE, 
		      (dev->lowspeed) ? mode |   MAX3421E_LOWSPEED | bmHubPre : 
		                      mode & ~(MAX3421E_HUBPRE | MAX3421E_LOWSPEED)); 
  
  return 0;
}

/* dispatch usb packet. Assumes peripheral address is set and relevant */
/* buffer is loaded/empty */
/* If NAK, tries to re-send up to nak_limit times  */
/* If nak_limit == 0, do not count NAKs, exit after timeout */
/* If bus timeout, re-sends up to USB_RETRY_LIMIT times */
/* return codes 0x00-0x0f are HRSLT (0x00 being success), 0xff means timeout */
uint8_t usb_dispatchPkt( uint8_t token, uint8_t ep, uint16_t nak_limit ) {
  //  iprintf("  %s(token=%x, ep=%d, nak_limit=%d)\n", 
  //	  __FUNCTION__, token, ep, nak_limit);
  unsigned long timeout = timer_get_msec() + USB_XFER_TIMEOUT;
  uint8_t tmpdata;   
  uint8_t rcode = 0x00;
  uint8_t retry_count = 0;
  uint16_t nak_count = 0;
	
  while( timeout > timer_get_msec() )  {
    max3421e_write_u08( MAX3421E_HXFR, ( token|ep )); //launch the transfer
    rcode = USB_ERROR_TRANSFER_TIMEOUT;   
    
    // wait for transfer completion
    while( timer_get_msec() < timeout )	{
      tmpdata = max3421e_read_u08( MAX3421E_HIRQ );

      if( tmpdata & MAX3421E_HXFRDNIRQ ) {
	//clear the interrupt
	max3421e_write_u08( MAX3421E_HIRQ, MAX3421E_HXFRDNIRQ );
	rcode = 0x00;
	break;
      }
    }

    if( rcode != 0x00 )                 //exit if timeout
      return( rcode );

    //analyze transfer result
    rcode = ( max3421e_read_u08( MAX3421E_HRSL ) & 0x0f );

    switch( rcode ) {

    case hrNAK:
      nak_count++;
      if( nak_limit && ( nak_count == nak_limit ))
	return( rcode );
      break;

    case hrTIMEOUT:
      retry_count++;
      if( retry_count == USB_RETRY_LIMIT )
	return( rcode );
      break;

    default:
      return( rcode );
    }
  }

  return( rcode );
}

uint8_t usb_InTransfer(ep_t *pep, uint16_t nak_limit, 
		       uint16_t *nbytesptr, uint8_t* data) {
  uint8_t rcode = 0;
  uint8_t pktsize;
  
  uint16_t	nbytes		= *nbytesptr;
  uint8_t	maxpktsize	= pep->maxPktSize; 

  *nbytesptr = 0;
  // set toggle value
  max3421e_write_u08( MAX3421E_HCTL, 
	      (pep->bmRcvToggle) ? MAX3421E_RCVTOG1 : MAX3421E_RCVTOG0 );
  
  // use a 'return' to exit this loop
  while( 1 ) { 
    //IN packet to EP-'endpoint'. Function takes care of NAKS.
    rcode = usb_dispatchPkt( tokIN, pep->epAddr, nak_limit );
      
    //should be 0, indicating ACK. Else return error code.
    if( rcode )
      return( rcode );
    
    /* check for RCVDAVIRQ and generate error if not present */ 
    /* the only case when absense of RCVDAVIRQ makes sense is when */
    /* toggle error occured. Need to add handling for that */
    if(( max3421e_read_u08( MAX3421E_HIRQ ) & MAX3421E_RCVDAVIRQ ) == 0 ) 
      return ( 0xf0 );                            //receive error
    
    pktsize = max3421e_read_u08( MAX3421E_RCVBC ); // number of received bytes
        
    int16_t mem_left = (int16_t)nbytes - *((int16_t*)nbytesptr);

    if (mem_left < 0)
      mem_left = 0;

    data = max3421e_read(MAX3421E_RCVFIFO, 
		 ((pktsize > mem_left) ? mem_left : pktsize), data );
    
    // Clear the IRQ & free the buffer
    max3421e_write_u08( MAX3421E_HIRQ, MAX3421E_RCVDAVIRQ );
    *nbytesptr += pktsize;							
    // add this packet's byte count to total transfer length
    /* The transfer is complete under two conditions:           */
    /* 1. The device sent a short packet (L.T. maxPacketSize)   */
    /* 2. 'nbytes' have been transferred.                       */

    // have we transferred 'nbytes' bytes?
    if (( pktsize < maxpktsize ) || (*nbytesptr >= nbytes )) {     
      // Save toggle value
      pep->bmRcvToggle = (( max3421e_read_u08( MAX3421E_HRSL ) & 
			    MAX3421E_RCVTOGRD )) ? 1 : 0;
      
      return 0;
    }
  }
}

/* IN transfer to arbitrary endpoint. Assumes PERADDR is set. Handles multiple packets */
/* if necessary. Transfers 'nbytes' bytes. Keep sending INs and writes data to memory area */
/* pointed by 'data' */
/* rcode 0 if no errors. rcode 01-0f is relayed from dispatchPkt(). Rcode f0 means RCVDAVIRQ error, */
/* fe USB xfer timeout */
uint8_t usb_in_transfer( usb_device_t *dev, ep_t *ep, uint16_t *nbytesptr, uint8_t* data) {
  uint16_t nak_limit = 0;

  uint8_t rcode = usb_set_address(dev, ep, &nak_limit);
  if (rcode) return rcode;

  return usb_InTransfer(ep, nak_limit, nbytesptr, data);
}

uint8_t usb_OutTransfer(ep_t *pep, uint16_t nak_limit, 
			uint16_t nbytes, uint8_t *data) {
  //  iprintf("%s(%d)\n", __FUNCTION__, nbytes);

  uint8_t rcode = 0, retry_count;
  uint16_t bytes_tosend, nak_count;
  uint16_t bytes_left = nbytes;
  
  uint8_t maxpktsize = pep->maxPktSize; 
 
  if (maxpktsize < 1 || maxpktsize > 64)
    return USB_ERROR_INVALID_MAX_PKT_SIZE;
 
  unsigned long timeout = timer_get_msec() + USB_XFER_TIMEOUT;
 
  //set toggle value
  max3421e_write_u08(MAX3421E_HCTL, 
     (pep->bmSndToggle) ? MAX3421E_SNDTOG1 : MAX3421E_SNDTOG0 );
  
  while( bytes_left ) {
    retry_count = 0;
    nak_count = 0;
    bytes_tosend = ( bytes_left >= maxpktsize ) ? maxpktsize : bytes_left;

    //filling output FIFO
    max3421e_write( MAX3421E_SNDFIFO, bytes_tosend, data );
    
    //set number of bytes
    max3421e_write_u08( MAX3421E_SNDBC, bytes_tosend );

    // dispatch packet
    max3421e_write_u08( MAX3421E_HXFR, ( tokOUT | pep->epAddr ));

    //wait for the completion IRQ
    while(!(max3421e_read_u08( MAX3421E_HIRQ ) & MAX3421E_HXFRDNIRQ ));
    max3421e_write_u08( MAX3421E_HIRQ, MAX3421E_HXFRDNIRQ );    //clear IRQ
    rcode = max3421e_read_u08( MAX3421E_HRSL ) & 0x0f;
    
    while( rcode && ( timeout > timer_get_msec())) {
      switch( rcode ) {
      case hrNAK:
	nak_count ++;
	if( nak_limit && ( nak_count == nak_limit )) 
	  return( rcode );
	break;
      case hrTIMEOUT:
	retry_count ++;
	if( retry_count == USB_RETRY_LIMIT ) 
	  return( rcode );
	break;
      default:
	return( rcode );
      }
      
      /* process NAK according to Host out NAK bug */
      max3421e_write_u08( MAX3421E_SNDBC, 0 );
      max3421e_write_u08( MAX3421E_SNDFIFO, *data );
      max3421e_write_u08( MAX3421E_SNDBC, bytes_tosend );

      // dispatch packet
      max3421e_write_u08( MAX3421E_HXFR, ( tokOUT | pep->epAddr ));

      // wait for the completion IRQ
      while(!(max3421e_read_u08( MAX3421E_HIRQ ) & MAX3421E_HXFRDNIRQ ));
      max3421e_write_u08( MAX3421E_HIRQ, MAX3421E_HXFRDNIRQ );      // clear IRQ
      rcode = ( max3421e_read_u08( MAX3421E_HRSL ) & 0x0f );
    }//while( rcode && ....
    bytes_left -= bytes_tosend;
    data += bytes_tosend;
  }//while( bytes_left...

  //update toggle
  pep->bmSndToggle = ( max3421e_read_u08( MAX3421E_HRSL ) & MAX3421E_SNDTOGRD ) ? 1 : 0;
  return( rcode );    //should be 0 in all cases
}

/* OUT transfer to arbitrary endpoint. Handles multiple packets if necessary. Transfers 'nbytes' bytes. */
/* Handles NAK bug per Maxim Application Note 4000 for single buffer transfer   */
/* rcode 0 if no errors. rcode 01-0f is relayed from HRSL                       */
uint8_t usb_out_transfer(usb_device_t *dev, ep_t *ep, uint16_t nbytes, uint8_t* data ) {
  uint16_t nak_limit = 0;

  uint8_t rcode = usb_set_address(dev, ep, &nak_limit);
  if (rcode) return rcode;

  return usb_OutTransfer(ep, nak_limit, nbytes, data);
}

/* Control transfer. Sets address, endpoint, fills control packet */
/* with necessary data, dispatches control packet, and initiates */
/* bulk IN transfer, depending on request. Actual requests are defined */
/* as inlines                   */
/* return codes:                */
/* 00       =   success         */
/* 01-0f    =   non-zero HRSLT  */

uint8_t usb_ctrl_req(usb_device_t *dev, uint8_t bmReqType, 
		    uint8_t bRequest, uint8_t wValLo, uint8_t wValHi, 
		    uint16_t wInd, uint16_t nbytes, uint8_t* dataptr) {
  //  iprintf("%s(addr=%x, len=%d, ptr=%p)\n", __FUNCTION__,
  //	  dev->bAddress, nbytes, dataptr);
  bool direction = false;     //request direction, IN or OUT
  uint8_t rcode;   
  setup_pkt_t setup_pkt;
  uint16_t	nak_limit;
  
  rcode = usb_set_address(dev, &(dev->ep0), &nak_limit);
  if (rcode)
    return rcode;
  
  direction = (( bmReqType & 0x80 ) > 0);

  /* fill in setup packet */
  setup_pkt.ReqType_u.bmRequestType	= bmReqType;
  setup_pkt.bRequest			= bRequest;
  setup_pkt.wVal_u.wValueLo		= wValLo;
  setup_pkt.wVal_u.wValueHi		= wValHi;
  setup_pkt.wIndex			= wInd;
  setup_pkt.wLength			= nbytes;
  
  // transfer to setup packet FIFO
  max3421e_write(MAX3421E_SUDFIFO, sizeof(setup_pkt_t), (uint8_t*)&setup_pkt );
  
  rcode = usb_dispatchPkt( tokSETUP, 0, nak_limit );     //dispatch packet
  if( rcode )		//return HRSLT if not zero
    return( rcode );
  
  // data stage, if present
  if( dataptr != NULL )	{
    if( direction ) { //IN transfer
      dev->ep0.bmRcvToggle = 1;
      rcode = usb_InTransfer( &(dev->ep0), nak_limit, &nbytes, dataptr );
    } else { //OUT transfer
      dev->ep0.bmSndToggle = 1;
      rcode = usb_OutTransfer( &(dev->ep0), nak_limit, nbytes, dataptr );
    }    

    //return error
    if( rcode )	return( rcode );
  }

  // Status stage
  // GET if direction
  return usb_dispatchPkt( (direction) ? tokOUTHS : tokINHS, 0, nak_limit );
}

// list of supported device classes
static const usb_device_class_config_t *class_list[] = {
  &usb_hub_class,
  &usb_hid_class,
  &usb_asix_class,
  &usb_storage_class,
  &usb_usbrtc_class,
  NULL
};

uint8_t usb_configure(uint8_t parent, uint8_t port, bool lowspeed) {
  uint8_t rcode = 0;
  iprintf("%s(parent=%x port=%d lowspeed=%d)\n", __FUNCTION__, parent, port, lowspeed);

  // find an empty device entry
  uint8_t i;
  for(i=0; i<USB_NUMDEVICES && dev[i].bAddress; i++);

  if(i < USB_NUMDEVICES) {
    iprintf("using free entry at %d\n", i);

    usb_device_t *d = dev+i;

    // setup generic info
    d->bAddress = 0;
    d->parent = parent;
    d->lowspeed = lowspeed;
    d->port = port;
    d->class = NULL;

    // setup endpoint 0
    d->ep0.epAddr	= 0;
    d->ep0.maxPktSize	= 8;
    d->ep0.epAttribs	= 0;
    d->ep0.bmNakPower	= USB_NAK_MAX_POWER;

    // --- enumerate device ---

    // Assign new address to the device
    // (address is simply the number of the free slot + 1)
    iprintf("Setting addr %x\n", i+1);
    rcode = usb_set_addr(d, i+1);
    if(rcode) {
      puts("failed to assign address");
      return rcode;
    }

    // try to connect device to one of the supported classes
    uint8_t c;
    for(c=0;class_list[c];c++) {
      iprintf("trying to init class %d\n", c);
      rcode = class_list[c]->init(d);

      if (!rcode) {
	d->class = class_list[c];

	puts(" -> accepted :-)");
	// ok, device accepted by class

	return 0;
      }
  
      puts(" -> not accepted :-(");
    }
  } else
    iprintf("no more free entries\n");

  iprintf("unsupported device\n");
  return 0;
}

void usb_poll() {
  uint8_t rcode;
  uint8_t tmpdata;
  static msec_t delay = 0;
  bool lowspeed = false;

  // poll underlaying hardware layer
  tmpdata = max3421e_poll();
  
  /* modify USB task state if Vbus changed */
  switch( tmpdata )  {

    // illegal state
  case MAX3421E_STATE_SE1:   
    usb_task_state = USB_DETACHED_SUBSTATE_ILLEGAL;
    lowspeed = false;
    break;

    // disconnected
  case MAX3421E_STATE_SE0:
    if(( usb_task_state & USB_STATE_MASK ) != USB_STATE_DETACHED ) 
      usb_task_state = USB_DETACHED_SUBSTATE_INITIALIZE;
    lowspeed = false;
    break;

    // attached
  case MAX3421E_STATE_LSHOST:
    lowspeed = true;
    // intentional fall-through ...

  case MAX3421E_STATE_FSHOST:
    if(( usb_task_state & USB_STATE_MASK ) == USB_STATE_DETACHED ) {
      delay = timer_get_msec() + USB_SETTLE_DELAY;
      usb_task_state = USB_ATTACHED_SUBSTATE_SETTLE;
    }
    break;
  }

  // max poll 1ms
  static msec_t poll=0;
  if(timer_get_msec() > poll) {
    poll = timer_get_msec()+1;

    // poll all configured devices
    uint8_t i;
    for (i=0; i<USB_NUMDEVICES; i++)
      if(dev[i].bAddress && dev[i].class && dev[i].class->poll)
	rcode = dev[i].class->poll(dev+i);
    
    switch( usb_task_state ) {
    case USB_DETACHED_SUBSTATE_INITIALIZE:
      usb_reset_state();
      
      // just remove everything ...
      for (i=0; i<USB_NUMDEVICES; i++) {
	if(dev[i].bAddress && dev[i].class) {
	  rcode = dev[i].class->release(dev+i);
	  dev[i].bAddress = 0;
	}
      }
    
      usb_task_state = USB_DETACHED_SUBSTATE_WAIT_FOR_DEVICE;
      break;
      
    case USB_DETACHED_SUBSTATE_WAIT_FOR_DEVICE:
    case USB_DETACHED_SUBSTATE_ILLEGAL:
      break;
      
    case USB_ATTACHED_SUBSTATE_SETTLE:              //settle time for just attached device            
      if( delay < timer_get_msec() ) 
	usb_task_state = USB_ATTACHED_SUBSTATE_RESET_DEVICE;
      break;
      
    case USB_ATTACHED_SUBSTATE_RESET_DEVICE:
      max3421e_write_u08( MAX3421E_HCTL, MAX3421E_BUSRST );	             // issue bus reset
      usb_task_state = USB_ATTACHED_SUBSTATE_WAIT_RESET_COMPLETE;
      break;
      
    case USB_ATTACHED_SUBSTATE_WAIT_RESET_COMPLETE:
      if(( !max3421e_read_u08( MAX3421E_HCTL ) & MAX3421E_BUSRST ) ) {
	tmpdata = max3421e_read_u08( MAX3421E_MODE ) | MAX3421E_SOFKAENAB;   // start SOF generation
	max3421e_write_u08( MAX3421E_MODE, tmpdata );
	usb_task_state = USB_ATTACHED_SUBSTATE_WAIT_SOF;
	delay = timer_get_msec() + 20;                           //20ms wait after reset per USB spec
      }
      break;
      
    case USB_ATTACHED_SUBSTATE_WAIT_SOF:  //todo: change check order
      if( max3421e_read_u08( MAX3421E_HIRQ ) & MAX3421E_FRAMEIRQ ) { //when first SOF received we can continue
	if( delay < timer_get_msec() ) //20ms passed
	  usb_task_state = USB_STATE_CONFIGURING;
      }
      break;
      
    case USB_STATE_CONFIGURING:
      // configure root device
      usb_configure(0, 0, lowspeed);
      usb_task_state = USB_STATE_RUNNING;
    break;
    
    case USB_STATE_RUNNING:
      break;
    }
  }
}

uint8_t usb_release_device(uint8_t parent, uint8_t port) {
  iprintf("%s(parent=%x, port=%d\n", __FUNCTION__, parent, port);

  uint8_t i;
  for(i=0; i<USB_NUMDEVICES; i++) {
    if(dev[i].bAddress && dev[i].parent == parent && dev[i].port == port) {
      iprintf("  -> device with address %x\n", dev[i].bAddress);

      // check if this is a hub (parent of some other device)
      // and release its kids first
      uint8_t j;
      for(j=0; j<USB_NUMDEVICES; j++) {
	if(dev[j].parent == dev[i].bAddress)
	  usb_release_device(dev[i].bAddress, dev[j].port);
      }
      
      uint8_t rcode = 0;
      if(dev[i].class)
	rcode = dev[i].class->release(dev+i);

      dev[i].bAddress = 0;
      return rcode;	
    }
  }

  // this should never happen ...
  return 0;
}

uint8_t usb_get_dev_descr( usb_device_t *dev, uint16_t nbytes, usb_device_descriptor_t* p )  {
  return( usb_ctrl_req( dev, USB_REQ_GET_DESCR, USB_REQUEST_GET_DESCRIPTOR, 
	       0x00, USB_DESCRIPTOR_DEVICE, 0x0000, nbytes, (uint8_t*)p));
}

//get configuration descriptor  
uint8_t usb_get_conf_descr( usb_device_t *dev, uint16_t nbytes, 
			    uint8_t conf, usb_configuration_descriptor_t* p )  {
  return( usb_ctrl_req( dev, USB_REQ_GET_DESCR, USB_REQUEST_GET_DESCRIPTOR, 
	       conf, USB_DESCRIPTOR_CONFIGURATION, 0x0000, nbytes, (uint8_t*)p));
}

uint8_t usb_set_addr( usb_device_t *dev, uint8_t newaddr )  {
  iprintf("%s(new=%x)\n", __FUNCTION__, newaddr);
  
  uint8_t rcode = usb_ctrl_req( dev, USB_REQ_SET, USB_REQUEST_SET_ADDRESS, newaddr, 
				0x00, 0x0000, 0x0000, NULL);
  if(!rcode) dev->bAddress = newaddr;
  return rcode;
}

//set configuration
uint8_t usb_set_conf( usb_device_t *dev, uint8_t conf_value )  {
  return( usb_ctrl_req( dev, USB_REQ_SET, USB_REQUEST_SET_CONFIGURATION,
			conf_value, 0x00, 0x0000, 0x0000, NULL));
}

void usb_SetHubPreMask() { 
  bmHubPre |= MAX3421E_HUBPRE; 
};

void usb_ResetHubPreMask() { 
  bmHubPre &= ~MAX3421E_HUBPRE; 
};
