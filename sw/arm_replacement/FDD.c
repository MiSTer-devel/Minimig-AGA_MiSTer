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

//#include "stdio.h"
//#include "string.h"
#include "errors.h"
#include "hardware.h"
#include "FAT.h"
#include "FDD.h"

unsigned char DEBUG = 0;

unsigned char drives = 0; // number of active drives reported by FPGA (may change only during reset)
adfTYPE *pdfx; // drive select pointer
adfTYPE df[4]; // drive 0 information structure

extern fileTYPE file;

void SectorGapToFpga(void)
{
    unsigned char i = 244;
    do
    {
        SPI(0xAA);
        SPI(0xAA);
    }
    while (--i);
}

void SectorHeaderToFpga(unsigned char n, unsigned char dsksynch, unsigned char dsksyncl)
{
    if (n)
    {
        SPI(0xAA);
        SPI(0xAA);

        if (--n)
        {
            SPI(0xAA);
            SPI(0xAA);

            if (--n)
            {
                SPI(dsksynch);
                SPI(dsksyncl);
            }
        }
    }
}

// sends the data in the sector buffer to the FPGA, translated into an Amiga floppy format sector
// note that we do not insert clock bits because they will be stripped by the Amiga software anyway
unsigned short SectorToFpga(unsigned char sector, unsigned char track, unsigned char dsksynch, unsigned char dsksyncl)
{
    unsigned char c, i;
    unsigned char csum[4];
    unsigned char *p;
    unsigned char c3, c4;

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

    // clear header checksum
    csum[0] = 0;
    csum[1] = 0;
    csum[2] = 0;
    csum[3] = 0;

    // odd bits of header
    c = 0x55;
    csum[0] ^= c;
    SPI(c);
    c = (track >> 1) & 0x55;
    csum[1] ^= c;
    SPI(c);
    c = (sector >> 1) & 0x55;
    csum[2] ^= c;
    SPI(c);
    c = ((11 - sector) >> 1) & 0x55;
    csum[3] ^= c;
    SPI(c);

    // even bits of header
    c = 0x55;
    csum[0] ^= c;
    SPI(c);
    c = track & 0x55;
    csum[1] ^= c;
    SPI(c);
    c = sector & 0x55;
    csum[2] ^= c;
    SPI(c);
    c = (11 - sector) & 0x55;
    csum[3] ^= c;
    SPI(c);

    // sector label and reserved area (changes nothing to checksum)
    for (i = 0; i < 32; i++)
        SPI(0x55);

    // checksum over header
    SPI((csum[0] >> 1) | 0xAA);
    SPI((csum[1] >> 1) | 0xAA);
    SPI((csum[2] >> 1) | 0xAA);
    SPI((csum[3] >> 1) | 0xAA);
    SPI(csum[0] | 0xAA);
    SPI(csum[1] | 0xAA);
    SPI(csum[2] | 0xAA);
    SPI(csum[3] | 0xAA);

    // calculate data checksum
    csum[0] = 0;
    csum[1] = 0;
    csum[2] = 0;
    csum[3] = 0;
    i = 128;
    p = sector_buffer;
    do
    {
        c = *p++;
        csum[0] ^= c >> 1;
        csum[0] ^= c;
        c = *p++;
        csum[1] ^= c >> 1;
        csum[1] ^= c;
        c = *p++;
        csum[2] ^= c >> 1;
        csum[2] ^= c;
        c = *p++;
        csum[3] ^= c >> 1;
        csum[3] ^= c;
    }
    while (--i);

    csum[0] &= 0x55;
    csum[1] &= 0x55;
    csum[2] &= 0x55;
    csum[3] &= 0x55;

    // checksum over data
    SPI((csum[0] >> 1) | 0xAA);
    SPI((csum[1] >> 1) | 0xAA);
    SPI((csum[2] >> 1) | 0xAA);
    SPI((csum[3] >> 1) | 0xAA);
    SPI(csum[0] | 0xAA);
    SPI(csum[1] | 0xAA);
    SPI(csum[2] | 0xAA);
    SPI(csum[3] | 0xAA);

    // odd bits of data field
    i = 128;
    p = sector_buffer;
    do
    {
        c = *p++;
        c >>= 1;
        c |= 0xAA;
        SPI(c);

        c = *p++;
        c >>= 1;
        c |= 0xAA;
        SPI(c);

        c = *p++;
        c >>= 1;
        c |= 0xAA;
        SPI(c);

        c = *p++;
        c >>= 1;
        c |= 0xAA;
        SPI(c);
    }
    while (--i);

    // even bits of data field
    i = 128;
    p = sector_buffer;
    do
    {
        c = *p++;
        SPI(c | 0xAA);
        c = *p++;
        SPI(c | 0xAA);
        c = *p++;
        c3 = SPI(c | 0xAA);
        c = *p++;
        c4 = SPI(c | 0xAA);
    }
    while (--i);

    return((c3 << 8) | c4);
}

