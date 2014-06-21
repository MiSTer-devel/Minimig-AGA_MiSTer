/*
 * Include file for the NewMouse standard way of handling wheeled mice.
 * 
 * Copyright (c) 1999 by Alessandro Zummo <azummo@ita.flashnet.it> . All Rights Reserved.
*/

#ifndef NEWMOUSE_H
#define NEWMOUSE_H

#define NEWMOUSE_VERSION	1

#define IECLASS_NEWMOUSE	(0x16)  /* IECLASS_MAX + 1 as of V40 */ 

/* These are issued both under IECLASS_NEWMOUSE and IECLASS_RAWKEY 	*/ 
/* by the NewMouse driver											*/

#define NM_WHEEL_UP			(0x7A)
#define NM_WHEEL_DOWN		(0x7B)
#define NM_WHEEL_LEFT		(0x7C)
#define NM_WHEEL_RIGHT		(0x7D)

#define NM_BUTTON_FOURTH	(0x7E)


#endif /* NEWMOUSE_H */

