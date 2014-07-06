#include "errors.h"
#include "hardware.h"
#include "mmc.h"
#include "fat.h"
#include "osd.h"
#include "fpga.h"
#include "fdd.h"
#include "hdd.h"
#include "firmware.h"
#include "menu.h"
#include "config.h"
#include "boot.h"

#include "stdio.h"
#include "string.h"

configTYPE config;
fileTYPE file;
extern char s[40];
char configfilename[12];
char DebugMode=0;

unsigned char romkey[3072];

RAFile romfile;


char UploadKickstart(char *name)
{
  DEBUG_FUNC_IN(DEBUG_F_CONFIG | DEBUG_L0);

	int keysize=0;
    char filename[12];
    strncpy(filename, name, 8); // copy base name
    strcpy(&filename[8], "ROM"); // add extension

	BootPrint("Checking for Amiga Forever key file:");
	if(FileOpen(&file,"ROM     KEY"))
	{
		keysize=file.size;
		if(file.size<sizeof(romkey))
		{
			int c=0;
			while(c<keysize)
			{
		        FileRead(&file, &romkey[c]);
				c+=512;
				FileNextSector(&file);
			}
			BootPrint("Loaded Amiga Forever key file");
		}
		else
			BootPrint("Amiga Forever keyfile is too large!");
	}

	BootPrint("Loading file: ");
	BootPrint(filename);

  //// reset minimig & CPU
  //EnableOsd();
  //SPI(OSD_CMD_RST);
  //SPI(6);
  //DisableOsd();
  ////while ((read32(REG_SYS_STAT_ADR) & 0x2));
  //SPIN(); SPIN();
  //EnableOsd();
  //SPI(OSD_CMD_RST);
  //SPI(4);
  //DisableOsd();
  //SPIN(); SPIN();
  //while ((read32(REG_SYS_STAT_ADR) & 0x2));

  if (RAOpen(&romfile, filename))
  {
    int i,j;
    unsigned int adr, size, base=0x180000, offset=0xc00000, data;
    //BootPrintEx("Uploading 512KB Kickstart ...");
    size = ((romfile.file.size)+511)>>9;
    printf("File size: %d\r", size);

    printf("[");
    for (i=0; i<size; i++) {
      if (!(i&31)) printf("*");
      RARead(&romfile,sector_buffer,512);
      //adr = offset + base + i*512;
      //data = ((unsigned int*)sector_buffer)[0];
      //write32(adr, data);
      //for (j=0; j<512; j=j+4) {
      //  data = ((unsigned int*)sector_buffer)[j>>2];
      //  write32(adr+j, data);
      //  if (data != read32(adr+j)) printf("Mismatch @ 0x%08x : 0x%08x != 0x%08x\r", adr+j, data, read32(adr+j));
      //}
      EnableOsd();
      adr = 0xf80000 + i*512;
      SPI(OSD_CMD_WR);
      SPIN(); SPIN(); SPIN(); SPIN();
      SPI(adr&0xff); adr = adr>>8;
      SPI(adr&0xff); adr = adr>>8;
      SPIN(); SPIN(); SPIN(); SPIN();
      SPI(adr&0xff); adr = adr>>8;
      SPI(adr&0xff); adr = adr>>8;
      SPIN(); SPIN(); SPIN(); SPIN();
      for (j=0; j<512; j=j+4) {
        SPI(sector_buffer[j+0]);
        SPI(sector_buffer[j+1]);
        SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN();
        SPI(sector_buffer[j+2]);
        SPI(sector_buffer[j+3]);
        SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN(); SPIN();
        data = ((unsigned int*)sector_buffer)[j>>2];
        if (data != read32(offset+base+i*512+j)) printf("Mismatch @ 0x%08x : 0x%08x != 0x%08x\r", offset+base+i*512+j, data, read32(offset+base+i*512+j));
      }
      DisableOsd();
    }
    printf("]\r");
    return(1);
  }

/*
    {
        if (romfile.size == 0x80000)
        { // 512KB Kickstart ROM
            BootPrint("Uploading 512 KB Kickstart...");
            PrepareBootUpload(0xF8, 0x08);
			SendFile(&romfile);
            return(1);
        }
        if ((romfile.size == 0x8000b) && keysize)
        { // 512KB Kickstart ROM
            BootPrint("Uploading 512 KB Kickstart (Probably Amiga Forever encrypted...)");
            PrepareBootUpload(0xF8, 0x08);
			SendFileEncrypted(&romfile,romkey,keysize);
            return(1);
        }
        else if (romfile.size == 0x40000)
        { // 256KB Kickstart ROM
            BootPrint("Uploading 256 KB Kickstart...");
            PrepareBootUpload(0xF8, 0x04);
			SendFile(&romfile);
            return(1);
        }
        else if ((romfile.size == 0x4000b) && keysize)
        { // 256KB Kickstart ROM
            BootPrint("Uploading 256 KB Kickstart (Probably Amiga Forever encrypted...");
            PrepareBootUpload(0xF8, 0x04);
			SendFileEncrypted(&romfile,romkey,keysize);
            return(1);
        }
        else
        {
            BootPrint("Unsupported ROM file size!");
        }
    }
*/
    else
    {
        sprintf(s, "No \"%s\" file!", filename);
        BootPrint(s);
    }
    return(0);

  DEBUG_FUNC_OUT(DEBUG_F_CONFIG | DEBUG_L0);
}

