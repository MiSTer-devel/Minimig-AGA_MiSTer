/*
Copyright 2005, 2006, 2007 Dennis van Weeren
Copyright 2008, 2009 Jakub Bednarski

This file is part of Minimig

Minimig is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

Minimig is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// 2009-10-10   - any length (any multiple of 8 bytes) fpga core file support
// 2009-12-10   - changed command header id
// 2010-04-14   - changed command header id

#ifdef __GNUC__
#include "AT91SAM7S256.h"
#endif

#include "stdio.h"
#include "string.h"
#include "errors.h"
#include "hardware.h"
#include "fat.h"
#include "fdd.h"
#include "rafile.h"
#include "user_io.h"
#include "config.h"
#include "boot.h"
#include "osd.h"

#include "fpga.h"

#define CMD_HDRID 0xAACA

// TODO!
#define SPIN() asm volatile ( "mov r0, r0\n\t" \
                              "mov r0, r0\n\t" \
                              "mov r0, r0\n\t" \
                              "mov r0, r0");

extern fileTYPE file;
extern char s[40];
extern adfTYPE df[4];

char BootPrint(const char *text);

#ifdef XILINX_CCLK

// single byte serialization of FPGA configuration datastream
void ShiftFpga(unsigned char data)
{
    AT91_REG *ppioa_codr = AT91C_PIOA_CODR;
    AT91_REG *ppioa_sodr = AT91C_PIOA_SODR;

    // bit 0
    *ppioa_codr = XILINX_DIN | XILINX_CCLK;
    if (data & 0x80)
        *ppioa_sodr = XILINX_DIN;
    *ppioa_sodr = XILINX_CCLK;

    // bit 1
    *ppioa_codr = XILINX_DIN | XILINX_CCLK;
    if (data & 0x40)
        *ppioa_sodr = XILINX_DIN;
    *ppioa_sodr = XILINX_CCLK;

    // bit 2
    *ppioa_codr = XILINX_DIN | XILINX_CCLK;
    if (data & 0x20)
        *ppioa_sodr = XILINX_DIN;
    *ppioa_sodr = XILINX_CCLK;

    // bit 3
    *ppioa_codr = XILINX_DIN | XILINX_CCLK;
    if (data & 0x10)
        *ppioa_sodr = XILINX_DIN;
    *ppioa_sodr = XILINX_CCLK;

    // bit 4
    *ppioa_codr = XILINX_DIN | XILINX_CCLK;
    if (data & 0x08)
        *ppioa_sodr = XILINX_DIN;
    *ppioa_sodr = XILINX_CCLK;

    // bit 5
    *ppioa_codr = XILINX_DIN | XILINX_CCLK;
    if (data & 0x04)
        *ppioa_sodr = XILINX_DIN;
    *ppioa_sodr = XILINX_CCLK;

    // bit 6
    *ppioa_codr = XILINX_DIN | XILINX_CCLK;
    if (data & 0x02)
        *ppioa_sodr = XILINX_DIN;
    *ppioa_sodr = XILINX_CCLK;

    // bit 7
    *ppioa_codr = XILINX_DIN | XILINX_CCLK;
    if (data & 0x01)
        *ppioa_sodr = XILINX_DIN;
    *ppioa_sodr = XILINX_CCLK;

}

// Xilinx FPGA configuration
// was before unsigned char ConfigureFpga(void)
RAMFUNC unsigned char ConfigureFpga(char *name)
{
    unsigned long  t;
    unsigned long  n;
    unsigned char *ptr;

    // set outputs
    *AT91C_PIOA_SODR = XILINX_CCLK | XILINX_DIN | XILINX_PROG_B;
    // enable outputs
    *AT91C_PIOA_OER = XILINX_CCLK | XILINX_DIN | XILINX_PROG_B;

    // reset FGPA configuration sequence
    // specs: PROG_B pulse min 0.3 us
    t = 15;
    while (--t)
        *AT91C_PIOA_CODR = XILINX_PROG_B;

    *AT91C_PIOA_SODR = XILINX_PROG_B;

    // now wait for INIT to go high
    // specs: max 2ms
    t = 100000;
    while (!(*AT91C_PIOA_PDSR & XILINX_INIT_B))
    {
        if (--t == 0)
        {
            iprintf("FPGA init is NOT high!\r");
            FatalError(3);
        }
    }

    iprintf("FPGA init is high\r");

    if (*AT91C_PIOA_PDSR & XILINX_DONE)
    {
        iprintf("FPGA done is high before configuration!\r");
        FatalError(3);
    }

    if(!name)
    //  name = "CORE    BIN";
		name = "XESM38  BIN";

    // open bitstream file
    if (FileOpen(&file, name) == 0)
    {
        iprintf("No FPGA configuration file found!\r");
        FatalError(4);
    }

    iprintf("FPGA bitstream file opened, file size = %d\r", file.size);
    iprintf("[");

    // send all bytes to FPGA in loop
    t = 0;
    n = file.size >> 3;
    ptr = sector_buffer;
    do
    {
        // read sector if 512 (64*8) bytes done
        if ((t & 0x3F) == 0)
        {
            if (t & (1<<10))
                DISKLED_OFF
            else
                DISKLED_ON

            if ((t & 0x1FF) == 0)
                iprintf("*");

            if (!FileRead(&file, sector_buffer))
                return(0);

            ptr = sector_buffer;
        }

        // send data in packets of 8 bytes
        ShiftFpga(*ptr++);
        ShiftFpga(*ptr++);
        ShiftFpga(*ptr++);
        ShiftFpga(*ptr++);
        ShiftFpga(*ptr++);
        ShiftFpga(*ptr++);
        ShiftFpga(*ptr++);
        ShiftFpga(*ptr++);

        t++;

        // read next sector if 512 (64*8) bytes done
        if ((t & 0x3F) == 0)
            FileNextSector(&file);

    }
    while (t < n);

    // disable outputs
    *AT91C_PIOA_ODR = XILINX_CCLK | XILINX_DIN | XILINX_PROG_B;

    iprintf("]\r");
    iprintf("FPGA bitstream loaded\r");
    DISKLED_OFF;

    // check if DONE is high
    if (*AT91C_PIOA_PDSR & XILINX_DONE)
        return(1);

    iprintf("FPGA done is NOT high!\r");
    FatalError(5);
    return 0;
}
#endif


#ifdef ALTERA_DCLK
static inline void ShiftFpga(unsigned char data)
{
    unsigned char i;
    for ( i = 0; i < 8; i++ )
    {
        /* Dump to DATA0 and insert a positive edge pulse at the same time */
        *AT91C_PIOA_CODR = ALTERA_DATA0 | ALTERA_DCLK;
        if((data >> i) & 1) *AT91C_PIOA_SODR = ALTERA_DATA0;
        *AT91C_PIOA_SODR = ALTERA_DCLK;
    }
}

