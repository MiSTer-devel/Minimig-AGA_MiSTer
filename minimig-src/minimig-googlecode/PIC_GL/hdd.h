#ifndef HDD_H_
#define HDD_H_

// Enable / Disable Debug info in HDD Module
//#define HDD_DEBUG

// Enable / Disable HDD support
// HDD_SUPPORT_ENABLE -> Defined in firmwareConfiguration.h

// TODO: Enable / Disable HDD Multi block transfer
// NOTE: This feature is not finished
// #define HDD_MULTIBLOCK_TRANSFER_ENABLE

#define CMD_IDECMD			0x04
#define CMD_IDEDAT			0x08

#define CMD_IDE_REGS_RD		0x80
#define CMD_IDE_REGS_WR		0x90
#define CMD_IDE_DATA_WR		0xA0
#define CMD_IDE_DATA_RD		0xB0
#define CMD_IDE_STATUS_WR	0xF0

#define IDE_STATUS_END		0x80
#define IDE_STATUS_IRQ		0x10
#define IDE_STATUS_RDY		0x08
#define IDE_STATUS_REQ		0x04
#define IDE_STATUS_ERR		0x01

#define IDE_ERROR_BBK		1<<7
#define IDE_ERROR_UNC		1<<6
#define IDE_ERROR_MC		1<<5
#define IDE_ERROR_IDNF		1<<4
#define IDE_ERROR_MCR		1<<3
#define IDE_ERROR_ABRT		1<<2
#define IDE_ERROR_TK0NF		1<<1
#define IDE_ERROR_AMNF		1<<0


#define ACMD_RECALIBRATE					0x10
#define ACMD_IDENTIFY_DEVICE				0xEC
#define ACMD_INITIALIZE_DEVICE_PARAMETERS	0x91 
#define ACMD_READ_SECTORS					0x20
#define ACMD_WRITE_SECTORS					0x30
#define ACMD_READ_MULTIPLE					0xC4
#define ACMD_WRITE_MULTIPLE					0xC5
#define ACMD_SET_MULTIPLE_MODE				0xC6


// Device identifycation struct
typedef struct driveIdentify
{
												//	Table 11 - Identify drive information
												//	+=======-===================================================================+
												//	| Word	|																	|
												//	|-------+-------------------------------------------------------------------|
	unsigned short	general;					//	| 0		| General configuration bit-significant information:				|
												//	|		| 15 0 reserved for non-magnetic drives								|
												//	|		| 14 1=format speed tolerance gap required							|
												//	|		| 13 1=track offset option available								|
												//	|		| 12 1=data strobe offset option available							|
												//	|		| 11 1=rotational speed tolerance is > 0,5%							|
												//	|		| 10 1=disk transfer rate > 10 Mbs									|
												//	|		| 9 1=disk transfer rate > 5Mbs but <= 10Mbs						|
												//	|		| 8 1=disk transfer rate <= 5Mbs									|
												//	|		| 7 1=removable cartridge drive										|
												//	|		| 6 1=fixed drive													|
												//	|		| 5 1=spindle motor control option implemented						|
												//	|		| 4 1=head switch time > 15 usec									|
												//	|		| 3 1=not MFM encoded												|
												//	|		| 2 1=soft sectored													|
												//	|		| 1 1=hard sectored													|
												//	|		| 0 0=reserved														|
	unsigned short	noCylinders;				//	| 1		| Number of cylinders												|
	unsigned short	res00;						//	| 2		| Reserved															|
	unsigned short	noHeads;					//	| 3		| Number of heads													|
	unsigned short	noUnformatedBytesPerTrack;	//	| 4		| Number of unformatted bytes per track								|
	unsigned short	noUnformatedBytesPerSector;	//	| 5		| Number of unformatted bytes per sector							|
	unsigned short	noSectorsPerTrack;			//	| 6		| Number of sectors per track										|
	unsigned short	vendorUnique00[3];			//	| 7-9	| Vendor unique														|
	unsigned char	serialNo[20];				//	| 10-19	| Serial number (20 ASCII characters, 0000h=not specified)			|
	unsigned short	bufferType;					//	| 20	| Buffer type														|
	unsigned short	bufferSize;					//	| 21	| Buffer size in 512 byte increments (0000h=not specified)			|
	unsigned short	onECCBytes;					//	| 22	| # of ECC bytes avail on read/write long cmds (0000h=not spec'd)	|
	unsigned char	firmwareRevision[8];		//	| 23-26	| Firmware revision (8 ASCII characters, 0000h=not specified)		|
	unsigned char	modelNumber[40];			//	| 27-46	| Model number (40 ASCII characters, 0000h=not specified)			|
	unsigned short	maxSecTransfer;				//	| 47	| 15-8 Vendor unique												|
												//	|		| 7-0 00h = Read/write multiple commands not implemented			|
												//	|		| xxh = Maximum number of sectors that can be transferred			|
												//	|		| per interrupt on read and write multiple commands					|
	unsigned short	doubleWordIO;				//	| 48	| 0000h = cannot perform doubleword I/O Included for backwards		|
												//	|		| 0001h = can perform doubleword I/O Compatible VU use				|
	unsigned short 	capabilities;				//	| 49	| Capabilities														|
												//	|		| 15-10 0=reserved													|
												//	|		| 9 1=LBA supported													|
												//	|		| 8 1=DMA supported													|
												//	|		| 7- 0 Vendor unique												|
	unsigned short	res01;						//	| 50	| Reserved															|
	unsigned short	transferCycleTimingPIO;		//	| 51	| 15-8 PIO data transfer cycle timing mode							|
												//	|		| 7-0 Vendor unique													|
	unsigned short	transferCycleTimingDMA;		//	| 52	| 15-8 DMA data transfer cycle timing mode							|
												//	|		| 7-0 Vendor unique													|
	unsigned short	isValidCHS;					//	| 53	| 15-1 Reserved														|
												//	|		| 0 1=the fields reported in words 54-58 are valid					|
												//	|		| 0=the fields reported in words 54-58 may be valid					|
	unsigned short	curNoCylinders;				//	| 54	| Number of current cylinders										|
	unsigned short	curNoHeads;					//	| 55	| Number of current heads											|
	unsigned short	curNoSectorsPerTrack;		//	| 56	| Number of current sectors per track								|
	unsigned long	curCapacityInSectors;		//	| 57-58	| Current capacity in sectors										|
	unsigned short	curMaxSecTransfer;			//	| 59	| 15-9 Reserved														|
												//	|		| 8 1 = Multiple sector setting is valid							|
												//	|		| 7-0 xxh = Current setting for number of sectors that can be		|
												//	|		| transferred per interrupt on R/W multiple commands				|
	unsigned long	totalNoOfLBASectors;		//	| 60-61 | Total number of user addressable sectors (LBA mode only)			|
	unsigned short	singleWordDMA;				//	| 62	| 15-8 Single word DMA transfer mode active							|
												//	| 		| 7-0 Single word DMA transfer modes supported (see 11-3a)			|
	unsigned short	multiWordDMA;				//	| 63 	| 15-8 Multiword DMA transfer mode active							|
												//	|		| 7-0 Multiword DMA transfer modes supported (see 11-3b)			|
//	unsigned short	res02[64];					//	| 64-127| Reserved															|
//	unsigned short	vendorUnique01[32];			//	|128-159| Vendor unique 													|
//	unsigned short	res03[96];					//	|160-255| Reserved 															|
												//	+===========================================================================+
};