typedef struct {
  uint8_t dummy[4+4];
  uint8_t jmps[3*4];
  uint32_t mon_size;
  uint8_t col0h, col0l, col1h, col1l;
  uint8_t right;
  uint8_t keyboard;
  uint8_t key;
  uint8_t ide;
  uint8_t a1200;
  uint8_t aga;
  uint8_t insert;
  uint8_t delay;
  uint8_t lview;
  uint8_t cd32;
  uint8_t screenmode;
  uint8_t novbr;
  uint8_t entered;
  uint8_t hexmode;
  uint16_t error_sr;
  uint32_t error_pc;
  uint16_t error_status;
  uint8_t newid[6];
  uint16_t mon_version;
  uint16_t mon_revision;
  uint32_t whd_base;
  uint16_t whd_version;
  uint16_t whd_revision;
  uint32_t max_chip;
  uint32_t whd_expstrt;
  uint32_t whd_expstop;
} __attribute__((__packed__)) hrtmon_cfg_t;


void hrtcfg_print()
{
  DEBUG_FUNC_IN(DEBUG_F_CONFIG | DEBUG_L2);

  int i;
  volatile hrtmon_cfg_t* hrtcfg = (hrtmon_cfg_t*)(0xd00000);

  printf("HRTCFG:\r");
  for (i=0; i<(4+4); i++) printf("dummy[%d]: %x\r", i, hrtcfg->dummy[i]);
  for (i=0; i<(3*4); i++) printf("jmps[%d]: %x\r", i, hrtcfg->jmps[i]);
  printf("mon_size: %x\r",  hrtcfg->mon_size);
  printf("col0h: %x\r", hrtcfg->col0h);
  printf("col0l: %x\r", hrtcfg->col0l);
  printf("col1h: %x\r", hrtcfg->col1h);
  printf("col1l: %x\r", hrtcfg->col1l);
  printf("right: %x\r", hrtcfg->right);
  printf("keyboard: %x\r", hrtcfg->keyboard);
  printf("key: %x\r", hrtcfg->key);
  printf("ide: %x\r", hrtcfg->ide);
  printf("a1200: %x\r", hrtcfg->a1200);
  printf("aga: %x\r", hrtcfg->aga);
  printf("insert: %x\r", hrtcfg->insert);
  printf("delay: %x\r", hrtcfg->delay);
  printf("lview: %x\r", hrtcfg->lview);
  printf("cd32: %x\r", hrtcfg->cd32);
  printf("screenmode: %x\r", hrtcfg->screenmode);
  printf("novbr: %x\r", hrtcfg->novbr);
  printf("entered: %x\r", hrtcfg->entered);
  printf("hexmode: %x\r", hrtcfg->hexmode);
  printf("error_sr: %x\r", hrtcfg->error_sr);
  printf("error_pc: %x\r", hrtcfg->error_pc);
  printf("error_status: %x\r", hrtcfg->error_status);
  printf("newid[0]: %x\r", hrtcfg->newid[0]);
  printf("mon_version: %x\r", hrtcfg->mon_version);
  printf("mon_revision: %x\r", hrtcfg->mon_revision);
  printf("whd_base: %x\r", hrtcfg->whd_base);
  printf("whd_version: %x\r", hrtcfg->whd_version);
  printf("whd_revision: %x\r", hrtcfg->whd_revision);
  printf("max_chip: %x\r", hrtcfg->max_chip);
  printf("whd_expstrt: %x\r", hrtcfg->whd_expstrt);
  printf("whd_expstop: %x\r", hrtcfg->whd_expstop);

  DEBUG_FUNC_OUT(DEBUG_F_CONFIG | DEBUG_L0);
}


