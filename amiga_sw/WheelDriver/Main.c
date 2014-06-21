#include <stdio.h>
#include <stdlib.h>

#include <exec/types.h>
#include <dos/dos.h>

#include <clib/exec_protos.h>
#include <clib/dos_protos.h>

#include "WheelDriver.h"
#include "Cx.h"

void *PotgoBase,*CxBase,*IntuitionBase;

void _chkabort(){}

char *Main_Setup();
void Main_Cleanup();

int main()
{
  char *error;
  int counter=0;
  struct WheelDriverContext *MyWDC;
  struct CxContext *MyCx;

  if(error=Main_Setup())
  {
    printf("Error: %s\n",error);
    return(10);
  }

  if(MyWDC=WheelDriver_Create())
  {
    BOOL cont=TRUE;
    printf("Everything setup OK!\n");

    if(MyCx=CxContext_Create("WheelDriver","Driver for Wheel on mouse-port hack","© 2000 - Alastair M. Robinson"))
    {
      MyCx->UserData=MyWDC;
      MyCx->EnableCallback=(void (*)(void *))MyWDC->Enable;
      MyCx->DisableCallback=(void (*)(void *))MyWDC->Disable;
    }

    MyWDC->Enable(MyWDC);

    SetTaskPri(FindTask(NULL),19);

    while(cont)
    {
      unsigned long sigs;

      sigs=MyWDC->Signals|SIGBREAKF_CTRL_C;
      if(MyCx)
        sigs|=MyCx->Signals;

      sigs=Wait(sigs);

      if(MyCx);
        cont&=MyCx->Handle(MyCx,sigs);
      cont&=MyWDC->Handle(MyWDC,sigs);

      if(sigs&SIGBREAKF_CTRL_C)
        cont=FALSE;
    }

    if(MyCx)
      MyCx->Dispose(MyCx);

    MyWDC->Disable(MyWDC);

    MyWDC->Dispose(MyWDC);
  }
  Main_Cleanup();

  return(0);
}


char *Main_Setup()
{
  if(!(PotgoBase=OpenResource("potgo.resource")))
    return("Can't open potgo.resource");
  if(!(CxBase=OpenLibrary("commodities.library",0)))
    return("Can't open commodities.library");
  if(!(IntuitionBase=OpenLibrary("intuition.library",0)))
    return("Can't open intuition.library");
  return(NULL);
}


void Main_Cleanup()
{
  if(IntuitionBase)
    CloseLibrary(IntuitionBase);
  IntuitionBase=NULL;
  if(CxBase)
    CloseLibrary(CxBase);
  CxBase=NULL;
}