// Altera FPGA configuration
RAMFUNC unsigned char ConfigureFpga(char *name)
{
    unsigned long i;
    unsigned char *ptr;

    // set outputs
    *AT91C_PIOA_SODR = ALTERA_DCLK | ALTERA_DATA0 | ALTERA_NCONFIG;
    // enable outputs
    *AT91C_PIOA_OER = ALTERA_DCLK | ALTERA_DATA0 | ALTERA_NCONFIG;

    if(!name)
      name = "CORE    RBF";

    // open bitstream file
    if (FileOpen(&file, name) == 0)
    {
        iprintf("No FPGA configuration file found!\r");
        FatalError(4);
    }

    iprintf("FPGA bitstream file opened, file size = %d\r", file.size);
    iprintf("[");

    // send all bytes to FPGA in loop
    ptr = sector_buffer;

    /* Drive a transition of 0 to 1 to NCONFIG to indicate start of configuration */
    for(i=0;i<10;i++)
      *AT91C_PIOA_CODR = ALTERA_NCONFIG;  // must be low for at least 500ns

    *AT91C_PIOA_SODR = ALTERA_NCONFIG;

    // now wait for NSTATUS to go high
    // specs: max 800us
    i = 1000000;
    while (!(*AT91C_PIOA_PDSR & ALTERA_NSTATUS))
    {
        if (--i == 0)
        {
            iprintf("FPGA NSTATUS is NOT high!\r");
            FatalError(3);
        }
    }

    DISKLED_ON;

    int t = 0;
    int n = file.size >> 3;

    /* Loop through every single byte */
    for ( i = 0; i < file.size; )
    {
        // read sector if 512 (64*8) bytes done
        if ((i & 0x1FF) == 0)
        {
            if (i & (1<<13))
                DISKLED_OFF
            else
                DISKLED_ON

            if ((i & 0x3FFF) == 0)
                iprintf("*");

            if (!FileRead(&file, sector_buffer))
                return(0);

            ptr = sector_buffer;
        }

        int bytes2copy = (i < file.size - 8)?8:file.size-i;
        i += bytes2copy;
        while(bytes2copy) {
          ShiftFpga(*ptr++);
          bytes2copy--;
        }

        /* Check for error through NSTATUS for every 10KB programmed and the last byte */
        if ( !(i % 10240) || (i == file.size - 1) ) {
            if ( !*AT91C_PIOA_PDSR & ALTERA_NSTATUS ) {
                iprintf("FPGA NSTATUS is NOT high!\r");
                FatalError(5);
            }
        }

        // read next sector if 512 (64*8) bytes done
        if ((i & 0x1FF) == 0)
            FileNextSector(&file);
    }

    iprintf("]\r");
    iprintf("FPGA bitstream loaded\r");
    DISKLED_OFF;

    // check if DONE is high
    if (!(*AT91C_PIOA_PDSR & ALTERA_DONE)) {
      iprintf("FPGA Configuration done but contains error... CONF_DONE is LOW\r");
      FatalError(5);
    }

    
    /* Start initialization */
    /* Clock another extra DCLK cycles while initialization is in progress
       through internal oscillator or driving clock cycles into CLKUSR pin */
    /* These extra DCLK cycles do not initialize the device into USER MODE */
    /* It is not required to drive extra DCLK cycles at the end of configuration */
    /* The purpose of driving extra DCLK cycles here is to insert some delay
       while waiting for the initialization of the device to complete before
       checking the CONFDONE and NSTATUS signals at the end of whole 
       configuration cycle */
    
    for ( i = 0; i < 50; i++ )
    {
        *AT91C_PIOA_CODR = ALTERA_DCLK;
        *AT91C_PIOA_SODR = ALTERA_DCLK;
    }

    /* Initialization end */

    if ( !(*AT91C_PIOA_PDSR & ALTERA_NSTATUS) || 
         !(*AT91C_PIOA_PDSR & ALTERA_DONE)) {
      
      iprintf("FPGA Initialization finish but contains error: NSTATUS is %s and CONF_DONE is %s.\r", 
             ((*AT91C_PIOA_PDSR & ALTERA_NSTATUS)?"HIGH":"LOW"), ((*AT91C_PIOA_PDSR & ALTERA_DONE)?"HIGH":"LOW") );
      FatalError(5);
    }

    return 1;
}
#endif


