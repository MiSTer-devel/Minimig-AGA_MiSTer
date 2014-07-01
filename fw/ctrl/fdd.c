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

// 2009-11-14   - adapted gap size
// 2009-12-24   - updated sync word list
//              - fixed sector header generation
// 2010-01-09   - support for variable number of tracks

//#include "AT91SAM7S256.h"
//#include "stdio.h"
//#include "string.h"
#include "errors.h"
#include "hardware.h"
#include "fat.h"
#include "fdd.h"
#include "config.h"

#include "stdio.h"

unsigned char vDEBUG = 0;

unsigned char drives = 0; // number of active drives reported by FPGA (may change only during reset)
adfTYPE *pdfx;            // drive select pointer
adfTYPE df[4];            // drive 0 information structure

#define TRACK_SIZE 12668
#define HEADER_SIZE 0x40
#define DATA_SIZE 0x400
#define SECTOR_SIZE (HEADER_SIZE + DATA_SIZE)
#define SECTOR_COUNT 11
#define LAST_SECTOR (SECTOR_COUNT - 1)
#define GAP_SIZE (TRACK_SIZE - SECTOR_COUNT * SECTOR_SIZE)

// sends the data in the sector buffer to the FPGA, translated into an Amiga floppy format sector
// note that we do not insert clock bits because they will be stripped by the Amiga software anyway
void SendSector(unsigned char *pData, unsigned char sector, unsigned char track, unsigned char dsksynch, unsigned char dsksyncl)
{
  DEBUG_FUNC_IN(DEBUG_F_FDD | DEBUG_L2);

    unsigned char checksum[4];
    unsigned short i;
    unsigned char x;
    unsigned char *p;

    // preamble
    SPI(0xAA);
    SPI(0xAA);
    SPI(0xAA);
    SPI(0xAA);

    // synchronization
    SPI(dsksynch);
    SPI(dsksyncl);
    SPI(dsksynch);
    SPI(dsksyncl);

    // odd bits of header
    x = 0x55;
    checksum[0] = x;
    SPI(x);
    x = track >> 1 & 0x55;
    checksum[1] = x;
    SPI(x);
    x = sector >> 1 & 0x55;
    checksum[2] = x;
    SPI(x);
    x = 11 - sector >> 1 & 0x55;
    checksum[3] = x;
    SPI(x);

    // even bits of header
    x = 0x55;
    checksum[0] ^= x;
    SPI(x);
    x = track & 0x55;
    checksum[1] ^= x;
    SPI(x);
    x = sector & 0x55;
    checksum[2] ^= x;
    SPI(x);
    x = 11 - sector & 0x55;
    checksum[3] ^= x;
    SPI(x);

    // sector label and reserved area (changes nothing to checksum)
    i = 0x20;
    while (i--)
        SPI(0xAA);

    // send header checksum
    SPI(0xAA);
    SPI(0xAA);
    SPI(0xAA);
    SPI(0xAA);
    SPI(checksum[0] | 0xAA);
    SPI(checksum[1] | 0xAA);
    SPI(checksum[2] | 0xAA);
    SPI(checksum[3] | 0xAA);

    // calculate data checksum
    checksum[0] = 0;
    checksum[1] = 0;
    checksum[2] = 0;
    checksum[3] = 0;

    p = pData;
    i = DATA_SIZE / 2 / 4;
    while (i--)
    {
        x = *p++;
        checksum[0] ^= x ^ x >> 1;
        x = *p++;
        checksum[1] ^= x ^ x >> 1;
        x = *p++;
        checksum[2] ^= x ^ x >> 1;
        x = *p++;
        checksum[3] ^= x ^ x >> 1;
    }

    // send data checksum
    SPI(0xAA);
    SPI(0xAA);
    SPI(0xAA);
    SPI(0xAA);
    SPI(checksum[0] | 0xAA);
    SPI(checksum[1] | 0xAA);
    SPI(checksum[2] | 0xAA);
    SPI(checksum[3] | 0xAA);

    // odd bits of data field
    i = DATA_SIZE / 2;
    p = pData;
    while (i--)
        SPI(*p++ >> 1 | 0xAA);

    // even bits of data field
    i = DATA_SIZE / 2;
    p = pData;
    while (i--)
        SPI(*p++ | 0xAA);

  DEBUG_FUNC_OUT(DEBUG_F_FDD | DEBUG_L2);
}


