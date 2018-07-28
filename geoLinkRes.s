; -----------------------------------------------------------
; geoLinkRes: geoLink resident module (VLIR)
; -----------------------------------------------------------
	.forceimport	__STARTUP__
	.forceimport	bin2hex
	.forceimport	modLoad
	.export		_main
	.export		bServer
	.export		autoVect
	.export		bPort
	.export		bankNet
	.export		beep
	.export		cfg2geos
	.export		autoVect
	.export		bPort
	.export		bankNet
	.export		bankRst
	.export		beep
	.export		cfg2geos
	.export		cfg2ip65
	.export		chatting
	.export		debug
	.export		dhcp
	.export		dnsStrc
	.export		errHndlr
	.export		errorDB
	.export		errorMsg
	.export		geosMenu
	.export		geosWord
	.export		impDlg
	.export		ip65
	.export		ipAddr
	.export		ipData
	.export		loadIRC
	.export		macAddr
	.export		mainMenu
	.export		nick
	.export		noDhcp
	.export		noIcons
	.export		okDB
	.export		okMsg
	.export		optMenu
	.export		optWord
	.export		pingAddr
	.export		server
	.export		setName
	.export		setupOK
	.export		strWidth
	.export		swapMod
	.export		tcpConn
	.export		tcpSend
	.export		tcpStrc
	.include	"geoLink.inc"
	.include	"geosmac.inc"
	.include	"geossym.inc"
	.include	"geossym2.inc"
	.include	"const.inc"
	.include	"jumptab.inc"

; -----------------------------------------------------------
NUM_MODS	=	9
MOD_SETUP	=	1
MOD_PING	=	2
MOD_LOGIN	=	3
MOD_IRC	=	4
MOD_FONT	=	8	;embedded mono font
MOD_IP65	=	9
; -----------------------------------------------------------

.segment	"STARTUP"

.proc	_main: near

.segment	"STARTUP"

start:	lda	#2	;50% stipple
	jsr	SetPattern
	LoadB	r2L,0
	LoadB	r2H,199
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;clear screen
	lda	version
	tax
	and	#$f0
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	ora	#$30
	sta	verHi
	sta	iVerHi
	txa
	and	#$0f
	ora	#$30
	sta	verLo
	sta	iVerLo
	txa
	cmp	#$20
	beq	@20
	bcs	@10
	LoadW	r0,versDB	;GEOS version <2.0
	LoadW	versMsg,loVers
	jsr	DoDlgBox
	jmp	EnterDeskTop
@10:	LoadW	r0,versDB	;GEOS version \>2.0 (e.g. Wheels)
	LoadW	versMsg,hiVers
	jsr	DoDlgBox
@20:	jsr	getMods	;get module locations on disk
	jsr	loadLib	;load network library
	bcc	@30
	jmp	EnterDeskTop
@30:	ldy	#K_CINIT	;check for network card
	jsr	ip65	;and initialize if found
	bcc	@40
	LoadW	errorMsg,noCard
	LoadW	r0,errorDB
	jsr	DoDlgBox
	jmp	EnterDeskTop
@40:	LoadW	r0,procNet	;set up network polling processes
	lda	#NUM_PRCS
	jsr	InitProcesses	;don''t start until RestartProcess is called
	ldy	#K_SETIRQ	;install IRQ hook for timer
	jsr	ip65
	LoadW	r0,mainMenu
	lda	#0
	jsr	DoMenu
	jsr	getSets	;look for settings files on disk
	rts
	
.endproc
	
	
; -----------------------------------------------------------
doInfo:	jsr	GotoFirstMenu
	lda	curMod
	cmp	#MOD_IRC	;IRC module runs without double-buffering
	bne	@10
	jsr	impDlg	;imprint dialog area to background screen
@10:	LoadW	r0,infoDB
	jsr	DoDlgBox
	rts
; -----------------------------------------------------------
doSetup:	jsr	GotoFirstMenu
	LoadW	r7,modLoad
	lda	#MOD_SETUP
	sec
	jsr	swapMod	;swap in settings module
	LoadW	optWord,deadMenu
	LoadW	r0,mainMenu
	lda	#1
	jsr	DoMenu	;disable options menu
	jsr	modLoad	;call module init routine
	rts
