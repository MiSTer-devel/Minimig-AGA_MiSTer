# Minimig-AGA_MiSTer

This is a port of the minimig core to the [MiSTer board](https://github.com/MiSTer-devel).

[Minimig](http://en.wikipedia.org/wiki/Minimig) (short for Mini Amiga) is an open source re-implementation of an Amiga using a field-programmable gate array (FPGA). Original Minimig author is Dennis van Weeren.

[Amiga](http://en.wikipedia.org/wiki/Amiga_500) was - in my opinion - an amazing personal computer, announced around 1984, which - at the time - far surpassed any other personal computer on the market, with advanced graphic & sound capabilities, not to mention its great OS with preemptive multitasking capabilities.

The Minimig-MiSTer variant in this repository has been upgraded with [AGA chipset](http://en.wikipedia.org/wiki/Amiga_Advanced_Graphics_Architecture) capabilites, which allows it to emulate the latest Amiga models ([Amiga 1200](http://en.wikipedia.org/wiki/Amiga_1200)) and (partially) [Amiga CD32](http://en.wikipedia.org/wiki/Amiga_CD32)). Of course it also supports previous OCS/ECS Amigas like [Amiga 500](http://en.wikipedia.org/wiki/Amiga_500), [Amiga 600](http://en.wikipedia.org/wiki/Amiga_600) etc.


## Core features supported

* Chipset variants : OCS, ECS, AGA
* ChipRAM : 0.5MB - 2.0MB
* SlowRAM : 0.0MB - 1.5MB
* FastRAM : 0.0MB - 384MB
* CPU core : 68000, 68020
* Kickstart : 1.2, 1.3, 2.0, 3.0, 3.1, 3.1.4, 3.2 (256kB, 512kB & 1MB kickstart ROMs currently supported)
* HRTmon with custom registers mirror
* Floppy drives : 1-4 floppies (supports ADF floppy image format), with normal & turbo speeds
* Up to 4 IDE devices
* CDROM
* Video standard : PAL / NTSC
* Supports almost all OCS/ECS/AGA custom resolutions
* RTG with up to 1920x1080 and 1600x1200 resolutions
* Peripherals : USB keyboards, USB mice, USB gamepads
* Serial connection to Linux with ability to connect to Internet.
* Shared folder for rapid file exchange between Linux and Amiga.
* MIDI: both MiSTer internal emulation and external through USER_IO port (MT32-pi and generic MIDI device)
* Akiko chunk to planar implementation
* Mouse with wheel.

## Usage

### Screen adjustment
Adjustment is initiated from OSD menu. 
Keyboard control:
* Cursor keys - top/left corner.
* ALT+Cursor keys - bottom/right corner.
* Enter - finish and store position.
* Backspace - reset do default.
* Esc - cancel and finish.

Positions are saved in the configuration file. Up to 64 different resolutions can be adjusted.

### Shared folder

All required files (and sources) are in extra/MiSTer_share.lha

Amiga driver is based on Niklas Ekström [a314](https://github.com/niklasekstrom/a314) driver.

On Amiga:
- copy dummy.device to DEVS:
- copy MountList to DEVS: (or add content from MountList to existing file)
- copy MiSTerFileSystem to L:
- open CLI and type there: mount share:
- MiSTer drive will appear on main WB screen. If it will work, then you can add this command into user-startup file, and it will be mounted at every boot.

On Linux side the folder is "shared" inside Amiga folder.

### RTG

* install [Picasso96.lha](http://aminet.net/package/driver/video/Picasso96) Choose uaegfx while installing.
* remove uaegfx (or whatever driver you choose in install) from SYS:Devs/Monitors
* extract [MiSTer_RTG.lha](https://github.com/MiSTer-devel/Minimig-AGA_MiSTer/raw/MiSTer/extra/rtg_driver/MiSTer_RTG.lha) and copy content to SYS:
* reboot

New video modes will appear in ScreenMode preference. For more screen modes use Picasso96Mode preference (attn: it has awkward interface!)

**Note: RTG outputs to HDMI primarily as it uses scaler.**
If you want to see RTG video on VGA output, then set vga_scaler=1 in MiSTer.ini.
RTG is available only for 68020 CPU.

### IDE and CDROM
By default up to 2 IDE devices are supported. For Secondary Master/Slave devices, you have to install either IDEFix97 (shareware, WB3.1/3.9) or AtapiMagic (freeware, WB 3.1.4/3.2).
Removable/CD mode allows to hot swap CDs. Currently audio portion of CD isn't implemented (although playback commands should be accepted).

### How to make a new HDF (HDD Image)
1) Create an empty HDF file of required size on PC (ideally fill it by 0 if possible).
2) Copy it to MiSTer
3) Mount it as HDF on OSD, and also mount some adf with HDToolBox (for example install3.2.adf from OS3.2)
4) Boot that ADF
5) go to HDToolBox, then Change Drive Type -> Define New -> Read Configuration. Then Ok, Ok. Then Save Changes to Drive.
6) Press Partition Drive. Optionally delete MDH1 partition, expand MDH0 to full drive. Rename MDH0 to standard DH0 name, mark it as Bootable. Then OK, then Save Changes to Drive.
7) Exit, reboot.
8) After booting you will see DH0:Uninitialized. Format it from Workbench menu. You can use Quick format option.
9) Install required OS.


