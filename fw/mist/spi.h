#ifndef SPI_H
#define SPI_H

#include "AT91SAM7S256.h"
#include <inttypes.h>

#define RAMFUNC __attribute__ ((long_call, section (".ramsection")))

#include "hardware.h"

/* main init functions */
void spi_init(void);
void spi_slow();
void spi_fast();
void spi_fast_mmc();
RAMFUNC void spi_wait4xfer_end();

/* chip select functions */
void EnableFpga(void);
void DisableFpga(void);
void EnableOsd(void);
void DisableOsd(void);
void EnableDMode();
void DisableDMode();
RAMFUNC void EnableCard();
RAMFUNC void DisableCard();

/* generic helper */
unsigned char spi_in();
void spi8(unsigned char parm);
void spi16(unsigned short parm);
void spi24(unsigned long parm);
void spi32(unsigned long parm);
void spi32le(unsigned long parm);
void spi_n(unsigned char value, unsigned short cnt);

/* block transfer functions */
RAMFUNC void spi_block_read(char *addr);
RAMFUNC void spi_read(char *addr, uint16_t len);
void spi_block_write(char *addr);
void spi_write(char *addr, uint16_t len);

/* OSD related SPI functions */
void spi_osd_cmd_cont(unsigned char cmd);
void spi_osd_cmd(unsigned char cmd);
void spi_osd_cmd8_cont(unsigned char cmd, unsigned char parm);
void spi_osd_cmd8(unsigned char cmd, unsigned char parm);
void spi_osd_cmd32_cont(unsigned char cmd, unsigned long parm);
void spi_osd_cmd32(unsigned char cmd, unsigned long parm);
void spi_osd_cmd32le_cont(unsigned char cmd, unsigned long parm);
void spi_osd_cmd32le(unsigned char cmd, unsigned long parm);

/* User_io related SPI functions */
void spi_uio_cmd_cont(unsigned char cmd);
void spi_uio_cmd(unsigned char cmd);
void spi_uio_cmd8(unsigned char cmd, unsigned char parm);

/* spi functions for max3421 */
#define spi_max_start()  { *AT91C_PIOA_CODR = USB_SEL; }
#define spi_max_end()    {  spi_wait4xfer_end(); *AT91C_PIOA_SODR = USB_SEL; }

static inline unsigned char SPI(unsigned char outByte) {
  while (!(*AT91C_SPI_SR & AT91C_SPI_TDRE));
  *AT91C_SPI_TDR = outByte;
  while (!(*AT91C_SPI_SR & AT91C_SPI_RDRF));
  return((unsigned char)*AT91C_SPI_RDR);
}

static inline unsigned char SPI_READ() {
  *AT91C_SPI_TDR = 0;
  while (!(*AT91C_SPI_SR & AT91C_SPI_RDRF));
  return((unsigned char)*AT91C_SPI_RDR);
}

static inline void SPI_WRITE(unsigned char outByte) {
  while (!(*AT91C_SPI_SR & AT91C_SPI_TDRE));
  *AT91C_SPI_TDR = outByte;
}

#define SPI_SDC_CLK_VALUE 2     // 24 Mhz
#define SPI_MMC_CLK_VALUE 3     // 16 Mhz
#define SPI_SLOW_CLK_VALUE 120  // 400kHz

#endif // SPI_H