; -----------------------------------------------------------
doPing:	jsr	GotoFirstMenu
	LoadW	r7,modLoad
	lda	#MOD_PING
	sec
	jsr	swapMod	;swap in ping module
	LoadW	optWord,deadMenu
	LoadW	r0,mainMenu
	lda	#1
	jsr	DoMenu	;disable options menu
	jsr	modLoad	;call module init routine
	rts
; -----------------------------------------------------------
doIRC:	jsr	GotoFirstMenu
	LoadW	r7,modLoad
	lda	#MOD_LOGIN
	sec
	jsr	swapMod	;swap in IRC login module
	LoadW	optWord,deadMenu
	LoadW	r0,mainMenu
	lda	#1
	jsr	DoMenu	;disable options menu
	jsr	modLoad	;call module init routine
	rts

; -----------------------------------------------------------
; This loader is called from the IRC login module on success. The 
; IRC module puts up ircMenu by itself so it can control the order
; in which DoIcons and DoMenu are called.
; -----------------------------------------------------------
loadIRC:	ldx	#PRC_POLL
	jsr	FreezeProcess	;don''t poll during load
	LoadW	r7,modLoad
	lda	#MOD_IRC
	sec
	jsr	swapMod	;swap in IRC module
	jsr	modLoad	;call module init routine
	rts
; -----------------------------------------------------------
doQuit:	jsr	GotoFirstMenu
	ldx	#PRC_POLL
	jsr	BlockProcess	;stop polling network card
	ldy	#K_KILIRQ	;remove IRQ timer hook
	jsr	ip65
	jmp	EnterDeskTop
; -----------------------------------------------------------
dummy:	jsr	GotoFirstMenu
	rts

; -----------------------------------------------------------
; Load ip65 network library from VLIR module. See program 
; geoLinkEmbed, which loads the ip65 stack built with cc65 and
; embeds it in this executable after it is built.
;	pass:	nothing
;	return:	carry clear on success, set otherwise
; -----------------------------------------------------------
loadLib:	LoadW	r7,IP65
	lda	#MOD_IP65
	clc
	jsr	swapMod
@20:	ldy	#K_GETCFG	;get ip65 settings address
	jsr	ip65
	sta	ip65Cfg	;save for run of program
	stx	ip65Cfg+1
	clc
	rts
; -----------------------------------------------------------
; Get track and sector addresses of VLIR modules, load settings.
; -----------------------------------------------------------
getMods:	LoadW	r6,fileName	;get module load pointers
	LoadB	r7L,APPLICATION
	LoadB	r7H,1
	LoadW	r10,permName
	jsr	FindFTypes	;we''re looking for ourself
	txa
	beq	@10
	jmp	errHndlr
@10:	LoadW	r0,fileName
	jsr	OpenRecordFile
	LoadW	r0,$8104	;fileHeader+4
	LoadW	r1,swapTS
	LoadW	r2,NUM_MODS*2
	jsr	MoveData
	jsr	CloseRecordFile
	rts
; -----------------------------------------------------------
; Load settings file if present. Show settings dialog if no settings
; file found or user cancels load.
; -----------------------------------------------------------
getSets:	LoadW	r6,fileName	;look for any settings files
	LoadB	r7L,DATA
	LoadB	r7H,1
	LoadW	r10,setPerm
	jsr	FindFTypes
	txa
	beq	@20
	jmp	errHndlr
@20:	lda	r7H
	beq	@30	;at least one found, show DB
@25:	LoadW	r7,modLoad	;no settings files found
	lda	#MOD_SETUP
	sec
	jsr	swapMod	;swap in settings module
	jmp	modLoad	;and jump to its init routine
@30:	LoadW	r0,setDB
	LoadW	r5,fileName
	LoadB	r7L,DATA
	LoadW	r10,setPerm
	jsr	DoDlgBox
	lda	r0L
	cmp	#OPEN
	bne	@25	;user canceled, load setup module
;	------------------------------------------------
	LoadW	r6,fileName	;load selected settings file
	LoadW	r7,ipAddr	;load at absolute address
	LoadB	r0L,ST_LD_AT_ADDR
	jsr	GetFile
	txa
	beq	@40
	jmp	errHndlr