void SendGap(void)
{
  DEBUG_FUNC_IN(DEBUG_F_FDD | DEBUG_L2);

    unsigned short i = GAP_SIZE;
    while (i--)
        SPI(0xAA);

  DEBUG_FUNC_OUT(DEBUG_F_FDD | DEBUG_L2);
}


// read a track from disk
void ReadTrack(adfTYPE *drive)
{ // track number is updated in drive struct before calling this function
  DEBUG_FUNC_IN(DEBUG_F_FDD | DEBUG_L2);

    unsigned char sector;
    unsigned char status;
    unsigned char track;
    unsigned short dsksync;
    unsigned short dsklen;
    //unsigned short n;

    if (drive->track >= drive->tracks)
    {
        printf("Illegal track read: %d\r", drive->track);
        ErrorMessage("    Illegal track read!", drive->track);
        drive->track = drive->tracks - 1;
    }

    // display track number: cylinder & head
    if (vDEBUG)
        printf("*%u:", drive->track);

    if (drive->track != drive->track_prev)
    { // track step or track 0, start at beginning of track
        drive->track_prev = drive->track;
        sector = 0;
        file.cluster = drive->cache[drive->track];
        file.sector = drive->track * SECTOR_COUNT;
        drive->sector_offset = sector;
        drive->cluster_offset = file.cluster;
    }
    else
    { // same track, start at next sector in track
        sector = drive->sector_offset;
        file.cluster = drive->cluster_offset;
        file.sector = (drive->track * SECTOR_COUNT) + sector;
    }

    EnableFpga();
    status   = SPI(0); // read request signal
    track    = SPI(0); // track number (cylinder & head)
    dsksync  = (SPI(0)) << 8; // disk sync high byte
    dsksync |= SPI(0); // disk sync low byte
    dsklen   = (SPI(0)) << 8 & 0x3F00; // msb of mfm words to transfer
    dsklen  |= SPI(0); // lsb of mfm words to transfer
    DisableFpga();

    if (track >= drive->tracks)
        track = drive->tracks - 1;

    if (vDEBUG)
        printf("(%u)[%04X]:", status >> 6, dsksync);

    while (1)
    {
        FileRead(&file, sector_buffer);

        EnableFpga();

        // check if FPGA is still asking for data
        status   = SPI(0); // read request signal
        track    = SPI(0); // track number (cylinder & head)
        dsksync  = (SPI(0)) << 8; // disk sync high byte
        dsksync |= SPI(0); // disk sync low byte
        dsklen   = (SPI(0)) << 8 & 0x3F00; // msb of mfm words to transfer
        dsklen  |= SPI(0); // lsb of mfm words to transfer

        if (track >= drive->tracks)
            track = drive->tracks - 1;

        // workaround for Copy Lock in Wiz'n'Liz and North&South (might brake other games)
        if (dsksync == 0x0000 || dsksync == 0x8914 || dsksync == 0xA144)
            dsksync = 0x4489;

        // North&South: $A144
        // Wiz'n'Liz (Copy Lock): $8914
        // Prince of Persia: $4891
        // Commando: $A245

        if (vDEBUG)
            printf("%X:%04X", sector, dsklen);

        // some loaders stop dma if sector header isn't what they expect
        // because we don't check dma transfer count after sending a word
        // the track can be changed while we are sending the rest of the previous sector
        // in this case let's start transfer from the beginning
        if (track == drive->track)
        {
            // send sector if fpga is still asking for data
            if (status & CMD_RDTRK)
            {
                //GenerateHeader(sector_header, sector_buffer, sector, track, dsksync);
                //SendSector(sector_header, sector_buffer);
                SendSector(sector_buffer, sector, track, (unsigned char)(dsksync >> 8), (unsigned char)dsksync);

                if (sector == LAST_SECTOR)
                    SendGap();
            }
        }

        // we are done accessing FPGA
        DisableFpga();

        // track has changed
        if (track != drive->track)
            break;

        // read dma request
        if (!(status & CMD_RDTRK))
            break;

        sector++;
        if (sector < SECTOR_COUNT)
        {
            FileNextSector(&file);
        }
        else // go to the start of current track
        {
            sector = 0;
            file.cluster = drive->cache[drive->track];
            file.sector = drive->track * SECTOR_COUNT;
        }

        // remember current sector and cluster
        drive->sector_offset = sector;
        drive->cluster_offset = file.cluster;

        if (vDEBUG)
            printf("->");
    }
    if (vDEBUG)
        printf(":OK\r");

  DEBUG_FUNC_OUT(DEBUG_F_FDD | DEBUG_L2);
}


