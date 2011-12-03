#ifndef HARDWARE_H_INCLUDED
#define HARDWARE_H_INCLUDED

/*IO defines*/
#define	PROG_B		TRISA2			/*FPGA config*/
#define	DONE		RB3				/*FPGA config*/
#define	INIT_B		RA3				/*FPGA config*/
#define	CCLK		LATA5			/*FPGA config*/
#define	DIN			LATB7			/*FPGA config*/
#define	_SW0		RB0				/*switch input*/
#define	_SW1		RB1				/*switch input*/
#define DISKLED_ON	RB4=1			/*disk led output*/
#define DISKLED_OFF	RB4=0			/*disk led output*/
#define	_M_CD		TRISA0			/*mmc card clock disable*/
#define	_M_CS		RC0				/*mmc card spi select*/
#define	_F_CS0		RA1				/*FGPA spi0 select*/
#define	_F_CS1		RB5				/*FGPA spi1 select*/
#define	_F_CS2		RB6				/*FGPA spi2 select*/

/*functions and macro's*/
void HardwareInit(void);
unsigned char SPI(unsigned char data);
void ShiftFpga(unsigned char data);
unsigned short GetTimer(unsigned short offset);
unsigned char CheckTimer(unsigned short t);
#define		EnableFpga()	_F_CS0=0
#define		DisableFpga()	_F_CS0=1
#define		EnableOsd()		_F_CS1=0
#define		DisableOsd()	_F_CS1=1
#define		EnableCard()	{_M_CD=1;_M_CS=0;}
#define		DisableCard()	{_M_CS=1;SPI(0xff);_M_CD=0;}
#define		CheckButton()	(!_SW0)
#endif
