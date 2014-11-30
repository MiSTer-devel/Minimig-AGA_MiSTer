//*----------------------------------------------------------------------------
//*      ATMEL Microcontroller Software Support  -  ROUSSET  -
//*----------------------------------------------------------------------------
//* The software is delivered "AS IS" without warranty or condition of any
//* kind, either express, implied or statutory. This includes without
//* limitation any warranty or condition with respect to merchantability or
//* fitness for any particular purpose, or against the infringements of
//* intellectual property rights of others.
//*----------------------------------------------------------------------------
//* File Name           : cdc_enumerate.h
//* Object              : Handle CDC enumeration
//*
//* 1.0 Apr 20 200 	: ODi Creation
//*----------------------------------------------------------------------------
#ifndef CDC_ENUMERATE_H
#define CDC_ENUMERATE_H

#include <inttypes.h>

#define AT91C_EP_OUT_SIZE 0x40
#define AT91C_EP_OUT 1

#define AT91C_EP_IN_SIZE 0x40
#define AT91C_EP_IN  2

void usb_cdc_open(void);
unsigned char usb_cdc_is_configured(void);
unsigned int  usb_cdc_write(const char *pData, unsigned int length);
uint16_t  usb_cdc_read(char *pData, uint16_t length);

#define usb_cdc_poll() usb_cdc_is_configured()

#endif // CDC_ENUMERATE_H