unsigned char FindSync(adfTYPE *drive)
// reads data from fifo till it finds sync word or fifo is empty and dma inactive (so no more data is expected)
{
  DEBUG_FUNC_IN(DEBUG_F_FDD | DEBUG_L2);

    unsigned char  c1, c2, c3, c4;
    unsigned short n;

    while (1)
    {
        EnableFpga();
        c1 = SPI(0); // write request signal
        c2 = SPI(0); // track number (cylinder & head)
        if (!(c1 & CMD_WRTRK))
            break;
        if (c2 != drive->track)
            break;
        SPI(0); // disk sync high byte
        SPI(0); // disk sync low byte
        c3 = (SPI(0)) & 0xBF; // msb of mfm words to transfer
        c4 = SPI(0); // lsb of mfm words to transfer

        if (c3 == 0 && c4 == 0)
            break;

        n = ((c3 & 0x3F) << 8) + c4;

        while (n--)
        {
            c3 = SPI(0);
            c4 = SPI(0);
            if (c3 == 0x44 && c4 == 0x89)
            {
                DisableFpga();
                if (vDEBUG)
                    printf("#SYNC:");

                return 1;
            }
        }
        DisableFpga();
    }
    DisableFpga();
    return 0;

  DEBUG_FUNC_OUT(DEBUG_F_FDD | DEBUG_L2);
}


