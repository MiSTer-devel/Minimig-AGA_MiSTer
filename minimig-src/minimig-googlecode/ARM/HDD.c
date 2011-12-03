/*
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

// 2009-11-22 - read/write multiple implemented

#include "AT91SAM7S256.h"
#include "stdio.h"
#include "string.h"
#include "errors.h"
#include "hardware.h"
#include "FAT.h"
#include "HDD.h"
#include "MMC.h"
#include "FPGA.h"
#include "config.h"

// hardfile structure
hdfTYPE hdf[2];

// helper function for byte swapping
void SwapBytes(char *ptr, unsigned long len)
{
    char x;
    len >>= 1;
    while (len--)
    {
        x = *ptr;
        *ptr++ = ptr[1];
        *ptr++ = x;
    }
}

void IdentifyDevice(unsigned short *pBuffer, unsigned char unit)
{ // builds Identify Device struct

    char *p, i, x;
    unsigned long total_sectors = hdf[unit].cylinders * hdf[unit].heads * hdf[unit].sectors;

    memset(pBuffer, 0, 512);

    pBuffer[0] = 1 << 6; // hard disk
    pBuffer[1] = hdf[unit].cylinders; // cyl count
    pBuffer[3] = hdf[unit].heads; // head count
    pBuffer[6] = hdf[unit].sectors; // sectors per track
    memcpy((char*)&pBuffer[10], "1234567890ABCDEFGHIJ", 20); // serial number - byte swapped
    memcpy((char*)&pBuffer[23], ".100    ", 8); // firmware version - byte swapped
    p = (char*)&pBuffer[27];
    memcpy(p, "YAQUBE                                  ", 40); // model name - byte swapped
    p += 8;
    if (config.hardfile[unit].long_name[0])
    {
        for (i = 0; (x = config.hardfile[unit].long_name[i]) && i < 16; i++) // copy file name as model name
            p[i] = x;
    }
    else
    {
        memcpy(p, config.hardfile[unit].name, 8); // copy file name as model name
    }
    SwapBytes((char*)&pBuffer[27], 40);

    pBuffer[47] = 0x8010; //maximum sectors per block in Read/Write Multiple command
    pBuffer[53] = 1;
    pBuffer[54] = hdf[unit].cylinders;
    pBuffer[55] = hdf[unit].heads;
    pBuffer[56] = hdf[unit].sectors;
    pBuffer[57] = (unsigned short)total_sectors;
    pBuffer[58] = (unsigned short)(total_sectors >> 16);
}

unsigned long chs2lba(unsigned short cylinder, unsigned char head, unsigned short sector, unsigned char unit)
{
    return(cylinder * hdf[unit].heads + head) * hdf[unit].sectors + sector - 1;
}

void WriteTaskFile(unsigned char error, unsigned char sector_count, unsigned char sector_number, unsigned char cylinder_low, unsigned char cylinder_high, unsigned char drive_head)
{
    EnableFpga();

    SPI(CMD_IDE_REGS_WR); // write task file registers command
    SPI(0x00);
    SPI(0x00); // dummy
    SPI(0x00);
    SPI(0x00); // dummy
    SPI(0x00);
    SPI(0x00); // dummy

    SPI(0x00);
    SPI(0x00);
    SPI(error); // error
    SPI(0x00);
    SPI(sector_count); // sector count
    SPI(0x00);
    SPI(sector_number); //sector number
    SPI(0x00);
    SPI(cylinder_low); // cylinder low
    SPI(0x00);
    SPI(cylinder_high); // cylinder high
    SPI(0x00);
    SPI(drive_head); // drive/head

    DisableFpga();
}

void WriteStatus(unsigned char status)
{
    EnableFpga();

    SPI(CMD_IDE_STATUS_WR);
    SPI(status);
    SPI(0x00);
    SPI(0x00);
    SPI(0x00);
    SPI(0x00);

    DisableFpga();
}

void HandleHDD(unsigned char c1, unsigned char c2)
{
    unsigned short id[256];
    unsigned char  tfr[8];
    unsigned short i;
    unsigned short sector;
    unsigned short cylinder;
    unsigned char  head;
    unsigned char  unit;
    unsigned short sector_count;
    unsigned short block_count;

    if (c1 & CMD_IDECMD)
    {
        DISKLED_ON;
        EnableFpga();
        SPI(CMD_IDE_REGS_RD); // read task file registers
        SPI(0x00);
        SPI(0x00);
        SPI(0x00);
        SPI(0x00);
        SPI(0x00);
        for (i = 0; i < 8; i++)
        {
            SPI(0);
            tfr[i] = SPI(0);
        }
        DisableFpga();

        unit = tfr[6] & 0x10 ? 1 : 0; // master/slave selection

        if (0)
        {
            printf("IDE:");
            for (i = 1; i < 7; i++)
                printf("%02X.",tfr[i]);
            printf("%02X\r", tfr[7]);
        }

        if ((tfr[7] & 0xF0) == ACMD_RECALIBRATE) // Recalibrate 0x10-0x1F (class 3 command: no data)
        {
            printf("Recalibrate\r");
            WriteTaskFile(0, 0, 1, 0, 0, tfr[6] & 0xF0);
            WriteStatus(IDE_STATUS_END | IDE_STATUS_IRQ);
        }
        else if (tfr[7] == ACMD_IDENTIFY_DEVICE) // Identify Device
        {
            printf("Identify Device\r");
            IdentifyDevice(id, unit);
            WriteTaskFile(0, tfr[2], tfr[3], tfr[4], tfr[5], tfr[6]);
            WriteStatus(IDE_STATUS_RDY); // pio in (class 1) command type
            EnableFpga();
            SPI(CMD_IDE_DATA_WR); // write data command
            SPI(0x00);
            SPI(0x00);
            SPI(0x00);
            SPI(0x00);
            SPI(0x00);
            for (i = 0; i < 256; i++)
            {
                SPI((unsigned char)id[i]);
                SPI((unsigned char)(id[i] >> 8));
            }
            DisableFpga();
            WriteStatus(IDE_STATUS_END | IDE_STATUS_IRQ);
        }
        else if (tfr[7] == ACMD_INITIALIZE_DEVICE_PARAMETERS) // Initiallize Device Parameters
        {
            printf("Initialize Device Parameters\r");
            printf("IDE:");
            for (i = 1; i < 7; i++)
                printf("%02X.", tfr[i]);
            printf("%02X\r", tfr[7]);
            WriteTaskFile(0, tfr[2], tfr[3], tfr[4], tfr[5], tfr[6]);
            WriteStatus(IDE_STATUS_END | IDE_STATUS_IRQ);
        }
        else if (tfr[7] == ACMD_SET_MULTIPLE_MODE) // Set Multiple Mode
        {
            hdf[unit].sectors_per_block = tfr[2];

            printf("Set Multiple Mode\r");
            printf("IDE:");
            for (i = 1; i < 7; i++)
                printf("%02X.", tfr[i]);
            printf("%02X\r", tfr[7]);

            WriteStatus(IDE_STATUS_END | IDE_STATUS_IRQ);
        }
        else if (tfr[7] == ACMD_READ_SECTORS) // Read Sectors
        {
            WriteStatus(IDE_STATUS_RDY); // pio in (class 1) command type

            sector = tfr[3];
            cylinder = tfr[4] | (tfr[5] << 8);
            head = tfr[6] & 0x0F;
            sector_count = tfr[2];
            if (sector_count == 0)
               sector_count = 0x100;

            if (hdf[unit].file.size)
                HardFileSeek(&hdf[unit], chs2lba(cylinder, head, sector, unit));

            while (sector_count)
            {
                while (!(GetFPGAStatus() & CMD_IDECMD)); // wait for empty sector buffer

                WriteStatus(IDE_STATUS_IRQ);

                if (hdf[unit].file.size)
                {
                    FileRead(&hdf[unit].file, NULL);
                    FileSeek(&hdf[unit].file, 1, SEEK_CUR);
                }

                sector_count--; // decrease sector count
            }
        }
        else if (tfr[7] == ACMD_READ_MULTIPLE) // Read Multiple Sectors (multiple sector transfer per IRQ)
        {
            WriteStatus(IDE_STATUS_RDY); // pio in (class 1) command type

            sector = tfr[3];
            cylinder = tfr[4] | (tfr[5] << 8);
            head = tfr[6] & 0x0F;
            sector_count = tfr[2];
            if (sector_count == 0)
               sector_count = 0x100;

            if (hdf[unit].file.size)
                HardFileSeek(&hdf[unit], chs2lba(cylinder, head, sector, unit));

            while (sector_count)
            {
                while (!(GetFPGAStatus() & CMD_IDECMD)); // wait for empty sector buffer

                block_count = sector_count;
                if (block_count > hdf[unit].sectors_per_block)
                    block_count = hdf[unit].sectors_per_block;

                WriteStatus(IDE_STATUS_IRQ);

                if (hdf[unit].file.size)
                    FileReadEx(&hdf[unit].file, NULL, block_count); // NULL enables direct transfer to the FPGA

                sector_count -= block_count; // decrease sector count
            }
        }
        else if (tfr[7] == ACMD_WRITE_SECTORS) // write sectors
        {
            WriteStatus(IDE_STATUS_REQ); // pio out (class 2) command type

            sector = tfr[3];
            cylinder = tfr[4] | (tfr[5] << 8);
            head = tfr[6] & 0x0F;
            sector_count = tfr[2];
            if (sector_count == 0)
                sector_count = 0x100;

            if (hdf[unit].file.size)
                HardFileSeek(&hdf[unit], chs2lba(cylinder, head, sector, unit));

            while (sector_count)
            {
                while (!(GetFPGAStatus() & CMD_IDEDAT)); // wait for full write buffer

                EnableFpga();
                SPI(CMD_IDE_DATA_RD); // read data command
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
                SPI(0x00);
                for (i = 0; i < 512; i++)
                    sector_buffer[i] = SPI(0xFF);
                DisableFpga();

                sector_count--; // decrease sector count

                if (sector_count)
                    WriteStatus(IDE_STATUS_IRQ);
                else
                    WriteStatus(IDE_STATUS_END | IDE_STATUS_IRQ);

                if (hdf[unit].file.size)
                {
                    FileWrite(&hdf[unit].file, sector_buffer);
                    FileSeek(&hdf[unit].file, 1, SEEK_CUR);
                }
            }
        }
        else if (tfr[7] == ACMD_WRITE_MULTIPLE) // write sectors
        {
            WriteStatus(IDE_STATUS_REQ); // pio out (class 2) command type

            sector = tfr[3];
            cylinder = tfr[4] | (tfr[5] << 8);
            head = tfr[6] & 0x0F;
            sector_count = tfr[2];
            if (sector_count == 0)
                sector_count = 0x100;

            if (hdf[unit].file.size)
                HardFileSeek(&hdf[unit], chs2lba(cylinder, head, sector, unit));

            while (sector_count)
            {
                block_count = sector_count;
                if (block_count > hdf[unit].sectors_per_block)
                    block_count = hdf[unit].sectors_per_block;

                while (block_count)
                {
                    while (!(GetFPGAStatus() & CMD_IDEDAT)); // wait for full write buffer

                    EnableFpga();
                    SPI(CMD_IDE_DATA_RD); // read data command
                    SPI(0x00);
                    SPI(0x00);
                    SPI(0x00);
                    SPI(0x00);
                    SPI(0x00);
                    for (i = 0; i < 512; i++)
                        sector_buffer[i] = SPI(0xFF);
                    DisableFpga();

                    if (hdf[unit].file.size)
                    {
                        FileWrite(&hdf[unit].file, sector_buffer);
                        FileSeek(&hdf[unit].file, 1, SEEK_CUR);
                    }

                    block_count--;  // decrease block count
                    sector_count--; // decrease sector count
                }

                if (sector_count)
                    WriteStatus(IDE_STATUS_IRQ);
                else
                    WriteStatus(IDE_STATUS_END | IDE_STATUS_IRQ);
            }
        }
        else
        {
            printf("Unknown ATA command\r");

            printf("IDE:");
            for (i = 1; i < 7; i++)
                printf("%02X.", tfr[i]);
            printf("%02X\r", tfr[7]);
            WriteTaskFile(0x04, tfr[2], tfr[3], tfr[4], tfr[5], tfr[6]);
            WriteStatus(IDE_STATUS_END | IDE_STATUS_IRQ | IDE_STATUS_ERR);
        }
        DISKLED_OFF;
    }
}

void GetHardfileGeometry(hdfTYPE *pHDF)
{ // this function comes from WinUAE, should return the same CHS as WinUAE

    unsigned long total;
    unsigned long i, head, cyl, spt;
    unsigned long sptt[] = { 63, 127, 255, -1 };

    if (pHDF->file.size == 0)
        return;

    total = pHDF->file.size / 512;

    for (i = 0; sptt[i] >= 0; i++)
    {
        spt = sptt[i];
        for (head = 4; head <= 16; head++)
        {
            cyl = total / (head * spt);
            if (pHDF->file.size <= 512 * 1024 * 1024)
            {
                if (cyl <= 1023)
                    break;
            }
            else
            {
                if (cyl < 16383)
                    break;
                if (cyl < 32767 && head >= 5)
                    break;
                if (cyl <= 65535)
                    break;
            }
        }
        if (head <= 16)
            break;
    }
    pHDF->cylinders = (unsigned short)cyl;
    pHDF->heads = (unsigned short)head;
    pHDF->sectors = (unsigned short)spt;
}

void BuildHardfileIndex(hdfTYPE *pHDF)
{
    // builds index to speed up hard file seek

    fileTYPE *file = &pHDF->file;
    unsigned long *index = pHDF->index;
    unsigned long i;
    unsigned long j;

    pHDF->index_size = 16; // indexing size
    j = 1 << pHDF->index_size;
    i = pHDF->file.size >> 10; // divided by index table size (1024)
    while (j < i) // find greater or equal power of two
    {
        j <<= 1;
        pHDF->index_size++;
    }

    for (i = 0; i < file->size; i += j)
    {
        FileSeek(file, i >> 9, SEEK_SET); // FileSeek seeks in 512-byte sectors
        *index++ = file->cluster;
    }
}

unsigned char HardFileSeek(hdfTYPE *pHDF, unsigned long lba)
{
    if ((pHDF->file.sector ^ lba) & cluster_mask)
    { // different clusters
        if ((pHDF->file.sector > lba) || ((pHDF->file.sector ^ lba) & (cluster_mask << (fat32 ? 7 : 8)))) // 7: 128 FAT32 links per sector, 8: 256 FAT16 links per sector
        { // requested cluster lies before current pointer position or in different FAT sector
            pHDF->file.cluster = pHDF->index[lba >> (pHDF->index_size - 9)];// minus 9 because lba is in 512-byte sectors
            pHDF->file.sector = lba & (-1 << (pHDF->index_size - 9));
        }
    }
    return FileSeek(&pHDF->file, lba, SEEK_SET);
}

unsigned char OpenHardfile(unsigned char unit)
{
    unsigned long time;
    char filename[12];

    strncpy(filename, config.hardfile[unit].name, 8);
    strcpy(&filename[8], "HDF");

    if (filename[0])
    {
        if (FileOpen(&hdf[unit].file, filename))
        {
            GetHardfileGeometry(&hdf[unit]);

            printf("HARDFILE %d:\r", unit);
            printf("file: \"%.8s.%.3s\"\r", hdf[unit].file.name, &hdf[unit].file.name[8]);
            printf("size: %lu (%lu MB)\r", hdf[unit].file.size, hdf[unit].file.size >> 20);
            printf("CHS: %u.%u.%u", hdf[unit].cylinders, hdf[unit].heads, hdf[unit].sectors);
            printf(" (%lu MB)\r", ((((unsigned long) hdf[unit].cylinders) * hdf[unit].heads * hdf[unit].sectors) >> 11));

            time = GetTimer(0);
            BuildHardfileIndex(&hdf[unit]);
            time = GetTimer(0) - time;
            printf("Hardfile indexed in %lu ms\r", time >> 20);

            config.hardfile[unit].present = 1;
            return 1;
        }
    }

    config.hardfile[unit].present = 0;
    return 0;
}