char UploadActionReplay()
{
  DEBUG_FUNC_IN(DEBUG_F_CONFIG | DEBUG_L0);

  int i,j;
  unsigned int adr, size, base=0x100000, offset=0xc00000, data;

  //hrtcfg_print();

  // TODO ROM isn-t uploaded properly, probablz the same reason kickstart wasn't working.
  // Should probably fix in hardware. (see Gary.v)

  //// reset minimig & CPU
  //EnableOsd();
  //SPI(OSD_CMD_RST);
  //SPI(6);
  //DisableOsd();
  ////while ((read32(REG_SYS_STAT_ADR) & 0x2));
  //SPIN(); SPIN();
  //EnableOsd();
  //SPI(OSD_CMD_RST);
  //SPI(4);
  //DisableOsd();
  //SPIN(); SPIN();
  //while ((read32(REG_SYS_STAT_ADR) & 0x2));

  if (RAOpen(&romfile, "HRTMON  ROM")) {
    //BootPrintEx("Uploading HRTmon ROM...");
    size = ((romfile.file.size)+511)>>9;
    printf("File size: %d\r", size);
    printf("[");
    for (i=0; i<size; i++) {
      if (!(i&15)) printf("*");
      RARead(&romfile,sector_buffer,512);
      adr = offset + base + i*512;
      for (j=0; j<512; j=j+4) {
        data = ((unsigned int*)sector_buffer)[j>>2];
        write32(adr+j, data);
        if (data != read32(adr+j)) printf("Mismatch @ 0x%08x : 0x%08x != 0x%08x\r", adr+j, data, read32(adr+j));
      }
      //EnableOsd();
      //adr = 0xa00000 + i*512;
      //SPI(OSD_CMD_WR);
      //SPI(adr&0xff); adr = adr>>8;
      //SPI(adr&0xff); adr = adr>>8;
      //SPI(adr&0xff); adr = adr>>8;
      //SPI(adr&0xff); adr = adr>>8;
      //for (j=0; j<512; j=j+4) {
      //  SPI(sector_buffer[j+0]);
      //  SPI(sector_buffer[j+1]);
      //  SPIN(); SPIN(); SPIN(); SPIN();
      //  SPI(sector_buffer[j+2]);
      //  SPI(sector_buffer[j+3]);
      //  SPIN(); SPIN(); SPIN(); SPIN();
      //  //data = ((unsigned int*)sector_buffer)[j>>2];
      //  //if (data != read32(offset+base+i*512+j)) printf("Mismatch @ 0x%08x : 0x%08x != 0x%08x\r", offset+base+i*512+j, data, read32(offset+base+i*512+j));
      //}
      //DisableOsd();
    }
    //EnableOsd();
    //adr = 0xa00000;
    //SPI(OSD_CMD_WR);
    //SPI(adr&0xff); adr = adr>>8;
    //SPI(adr&0xff); adr = adr>>8;
    //SPI(adr&0xff); adr = adr>>8;
    //SPI(adr&0xff); adr = adr>>8;
    //SPI(sector_buffer[j+0]);
    //SPI(sector_buffer[j+1]);
    //DisableOsd();
    printf("]\r");

    // configure HRTmon
    volatile hrtmon_cfg_t* hrtcfg = (hrtmon_cfg_t*)(0xd00000);
    hrtcfg->col0h       = 0x00;
    hrtcfg->col0l       = 0x5a;
    hrtcfg->col1h       = 0x0f;
    hrtcfg->col1l       = 0xff;
    hrtcfg->aga         = 0; // AGA?
    hrtcfg->cd32        = 0; // CD32?
    hrtcfg->screenmode  = 0; // NTSC?
    hrtcfg->novbr       = 1; // VBR?
    hrtcfg->hexmode     = 1; // HEXMODE?
    hrtcfg->entered     = 0;
    hrtcfg->keyboard    = 0; // LANG?
    hrtcfg->max_chip    = 1; // CHIPMEM_SIZE? (in 512kB blocks)
    hrtcfg->mon_size    = 0x800000; // MON_SIZE? (this could be wrong, but this is in WinUAE)
    hrtcfg->ide         = 0; // IDE_ENABLED?
    hrtcfg->a1200       = 1; // IDE_TYPE? (1 = A600/A1200, 0 = A4000)
    hrtcfg_print();

    return(1);
    //// unreset CPU
    //EnableOsd();
    //SPI(OSD_CMD_RST);
    //SPI(0);
    //DisableOsd();
  }
  return(0);

  DEBUG_FUNC_OUT(DEBUG_F_CONFIG | DEBUG_L0);
}


