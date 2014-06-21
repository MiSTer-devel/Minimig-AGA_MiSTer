#ifndef CXCONTEXT_H
#define CXCONTEXT_H

#include <libraries/commodities.h>

struct CxContext
{
  void (*Dispose)(struct CxContext *cx);
  BOOL (*Handle)(struct CxContext *cx,unsigned long signals);
  BOOL (*SetHotKey)(struct CxContext *cx,char *hotkey);
  BOOL (*SetCustom)(struct CxContext *cx,void (*rout)(CxMsg *msg,CxObj *obj));
  void (*ShowCallback)(void *userdata);
  void (*HideCallback)(void *userdata);
  void (*EnableCallback)(void *userdata);
  void (*DisableCallback)(void *userdata);
  void *UserData; /* Useful from within Callback functions */
  struct MsgPort *Port;
  void *Broker;
  void *CustomObject;
  void *HotKey;
  unsigned long Signals;
};

struct CxContext *CxContext_Create(char *name,char *title,char *descr);

#endif