void SendFile(RAFile *file)
{
    unsigned char  c1, c2;
    unsigned long  j;
    unsigned long  n;
    unsigned char *p;

    iprintf("[");
    n = (file->file.size + 511) >> 9; // sector count (rounded up)
    while (n--)
    {
        // read data sector from memory card
		RARead(file,sector_buffer,512);

        do
        {
            // read FPGA status
            EnableFpga();
            c1 = SPI(0);
            c2 = SPI(0);
            SPI(0);
            SPI(0);
            SPI(0);
            SPI(0);
            DisableFpga();
        }
        while (!(c1 & CMD_RDTRK));

        if ((n & 15) == 0)
            iprintf("*");

        // send data sector to FPGA
        EnableFpga();
        c1 = SPI(0);
        c2 = SPI(0);
        SPI(0);
        SPI(0);
        SPI(0);
        SPI(0);
        p = sector_buffer;

        for (j = 0; j < 512; j++)
            SPI(*p++);

        DisableFpga();
    }
    iprintf("]\r");
}


void SendFileEncrypted(RAFile *file,unsigned char *key,int keysize)
{
    unsigned char  c1, c2;
	unsigned char headersize;
	unsigned int keyidx=0;
    unsigned long  j;
    unsigned long  n;
    unsigned char *p;
	int badbyte=0;

    iprintf("[");
	headersize=file->size&255;	// ROM should be a round number of kilobytes; overspill will likely be the Amiga Forever header.

	RARead(file,sector_buffer,headersize);	// Read extra bytes

    n = (file->size + (511-headersize)) >> 9; // sector count (rounded up)
    while (n--)
    {
		RARead(file,sector_buffer,512);
        for (j = 0; j < 512; j++)
		{
			sector_buffer[j]^=key[keyidx++];
			if(keyidx>=keysize)
				keyidx-=keysize;
		}

        do
        {
            // read FPGA status
            EnableFpga();
            c1 = SPI(0);
            c2 = SPI(0);
            SPI(0);
            SPI(0);
            SPI(0);
            SPI(0);
            DisableFpga();
        }
        while (!(c1 & CMD_RDTRK));

        if ((n & 15) == 0)
            iprintf("*");

        // send data sector to FPGA
        EnableFpga();
        c1 = SPI(0);
        c2 = SPI(0);
        SPI(0);
        SPI(0);
        SPI(0);
        SPI(0);
        p = sector_buffer;

        for (j = 0; j < 512; j++)
            SPI(*p++);
        DisableFpga();
    }
    iprintf("]\r");
}