void SetConfigurationFilename(int config)
{
  DEBUG_FUNC_IN(DEBUG_F_CONFIG | DEBUG_L1);

	if(config)
		sprintf(configfilename,"MINIMIG%dCFG",config);
	else
		strcpy(configfilename,"MINIMIG CFG");

  DEBUG_FUNC_OUT(DEBUG_F_CONFIG | DEBUG_L1);
}


unsigned char ConfigurationExists(char *filename)
{
  DEBUG_FUNC_IN(DEBUG_F_CONFIG | DEBUG_L1);

	if(!filename)
		filename=configfilename;	// Use slot-based filename if none provided.
    if (FileOpen(&file, filename))
    {
		return(1);
	}
	return(0);

  DEBUG_FUNC_OUT(DEBUG_F_CONFIG | DEBUG_L1);
}


unsigned char LoadConfiguration(char *filename)
{
  DEBUG_FUNC_IN(DEBUG_F_CONFIG | DEBUG_L1);

    static const char config_id[] = "MNMGCFG0";
	char updatekickstart=0;
	char result=0;
    unsigned char key;

	if(!filename)
		filename=configfilename;	// Use slot-based filename if none provided.

    // load configuration data
    if (FileOpen(&file, filename))
    {
		BootPrint("Opened configuration file\n");
        printf("Configuration file size: %lu\r", file.size);
        if (file.size == sizeof(config))
        {
            FileRead(&file, sector_buffer);

			configTYPE *tmpconf=(configTYPE *)&sector_buffer;

            // check file id and version
            if (strncmp(tmpconf->id, config_id, sizeof(config.id)) == 0)
            {
				// A few more sanity checks...
				if(tmpconf->floppy.drives<=4) 
				{
					// If either the old config and new config have a different kickstart file,
					// or this is the first boot, we need to upload a kickstart image.
					if(strncmp(tmpconf->kickstart.name,config.kickstart.name,8)!=0)
						updatekickstart=true;
	                memcpy((void*)&config, (void*)sector_buffer, sizeof(config));
					result=1; // We successfully loaded the config.
				}
				else
					BootPrint("Config file sanity check failed!\n");
            }
            else
                BootPrint("Wrong configuration file format!\n");
        }
        else
            printf("Wrong configuration file size: %lu (expected: %lu)\r", file.size, sizeof(config));
    }
    if(!result)
	{
        BootPrint("Can not open configuration file!\n");

		BootPrint("Setting config defaults\n");

		// set default configuration
		memset((void*)&config, 0, sizeof(config));	// Finally found default config bug - params were reversed!
		strncpy(config.id, config_id, sizeof(config.id));
		strncpy(config.kickstart.name, "KICK    ", sizeof(config.kickstart.name));
		config.kickstart.long_name[0] = 0;
		config.memory = 0x15;
		config.cpu = 0;
		config.chipset = 0;
		config.floppy.speed=CONFIG_FLOPPY2X;
		config.floppy.drives=1;
		config.enable_ide=0;
		config.hardfile[0].enabled = 1;
		strncpy(config.hardfile[0].name, "HARDFILE", sizeof(config.hardfile[0].name));
		config.hardfile[0].long_name[0]=0;
		strncpy(config.hardfile[1].name, "HARDFILE", sizeof(config.hardfile[1].name));
		config.hardfile[1].long_name[0]=0;
		config.hardfile[1].enabled = 2;	// Default is access to entire SD card
		updatekickstart=true;

		BootPrint("Defaults set\n");
	}

    key = OsdGetCtrl();
    if (key == KEY_F1)
       config.chipset |= CONFIG_NTSC; // force NTSC mode if F1 pressed

    if (key == KEY_F2)
       config.chipset &= ~CONFIG_NTSC; // force PAL mode if F2 pressed

	ApplyConfiguration(updatekickstart);

    return(result);

  DEBUG_FUNC_OUT(DEBUG_F_CONFIG | DEBUG_L1);
}


