#include <stdio.h>
#include <stdlib.h>

#include <exec/types.h>
#include <exec/io.h>
#include <exec/interrupts.h>
#include <hardware/intbits.h>
#include <resources/potgo.h>

#include <devices/input.h>
#include <devices/inputevent.h>
#include <intuition/newmouse.h>
#include <intuition/intuitionbase.h>

#include <clib/exec_protos.h>
#include <clib/dos_protos.h>
#include <clib/potgo_protos.h>
#include <clib/input_protos.h>

#include "WheelDriver.h"

void WheelDriver_Dispose(struct WheelDriverContext *wdc);
BOOL WheelDriver_Handle(struct WheelDriverContext *wdc,unsigned long Signals);
void WheelDriver_Enable(struct WheelDriverContext *wdc);
void WheelDriver_Disable(struct WheelDriverContext *wdc);

extern void *WheelDriver_ServerStub;
void *InputBase;

extern struct IntuitionBase *IntuitionBase;

void WheelDriver_Enable(struct WheelDriverContext *wdc)
{
  if(wdc->Active==FALSE)
  {
    wdc->Interrupt.is_Node.ln_Name="WheelMouse Driver";
    wdc->Interrupt.is_Node.ln_Type=NT_INTERRUPT;
    wdc->Interrupt.is_Node.ln_Pri=-128;
    wdc->Interrupt.is_Code=wdc->Server;
    wdc->Interrupt.is_Data=wdc;
    AddIntServer(INTB_VERTB,&wdc->Interrupt);
    wdc->Active=TRUE;
  }
}


void WheelDriver_Disable(struct WheelDriverContext *wdc)
{
  if(wdc->Active)
  {
    RemIntServer(INTB_VERTB,&wdc->Interrupt);
    wdc->Active=FALSE;
  }
}


struct WheelDriverContext *WheelDriver_Create()
{
  struct WheelDriverContext *wdc;
  if(!(wdc=malloc(sizeof(struct WheelDriverContext))))
    return(NULL);
  memset(wdc,0,sizeof(struct WheelDriverContext));
  wdc->Dispose=WheelDriver_Dispose;
  wdc->Handle=WheelDriver_Handle;
  wdc->Enable=WheelDriver_Enable;
  wdc->Disable=WheelDriver_Disable;

  wdc->Server=&WheelDriver_ServerStub;  /* Just an Asm stub */

  wdc->Active=FALSE;
  wdc->SigTask=FindTask(NULL);
  if((wdc->SigBit=AllocSignal(-1))==-1)
  {
    wdc->Dispose(wdc);
    return(NULL);
  }
  wdc->Signals=1<<wdc->SigBit;

  if(!(wdc->Port=CreateMsgPort()))
  {
    wdc->Dispose(wdc);
    return(NULL);
  }

  if(!(wdc->IOReq=(struct IOStdReq *)CreateIORequest(wdc->Port,sizeof(struct IOStdReq))))
  {
    wdc->Dispose(wdc);
    return(NULL);
  }

  if(OpenDevice("input.device",0,(struct IORequest *)wdc->IOReq,0))
  {
    DeleteIORequest((struct IORequest *)wdc->IOReq);
    wdc->IOReq=NULL;
    wdc->Dispose(wdc);
  }
  InputBase=wdc->IOReq->io_Device;

  wdc->IOReq->io_Command=IND_WRITEEVENT;
  wdc->IOReq->io_Length=sizeof(struct InputEvent);
  wdc->IOReq->io_Data=&wdc->Event;

  return(wdc);
}


void WheelDriver_Dispose(struct WheelDriverContext *wdc)
{
  if(wdc)
  {
    if(wdc->Active)
      wdc->Disable(wdc);

    if(wdc->IOReq)
    {
      CloseDevice((struct IORequest *)wdc->IOReq);
      DeleteIORequest((struct IORequest *)wdc->IOReq);
      wdc->IOReq=NULL;
    }
    if(wdc->Port)
      DeleteMsgPort(wdc->Port);
    wdc->Port=NULL;

    if(wdc->SigBit>-1)
      FreeSignal(wdc->SigBit);
    wdc->SigBit=-1;

    free(wdc);
  }
}