// draw on screen
char BootDraw(char *data, unsigned short len, unsigned short offset)
{
  DEBUG_FUNC_IN();

    unsigned char c1, c2, c3, c4;
    unsigned char cmd;
    const char *p;
    unsigned short n;
    unsigned short i;

    n = (len+3)&(~3);
    i = 0;

    cmd = 1;
    while (1)
    {
        EnableFpga();
        c1 = SPI(0x10); // track read command
        c2 = SPI(0x01); // disk present
        unsigned char x = SPI(0);
        unsigned char y = SPI(0);
        c3 = SPI(0);
        c4 = SPI(0);

	//	iprintf("FPGA state: %d %d (%d %d) %d %d\n", c1, c2, x, y, c3, c4);

        if (c1 & CMD_RDTRK)
        {
            if (cmd)
            { // command phase
                if (c3 == 0x80 && c4 == 0x06) // command packet size must be 12 bytes
                {
                    cmd = 0;
                    SPI(CMD_HDRID >> 8); // command header
                    SPI(CMD_HDRID & 0xFF);
                    SPI(0x00); // cmd: 0x0001 = print text
                    SPI(0x01);
                    // data packet size in bytes
                    SPI(0x00);
                    SPI(0x00);
                    SPI((n)>>8);
                    SPI((n)&0xff); // +2 because only even byte count is possible to send and we have to send termination zero byte
                    // offset
                    SPI(0x00);
                    SPI(0x00);
                    SPI(offset>>8);
                    SPI(offset&0xff);
                }
                else
                    break;
            }
            else
            { // data phase
                if (c3 == 0x80 && c4 == ((n) >> 1))
                {
                    p = data;
                    n = c4 << 1;
                    while (n--)
                    {
                        c4 = *p;
                        SPI((i>=len) ? 0 : c4);
                        p++;
                        i++;
                    }
                    DisableFpga();
                    return 1;
                }
                else
                    break;
            }
        }
        DisableFpga();
    }
    DisableFpga();
    return 0;

  DEBUG_FUNC_OUT();
}


