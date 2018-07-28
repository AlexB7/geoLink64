AS=ca65
LD=ld65
AFLAGS=

all: geolink geolinkemb

%.o: %.c
	$(CC) -c $(CFLAGS) $<

%.o: %.s
	$(AS) $(AFLAGS) $<
	
GEOLINKOBJS= \
geoLinkG.o \
geoLinkRes.o \
geoLinkVal.o \
geoLinkSetup.o \
geoLinkPing.o \
geoLinkLogin.o \
geoLinkIRC.o \
geoLinkFontStub.o \
geoLinkIP65Stub.o \

GEOLINKEMBOBJS= \
geoLinkEmbed.o \
geoLinkEmbedG.o \

geolink: $(GEOLINKOBJS) 
	$(LD) -C ./geos-cbm.cfg -Ln geoLink.lbl -o geoLink.cvt -m geoLink.map \
	$(GEOLINKOBJS) geos-cbm.lib ip65_tcp.lib ip65.lib

geolinkemb: $(GEOLINKEMBOBJS) 
	$(LD) -C ./geos-cbm.cfg -Ln geoLinkEmbed.lbl -o geoLinkEmbed.cvt -m geoLinkEmbed.map \
	$(GEOLINKEMBOBJS) geos-cbm.lib
	
clean:
	rm -f *.o *.cvt *.map *.lbl

distclean: clean
	rm -f *~
