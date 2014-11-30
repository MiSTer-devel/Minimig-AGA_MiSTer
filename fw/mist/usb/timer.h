// interface between USB timer and minimig timer

#ifndef TIMER_H
#define TIMER_H

#include <inttypes.h>
typedef uint32_t msec_t;

void timer_init();
msec_t timer_get_msec();
void timer_delay_msec(msec_t t);

#endif // TIMER_H
