////////////////////////////////////////////////////////////////////////////////
// debug.h                                                                    //
// Debug defines & functions                                                  //
//                                                                            //
// Copyright 2013, Rok Krajnc                                                 //
//                                                                            //
// This file is part of Minimig                                               //
//                                                                            //
// Minimig is free software; you can redistribute it and/or modify            //
// it under the terms of the GNU General Public License as published by       //
// the Free Software Foundation; either version 2 of the License, or          //
// (at your option) any later version.                                        //
//                                                                            //
// Minimig is distributed in the hope that it will be useful,                 //
// but WITHOUT ANY WARRANTY; without even the implied warranty of             //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              //
// GNU General Public License for more details.                               //
//                                                                            //
// You should have received a copy of the GNU General Public License          //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
// Changelog                                                                  //
//                                                                            //
// 2013-12-17 - rok.krajnc@gmail.com                                          //
// Moved debug stuff from hardware.h and expanded the debug functions         //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


#ifndef __DEBUG_H__
#define __DEBUG_H__


//// debug levels and per-file debug ////
// levels
#define DEBUG_L0            0x00000001   // for init functions, or one-time functions
#define DEBUG_L1            0x00000002   // for less used functions
#define DEBUG_L2            0x00000004   // for frequently-called functions (LOTS of debug output!)
#define DEBUG_L3            0x00000008   // don't even think about enabling this! :) system functions, or very tight loop functions

// files
#define DEBUG_F_MAIN        0x00010000
#define DEBUG_F_MMC         0x00020000
#define DEBUG_F_FPGA        0x00040000
#define DEBUG_F_FAT         0x00080000
#define DEBUG_F_CONFIG      0x00100000
#define DEBUG_F_MENU        0x00200000
#define DEBUG_F_OSD         0x00400000
#define DEBUG_F_HARDWARE    0x00800000
#define DEBUG_F_FDD         0x01000000
#define DEBUG_F_HDD         0x02000000
#define DEBUG_F_BOOT_PRINT  0x04000000
#define DEBUG_F_BOOT_LOGO   0x08000000
#define DEBUG_F_PRINTF      0x10000000
#define DEBUG_F_RAFILE      0x20000000
#define DEBUG_F_SWAP        0x40000000


//// debug enable ////
//#define DEBUG
#define DEBUG_LMASK (DEBUG_L0 | DEBUG_L1)
#define DEBUG_FMASK 0xffff0000


//// debug print functions ////
#ifdef DEBUG
#define DBGPRINT(...)       printf(__VA_ARGS__)
#else
#define DBGPRINT(...)       ;
#endif

#define STR(x)              #x
#define XSTR(x)             STR(x)

#define DEBUG_FUNC_IN(m)    if(((m)&(DEBUG_LMASK)) && ((m)&(DEBUG_FMASK))) { DBGPRINT("* DBG : FUNC IN  : %s(), file " __FILE__ ", line " XSTR(__LINE__) "\r", __FUNCTION__) }
#define DEBUG_FUNC_OUT(m)   if(((m)&(DEBUG_LMASK)) && ((m)&(DEBUG_FMASK))) { DBGPRINT("* DBG : FUNC OUT : %s()\r", __FUNCTION__) }
#define DEBUG_MSG(m,x)      if(((m)&(DEBUG_LMASK)) && ((m)&(DEBUG_FMASK))) { DBGPRINT("* DBG : " x "\r") }


#endif // __DEBUG_H__

