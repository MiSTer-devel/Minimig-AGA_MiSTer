#include "spi.h"
#include "hardware.h"

void spi_init() {
    // Enable the peripheral clock in the PMC
    AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_SPI;

    // Enable SPI interface
    *AT91C_SPI_CR = AT91C_SPI_SPIEN;

    // SPI Mode Register
    *AT91C_SPI_MR = AT91C_SPI_MSTR | AT91C_SPI_MODFDIS  | (0x0E << 16);

    // SPI CS register
    AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (48 << 8) | (0x00 << 16) | (0x01 << 24);

    // Configure pins for SPI use
    AT91C_BASE_PIOA->PIO_PDR = AT91C_PA14_SPCK | AT91C_PA13_MOSI | AT91C_PA12_MISO;
}

RAMFUNC void spi_wait4xfer_end() {
  while (!(*AT91C_SPI_SR & AT91C_SPI_TXEMPTY));
  
  /* Clear any data left in the receiver */
  (void)*AT91C_SPI_RDR;
  (void)*AT91C_SPI_RDR;
}

void EnableFpga()
{
    *AT91C_PIOA_CODR = FPGA0;  // clear output
}

void DisableFpga()
{
    spi_wait4xfer_end();
    *AT91C_PIOA_SODR = FPGA0;  // set output
}

void EnableOsd()
{
    *AT91C_PIOA_CODR = FPGA1;  // clear output
}

void DisableOsd()
{
    spi_wait4xfer_end();
    *AT91C_PIOA_SODR = FPGA1;  // set output
}

void EnableIO() {
    *AT91C_PIOA_CODR = FPGA3;  // clear output
}

void DisableIO() {
    spi_wait4xfer_end();
    *AT91C_PIOA_SODR = FPGA3;  // set output
}

void EnableDMode() {
  *AT91C_PIOA_CODR = FPGA2;    // enable FPGA2 output
}

void DisableDMode() {
  *AT91C_PIOA_SODR = FPGA2;    // disable FPGA2 output
}

RAMFUNC void EnableCard() {
  *AT91C_PIOA_CODR = MMC_SEL;  // clear output (MMC chip select enabled)
}

RAMFUNC void DisableCard() {
  spi_wait4xfer_end();
  *AT91C_PIOA_SODR = MMC_SEL;  // set output (MMC chip select disabled)
  SPI(0xFF);
  spi_wait4xfer_end();
}

void spi_block(unsigned short num) {
  unsigned short i;
  unsigned long t;

  for (i = 0; i < num; i++) {
    while (!(*AT91C_SPI_SR & AT91C_SPI_TDRE)); // wait until transmiter buffer is empty
    *AT91C_SPI_TDR = 0xFF; // write dummy spi data
  }
  while (!(*AT91C_SPI_SR & AT91C_SPI_TXEMPTY)); // wait for transfer end
  t = *AT91C_SPI_RDR; // dummy read to empty receiver buffer for new data
}

RAMFUNC void spi_read(char *addr, uint16_t len) {
  *AT91C_PIOA_SODR = AT91C_PA13_MOSI; // set GPIO output register
  *AT91C_PIOA_OER = AT91C_PA13_MOSI;  // GPIO pin as output
  *AT91C_PIOA_PER = AT91C_PA13_MOSI;  // enable GPIO function
  
  // use SPI PDC (DMA transfer)
  *AT91C_SPI_TPR = (unsigned long)addr;
  *AT91C_SPI_TCR = len;
  *AT91C_SPI_TNCR = 0;
  *AT91C_SPI_RPR = (unsigned long)addr;
  *AT91C_SPI_RCR = len;
  *AT91C_SPI_RNCR = 0;
  *AT91C_SPI_PTCR = AT91C_PDC_RXTEN | AT91C_PDC_TXTEN; // start DMA transfer
  // wait for tranfer end
  while ((*AT91C_SPI_SR & (AT91C_SPI_ENDTX | AT91C_SPI_ENDRX)) != (AT91C_SPI_ENDTX | AT91C_SPI_ENDRX));
  *AT91C_SPI_PTCR = AT91C_PDC_RXTDIS | AT91C_PDC_TXTDIS; // disable transmitter and receiver

  *AT91C_PIOA_PDR = AT91C_PA13_MOSI; // disable GPIO function
}

