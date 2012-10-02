
#define CMD_IDECMD 0x04
#define CMD_IDEDAT 0x08

#define CMD_IDE_REGS_RD 0x80
#define CMD_IDE_REGS_WR 0x90
#define CMD_IDE_DATA_WR 0xA0
#define CMD_IDE_DATA_RD 0xB0
#define CMD_IDE_STATUS_WR 0xF0

#define IDE_STATUS_END 0x80
#define IDE_STATUS_IRQ 0x10
#define IDE_STATUS_RDY 0x08
#define IDE_STATUS_REQ 0x04
#define IDE_STATUS_ERR 0x01

#define ACMD_RECALIBRATE 0x10
#define ACMD_IDENTIFY_DEVICE 0xEC
#define ACMD_INITIALIZE_DEVICE_PARAMETERS 0x91
#define ACMD_READ_SECTORS 0x20
#define ACMD_WRITE_SECTORS 0x30
#define ACMD_READ_MULTIPLE 0xC4
#define ACMD_WRITE_MULTIPLE 0xC5
#define ACMD_SET_MULTIPLE_MODE 0xC6

#define HDF_DISABLED 0
#define HDF_FILE 1
#define HDF_CARD 2
#define HDF_CARDPART0 3
#define HDF_CARDPART1 4
#define HDF_CARDPART2 5
#define HDF_CARDPART3 6

typedef struct
{
	int			   type;	// Are we using a file, the entire SD card or a partition on the SD card?
    fileTYPE       file;
    unsigned short cylinders;
    unsigned short heads;
    unsigned short sectors;
    unsigned short sectors_per_block;
	unsigned short partition;	// Partition no.
	unsigned long  offset;	// If a partition, the lba offset of the partition.
    unsigned long  index[1024];
    unsigned long  index_size;
} hdfTYPE;

void IdentifyDevice(unsigned short *pBuffer, unsigned char unit);
unsigned long chs2lba(unsigned short cylinder, unsigned char head, unsigned short sector, unsigned char unit);
void WriteTaskFile(unsigned char error, unsigned char sector_count, unsigned char sector_number, unsigned char cylinder_low, unsigned char cylinder_high, unsigned char drive_head);
void WriteStatus(unsigned char status);
void HandleHDD(unsigned char c1, unsigned char c2);
void GetHardfileGeometry(hdfTYPE *hdf);
void BuildHardfileIndex(hdfTYPE *hdf);
unsigned char HardFileSeek(hdfTYPE *hdf, unsigned long lba);
unsigned char OpenHardfile(unsigned char unit);

extern char debugmsg[40];
extern char debugmsg2[40];