void ApplyConfiguration(char reloadkickstart)
{
  DEBUG_FUNC_IN(DEBUG_F_CONFIG | DEBUG_L1);

    ConfigCPU(config.cpu);

	if(reloadkickstart)
	{
		//ConfigChipset(config.chipset | CONFIG_TURBO); // set CPU in turbo mode
		//ConfigFloppy(1, CONFIG_FLOPPY2X); // set floppy speed
		//OsdReset(RESET_BOOTLOADER);

		//if (!UploadKickstart(config.kickstart.name))
		//{
		//    strcpy(config.kickstart.name, "KICK    ");
		//    if (!UploadKickstart(config.kickstart.name))
		//        FatalError(6);
		//}

		//if (!CheckButton() && !config.disable_ar3) // if menu button pressed don't load Action Replay
		//{
		////	if(config.memory & 0x20)
		////		BootPrint("More than 2MB of Fast RAM configured - disabling Action Replay!");
		////	else
		//		UploadActionReplay();
		//}
	}
	else
	{
	    ConfigChipset(config.chipset);
	    ConfigFloppy(config.floppy.drives, config.floppy.speed);
	}

	// Whether or not we uploaded a kickstart image we now need to set various parameters from the config.

  	if(OpenHardfile(0))
	{
		switch(hdf[0].type) // Customise message for SD card access
		{
			case (HDF_FILE | HDF_SYNTHRDB):
		        sprintf(s, "Hardfile 1 (with fake RDB): %.8s.%.3s", hdf[1].file.name, &hdf[1].file.name[8]);
				break;
			case HDF_FILE:
		        sprintf(s, "Hardfile 0: %.8s.%.3s", hdf[0].file.name, &hdf[0].file.name[8]);
				break;
			case HDF_CARD:
		        sprintf(s, "Hardfile 0: using entire SD card");
				break;
			default:
		        sprintf(s, "Hardfile 0: using SD card partition %d",hdf[0].type-HDF_CARD);	// Number from 1
				break;
		}
        BootPrint(s);
        sprintf(s, "CHS: %u.%u.%u", hdf[0].cylinders, hdf[0].heads, hdf[0].sectors);
        BootPrint(s);
        sprintf(s, "Size: %lu MB", ((((unsigned long) hdf[0].cylinders) * hdf[0].heads * hdf[0].sectors) >> 11));
        BootPrint(s);
        sprintf(s, "Offset: %ld", hdf[0].offset);
		BootPrint(s);
	}
   	if(OpenHardfile(1))
	{
		switch(hdf[1].type)
		{
			case (HDF_FILE | HDF_SYNTHRDB):
		        sprintf(s, "Hardfile 1 (with fake RDB): %.8s.%.3s", hdf[1].file.name, &hdf[1].file.name[8]);
				break;
			case HDF_FILE:
		        sprintf(s, "Hardfile 1: %.8s.%.3s", hdf[1].file.name, &hdf[1].file.name[8]);
				break;
			case HDF_CARD:
		        sprintf(s, "Hardfile 1: using entire SD card");
				break;
			default:
		        sprintf(s, "Hardfile 1: using SD card partition %d",hdf[1].type-HDF_CARD);	// Number from 1
				break;
		}
        BootPrint(s);
        sprintf(s, "CHS: %u.%u.%u", hdf[1].cylinders, hdf[1].heads, hdf[1].sectors);
        BootPrint(s);
        sprintf(s, "Size: %lu MB", ((((unsigned long) hdf[1].cylinders) * hdf[1].heads * hdf[1].sectors) >> 11));
        BootPrint(s);
        sprintf(s, "Offset: %ld", hdf[1].offset);
        BootPrint(s);
	}

    ConfigIDE(config.enable_ide, config.hardfile[0].present && config.hardfile[0].enabled, config.hardfile[1].present && config.hardfile[1].enabled);

    sprintf(s, "CPU clock     : %s", config.chipset & 0x01 ? "turbo" : "normal");
    BootPrint(s);
    sprintf(s, "Chip RAM size : %s", config_memory_chip_msg[config.memory & 0x03]);
    BootPrint(s);
    sprintf(s, "Slow RAM size : %s", config_memory_slow_msg[config.memory >> 2 & 0x03]);
    BootPrint(s);
    sprintf(s, "Fast RAM size : %s", config_memory_fast_msg[config.memory >> 4 & 0x03]);
    BootPrint(s);


    sprintf(s, "Floppy drives : %u", config.floppy.drives + 1);
    BootPrint(s);
    sprintf(s, "Floppy speed  : %s", config.floppy.speed ? "fast": "normal");
    BootPrint(s);

    BootPrint("");

    sprintf(s, "\nA600 IDE HDC is %s.", config.enable_ide ? "enabled" : "disabled");
    BootPrint(s);
    sprintf(s, "Master HDD is %s.", config.hardfile[0].present ? config.hardfile[0].enabled ? "enabled" : "disabled" : "not present");
    BootPrint(s);
    sprintf(s, "Slave HDD is %s.", config.hardfile[1].present ? config.hardfile[1].enabled ? "enabled" : "disabled" : "not present");
    BootPrint(s);

#if 0
    if (cluster_size < 64)
    {
        BootPrint("\n***************************************************");
        BootPrint(  "*  It's recommended to reformat your memory card  *");
        BootPrint(  "*   using 32 KB clusters to improve performance   *");
		BootPrint(  "*           when using large hardfiles.           *");	// AMR
        BootPrint(  "***************************************************");
    }
    printf("Bootloading is complete.\r");
#endif

    BootPrint("\nExiting bootloader...");

    ConfigMemory(config.memory);
    ConfigCPU(config.cpu);
    //ConfigFilter(config.filter.lores, config.filter.hires);
    //ConfigScanlines(config.scanlines);
    ConfigVideo(config.filter.hires, config.filter.lores, config.scanlines);
    ConfigChipset(config.chipset);
    ConfigFloppy(config.floppy.drives, config.floppy.speed);


	if(reloadkickstart)
	{
    UploadActionReplay();

    printf("Reloading kickstart ...\r");
	  TIMER_wait(1000);
	    //BootExit();
    EnableOsd();
    SPI(OSD_CMD_RST);
    rstval |= (SPI_RST_CPU | SPI_CPU_HLT);
    SPI(rstval);
    DisableOsd();
    SPIN(); SPIN(); SPIN(); SPIN();
		if (!UploadKickstart(config.kickstart.name))
		{
		    strcpy(config.kickstart.name, "KICK    ");
		    if (!UploadKickstart(config.kickstart.name))
		        FatalError(6);
		}
    EnableOsd();
    SPI(OSD_CMD_RST);
    rstval |= (SPI_RST_USR | SPI_RST_CPU);
    SPI(rstval);
    DisableOsd();
    SPIN(); SPIN(); SPIN(); SPIN();
    EnableOsd();
    SPI(OSD_CMD_RST);
    rstval = 0;
    SPI(rstval);
    DisableOsd();
    SPIN(); SPIN(); SPIN(); SPIN();
      //while ((read32(REG_SYS_STAT_ADR) & 0x2));
	}
	else {
    printf("Resetting ...\r");
		//OsdReset(RESET_NORMAL);
    EnableOsd();
    SPI(OSD_CMD_RST);
    rstval |= (SPI_RST_USR | SPI_RST_CPU);
    SPI(rstval);
    DisableOsd();
    SPIN(); SPIN(); SPIN(); SPIN();
    EnableOsd();
    SPI(OSD_CMD_RST);
    rstval = 0;
    SPI(rstval);
    DisableOsd();
    SPIN(); SPIN(); SPIN(); SPIN();
    //while ((read32(REG_SYS_STAT_ADR) & 0x2));
}

  DEBUG_FUNC_OUT(DEBUG_F_CONFIG | DEBUG_L1);
}