unsigned char GetHeader(unsigned char *pTrack, unsigned char *pSector)
// this function reads data from fifo till it finds sync word or dma is inactive
{
  DEBUG_FUNC_IN(DEBUG_F_FDD | DEBUG_L2);

    unsigned char c, c1, c2, c3, c4;
    unsigned char i;
    unsigned char checksum[4];

    Error = 0;
    while (1)
    {
        EnableFpga();
        c1 = SPI(0); // write request signal
        c2 = SPI(0); // track number (cylinder & head)
        if (!(c1 & CMD_WRTRK))
            break;
        SPI(0); // disk sync high byte
        SPI(0); // disk sync low byte
        c3 = SPI(0); // msb of mfm words to transfer
        c4 = SPI(0); // lsb of mfm words to transfer

        if ((c3 & 0x3F) != 0 || c4 > 24)// remaining header data is 25 mfm words
        {
            c1 = SPI(0); // second sync lsb
            c2 = SPI(0); // second sync msb
            if (c1 != 0x44 || c2 != 0x89)
            {
                Error = 21;
                printf("\rSecond sync word missing...\r");
                break;
            }

			SPIN();

            c = SPI(0);
            checksum[0] = c;
            c1 = (c & 0x55) << 1;
			SPIN();
            c = SPI(0);
            checksum[1] = c;
            c2 = (c & 0x55) << 1;

			SPIN();

            c = SPI(0);
            checksum[2] = c;
            c3 = (c & 0x55) << 1;
			SPIN();
            c = SPI(0);
            checksum[3] = c;
            c4 = (c & 0x55) << 1;

			SPIN();

            c = SPI(0);
            checksum[0] ^= c;
            c1 |= c & 0x55;
			SPIN();
            c = SPI(0);
            checksum[1] ^= c;
            c2 |= c & 0x55;

			SPIN();

            c = SPI(0);
            checksum[2] ^= c;
            c3 |= c & 0x55;
			SPIN();
            c = SPI(0);
            checksum[3] ^= c;
            c4 |= c & 0x55;

            if (c1 != 0xFF) // always 0xFF
                Error = 22;
            else if (c2 > 159) // Track number (0-159)
                Error = 23;
            else if (c3 > 10) // Sector number (0-10)
                Error = 24;
            else if (c4 > 11 || c4 == 0) // Number of sectors to gap (1-11)
                Error = 25;

            if (Error)
            {
                printf("\rWrong header: %u.%u.%u.%u\r", c1, c2, c3, c4);
                break;
            }

            if (vDEBUG)
                printf("T%uS%u\r", c2, c3);

            *pTrack = c2;
            *pSector = c3;

            for (i = 0; i < 8; i++)
            {
				SPIN();
                checksum[0] ^= SPI(0);
                checksum[1] ^= SPI(0);
				SPIN();
                checksum[2] ^= SPI(0);
                checksum[3] ^= SPI(0);
            }

            checksum[0] &= 0x55;
            checksum[1] &= 0x55;
            checksum[2] &= 0x55;
            checksum[3] &= 0x55;

			SPIN();

            c1 = ((SPI(0)) & 0x55) << 1;
            c2 = ((SPI(0)) & 0x55) << 1;
			SPIN();
            c3 = ((SPI(0)) & 0x55) << 1;
            c4 = ((SPI(0)) & 0x55) << 1;

			SPIN();

            c1 |= (SPI(0)) & 0x55;
            c2 |= (SPI(0)) & 0x55;
			SPIN();
            c3 |= (SPI(0)) & 0x55;
            c4 |= (SPI(0)) & 0x55;

            if (c1 != checksum[0] || c2 != checksum[1] || c3 != checksum[2] || c4 != checksum[3])
            {
                Error = 26;
                break;
            }

            DisableFpga();
            return 1;
        }
        else if ((c3 & 0x80) == 0) // not enough data for header and write dma is not active
        {
            Error = 20;
            break;
        }

        DisableFpga();
    }

    DisableFpga();
    return 0;

  DEBUG_FUNC_OUT(DEBUG_F_FDD | DEBUG_L2);
}


unsigned char GetData(void)
{
  DEBUG_FUNC_IN(DEBUG_F_FDD | DEBUG_L2);

    unsigned char c, c1, c2, c3, c4;
    unsigned char i;
    unsigned char *p;
    unsigned short n;
    unsigned char checksum[4];

    Error = 0;
    while (1)
    {
        EnableFpga();
        c1 = SPI(0); // write request signal
        c2 = SPI(0); // track number (cylinder & head)
        if (!(c1 & CMD_WRTRK))
            break;
        SPI(0); // disk sync high byte
        SPI(0); // disk sync low byte
        c3 = SPI(0); // msb of mfm words to transfer
        c4 = SPI(0); // lsb of mfm words to transfer

        n = ((c3 & 0x3F) << 8) + c4;

        if (n >= 0x204)
        {
			SPIN();

            c1 = ((SPI(0)) & 0x55) << 1;
            c2 = ((SPI(0)) & 0x55) << 1;
			SPIN();
            c3 = ((SPI(0)) & 0x55) << 1;
            c4 = ((SPI(0)) & 0x55) << 1;

			SPIN();

            c1 |= (SPI(0)) & 0x55;
            c2 |= (SPI(0)) & 0x55;
			SPIN();
            c3 |= (SPI(0)) & 0x55;
            c4 |= (SPI(0)) & 0x55;

            checksum[0] = 0;
            checksum[1] = 0;
            checksum[2] = 0;
            checksum[3] = 0;

            // odd bits of data field
            i = 128;
            p = sector_buffer;
            do
            {
				SPIN();
                c = SPI(0);
                checksum[0] ^= c;
                *p++ = (c & 0x55) << 1;
                c = SPI(0);
                checksum[1] ^= c;
                *p++ = (c & 0x55) << 1;
				SPIN();
                c = SPI(0);
                checksum[2] ^= c;
                *p++ = (c & 0x55) << 1;
                c = SPI(0);
                checksum[3] ^= c;
                *p++ = (c & 0x55) << 1;
            }
            while (--i);

            // even bits of data field
            i = 128;
            p = sector_buffer;
            do
            {
				SPIN();
                c = SPI(0);
                checksum[0] ^= c;
                *p++ |= c & 0x55;
                c = SPI(0);
                checksum[1] ^= c;
                *p++ |= c & 0x55;
				SPIN();
                c = SPI(0);
                checksum[2] ^= c;
                *p++ |= c & 0x55;
                c = SPI(0);
                checksum[3] ^= c;
                *p++ |= c & 0x55;
            }
            while (--i);

            checksum[0] &= 0x55;
            checksum[1] &= 0x55;
            checksum[2] &= 0x55;
            checksum[3] &= 0x55;

            if (c1 != checksum[0] || c2 != checksum[1] || c3 != checksum[2] || c4 != checksum[3])
            {
                Error = 29;
                break;
            }

            DisableFpga();
            return 1;
        }
        else if ((c3 & 0x80) == 0) // not enough data in fifo and write dma is not active
        {
            Error = 28;
            break;
        }

        DisableFpga();
    }
    DisableFpga();
    return 0;

  DEBUG_FUNC_OUT(DEBUG_F_FDD | DEBUG_L2);
}