@40:	jsr	cfg2ip65	;copy loaded config to ip65
	ldy	#K_CINIT	;initialize network card
	jsr	ip65	;(to set MAC address)
	ldy	#K_SINIT	;initialize IP stack variables
	jsr	ip65
	lda	dhcp
	beq	@50
	ldy	#K_DINIT	;initialize DHCP (get address)
	jsr	ip65	
	bcc	@50
	LoadW	errorMsg,noDhcp	 ;DHCP request failed
	LoadW	r0,errorDB
	jsr	DoDlgBox
	LoadW	r7,modLoad
	lda	#MOD_SETUP
	sec
	jsr	swapMod	;swap in settings mod
	jmp	modLoad	;and jump to its init routine
@50:	LoadB	setupOK, $ff
	ldx	#PRC_POLL
	jsr	RestartProcess	;start network card polling
	LoadW	okMsg,setOK
	LoadW	r0,okDB
	jsr	DoDlgBox
	rts

; -----------------------------------------------------------
; Swap in a geoLink VLIR module using track and sector pointers.
; If program module, check to see if already loaded. IP stack and
; mono font are loaded unconditionally by passing carry clear.
;	pass:	.A, module number to load
;		r7, address to load at
;		carry set if program module, clear otherwise
;	return:	r7, end address of load +1
;	destroyed:	a9L
; -----------------------------------------------------------
swapMod:	sta	a9L	;VLIR module number
	php
	bcc	@10
	cmp	curMod	;module already loaded?
	bne	@10
	plp
	rts
@10:	sec
	sbc	#1
	asl	a
	tay
	lda	swapTS,y
	bne	@20
	lda	#2	;invalid track
	bne	@30
@20:	sta	r1L
	lda	swapTS+1,y
	sta	r1H
	;LoadW	r2,($6000-modLoad)
	;LoadW	r2,(modLoad)
	LoadW	r2,$3000
	jsr	ReadFile
	txa
	beq	@40
;	------------------------------------------------
@30:	plp
	jsr	bin2hex
	stx	modErrNo
	sty	modErrNo+1
	lda	a9L	;VLIR module number
	ora	#$30
	sta	badModNo
	LoadW	errorMsg,modErr
	LoadW	r0,errorDB
	jsr	DoDlgBox
	jmp	EnterDeskTop
;	------------------------------------------------
@40:	plp
	bcc	@50
	lda	a9L
	sta	curMod
@50:	rts
; -----------------------------------------------------------
; Imprint area covered by a dialog box to the background screen.
; Used by the IRC module, since it runs without double-buffering.
; -----------------------------------------------------------
impDlg:	LoadB	r2L,DEF_DB_TOP
	LoadB	r2H,DEF_DB_BOT+8	 ;allow for shadow box
	LoadW	r3,DEF_DB_LEFT
	LoadW	r4,DEF_DB_RIGHT+8
	jsr	ImprintRectangle
	rts

; -----------------------------------------------------------
;	get string width
;	pass:	string address in r0
;	return:	string length in pixels in a0
;	destroyed:	a1L
; -----------------------------------------------------------
strWidth:	ldy	#0
	sty	a0L
	sty	a0H
@10:	lda	(r0),y
	beq	@20
	sty	a1L
	jsr	GetCharWidth
	clc
	adc	a0L
	sta	a0L
	lda	#0
	adc	a0H
	sta	a0H
	ldy	a1L
	iny
	bne	@10	; string must be < 256 chars.
@20:	rts
; -----------------------------------------------------------
;	generic error handler
;	pass:	error no. in .a (99 denotes internal error)
;	return:	kills program and exits to deskTop
; -----------------------------------------------------------
errHndlr:	pha
	and	#$F0
	lsr	a
	lsr	a
	lsr	a
	lsr	a
	ora	#$30
	sta	errorNum
	pla
	and	#$0F
	ora	#$30
	sta	errorNum+1
	jsr	beep
	LoadW	r0,fatalDB
	jsr	DoDlgBox
	jsr	CloseRecordFile
	jmp	EnterDeskTop
