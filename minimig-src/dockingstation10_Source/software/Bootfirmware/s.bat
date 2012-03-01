@echo off
echo.
echo to assemble use the AS V 1.42 by Alfred Arnold 
echo http://john.ccac.rwth-aachen.de:8000/as/download.html
echo download aswcurr.zip and unzip it to c:\bin\as
echo.

del hostboot.bin
if exist hostboot.hex if exist hostboot.bak del hostboot.bak
if exist hostboot.hex rename hostboot.hex hostboot.bak
c:\bin\as\asw -cpu 68000 hostboot.asm -L -olist hostboot.lst 
if exist hostboot.p c:\bin\as\p2bin hostboot.p hostboot.bin -r 0-$7FF
if exist hostboot.bin hexer hostboot.bin hostboot.hex
del hostboot.p

del osdload.bin
if exist osdload.hex if exist osdload.bak del osdload.bak
if exist osdload.hex rename osdload.hex osdload.bak
c:\bin\as\asw -cpu 68000 osdload.asm -L -olist osdload.lst 
if exist osdload.p c:\bin\as\p2bin osdload.p osdload.bin -r 0-$7FF
if exist osdload.bin hexer osdload.bin osdload.hex
del osdload.p

