// interface between USB spi and minimig spi

#ifndef SPI_H
#define SPI_H

#include "AT91SAM7S256.h"
#include "hardware.h"

#define spi_init()
#define spi_start(a) { *AT91C_PIOA_CODR = USB_SEL; }
#define spi_end()    { SPI_Wait4XferEnd(); *AT91C_PIOA_SODR = USB_SEL; }
#define spi_xmit(a)  SPI(a)

#endif // SPI_H
