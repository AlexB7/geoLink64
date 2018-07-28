# geoLink v1.01
Written by Glenn Holmer (a.k.a "Shadow", a.k.a "Cenbe").

https://csdb.dk/release/?id=91469

July 27th, 2018


## Overview

geoLink is a networked GEOS application for the Commodore 64 written by ShadowM which includes an IRC client and uses the IP65 network stack.  A technical presentation on geoLink called 'geoLink Internals' was given at the C=4 Expo on 2010-05-29 (1) and a presentation on 'Networking in Geos' was given at the 2009 World of Commodore (2).  The program works with GEOS 64 2.0 and GOES 128 2.0 in 40 column mode and requires a 1541/71/81 disk drive or 1541 Ultimate (it will not run on a µIEC).  See Manual.html for instructions on using geoLink and Readme2.html for other useful information including the version history, downloading disk images and compiling using geoProgrammer.  It requires a 64NIC+, 1541 Ultimate, RR-Net, MMC Replay, or FB-Net network card (it does not work with 'WiFi' modems).

	(1) ftp://8bitfiles.net/archives/geos-archive/GEOS-LINK/geoLinkInternals.pdf
	(2) ftp://8bitfiles.net/archives/geos-archive/GEOS-LINK

The original geoProgrammer source files were converted to ASCII and then tweaked by Alex Burger to compile with CC65.


## Installing

If this is your first time trying geoLink, it is recommended that you download a .d64 image from CSDB or 8bitfiles.net which contains a bootable GEOS 64 2.0 disk along with the geoLink program.  Read both Readme2.html and Manual.html before attempting to run geoLink.

If using the Vice c64 emulator, you can configure the network card using by clicking Settings / Cartridge I/O Settings / Ethernet Cart Settings.  Enable cartridge and set to RR-Net at $DE00.  Then Settings / Ethernet Settings and select your PC network card to attach to.

To manually install from this repository, inside the bin folder is a cc65 compiled version (geolink.cvt) in GEOS CONVERT format which can be copied directly to a .d64, d71 or .d81 image file using DirMaster or another Commodore disk imaging program.  When using DirMaster, the file will be automatically converted to GEOS format but with other utilities you may have to manually convert to GEOS format using CONVERT 2.5.


## Compiling geoLink

Compiling requires the cc65 6502 compiler which is available from https://cc65.github.io/cc65/.

geoLink uses the IP65 TCP/IP stack for 6502 based computers from https://github.com/cc65/ip65.  Included in this repository are the compiled library files along with IP65-GEOS.prg which contains the compiled stack for GEOS.  Compiling IP65 from scratch is detailed below but is not required.

The following libraries are required from the GOES 2.0 source code at https://github.com/mist64/geos/tree/master/inc

	geosmac.inc
	geossym.inc
	jumptab.inc

The following libraries are required from the cc65 project, which can be found at https://github.com/cc65/cc65/tree/master/libsrc/geos-cbm

	geossym2.inc

Note:  cc65 will create a vice symbol file (geoLink.lbl) with all lables (eg: io := $d000), but it does not include constants (eg: two = 2).  To make debugging easier, modify geossym.inc, geossym2.inc and jumptab.inc by changing all '=' to ':=' so that they are all added to the symbol file.

The button bitmap data is contained inside the main source files (geoLinkIRC.s, geoLinkPing etc).  If the .png/.pcx source images are changed, they need to be recompiled using sp65 and then manually added to source files.  If needed, use Gimp to convert from .png to .pcx.

	sp65 -v -r button-unck.pcx -c geos-bitmap -w button-unck.s,format=asm
	sp65 -v -r button-ck.pcx -c geos-bitmap -w button-ck.s,format=asm
	sp65 -v -r button-ok.pcx -c geos-bitmap -w button-ok.s,format=asm
	sp65 -v -r button-cncl.pcx -c geos-bitmap -w button-cncl.s,format=asm
	sp65 -v -r button-okDis.pcx -c geos-bitmap -w button-okDis.s,format=asm
	sp65 -v -r button-cnclDis.pcx -c geos-bitmap -w button-cnclDis.s,format=asm

	sp65 -v -r button-send.pcx -c geos-bitmap -w button-send.s,format=asm
	sp65 -v -r button-str.pcx -c geos-bitmap -w button-str.s,format=asm
	sp65 -v -r button-stp.pcx -c geos-bitmap -w button-stp.s,format=asm
	sp65 -v -r button-exit.pcx -c geos-bitmap -w button-exit.s,format=asm
	
The program icon is contained in icon-program.bin.  If the .png/.pcx source image is changed, it needs to be recompiled using sp65.

	sp65 -v -r icon-program.pcx -c geos-icon -w icon-program.bin,format=bin

Included with the source is a Unix Makefile and a Windows make.cmd batch file.  To build with either environment, type make and you should end up with:

	geoLink.cvt
	geoLinkEmbed.cvt

Copy the following files to a .d64, d71 or .d81 image file using DirMaster or another Commodore disk imaging program.  When using DirMaster, the .cvt files will be automatically converted to GEOS format but with other utilities you may have to manually convert to GEOS format using CONVERT 2.5.

	vip64-mono.cvt		(located in bin folder)
	IP65-GEOS.prg		(located in bin folder)
	geoLinkEmbed.cvt
	geoLink.cvt

Launch GEOS and run geoLinkEmbed. This will embed the TCP/IP stack (ip65-geos) into VLIR record 9 of the geoLink executable and the monospaced font (VIP64-mono) into record 8.  You should now have a working copy of geoLink.


## Compiling IP65

Coming soon...



