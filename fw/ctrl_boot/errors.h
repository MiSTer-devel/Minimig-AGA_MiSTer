////////////////////////////////////////////////////////////////////////////////
// errors.h                                                                   //
// error defines & error handling funcs                                       //
//                                                                            //
// Copyright 2012-     Christian Vogelgsang, A.M. Robinson, Rok Krajnc        //
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
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

#ifndef __ERRORS_H__
#define __ERRORS_H__

#define ERROR_NONE 0
#define ERROR_FILE_NOT_FOUND 1
#define ERROR_INVALID_DATA 2
#define ERROR_UPDATE_FAILED 3

extern unsigned char Error;

void FatalError(unsigned long error);

#endif // __ERRORS_H__