; -----------------------------------------------------------
;	generic beep
; -----------------------------------------------------------
beep:	lda	$01
	pha
	and	#$f8
	ora	#$05
	sta	$01
	LoadB	$d400,$31	;voice 1 frequency low
	LoadB	$d401,$1c	;voice 1 frequency high
	LoadB	$d405,$00	;voice 1 attack/decay
	LoadB	$d406,$f9	;voice 1 sustain/release
	LoadB	$d418,$0c	;no filters, volume 15
	LoadB	$d404,$11	;gate on triangle, voice 1
	LoadB	$d404,$10	;gate off voice 1
	pla
	sta	$01
	rts	

; -----------------------------------------------------------
; Process for periodic polling of network card.
; -----------------------------------------------------------
netPoll:	lda	ip65Poll	;polling in progress or disabled?
	beq	@10
	rts
@10:	lda	#$ff
	sta	ip65Poll	;set polling in progress flag
	ldy	#K_POLL	;network card polling routine
	jsr	ip65
	bcc	@20	;process packet
	lda	#0
	sta	ip65Poll	;clear polling in progress flag
	rts
@20:	nop		;(stubbed out)
	lda	#0
	sta	ip65Poll	;clear polling in progress flag
	rts
; -----------------------------------------------------------
; Process for sending pings.
; -----------------------------------------------------------
pingSend:	lda	#<pingAddr	;pass address to ping
	ldx	#>pingAddr
	ldy	#K_ICECHO
	jsr	ip65
	bcc	@10
	ldy	#K_GETERR
	jsr	ip65
	and	#$0f
	ora	#$30
	sta	pingErr
	rts
@10:	lda	#0
	sta	pingErr
	rts

; -----------------------------------------------------------
; Call ip65 (wrapper that banks in I/O first). Status flags are retained 
; from call to ip65.
;	pass:	nothing
;	return:	nothing
; -----------------------------------------------------------
ip65:	jsr	bankNet	;bank in I/O space
	jsr	IP65
	jsr	bankRst		;restore memory map
	rts
; -----------------------------------------------------------
; Bank in I/O space to access network card (not re-entrant).
; .A, .X, and .Y are preserved.
; -----------------------------------------------------------
bankNet:	php
	sei
	pha
	lda	$01
	sta	bankSave
	and	#$f8
	ora	#$05
	sta	$01
	pla
	plp
	rts
; -----------------------------------------------------------
bankRst:	php
	sei
	pha
	lda	bankSave
	sta	$01
	pla
	plp
	rts
; -----------------------------------------------------------
bankSave:	.byte	0	;memory bank save

; -----------------------------------------------------------
; Copy application network configuration to ip65.
;	pass:	ip65Cfg holds address of ip65 config area
;	return:	nothing
;	destroyed:	a0, .A, .X, .Y
; -----------------------------------------------------------
cfg2ip65:	MoveW	ip65Cfg,a0
	ldx	#0
	ldy	#6
@10:	lda	ipAddr,x
	sta	(a0),y
	iny
	inx
	cpx	#16
	bne	@10
	ldy	#0
@20:	lda	macAddr,y
	sta	(a0),y
	iny
	cpy	#6
	bne	@20
	rts
; -----------------------------------------------------------
; Copy ip65 network configuration to application settings area.
;	pass:	ip65Cfg holds address of ip65 config area
;	return:	nothing
;	destroyed:	a0, .A, .X, .Y
; -----------------------------------------------------------
cfg2geos:	MoveW	ip65Cfg,a0
	ldy	#6
	ldx	#0
@10:	lda	(a0),y
	sta	ipAddr,x
	iny
	inx
	cpx	#16
	bne	@10
	ldy	#0
@20:	lda	(a0),y
	sta	macAddr,y
	iny
	cpy	#6
	bne	@20
	rts

; -----------------------------------------------------------
mainMenu:	.byte	0,14
	.word	0,67
	.byte	HORIZONTAL | 2
;	------------------------------------------------
	.word	geosText
	.byte	SUB_MENU
geosWord:	.word	geosMenu
;	------------------------------------------------
	.word	optText
	.byte	SUB_MENU
