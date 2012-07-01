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

#include <stdio.h>
#include <string.h>

configTYPE config;
fileTYPE file;
extern char s[40];
char configfilename[12];
char DebugMode=0;

unsigned char romkey[3072];

RAFile romfile;

char UploadKickstart(char *name)
{
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

    if (RAOpen(&romfile, filename))
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
    else
    {
        sprintf(s, "No \"%s\" file!", filename);
        BootPrint(s);
    }
    return(0);
}


char UploadActionReplay()
{
    if (RAOpen(&romfile, "AR3     ROM"))
    {
        if (romfile.file.size == 0x40000)
        { // 256 KB Action Replay 3 ROM
            BootPrint("\nUploading Action Replay ROM...");
            PrepareBootUpload(0x40, 0x04);
			SendFile(&romfile);
            ClearMemory(0x440000, 0x40000);
			return(1);
        }
        else
        {
            BootPrint("\nUnsupported AR3.ROM file size!!!");
			/* FatalError(6); */
			return(0);
        }
    }
	return(0);
}


void SetConfigurationFilename(int config)
{
	if(config)
		sprintf(configfilename,"MINIMIG%dCFG",config);
	else
		strcpy(configfilename,"MINIMIG CFG");
}



unsigned char ConfigurationExists(char *filename)
{
	if(!filename)
		filename=configfilename;	// Use slot-based filename if none provided.
    if (FileOpen(&file, filename))
    {
		return(1);
	}
	return(0);
}


unsigned char LoadConfiguration(char *filename)
{
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
}


void ApplyConfiguration(char reloadkickstart)
{
    ConfigCPU(config.cpu);

	if(reloadkickstart)
	{
		ConfigChipset(config.chipset | CONFIG_TURBO); // set CPU in turbo mode
		ConfigFloppy(1, CONFIG_FLOPPY2X); // set floppy speed
		OsdReset(RESET_BOOTLOADER);

		if (!UploadKickstart(config.kickstart.name))
		{
		    strcpy(config.kickstart.name, "KICK    ");
		    if (!UploadKickstart(config.kickstart.name))
		        FatalError(6);
		}

		if (!CheckButton() && !config.disable_ar3) // if menu button pressed don't load Action Replay
		{
#ifndef ACTIONREPLAY_BROKEN
			if(config.memory & 0x20)
				BootPrint("More than 2MB of Fast RAM configured - disabling Action Replay!");
			else
				UploadActionReplay();
#endif
		}
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
		        sprintf(s, "\nHardfile 1 (with fake RDB): %.8s.%.3s", hdf[1].file.name, &hdf[1].file.name[8]);
				break;
			case HDF_FILE:
		        sprintf(s, "\nHardfile 0: %.8s.%.3s", hdf[0].file.name, &hdf[0].file.name[8]);
				break;
			case HDF_CARD:
		        sprintf(s, "\nHardfile 0: using entire SD card");
				break;
			default:
		        sprintf(s, "\nHardfile 0: using SD card partition %d",hdf[0].type-HDF_CARD);	// Number from 1
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
		        sprintf(s, "\nHardfile 1 (with fake RDB): %.8s.%.3s", hdf[1].file.name, &hdf[1].file.name[8]);
				break;
			case HDF_FILE:
		        sprintf(s, "\nHardfile 1: %.8s.%.3s", hdf[1].file.name, &hdf[1].file.name[8]);
				break;
			case HDF_CARD:
		        sprintf(s, "\nHardfile 1: using entire SD card");
				break;
			default:
		        sprintf(s, "\nHardfile 1: using SD card partition %d",hdf[1].type-HDF_CARD);	// Number from 1
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
    ConfigFilter(config.filter.lores, config.filter.hires);
    ConfigScanlines(config.scanlines);

	if(reloadkickstart)
	{
	    WaitTimer(5000);
	    BootExit();
	}
	else
		OsdReset(RESET_NORMAL);

    ConfigChipset(config.chipset);
    ConfigFloppy(config.floppy.drives, config.floppy.speed);
}


unsigned char SaveConfiguration(char *filename)
{
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
}