RAMFUNC void spi_block_read(char *addr) {
  spi_read(addr, 512);
}

void spi_write(char *addr, uint16_t len) {
  // use SPI PDC (DMA transfer)
  *AT91C_SPI_TPR = (unsigned long)addr;
  *AT91C_SPI_TCR = len;
  *AT91C_SPI_TNCR = 0;
  *AT91C_SPI_RCR = 0;
  *AT91C_SPI_PTCR = AT91C_PDC_TXTEN; // start DMA transfer
  // wait for tranfer end
  while (!(*AT91C_SPI_SR & AT91C_SPI_ENDTX));
  *AT91C_SPI_PTCR = AT91C_PDC_TXTDIS; // disable transmitter
}

void spi_block_write(char *addr) {
  spi_write(addr, 512);
}

void spi_slow() {
  AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (SPI_SLOW_CLK_VALUE << 8) | (2 << 24); // init clock 100-400 kHz
}

void spi_fast() {
  // set appropriate SPI speed for SD/SDHC card (max 25 Mhz)
  AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (SPI_SDC_CLK_VALUE << 8); // 24 MHz SPI clock
}

void spi_fast_mmc() {
  // set appropriate SPI speed for MMC card (max 20Mhz)
  AT91C_SPI_CSR[0] = AT91C_SPI_CPOL | (SPI_MMC_CLK_VALUE << 8); // 16 MHz SPI clock
}

/* generic helper */
unsigned char spi_in() {
  return SPI(0);
}

void spi8(unsigned char parm) {
  SPI(parm);
}

void spi16(unsigned short parm) {
  SPI(parm >> 8);
  SPI(parm >> 0);
}

void spi24(unsigned long parm) {
  SPI(parm >> 16);
  SPI(parm >> 8);
  SPI(parm >> 0);
}

void spi32(unsigned long parm) {
  SPI(parm >> 24);
  SPI(parm >> 16);
  SPI(parm >> 8);
  SPI(parm >> 0);
}

// little endian: lsb first
void spi32le(unsigned long parm) {
  SPI(parm >> 0);
  SPI(parm >> 8);
  SPI(parm >> 16);
  SPI(parm >> 24);
}

void spi_n(unsigned char value, unsigned short cnt) {
  while(cnt--) 
    SPI(value);
}

/* OSD related SPI functions */
void spi_osd_cmd_cont(unsigned char cmd) {
  EnableOsd();
  SPI(cmd);
}

void spi_osd_cmd(unsigned char cmd) {
  spi_osd_cmd_cont(cmd);
  DisableOsd();
}

void spi_osd_cmd8_cont(unsigned char cmd, unsigned char parm) {
  EnableOsd();
  SPI(cmd);
  SPI(parm);
}

void spi_osd_cmd8(unsigned char cmd, unsigned char parm) {
  spi_osd_cmd8_cont(cmd, parm);
  DisableOsd();
}

void spi_osd_cmd32_cont(unsigned char cmd, unsigned long parm) {
  EnableOsd();
  SPI(cmd);
  spi32(parm);
}

void spi_osd_cmd32(unsigned char cmd, unsigned long parm) {
  spi_osd_cmd32_cont(cmd, parm);
  DisableOsd();
}

void spi_osd_cmd32le_cont(unsigned char cmd, unsigned long parm) {
  EnableOsd();
  SPI(cmd);
  spi32le(parm);
}

void spi_osd_cmd32le(unsigned char cmd, unsigned long parm) {
  spi_osd_cmd32le_cont(cmd, parm);
  DisableOsd();
}

/* User_io related SPI functions */
void spi_uio_cmd_cont(unsigned char cmd) {
  EnableIO();
  SPI(cmd);
}

void spi_uio_cmd(unsigned char cmd) {
  spi_uio_cmd_cont(cmd);
  DisableIO();
}

void spi_uio_cmd8_cont(unsigned char cmd, unsigned char parm) {
  EnableIO();
  SPI(cmd);
  SPI(parm);
}

void spi_uio_cmd8(unsigned char cmd, unsigned char parm) {
  spi_uio_cmd8_cont(cmd, parm);
  DisableIO();
}
