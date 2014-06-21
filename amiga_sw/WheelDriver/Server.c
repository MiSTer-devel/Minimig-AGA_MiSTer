
#include <exec/types.h>

#include "WheelDriver.h"


extern void AddLongAtomic(long *a,long v);


void WheelDriver_Server(struct WheelDriverContext *wdc)
{
  static long old_wheel = 0;
  long new_wheel = 0;
  long sum;
  int overflow = 0;


	/* Read wheel events, middle and fourth buttons from hardware here. */
  new_wheel = *((volatile long *)(0xdff1f0));
  sum = old_wheel + new_wheel;
  if (new_wheel < 0 ? sum > old_wheel : sum < old_wheel) overflow = 1;

  if (new_wheel > old_wheel) AddLongAtomic(&wdc->WheelCounter,-1);
  if (new_wheel < old_wheel) AddLongAtomic(&wdc->WheelCounter,1);

  old_wheel = new_wheel;

/*
  if( middle button is pressed )
    wdc->ButtonStatus|=1;	should atomic; will be cleared with an "and" in the main task.
  if( fourth button is pressed )
    wdc->ButtonStatus|=2;

  if(  scroll up - or is it down?  I can't remember now!  )
    AddLongAtomic(&wdc->WheelCounter,1);
  if(  scroll the other way! )
    AddLongAtomic(&wdc->WheelCounter,-1);
*/

  if((wdc->ButtonStatus!=wdc->PreviousButtons)||(wdc->WheelCounter)) /* Is there anything we need to act upon? */
    Signal(wdc->SigTask,wdc->Signals);
}

