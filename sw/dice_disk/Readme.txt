Minimig for Turbo Chameleon 64 Menu build disk

The Minimig port for Chameleon was done by Tobias Gubener, who chose to take an amazing approach to
emulating the "ARM processor" board, which powers the "real" Minimig board: Tobias just instanciated
a second 68000 processor and compiled the C-sourcecode with target 68k. Voila, we have the full menu,
which normally requires an ARM board, in our tiny little Chameleon.

The most interesting thing about this is that the free Amiga C-compiler "Dice" was used to compile the
menu code. However, Tobias was using a full-blown installation in UAE, which was a little beyond the
capacity of Minimig. Christian Vogelgsang has now taken up Jens Schönfeld's suggestion to make the
Chameleon it's own development system for the Minimig menu. The result is an ADF with all required
files for compiling the on-screen menu code for Minimig/Chameleon.

How to use
----------

- configure Minimig to use 2 disk drives
- mount an ADF with Workbench 3.1 in df0:
- mount mm_tc64-adf in df1:
- boot
- open a shell
- type 'cd df1:amiga'
- type 'dice_mini/bin/dmake clean all'
- wait... and the build is done!

The source code is under GPL, and Christian has published it here:
https://github.com/cnvogelg/minimig_tc64

Why?
----
Minimig on Turbo Chameleon 64 is a grown-up turbo Amiga with harddrive, 512k ROM capability, lots of
RAM and up to four emulated floppy drives. Naturally, people want to use it like a real Amiga and also
easily exchange data with a PC, just like Amiga users do it every day with a CF-card adapter for the
A1200 PCMCIA slot. However, exchanging data through the SD-card in Chameleon is painful, as the current
Minimig menu can only read ADF and hardfiles.

The Amiga has the capability to mount FAT-formatted drives. However, it needs block-access to the media.
This is currently not implemented in the Minimig core for Turbo Chameleon 64. This disk shall enable
programmers to alter the menu code to allow block access to the SD card for scsi.device unit 1, so it
can be mounted under the Amiga operating system. Once this type of access is available to the Amiga, we
can create a simple mountlist and see the full contents of the SD card from the Amiga operating system.

Going from there, you could even mount *.iso files using Matt Dillon's fmsdisk.device, and the whole
world of Aminet CDs will be available to the Minimig core.

Who will be the glorious programmer to take this challenge?

