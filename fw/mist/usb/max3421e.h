
#ifndef MAX3421E_H
#define MAX3421E_H

#include <inttypes.h>

#define MAX3421E_STATE_SE0     0
#define MAX3421E_STATE_SE1     1
#define MAX3421E_STATE_FSHOST  2
#define MAX3421E_STATE_LSHOST  3

#define MAX3421E_WRITE   0x02

/* MAX3421E command byte format: rrrrr0wa where 'r' is register number  */
//
// MAX3421E Registers in HOST mode. 
//
#define MAX3421E_RCVFIFO    0x08    //1<<3
#define MAX3421E_SNDFIFO    0x10    //2<<3
#define MAX3421E_SUDFIFO    0x20    //4<<3
#define MAX3421E_RCVBC      0x30    //6<<3
#define MAX3421E_SNDBC      0x38    //7<<3

#define MAX3421E_USBIRQ     0x68    //13<<3
/* USBIRQ Bits  */
#define MAX3421E_VBUSIRQ   0x40    //b6
#define MAX3421E_NOVBUSIRQ 0x20    //b5
#define MAX3421E_OSCOKIRQ  0x01    //b0

#define MAX3421E_USBIEN     0x70    //14<<3
/* USBIEN Bits  */
#define bmVBUSIE    0x40    //b6
#define bmNOVBUSIE  0x20    //b5
#define bmOSCOKIE   0x01    //b0

#define MAX3421E_USBCTL     0x78    //15<<3
/* USBCTL Bits  */
#define MAX3421E_CHIPRES   0x20    //b5
#define MAX3421E_PWRDOWN   0x10    //b4

#define MAX3421E_CPUCTL     0x80    //16<<3
/* CPUCTL Bits  */
#define MAX3421E_PUSLEWID1 0x80    //b7
#define MAX3421E_PULSEWID0 0x40    //b6
#define MAX3421E_IE        0x01    //b0

#define MAX3421E_PINCTL     0x88    //17<<3
/* PINCTL Bits  */
#define MAX3421E_FDUPSPI   0x10    //b4
#define MAX3421E_INTLEVEL  0x08    //b3
#define MAX3421E_POSINT    0x04    //b2
#define MAX3421E_GPXB      0x02    //b1
#define MAX3421E_GPXA      0x01    //b0
// GPX pin selections
#define MAX3421E_GPX_OPERATE 0x00
#define MAX3421E_GPX_VBDET   0x01
#define MAX3421E_GPX_BUSACT  0x02
#define MAX3421E_GPX_SOF     0x03

#define MAX3421E_REVISION   0x90    //18<<3

#define MAX3421E_IOPINS1    0xa0    //20<<3

/* IOPINS1 Bits */
#define bmGPOUT0    0x01
#define bmGPOUT1    0x02
#define bmGPOUT2    0x04
#define bmGPOUT3    0x08
#define bmGPIN0     0x10
#define bmGPIN1     0x20
#define bmGPIN2     0x40
#define bmGPIN3     0x80

#define MAX3421E_IOPINS2    0xa8    //21<<3
/* IOPINS2 Bits */
#define bmGPOUT4    0x01
#define bmGPOUT5    0x02
#define bmGPOUT6    0x04
#define bmGPOUT7    0x08
#define bmGPIN4     0x10
#define bmGPIN5     0x20
#define bmGPIN6     0x40
#define bmGPIN7     0x80

#define MAX3421E_GPINIRQ    0xb0    //22<<3
/* GPINIRQ Bits */
#define bmGPINIRQ0 0x01
#define bmGPINIRQ1 0x02
#define bmGPINIRQ2 0x04
#define bmGPINIRQ3 0x08
#define bmGPINIRQ4 0x10
#define bmGPINIRQ5 0x20
#define bmGPINIRQ6 0x40
#define bmGPINIRQ7 0x80

#define MAX3421E_GPINIEN    0xb8    //23<<3
/* GPINIEN Bits */
#define bmGPINIEN0 0x01
#define bmGPINIEN1 0x02
#define bmGPINIEN2 0x04
#define bmGPINIEN3 0x08
#define bmGPINIEN4 0x10
#define bmGPINIEN5 0x20
#define bmGPINIEN6 0x40
#define bmGPINIEN7 0x80

#define MAX3421E_GPINPOL    0xc0    //24<<3
/* GPINPOL Bits */
#define bmGPINPOL0 0x01
#define bmGPINPOL1 0x02
#define bmGPINPOL2 0x04
#define bmGPINPOL3 0x08
#define bmGPINPOL4 0x10
#define bmGPINPOL5 0x20
#define bmGPINPOL6 0x40
#define bmGPINPOL7 0x80

