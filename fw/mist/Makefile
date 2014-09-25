BASE ?= /opt/arm-none-eabi/bin/arm-none-eabi
CC      = $(BASE)-gcc
LD      = $(BASE)-gcc
AS      = $(BASE)-as
CP      = $(BASE)-objcopy
DUMP    = $(BASE)-objdump

TODAY = `date +"%m/%d/%y"`

PRJ = firmware
SRC = Cstartup_SAM7.c  fat.c  fdd.c  firmware.c  fpga.c  hardware.c  hdd.c  main.c  menu.c  mmc.c  osd.c syscalls.c user_io.c boot_print.c boot_logo.c rafile.c config.c tos.c ikbd.c
SRC += usb/max3421e.c usb/usb.c usb/hub.c usb/hid.c usb/hidparser.c usb/timer.c usb/asix.c usb/storage.c usb/usbrtc.c
SRC += cdc_enumerate.c cdc_control.c

OBJ = $(SRC:.c=.o)
DEP = $(SRC:.c=.d)

LINKMAP  = AT91SAM7S256-ROM.ld
LIBDIR   = 

# Commandline options for each tool.
DFLAGS  = -I. -Iusb -DMIST
CFLAGS  = $(DFLAGS) -c -fno-common -O2 -fsigned-char -DVDATE=\"`date +"%y%m%d"`\"
AFLAGS  = -ahls -mapcs-32
LFLAGS  = -nostartfiles -Wl,-Map,$(PRJ).map -T$(LINKMAP) $(LIBDIR)
CPFLAGS = --output-target=ihex

MKUPG = mkupg

# Libraries.
LIBS       =

# Our target.
all: $(PRJ).hex $(PRJ).upg

clean:
	rm -f *.d *.o *.hex *.elf *.map *.lst core *~ */*.d */*.o $(MKUPG) *.bin *.upg

INTERFACE=olimex-arm-usb-tiny-h
#INTERFACE=busblaster
ADAPTER_KHZ=10000

reset:
	openocd -f interface/$(INTERFACE).cfg -f target/at91sam7sx.cfg --command "adapter_khz $(ADAPTER_KHZ); init; reset init; resume; shutdown"

$(MKUPG): $(MKUPG).c
	gcc  -o $@ $<

flash: $(PRJ).bin
	openocd -f interface/$(INTERFACE).cfg -f target/at91sam7sx.cfg --command "adapter_khz $(ADAPTER_KHZ); init; reset init;  flash protect 0 0 7 off; sleep 1; arm7_9 fast_memory_access enable; flash write_bank 0 $(PRJ).bin 0x0; resume; shutdown"

flash_sam: $(PRJ).hex
	Sam_I_Am -x flash_sam_i_am

# Convert ELF binary to bin file.
$(PRJ).bin: $(PRJ).elf
	$(CP) -O binary $< $@

# Convert ELF binary to Intel HEX file.
$(PRJ).hex: $(PRJ).elf
	$(CP) $(CPFLAGS) $< $@

# Link - this produces an ELF binary.
$(PRJ).elf: crt.o $(OBJ)
	$(LD) $(LFLAGS) -o $@ $+ $(LIBS)

$(PRJ).upg: $(PRJ).bin $(MKUPG)
	./$(MKUPG) $< $@ `date +"%y%m%d"`

# Compile the C runtime.
crt.o: Cstartup.S
	$(AS) $(AFLAGS) -o $@ $< > crt.lst

%.o: %.c
	$(CC) $(CFLAGS)  -o $@ -c $<

# Automatic dependencies
-include $(DEP)
%.d: %.c
	$(CC) $(DFLAGS) -MM $< -MT $@ -MT $*.o -MF $@

# Ensure correct time stamp
main.o: $(filter-out main.o, $(OBJ))

sections: $(PRJ).elf
	$(DUMP) --section-headers $<

release:
	make $(PRJ).hex $(PRJ).bin $(PRJ).upg
	cp $(PRJ).hex $(PRJ).bin $(PRJ).upg ../bin/firmware