// read a track from disk
void ReadTrack(adfTYPE *drive)
{ // track number is updated in drive struct before calling this function

    unsigned char sector;
    unsigned char c1, c2, c3, c4;
    unsigned char dsksynch, dsksyncl;
    unsigned short n;

    // display track number: cylinder & head
    if (DEBUG)
        printf("*%u:", drive->track);

    if (drive->track != drive->track_prev)
    { // track step or track 0, start at beginning of track
        drive->track_prev = drive->track;
        sector = 0;
        file.cluster = drive->cache[drive->track];
        file.sector = drive->track * 11;
        drive->sector_offset = sector;
        drive->cluster_offset = file.cluster;
    }
    else
    { // same track, start at next sector in track
        sector = drive->sector_offset;
        file.cluster = drive->cluster_offset;
        file.sector = (drive->track * 11) + sector;
    }

    EnableFpga();
    c1 = SPI(0); //read request signal
    c2 = SPI(0); //track number (cylinder & head)
    dsksynch = SPI(0); //disk sync high byte
    dsksyncl = SPI(0); //disk sync low byte
    c3 = 0x3F & SPI(0); //msb of mfm words to transfer
    c4 = SPI(0); //lsb of mfm words to transfer
    DisableFpga();

    if (DEBUG)
        printf("(%u)[%02X%02X]:", c1>>6, dsksynch, dsksyncl);

    while (1)
    {
        FileRead(&file);

        EnableFpga();

        // check if FPGA is still asking for data
        c1 = SPI(0); // read request signal
        c2 = SPI(0); // track number (cylinder & head)
        dsksynch = SPI(0); // disk sync high byte
        dsksyncl = SPI(0); // disk sync low byte
        c3 = SPI(0); // msb of mfm words to transfer
        c4 = SPI(0); // lsb of mfm words to transfer

        if ((dsksynch == 0x00 && dsksyncl == 0x00) || (dsksynch == 0x89 && dsksyncl == 0x14)) // workaround for Copy Lock in Wiz'n'Liz (might brake other games)
        { // KS 1.3 doesn't write dsksync register after reset
            dsksynch = 0x44;
            dsksyncl = 0x89;
        }
        // Wiz'n'Liz (Copy Lock): $8914
        // Prince of Persia: $4891
        // Commando: $A245

        if (DEBUG)
            printf("%X:%02X%02X", sector, c3, c4);

        c3 &= 0x3F;

        // some loaders stop dma if sector header isn't what they expect
        // because we don't check dma transfer count after sending a word
        // the track can be changed while we are sending the rest of the previous sector
        // in this case let's start transfer from the beginning
        if (c2 == drive->track)
        {
            // send sector if fpga is still asking for data
        if (c1 & CMD_RDTRK)
        {
            if (c3 == 0 && c4 < 4)
                SectorHeaderToFpga(c4, dsksynch, dsksyncl);
            else
            {
                n = SectorToFpga(sector, drive->track, dsksynch, dsksyncl);

                if (DEBUG) // printing remaining dma count
                    printf("-%04X", n);

                n--;
                c3 = (n >> 8) & 0x3F;
                c4 = (unsigned char)n;

                if (c3 == 0 && c4 < 4)
                {
                    SectorHeaderToFpga(c4, dsksynch, dsksyncl);
                    if (DEBUG)
                        printf("+%X", c4);
                }
                else if (sector == 10)
                {
                    SectorGapToFpga();
                    if (DEBUG)
                        printf("+++");
                }
            }
        }
        }

        // we are done accessing FPGA
        DisableFpga();

        // track has changed
        if (c2 != drive->track)
            break;

        // read dma request
        if (!(c1 & CMD_RDTRK))
            break;

        sector++;
        if (sector < 11)
        {
            FileNextSector(&file);
        }
        else // go to the start of current track
        {
            sector = 0;
            file.cluster = drive->cache[drive->track];
            file.sector = drive->track * 11;
        }

        // remember current sector and cluster
        drive->sector_offset = sector;
        drive->cluster_offset = file.cluster;

        if (DEBUG)
            printf("->");
    }
    if (DEBUG)
        printf(":OK\r");

}