#define MAX3421E_HIRQ       0xc8    //25<<3
/* HIRQ Bits */
#define MAX3421E_BUSEVENTIRQ   0x01   // indicates BUS reset Done or BUS resume     
#define MAX3421E_RWUIRQ        0x02
#define MAX3421E_RCVDAVIRQ     0x04
#define MAX3421E_SNDBAVIRQ     0x08
#define MAX3421E_SUSDNIRQ      0x10
#define MAX3421E_CONDETIRQ     0x20
#define MAX3421E_FRAMEIRQ      0x40
#define MAX3421E_HXFRDNIRQ     0x80

#define MAX3421E_HIEN			0xd0    //26<<3

/* HIEN Bits */
#define MAX3421E_BUSEVENTIE    0x01
#define MAX3421E_RWUIE         0x02
#define MAX3421E_RCVDAVIE      0x04
#define MAX3421E_SNDBAVIE      0x08
#define MAX3421E_SUSDNIE       0x10
#define MAX3421E_CONDETIE      0x20
#define MAX3421E_FRAMEIE       0x40
#define MAX3421E_HXFRDNIE      0x80

#define MAX3421E_MODE			0xd8    //27<<3

/* MODE Bits */
#define MAX3421E_HOST          0x01
#define MAX3421E_LOWSPEED      0x02
#define MAX3421E_HUBPRE        0x04
#define MAX3421E_SOFKAENAB     0x08
#define MAX3421E_SEPIRQ        0x10
#define MAX3421E_DELAYISO      0x20
#define MAX3421E_DMPULLDN      0x40
#define MAX3421E_DPPULLDN      0x80

#define MAX3421E_PERADDR    0xe0    //28<<3

#define MAX3421E_HCTL       0xe8    //29<<3
/* HCTL Bits */
#define MAX3421E_BUSRST        0x01
#define MAX3421E_FRMRST        0x02
#define MAX3421E_SAMPLEBUS     0x04
#define MAX3421E_SIGRSM        0x08
#define MAX3421E_RCVTOG0       0x10
#define MAX3421E_RCVTOG1       0x20
#define MAX3421E_SNDTOG0       0x40
#define MAX3421E_SNDTOG1       0x80

#define MAX3421E_HXFR       0xf0    //30<<3
/* Host transfer token values for writing the HXFR MAX3421E_egister (R30)   */
/* OR this bit field with the endpoint number in bits 3:0               */
#define tokSETUP  0x10  // HS=0, ISO=0, OUTNIN=0, SETUP=1
#define tokIN     0x00  // HS=0, ISO=0, OUTNIN=0, SETUP=0
#define tokOUT    0x20  // HS=0, ISO=0, OUTNIN=1, SETUP=0
#define tokINHS   0x80  // HS=1, ISO=0, OUTNIN=0, SETUP=0
#define tokOUTHS  0xA0  // HS=1, ISO=0, OUTNIN=1, SETUP=0 
#define tokISOIN  0x40  // HS=0, ISO=1, OUTNIN=0, SETUP=0
#define tokISOOUT 0x60  // HS=0, ISO=1, OUTNIN=1, SETUP=0

#define MAX3421E_HRSL       0xf8    //31<<3

/* HRSL Bits */
#define MAX3421E_RCVTOGRD  0x10
#define MAX3421E_SNDTOGRD  0x20
#define MAX3421E_KSTATUS   0x40
#define MAX3421E_JSTATUS   0x80
#define MAX3421E_SE0       0x00    //SE0 - disconnect state
#define MAX3421E_SE1       0xc0    //SE1 - illegal state       

/* Host error MAX3421E_esult codes, the 4 LSB's in the HRSL register */
#define hrSUCCESS   0x00
#define hrBUSY      0x01
#define hrBADREQ    0x02
#define hrUNDEF     0x03
#define hrNAK       0x04
#define hrSTALL     0x05
#define hrTOGERR    0x06
#define hrWRONGPID  0x07
#define hrBADBC     0x08
#define hrPIDERR    0x09
#define hrPKTERR    0x0A
#define hrCRCERR    0x0B
#define hrKERR      0x0C
#define hrJERR      0x0D
#define hrTIMEOUT   0x0E
#define hrBABBLE    0x0F

#define MAX3421E_MODE_FS_HOST    (MAX3421E_DPPULLDN|MAX3421E_DMPULLDN|MAX3421E_HOST|MAX3421E_SOFKAENAB)
#define MAX3421E_MODE_LS_HOST    (MAX3421E_DPPULLDN|MAX3421E_DMPULLDN|MAX3421E_HOST|MAX3421E_LOWSPEED|MAX3421E_SOFKAENAB)

// interface used by usb.c
void max3421e_init();
uint8_t max3421e_poll();
void max3421e_write_u08(uint8_t reg, uint8_t data);
uint8_t max3421e_read_u08(uint8_t reg);
uint8_t *max3421e_write(uint8_t reg, uint8_t n, uint8_t* data);
uint8_t *max3421e_read(uint8_t reg, uint8_t n, uint8_t* data);

#endif //_max3421e_h_