// print message on the boot screen
char BootPrint(const char *text)
{
    if(!minimig_v1()) {
      iprintf("%s\n", text);
      return; // TODO
    }

    unsigned char c1, c2, c3, c4;
    unsigned char cmd;
    const char *p;
    unsigned char n;

    return 0;

    p = text;
    n = 0;
    while (*p++ != 0)
        n++; // calculating string length

    cmd = 1;
    while (1)
    {
        EnableFpga();
        c1 = SPI(0x10); // track read command
        c2 = SPI(0x01); // disk present
        SPI(0);
        SPI(0);
        c3 = SPI(0);
        c4 = SPI(0);

        if (c1 & CMD_RDTRK)
        {
            if (cmd)
            { // command phase
                if (c3 == 0x80 && c4 == 0x06) // command packet size must be 12 bytes
                {
                    cmd = 0;
                    SPI(CMD_HDRID >> 8); // command header
                    SPI(CMD_HDRID & 0xFF);
                    SPI(0x00); // cmd: 0x0001 = print text
                    SPI(0x01);
                    // data packet size in bytes
                    SPI(0x00);
                    SPI(0x00);
                    SPI(0x00);
                    SPI(n+2); // +2 because only even byte count is possible to send and we have to send termination zero byte
                    // don't care
                    SPI(0x00);
                    SPI(0x00);
                    SPI(0x00);
                    SPI(0x00);
                }
                else
                    break;
            }
            else
            { // data phase
                if (c3 == 0x80 && c4 == ((n + 2) >> 1))
                {
                    p = text;
                    n = c4 << 1;
                    while (n--)
                    {
                        c4 = *p;
                        SPI(c4);
                        if (c4) // if current character is not zero go to next one
                            p++;
                    }
                    DisableFpga();
                    return 1;
                }
                else
                    break;
            }
        }
        DisableFpga();
    }
    DisableFpga();
    return 0;
}

char PrepareBootUpload(unsigned char base, unsigned char size)
// this function sends given file to Minimig's memory
// base - memory base address (bits 23..16)
// size - memory size (bits 23..16)
{
    unsigned char c1, c2, c3, c4;
    unsigned char cmd = 1;

    while (1)
    {
        EnableFpga();
        c1 = SPI(0x10); // track read command
        c2 = SPI(0x01); // disk present
        SPI(0);
        SPI(0);
        c3 = SPI(0);
        c4 = SPI(0);

        if (c1 & CMD_RDTRK)
        {
            if (cmd)
            { // command phase
                if (c3 == 0x80 && c4 == 0x06) // command packet size 12 bytes
                {
                    cmd = 0;
                    SPI(CMD_HDRID >> 8); // command header
                    SPI(CMD_HDRID & 0xFF);
                    SPI(0x00);
                    SPI(0x02); // cmd: 0x0002 = upload memory
                    // memory base address
                    SPI(0x00);
                    SPI(base);
                    SPI(0x00);
                    SPI(0x00);
                    // memory size
                    SPI(0x00);
                    SPI(size);
                    SPI(0x00);
                    SPI(0x00);
                }
                else
                    break;
            }
            else
            { // data phase
                DisableFpga();
                iprintf("Ready to upload ROM file...\r");
                // send rom image to FPGA
//                SendFile(file);
//                iprintf("ROM file uploaded.\r");
                return 0;
            }
        }
        DisableFpga();
    }
    DisableFpga();
    return -1;
}

void BootExit(void)
{
    unsigned char c1, c2, c3, c4;

    while (1)
    {
        EnableFpga();
        c1 = SPI(0x10); // track read command
        c2 = SPI(0x01); // disk present
        SPI(0);
        SPI(0);
        c3 = SPI(0);
        c4 = SPI(0);
        if (c1 & CMD_RDTRK)
        {
            if (c3 == 0x80 && c4 == 0x06) // command packet size 12 bytes
            {
                SPI(CMD_HDRID >> 8); // command header
                SPI(CMD_HDRID & 0xFF);
                SPI(0x00); // cmd: 0x0003 = restart
                SPI(0x03);
                // don't care
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
                // don't care
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
            }
            DisableFpga();
            return;
        }
        DisableFpga();
    }
}