optWord:	.word	optMenu	;or deadMenu
;	------------------------------------------------
geosText:	.byte	"geos",0
optText:	.byte	"options",0
; -----------------------------------------------------------
geosMenu:	.byte	15,30
	.word	0,24
	.byte	VERTICAL | CONSTRAINED | 1
;	------------------------------------------------
	.word	infoText
	.byte	MENU_ACTION
	.word	doInfo
;	------------------------------------------------
infoText:	.byte	"info",0

; -----------------------------------------------------------
optMenu:	.byte	15,72
	.word	28,67
	.byte	VERTICAL | CONSTRAINED | 4
;	------------------------------------------------
	.word	setupText
	.byte	MENU_ACTION
	.word	doSetup
;	------------------------------------------------
	.word	pingText
	.byte	MENU_ACTION
	.word	doPing
;	------------------------------------------------
	.word	ircText
	.byte	MENU_ACTION
	.word	doIRC
;	------------------------------------------------
	.word	quitText
	.byte	MENU_ACTION
	.word	doQuit
;	------------------------------------------------
setupText:	.byte	"setup",0
pingText:	.byte	"ping",0
ircText:	.byte	"IRC",0
quitText:	.byte	"quit",0
; -----------------------------------------------------------
deadMenu:	.byte	15,72
	.word	28,67
	.byte	VERTICAL | CONSTRAINED | 4
;	------------------------------------------------
	.word	deadSetup
	.byte	MENU_ACTION
	.word	dummy
;	------------------------------------------------
	.word	deadPing
	.byte	MENU_ACTION
	.word	dummy
;	------------------------------------------------
	.word	deadIRC
	.byte	MENU_ACTION
	.word	dummy
;	------------------------------------------------
	.word	deadQuit
	.byte	MENU_ACTION
	.word	dummy
;	------------------------------------------------
deadSetup:	.byte	ITALICON,"setup",PLAINTEXT,0
deadPing:	.byte	ITALICON,"ping",PLAINTEXT,0
deadIRC:	.byte	ITALICON,"IRC",PLAINTEXT,0
deadQuit:	.byte	ITALICON,"quit",PLAINTEXT,0

; -----------------------------------------------------------
; dummy icon table (no icons)
; ------------------------------------------------------------
noIcons:	.byte	1	; one (dummy) icon
	.word	20	; Y-pos. to leave cursor
	.byte	6	; X-pos. to leave cursor
	.word	0	; no graphics data
; ------------------------------------------------------------
; GEOS version advisory dialog box
; ------------------------------------------------------------
versDB:	.byte	DEF_DB_POS | 1
	.byte	DBTXTSTR,14,28
	.word	thisVer
	.byte	DBTXTSTR,14,42
versMsg:	.word	0	;filled in by caller
	.byte	OK,16,72
	.byte	0
thisVer:	.byte	"You are running GEOS "
verHi:	.byte	"0."
verLo:	.byte	"0",0
loVers:	.byte	"This program requires version 2.0.",0
hiVers:	.byte	"This version is not supported.",0
; ------------------------------------------------------------
; "info" dialog box
; ------------------------------------------------------------
infoDB:	.byte	DEF_DB_POS | 1
	.byte	OK,16,72
	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_1_Y
	.word	infoMsg1
	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_2_Y
	.word	infoMsg2
	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_3_Y
	.word	infoMsg3
	.byte	DBTXTSTR,TXT_LN_X,TXT_LN_4_Y
	.word	infoMsg4
	.byte	0
infoMsg1:	.byte	"geoLink 1.01 (running under GEOS "
iVerHi:	.byte	"0."
iVerLo:	.byte	"0)",0
infoMsg2:	.byte	"code: ShadowM",0
infoMsg3:	.byte	"network stack: ip65",0
infoMsg4:	.byte	"(Per Olofsson, Jonno Downes)",0
; -----------------------------------------------------------
; error dialog box
; -----------------------------------------------------------
errorDB:	.byte	DEF_DB_POS | 1
	.byte	OK,2,72
	.byte	DBTXTSTR,14,28
errorMsg:	.word	0
	.byte	DB_USR_ROUT
	.word	beep
	.byte 0
