#include <stdio.h>
#include <stdlib.h>

#include <exec/types.h>
#include <exec/ports.h>
#include <exec/memory.h>
#include <libraries/commodities.h>
#include <clib/exec_protos.h>
#include <clib/commodities_protos.h>
#include <clib/alib_protos.h>

#include "Cx.h"

BOOL HandleCxMessages(struct CxContext *cx,unsigned long signals);
void DisposeCxContext(struct CxContext *cx);
BOOL Cx_SetHotKey(struct CxContext *cx,char *hotkey);
BOOL Cx_SetCustomRoutine(struct CxContext *cx,void (*rout)(CxMsg *msg,CxObj *obj));


BOOL Cx_SetHotKey(struct CxContext *cx,char *hotkey)
{
  if(cx->HotKey)
    DeleteCxObjAll(cx->HotKey);
  if(cx->HotKey=HotKey(hotkey,cx->Port,CXCMD_APPEAR))
    AttachCxObj(cx->Broker,cx->HotKey);
  if(cx->HotKey)
    return(TRUE);
  else
    return(FALSE);
}


BOOL Cx_SetCustomRoutine(struct CxContext *cx,void (*rout)(CxMsg *msg,CxObj *obj))
{
  if(cx->CustomObject)
    DeleteCxObjAll(cx->CustomObject);
  if(cx->CustomObject=CxCustom(rout,0))
    AttachCxObj(cx->Broker,cx->CustomObject);
  if(cx->CustomObject)
    return(TRUE);
  else
    return(FALSE);
}


BOOL HandleCxMessages(struct CxContext *cx,unsigned long signals)
{
  struct Message *msg;
  long id;
  BOOL result=TRUE;
  if(cx)
  {
    if(signals&cx->Signals)
    {
      while(msg=GetMsg(cx->Port))
      {
        id=CxMsgID((CxMsg *)msg);
        ReplyMsg(msg);
        switch(id)
        {
          case CXCMD_DISABLE:
            if(cx->DisableCallback)
            {
              cx->DisableCallback(cx->UserData);
            }
            else
            {
              if(cx->CustomObject)
                ActivateCxObj(cx->CustomObject,FALSE);
            }
            break;
          case CXCMD_ENABLE:
            if(cx->EnableCallback)
            {
              cx->EnableCallback(cx->UserData);
            }
            else
            {
              if(cx->CustomObject)
                ActivateCxObj(cx->CustomObject,TRUE);
            }
            break;
          case CXCMD_UNIQUE:
          case CXCMD_APPEAR:
            if(cx->ShowCallback)
              cx->ShowCallback(cx->UserData);
            break;
          case CXCMD_DISAPPEAR:
            if(cx->HideCallback)
              cx->HideCallback(cx->UserData);
            break;
          case CXCMD_KILL:
            result=FALSE;
            break;
        }
      }
    }
  }
  return(result);
}


struct CxContext *CxContext_Create(char *name,char *title,char *descr)
{
  struct CxContext *cx;
  char *hotkeystring;
  CxObj *hotkeyobj;

  struct NewBroker MyNewBroker =
  {
    NB_VERSION,
    NULL,
    NULL,
    NULL,
    NBU_UNIQUE|NBU_NOTIFY,
    0,
    0,
    NULL
  };

  MyNewBroker.nb_Name=name;
  MyNewBroker.nb_Title=title;
  MyNewBroker.nb_Descr=descr;

  if(!(cx=malloc(sizeof(struct CxContext))))
    return(NULL);
  memset(cx,0,sizeof(struct CxContext));

  cx->Dispose=DisposeCxContext;
  cx->Handle=HandleCxMessages;
  cx->SetHotKey=Cx_SetHotKey;
  cx->SetCustom=Cx_SetCustomRoutine;

  cx->HotKey=NULL;
  cx->CustomObject=NULL;

  cx->UserData=NULL;
  cx->EnableCallback=NULL;
  cx->DisableCallback=NULL;
  cx->ShowCallback=NULL;
  cx->HideCallback=NULL;

  if(!(cx->Port=CreateMsgPort()))
  {
    cx->Dispose(cx);
    return(NULL);
  }
  cx->Signals=(1<<cx->Port->mp_SigBit);
  MyNewBroker.nb_Port=cx->Port;

  if(!(cx->Broker=CxBroker(&MyNewBroker,NULL)))
  {
    cx->Dispose(cx);
    return(NULL);
  }

  ActivateCxObj(cx->Broker,TRUE);

  return(cx);
}


void DisposeCxContext(struct CxContext *cx)
{
  if(cx)
  {
    if(cx->Broker)
    {
      DeleteCxObjAll(cx->Broker);
      cx->Broker=NULL;
    }
    if(cx->Port)
    {
      DeleteMsgPort(cx->Port);
      cx->Port=NULL;
    }
    free(cx);
  }
}