#define	IDEREGS_DRIVE_MASK	0x10	// Mask for drive number
#define IDEREGS_HEAD_MASK	0x0F	// Mask for current head
#define IDEREGS_MODE_MASK	0x40	// Mask for mode LBA/CHS

// Host IDE registers
typedef union ideRegsTYPE
{
	struct
	{
		unsigned char	dummy;				// Dummy
		unsigned char	error;				// Error code
		unsigned char	count;				// Sector Count to transfer
		unsigned char	sector;				// Current sector
		unsigned short	cylinder;			// Current cylinder
		unsigned char	mode_drive_head;	// Current mode/drive/head
		unsigned char	cmd;				// Current IDE command, writing here triggers command
	} regs;
	unsigned char		tfr[8];
};


// Harddisk file type
typedef struct hdfTYPE 
{
	struct fileTYPE	file;
	unsigned char	present;
	unsigned char	enabled;
	unsigned short	cylinders;
	unsigned short	heads;
	unsigned short	sectors;
	#ifdef HDD_MULTIBLOCK_TRANSFER_ENABLE
	unsigned short	sectors_per_block;
	#endif
};

// hardfile structure
extern struct hdfTYPE hdf[2];

// Functions
void IdentifyDevice(struct driveIdentify *id, unsigned char unit);
unsigned long chs2lba(union ideRegsTYPE *ideRegs, unsigned char unit);
void NextHDDSector(union ideRegsTYPE *ideRegs, unsigned char unit);
void WriteIDERegs(union ideRegsTYPE *ideRegs);
void WriteIDEStatus(unsigned char status);
void BeginHDDTransfer(unsigned char cmd, unsigned char status);
void HandleHDD(unsigned char c1, unsigned char c2);
void GetHardfileGeometry(struct hdfTYPE *hdf);
unsigned char OpenHardfile(unsigned char unit, unsigned char *name);

#ifdef HDD_MULTIBLOCK_TRANSFER_ENABLE
void ReadHDDSectors(union ideRegsTYPE *ideRegs, unsigned char unit, unsigned char multi);
void WriteHDDSectors(union ideRegsTYPE *ideRegs, unsigned char unit, unsigned char multi);
#else
void ReadHDDSectors(union ideRegsTYPE *ideRegs, unsigned char unit);
void WriteHDDSectors(union ideRegsTYPE *ideRegs, unsigned char unit);
#endif

#ifdef HDD_DEBUG
void HDD_Debug(const char *msg, unsigned char *tfr);
#endif

#endif /*HDD_H_*/