### MIDI
Supported internal MiSTer emulation and external devices such as MT32-pi or generic MIDI though USER_IO.
For MIDI-IN support through USER_IO set UART mode to None in OSD settings.

### Akiko
Chunk to planar engine of Akiko is supported. It requires SetAkiko util (from releases/WheelDriverAkiko.adf) to be executed.

### Mouse Wheel
To enable wheel support both WheelDriver and FreeWheel must be run from releases/WheelDriverAkiko.adf

### Software
To use the core, you will need a Kickstart ROM image file, which you can obtain by copying Kickstart ROM IC from your actual Amiga, or by buying an [Amiga Forever](http://www.amigaforever.com/) software pack. The Kickstart image should be placed on the root of the SD card with the name KICK.ROM. Minimig also supports the [AROS](http://aros.sourceforge.net/) Kickstart ROM replacement.

The Minimig can read any ADF floppy images you place on the SD card. I recommend at least Workbench 1.3 or 3.1 (AmigaOS), some of the Amigas great games (I recommend Ruff'n'Tumble) or some of the amazing demos from the vast Amiga demoscene (like State of the Art from Spaceballs).

The Minimig can also use HDF harddisk images, which can be created with [WinUAE](http://www.winuae.net/).

### Recommended minimig config

* for ECS games / demos : CPU = 68000, Turbo=NONE, Chipset=ECS, ChipRAM=0.5MB, slowRAM=0.5MB, Kickstart 1.3
* for AGA games / demos : CPU = 68020, Turbo=NONE, Chipset=AGA, ChipRAM=2MB, SlowRAM=0MB, FastRAM=384MB, Kickstart 3.1

### Controlling minimig

Keyboard special keys:

* F12         - OSD menu
* F11         - start monitor (HRTmon) if HRTmon is enabled in OSD menu (otherwise F11 is the Amiga HELP key)
* ScrollLock  - toggle keyoard only / mouse / joystick 1 / joystick 2 emulation on the keyboard (direction keys + LCTRL)


## Sources

This sourcecode is based on Rok Krajnc project ([minimig-de1](https://github.com/rkrajnc/minimig-de1)).

Original Minimig sources from Dennis van Weeren with updates by Jakub Bednarski are published on [Google Code](http://code.google.com/p/minimig/).

Some Minimig updates are published on the [Minimig Discussion Forum](http://www.minimig.net/), done by Sascha Boing.

ARM firmware updates and Minimig-tc64 port changes by Christian Vogelsang ([minimig_tc64](https://github.com/cnvogelg/minimig_tc64)) and A.M. Robinson ([minimig_tc64](https://github.com/robinsonb5/minimig_tc64)).

MiSTer project by Sorgelig ([MiSTer](https://github.com/MiSTer-devel)).

TG68K.C core by Tobias Gubener.


## Links & more info

My page [somuch.guru](http://somuch.guru/).

Further info about Minimig can be found on the [Minimig Discussion Forum](http://www.minimig.net/).

MiSTer board support & other cores on the [MiSTer Project Page](https://github.com/MiSTer-devel).


## License

Copyright © 2011 - 2016 Rok Krajnc (rok.krajnc@gmail.com)

Copyright © 2005 - 2015 Dennis van Weeren, Jakub Bednarski, Sascha Boing, A.M. Robinson, Tobias Gubener, Till Harbaum

Copyright © 2017 - 2020 Sorgelig (mister.devel@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