unsigned char SaveConfiguration(char *filename)
{
  DEBUG_FUNC_IN(DEBUG_F_CONFIG | DEBUG_L1);

	if(!filename)
		filename=configfilename;	// Use slot-based filename if none provided.

    // save configuration data
    if (FileOpen(&file, filename))
    {
        printf("Configuration file size: %lu\r", file.size);
        if (file.size != sizeof(config))
        {
            file.size = sizeof(config);
            if (!UpdateEntry(&file))
                return(0);
        }

        memset((void*)&sector_buffer, 0, sizeof(sector_buffer));
        memcpy((void*)&sector_buffer, (void*)&config, sizeof(config));
        FileWrite(&file, sector_buffer);
        return(1);
    }
    else
    {
        printf("Configuration file not found!\r");
        printf("Trying to create a new one...\r");
        strncpy(file.name, filename, 11);
        file.attributes = 0;
        file.size = sizeof(config);
        if (FileCreate(0, &file))
        {
            printf("File created.\r");
            printf("Trying to write new data...\r");
            memset((void*)sector_buffer, 0, sizeof(sector_buffer));
            memcpy((void*)sector_buffer, (void*)&config, sizeof(config));

            if (FileWrite(&file, sector_buffer))
            {
                printf("File written successfully.\r");
                return(1);
            }
            else
                printf("File write failed!\r");
        }
        else
            printf("File creation failed!\r");
    }
    return(0);

  DEBUG_FUNC_OUT(DEBUG_F_CONFIG | DEBUG_L1);
}