void WriteTrack(adfTYPE *drive)
{
  DEBUG_FUNC_IN(DEBUG_F_FDD | DEBUG_L2);

    unsigned char sector;
    unsigned char Track;
    unsigned char Sector;

    // setting file pointer to begining of current track
    file.cluster = drive->cache[drive->track];
    file.sector = drive->track * 11;
    sector = 0;

    drive->track_prev = drive->track + 1; // just to force next read from the start of current track

    if (vDEBUG)
        printf("*%u:\r", drive->track);

    while (FindSync(drive))
    {
        if (GetHeader(&Track, &Sector))
        {
            if (Track == drive->track)
            {
                while (sector != Sector)
                {
                    if (sector < Sector)
                    {
                        FileNextSector(&file);
                        sector++;
                    }
                    else
                    {
                        file.cluster = drive->cache[drive->track];
                        file.sector = drive->track * 11;
                        sector = 0;
                    }
                }

                if (GetData())
                {
                    if (drive->status & DSK_WRITABLE)
                        FileWrite(&file, sector_buffer);
                    else
                    {
                        Error = 30;
                        printf("Write attempt to protected disk!\r");
                    }
                }
            }
            else
                Error = 27; //track number reported in sector header is not the same as current drive track
        }
        if (Error)
        {
            printf("WriteTrack: error %u\r", Error);
            ErrorMessage("  WriteTrack", Error);
        }
    }

  DEBUG_FUNC_OUT(DEBUG_F_FDD | DEBUG_L2);
}


void UpdateDriveStatus(void)
{
  DEBUG_FUNC_IN(DEBUG_F_FDD | DEBUG_L2);

    EnableFpga();
    SPI(0x10);
    SPI(df[0].status | (df[1].status << 1) | (df[2].status << 2) | (df[3].status << 3));
    DisableFpga();

  DEBUG_FUNC_OUT(DEBUG_F_FDD | DEBUG_L2);
}


void HandleFDD(unsigned char c1, unsigned char c2)
{
  DEBUG_FUNC_IN(DEBUG_F_FDD | DEBUG_L3);

    unsigned char sel;
    drives = (c1 >> 4) & 0x03; // number of active floppy drives

    if (c1 & CMD_RDTRK)
    {
        DISKLED_ON;
        sel = (c1 >> 6) & 0x03;
        df[sel].track = c2;
        ReadTrack(&df[sel]);
        DISKLED_OFF;
    }
    else if (c1 & CMD_WRTRK)
    {
        DISKLED_ON;
        sel = (c1 >> 6) & 0x03;
        df[sel].track = c2;
        WriteTrack(&df[sel]);
        DISKLED_OFF;
    }

  DEBUG_FUNC_OUT(DEBUG_F_FDD | DEBUG_L3);
}