void AddLongAtomic(long *a,long v)
{
  *a+=v;  /* Make sure your compiler generates a single instruction
             for this operation, i.e. add.l d0,(a0), and not
             move.l (a0),d1   add.l d0,d1   move.l d1,(a0) */
}


BOOL WheelDriver_Handle(struct WheelDriverContext *wdc,unsigned long Signals)
{
  if(Signals&wdc->Signals)
  {
    BOOL cont=TRUE;
    while(cont)
    {
      cont=FALSE;
      if(wdc->ButtonStatus!=wdc->PreviousButtons)
      {
        cont=TRUE;
        if((wdc->ButtonStatus&1)&&(!(wdc->PreviousButtons&1)))
        {
          wdc->Event.ie_Class=IECLASS_RAWMOUSE;
          wdc->Event.ie_Code=IECODE_MBUTTON;
          wdc->Event.ie_Qualifier=PeekQualifier();
          DoIO((struct IORequest *)wdc->IOReq);
        }
        if((!(wdc->ButtonStatus&1))&&(wdc->PreviousButtons&1))
        {
          wdc->Event.ie_Class=IECLASS_RAWMOUSE;
          wdc->Event.ie_Code=IECODE_UP_PREFIX|IECODE_MBUTTON;
          wdc->Event.ie_Qualifier=PeekQualifier();
          DoIO((struct IORequest *)wdc->IOReq);
        }
        if((wdc->ButtonStatus&2)&&(!(wdc->PreviousButtons&2)))
        {
          wdc->Event.ie_Class=IECLASS_RAWKEY;
          wdc->Event.ie_Code=NM_BUTTON_FOURTH;
          wdc->Event.ie_Qualifier=PeekQualifier();
          DoIO((struct IORequest *)wdc->IOReq);
        }
        if((!(wdc->ButtonStatus&2))&&(wdc->PreviousButtons&2))
        {
          wdc->Event.ie_Class=IECLASS_RAWKEY;
          wdc->Event.ie_Code=IECODE_UP_PREFIX|NM_BUTTON_FOURTH;
          wdc->Event.ie_Qualifier=PeekQualifier();
          DoIO((struct IORequest *)wdc->IOReq);
        }
        wdc->PreviousButtons=wdc->ButtonStatus;
      }
      if(wdc->WheelCounter)
      {
        cont=TRUE;
        if(wdc->WheelCounter<0)
        {
          AddLongAtomic(&wdc->WheelCounter,1);
          wdc->Event.ie_Class=IECLASS_RAWKEY;
          wdc->Event.ie_Code=NM_WHEEL_DOWN;
          wdc->Event.ie_Qualifier=PeekQualifier();
          DoIO((struct IORequest *)wdc->IOReq);
          wdc->Event.ie_Class=IECLASS_NEWMOUSE;
          wdc->Event.ie_Code=NM_WHEEL_DOWN;
          wdc->Event.ie_Qualifier=PeekQualifier();
          DoIO((struct IORequest *)wdc->IOReq);
        }
        if(wdc->WheelCounter>0)
        {
          AddLongAtomic(&wdc->WheelCounter,-1);
          wdc->Event.ie_Class=IECLASS_RAWKEY;
          wdc->Event.ie_Code=NM_WHEEL_UP;
          wdc->Event.ie_Qualifier=PeekQualifier();
          DoIO((struct IORequest *)wdc->IOReq);
          wdc->Event.ie_Class=IECLASS_NEWMOUSE;
          wdc->Event.ie_Code=NM_WHEEL_UP;
          wdc->Event.ie_Qualifier=PeekQualifier();
          DoIO((struct IORequest *)wdc->IOReq);
        }
      }
    }
  }
  return(TRUE);
}


