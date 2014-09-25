#ifndef CDC_CONTROL_H
#define CDC_CONTROL_H

#define CDC_REDIRECT_NONE     0x00
#define CDC_REDIRECT_CONTROL  0x01
#define CDC_REDIRECT_DEBUG    0x02
#define CDC_REDIRECT_RS232    0x03
#define CDC_REDIRECT_PARALLEL 0x04
#define CDC_REDIRECT_MIDI     0x05

void cdc_control_open(void);
void cdc_control_poll(void);
void cdc_control_tx(char c);
void cdc_control_flush(void);

#endif // CDC_CONTROL_H
