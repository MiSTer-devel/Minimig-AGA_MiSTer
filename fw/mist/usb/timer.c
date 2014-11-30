#include "timer.h"
#include "AT91SAM7S256.h"

// this is a 32 bit counter which overflows after 2^32 milliseconds
// -> after 46 days

void timer_init() {
  // reprogram the realtime timer to run at 1Khz
  AT91C_BASE_RTTC->RTTC_RTMR = 0x8000 / 1000;
}

msec_t timer_get_msec() {
  return AT91C_BASE_RTTC->RTTC_RTVR;
}

void timer_delay_msec(msec_t t) {
  msec_t now = AT91C_BASE_RTTC->RTTC_RTVR;

  while(AT91C_BASE_RTTC->RTTC_RTVR - now < t);
}