void ClearMemory(unsigned long base, unsigned long size)
{
    unsigned char c1, c2, c3, c4;

    while (1)
    {
        EnableFpga();
        c1 = SPI(0x10); // track read command
        c2 = SPI(0x01); // disk present
        SPI(0);
        SPI(0);
        c3 = SPI(0);
        c4 = SPI(0);
        if (c1 & CMD_RDTRK)
        {
            if (c3 == 0x80 && c4 == 0x06)// command packet size 12 bytes
            {
                SPI(CMD_HDRID >> 8); // command header
                SPI(CMD_HDRID & 0xFF);
                SPI(0x00); // cmd: 0x0004 = clear memory
                SPI(0x04);
                // memory base
                SPI((unsigned char)(base >> 24));
                SPI((unsigned char)(base >> 16));
                SPI((unsigned char)(base >> 8));
                SPI((unsigned char)base);
                // memory size
                SPI((unsigned char)(size >> 24));
                SPI((unsigned char)(size >> 16));
                SPI((unsigned char)(size >> 8));
                SPI((unsigned char)size);
            }
            DisableFpga();
            return;
        }
        DisableFpga();
    }
}

unsigned char GetFPGAStatus(void)
{
    unsigned char status;

    EnableFpga();
    status = SPI(0);
    SPI(0);
    SPI(0);
    SPI(0);
    SPI(0);
    SPI(0);
    DisableFpga();

    return status;
}

void fpga_init(char *name) {
  unsigned long time = GetTimer(0);

  if(!user_io_dip_switch1() || name) {
    unsigned char ct;

    if (ConfigureFpga(name)) {
      time = GetTimer(0) - time;
      iprintf("FPGA configured in %lu ms\r", time >> 20);
    } else {
      iprintf("FPGA configuration failed\r");
      FatalError(8); // 3
    }

    // wait max 100 msec for a valid core type
    time = GetTimer(100);
    do {
      EnableIO();
      ct = SPI(0xff);
      DisableIO();
      SPI(0xff);         // for old minimig core
    } while( ((ct == 0) || (ct == 0xff)) && !CheckTimer(time));

    iprintf("ident = %x\n", ct);
  }

  user_io_detect_core_type();

  if((user_io_core_type() == CORE_TYPE_MINIMIG)||
     (user_io_core_type() == CORE_TYPE_MINIMIG2)) {
    puts("Running minimig setup");
    
    if(minimig_v2()) {
      EnableOsd();
      
      SPI(OSD_CMD_RST);
      rstval = (SPI_RST_USR | SPI_RST_CPU | SPI_CPU_HLT);
      SPI(rstval);
      DisableOsd();
      SPIN(); SPIN(); SPIN(); SPIN();
      EnableOsd();
      SPI(OSD_CMD_RST);
      rstval = (SPI_RST_CPU | SPI_CPU_HLT);
      SPI(rstval);
      DisableOsd();
      SPIN(); SPIN(); SPIN(); SPIN();
      WaitTimer(100);
      BootInit();
      WaitTimer(1000);
      BootPrintEx("**** MINIMIG-AGA for MiST (BETA) ****");
      BootPrintEx(" ");
      //BootPrintEx("Original Minimig by Dennis van Weeren");
      //BootPrintEx("Updates by Jakub Bednarski, Tobias Gubener, Sascha Boing, A.M. Robinson & others");
      BootPrintEx("MINIMIG-AGA by Rok Krajnc (rok.krajnc@gmail.com)");
      BootPrintEx("MiST by Till Harbaum (till@harbaum.org)");
      //BootPrintEx("For updates & code see https://github.com/rkrajnc/minimig-de1");
      //BootPrintEx("For support, see http://www.minimig.net");
      BootPrintEx(" ");
      WaitTimer(1000);
    }

    ChangeDirectory(DIRECTORY_ROOT);
    
    //eject all disk
    df[0].status = 0;
    df[1].status = 0;
    df[2].status = 0;
    df[3].status = 0;

    if(minimig_v2())
      BootPrintEx("Booting ...");

    WaitTimer(6000);
    config.kickstart.name[0]=0;
    SetConfigurationFilename(0); // Use default config
    LoadConfiguration(0);  // Use slot-based config filename
    
  } // end of minimig setup
  
  if(user_io_core_type() == CORE_TYPE_MIST) {
    puts("Running mist setup");
    
    tos_upload(NULL);
    
    // end of mist setup
  }
}
