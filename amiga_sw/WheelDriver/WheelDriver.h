#ifndef WHEELDRIVER_H
#define WHEELDRIVER_H

#include <exec/interrupts.h>
#include <exec/io.h>
#include <devices/inputevent.h>

struct WheelDriverContext
{
  void (*Dispose)(struct WheelDriverContext *wdc);
  BOOL (*Handle)(struct WheelDriverContext *wdc,unsigned long Signals);
  void (*Enable)(struct WheelDriverContext *wdc);
  void (*Disable)(struct WheelDriverContext *wdc);
  void *Server;
  BOOL Active;
  long SigBit;
  long Signals;
  struct Task *SigTask;
  struct MsgPort *Port;
  long WheelCounter;
  long ButtonStatus;
  long PreviousButtons;
  struct IOStdReq *IOReq;
  struct InputEvent Event;
  struct Interrupt Interrupt;
};

struct WheelDriverContext *WheelDriver_Create();

#endif

