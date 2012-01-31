# minimig-de1


## Description

This is a port of minimig to the [Altera DE1 board](http://www.altera.com/education/univ/materials/boards/de1/unv-de1-board.html).

[minimig](http://en.wikipedia.org/wiki/Minimig) (short for Mini Amiga) is an open source re-implementation of an Amiga 500 using a field-programmable gate array (FPGA). Original minimig author is Dennis van Weeren.

[Amiga](http://en.wikipedia.org/wiki/Amiga_500) was (in my opinion) an amazing personal computer, announced around 1987, which - at the time - far surpassed any other personal computer on the market, with advanced graphic & sound capabilities.


## Sources

This port is based on work done by tobiflexx, who did the original hard work of porting minimig to the Altera boards. His sources are published on [minimigtg68](http://gamesource.groups.yahoo.com/group/minimigtg68) Yahoo Group. He is also the author of the tg68 Motorola 68000 softcore CPU, published on [opencores](http://opencores.org/project,tg68).

Original minimig sources with updates from yaqube (and possibly others) are published on [Google Code](http://code.google.com/p/minimig/).

Some updates are from user boing4000 from the Minimig forum.


## Usage

### Software
Under Downloads, there's a [zip](https://github.com/downloads/rkrajnc/minimig-de1/minimig-de1-config-latest.zip) file with the latest build. It contains a .sof file that is used to program the FPGA, and a menue.sys file, which should be placed on the root of a FAT16 - formatted SD card no larger than 2GB.
Also needed are a Kickstart ROM image file, which you can obtain by copying Kickstart ROM IC from your actual Amiga, or by buying an [Amiga Forever](http://www.amigaforever.com/) software pack. The Kickstart image should be placed on the root of the SD card with the name KICK.ROM.
The minimig can then read any ADF floppy images you place on the SD card. Recommended are at least Workbench 1.3 or 3.1 (AmigaOS), some of the Amigas great games (I recommend Ruff'n'Tumble) or some of the amazing demos from the vast Amiga demoscene (like State of the Art from Spaceballs).

### Hardware
You need at least an SD card for the software and a PS/2 keyboard connected to the DE1 board's PS/2 port. And, of course, a VGA monitor and a set of speakers. There's a way to also connect a PS/2 mouse and two real Amiga joysticks, but you have to make an adapter board (there's a schematic [here](https://github.com/rkrajnc/minimig-de1/tree/master/minimig-src/minimigtg68/other)).

### Controling minimig
DE1 board switches / keys:
* SW[9] - enables/disables keyboard joystick emulation
* SW[7] - switches left/right audio
* SW[1] - reset (internal)
* SW[0] - reset (PLL reset)
* KEY[3] - left mouse button
* KEY[2] - right mouse button

Keyboard emulation:
* Cursor movement keys for joystick up,down,left,right
* LCTRL - fire1
* LALT - fire2
* LWIN + LALT - left mouse button
* RWIN + RALT - right mouse button
* F12 - menu

## Links & info
Further info about minimig can be found on the [Minimig Discussion Forum](http://www.minimig.net/)