; -----------------------------------------------------------
; success dialog box
; -----------------------------------------------------------
okDB:	.byte	DEF_DB_POS | 1
	.byte	OK,2,72
	.byte	DBTXTSTR,14,28
okMsg:	.word	0
	.byte 0

; ------------------------------------------------------------
; settings file open dialog box
; ------------------------------------------------------------
setDB:	.byte	SET_DB_POS | 1
	.byte	32,137
	.word	64,255
	.byte	DBTXTSTR,4,11
	.word	setSelct
	.byte	DBGETFILES,4,14
	.byte	OPEN,DBI_X_2,14
	.byte	CANCEL,DBI_X_2,38
	.byte	0
setSelct:	.byte	"Select settings file:",0
; ------------------------------------------------------------
; fatal error dialog box
; ------------------------------------------------------------
fatalDB:	.byte	DEF_DB_POS | 1
	.byte	OK,2,72
	.byte	DBTXTSTR,14,28
	.word	fatalMsg
	.byte	DB_USR_ROUT
	.word	beep
	.byte	0
; -----------------------------------------------------------
; Process table
; -----------------------------------------------------------
procNet:	.word	netPoll	;poll network card
	.word	10	;every 1/6 second
	.word	pingSend	;send ICMP ping request
	.word	60	;every second
	.word	autoProc	;IRC auto-send timeout
	.word	60	;every second
; -----------------------------------------------------------
autoProc:	jmp	(autoVect)
autoVect:	.res	2

fatalMsg:	.byte	BOLDON,"Error "
errorNum:	.byte	0,0,", returning to deskTop.",PLAINTEXT,0
noCard:	.byte	"Network card not found.",0
modErr:	.byte	"Error $"
modErrNo:	.res	2
	.byte	" loading module "
badModNo:	.res	1
	.byte	", aborting!",0
ip65Poll:	.byte	0	;flag: network polling in progress
ip65Cfg:	.res	2	;ip65 settings address
fileName:	.res	17	;generic filename buffer
permName:	.byte	"geoLink     V1.0",0 ;permanent name string
setName:	.res	17	;settings filename
;note that the following perm string is in the setup module as well:
setPerm:	.byte	"geoLinkSettingsV1.0",0  ;permanent name string
setOK:	.byte	"Network settings loaded.",0
setupOK:	.byte	0
noDhcp:	.byte	"DHCP timeout.",0
yesDhcp:	.byte	"DHCP request successful.",0
ipAddr:	.res	4
netmask:	.res	4
gateway:	.res	4
dnsAddr:	.res	4
macAddr:	.res	6
dhcp:	.byte	0	;flag: DHCP in use
pingAddr:	.res	4	;address to ping
pingErr:	.res	1	;set by ping process
server:	.res	25	;these four copied from IRC login module
port:	.res	6
nick:	.res	NICKLEN+1
passwd:	.res	10
swapTS:	.res	NUM_MODS*2	;T&S pointers for VLIR mods
curMod:	.res	1	;currently loaded VLIR mod
DA0Text:	.res	17
DA1Text:	.res	17
DA2Text:	.res	17
DA3Text:	.res	17
DA4Text:	.res	17
DA5Text:	.res	17
DA6Text:	.res	17
; -----------------------------------------------------------
bServer:	.res	4
bPort:	.res	2
dnsStrc:	.res	4	;DNS structure
udLStrc:	.res	4	;UDP listener structure
udpStrc:	.res	4	;remote IP address
	.res	2	;remote port
	.res	2	;local port
	.res	2	;payload length
	.res	2	;pointer to payload
tcpStrc:	.res	4	;remote IP address
	.res	2	;remote port
	.res	2	;local port
	.res	2	;payload length
	.res	2	;pointer to payload
ipData:	.res	PKTSIZE	;IP payload data
tcpConn:	.res	8	;TCP connection structure
tcpSend:	.res	4	;TCP packet send structure
tcpCbAdr:	.res	2	;TCP callback routine address
chatting:	.byte	0	;chat loop in progress?
debug:	.byte	0	;debug output enabled?
motd:	.byte	0	;show MOTD messages?