unsigned char FindSync(adfTYPE *drive)
// reads data from fifo till it finds sync word or fifo is empty and dma inactive (so no more data is expected)
{
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
                if (DEBUG)
                    printf("#SYNC:");

                return 1;
            }
        }
        DisableFpga();
    }
    DisableFpga();
    return 0;
}

unsigned char GetHeader(unsigned char *pTrack, unsigned char *pSector)
// this function reads data from fifo till it finds sync word or dma is inactive
{
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

            c = SPI(0);
            checksum[0] = c;
            c1 = (c & 0x55) << 1;
            c = SPI(0);
            checksum[1] = c;
            c2 = (c & 0x55) << 1;
            c = SPI(0);
            checksum[2] = c;
            c3 = (c & 0x55) << 1;
            c = SPI(0);
            checksum[3] = c;
            c4 = (c & 0x55) << 1;

            c = SPI(0);
            checksum[0] ^= c;
            c1 |= c & 0x55;
            c = SPI(0);
            checksum[1] ^= c;
            c2 |= c & 0x55;
            c = SPI(0);
            checksum[2] ^= c;
            c3 |= c & 0x55;
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

            if (DEBUG)
                printf("T%uS%u\r", c2, c3);

            *pTrack = c2;
            *pSector = c3;

            for (i = 0; i < 8; i++)
            {
                checksum[0] ^= SPI(0);
                checksum[1] ^= SPI(0);
                checksum[2] ^= SPI(0);
                checksum[3] ^= SPI(0);
            }

            checksum[0] &= 0x55;
            checksum[1] &= 0x55;
            checksum[2] &= 0x55;
            checksum[3] &= 0x55;

            c1 = ((SPI(0)) & 0x55) << 1;
            c2 = ((SPI(0)) & 0x55) << 1;
            c3 = ((SPI(0)) & 0x55) << 1;
            c4 = ((SPI(0)) & 0x55) << 1;

            c1 |= (SPI(0)) & 0x55;
            c2 |= (SPI(0)) & 0x55;
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
}

unsigned char GetData(void)
{
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
            c1 = ((SPI(0)) & 0x55) << 1;
            c2 = ((SPI(0)) & 0x55) << 1;
            c3 = ((SPI(0)) & 0x55) << 1;
            c4 = ((SPI(0)) & 0x55) << 1;

            c1 |= (SPI(0)) & 0x55;
            c2 |= (SPI(0)) & 0x55;
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
                c = SPI(0);
                checksum[0] ^= c;
                *p++ = (c & 0x55) << 1;
                c = SPI(0);
                checksum[1] ^= c;
                *p++ = (c & 0x55) << 1;
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
                c = SPI(0);
                checksum[0] ^= c;
                *p++ |= c & 0x55;
                c = SPI(0);
                checksum[1] ^= c;
                *p++ |= c & 0x55;
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
}

void WriteTrack(adfTYPE *drive)
{
    unsigned char sector;
    unsigned char Track;
    unsigned char Sector;

    // setting file pointer to begining of current track
    file.cluster = drive->cache[drive->track];
    file.sector = drive->track * 11;
    sector = 0;

    drive->track_prev = drive->track + 1; // just to force next read from the start of current track

    if (DEBUG)
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
                        FileWrite(&file);
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

}

void UpdateDriveStatus(void)
{
    EnableFpga();
    SPI(0x10);
    SPI(df[0].status | (df[1].status << 1) | (df[2].status << 2) | (df[3].status << 3));
    DisableFpga();
}

void HandleFDD(unsigned char c1, unsigned char c2)
{
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
}
