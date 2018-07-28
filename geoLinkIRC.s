; -----------------------------------------------------------
; geoLink: A networked GEOS application for the Commodore 64 
;          which includes an IRC client.
;
; Written by Glenn Holmer (a.k.a "Shadow", a.k.a "Cenbe")
; -----------------------------------------------------------

; MOD_IRC
.segment	"OVERLAY4"

; Contains:
; geoLinkIRC.s
; geoLinkParse.s
; geoLinkText.s
; geoLinkIRCd.s

; -----------------------------------------------------------
; geoLinkIRC (IRC module for geoLink)
; -----------------------------------------------------------	
	.include	"geoLink.inc"
	.include	"geosmac.inc"
	.include	"geossym.inc"
	.include	"geossym2.inc"
	.include	"const.inc"
	.include	"jumptab.inc"
	
	.import		beep
	.import		debug
	.import		optMenu
	.import		bankNet
	.import		tcpStrc
	.import		bankRst
	.import		tcpSend
	.import		byte2asc
	.import		ipAddr
	.import		nick
	.import		ipData
	.import		errorDB
	.import		impDlg
	.import		errorMsg
	.import		bin2hex
	.import		strWidth
	.import		ip65
	.import		bPort
	.import		tcpConn
	.import		bServer
	.import		swapMod
	.import		geosMenu
	.import		chatting
	.import		autoVect
	.import		mainMenu
	.import		optWord
	.import		geosWord

; -----------------------------------------------------------
MOD_FONT	=	8	;VLIR record for mono font
SCR_WD	=	40	;width of text area in cards
SCR_FROM	=	24	;scan line to scroll from
SCR_TO	=	15	;scan line to scroll to
SCR_AMT	=	160	;scroll amount in scan lines
TXT_AREA	=	184	;top of text input area
; -----------------------------------------------------------
modIRC:	jsr	loadVip	;load 8-point mono font
	bcc	@10
	rts
@10:	lda	#2	;50% stipple
	jsr	SetPattern
	LoadB	r2L,15	;don't erase menu
	LoadB	r2H,199
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;clear screen
	LoadB	geosWord-1,DYN_SUB_MENU
	LoadW	geosWord,impGeos
	LoadB	optWord-1,DYN_SUB_MENU
	LoadW	optWord,impIrc
	LoadW	r0,mainMenu
	lda	#1
	jsr	DoMenu	;only option is "logout"	
	LoadB	dispBufferOn,ST_WR_FORE
	MoveB	mainMenu,r2L
	MoveB	mainMenu+1,r2H
	MoveW	mainMenu+2,r3
	MoveW	mainMenu+4,r4
	jsr	ImprintRectangle	;avoid screen corruption
	jsr	titleBar
	jsr	textArea	;calls DoIcons
	LoadW	r0,vipFont
	jsr	LoadCharSet
	ldx	#SCR_FROM	;save scan line addresses
	jsr	GetScanLine
	MoveW	r5,scrFrom
	ldx	#SCR_TO
	jsr	GetScanLine
	MoveW	r5,scrTo
	lda	#0
	sta	nickSent
	sta	userSent
	sta	autoWait
	sta	autoTry
	jsr	connect	;TCP/IP connection to server
	bcc	@20
	jsr	showErr
	jmp	enablOpt	;bail
@20:	LoadW	autoVect,autoSend
	ldx	#PRC_AUTO	
	jsr	RestartProcess
	LoadB	chatting,$ff	;(in resident module)
	jsr	getInput	;start chatting
	rts

; -----------------------------------------------------------
; DYN_SUB_MENU handlers to imprint the area covered by a 
; submenu to the background screen before it is drawn. This makes 
; it possible to turn of double-buffering for greater speed.
; -----------------------------------------------------------
impGeos:	LoadB	r2L,0
	MoveB	geosMenu+1,r2H
	LoadW	r3,0
	MoveW	geosMenu+4,r4
	jsr	ImprintRectangle
	LoadW	r0,geosMenu	;actual submenu table
	rts
impIrc:	LoadB	r2L,0
	MoveB	ircMenu+1,r2H
	LoadW	r3,0
	MoveW	ircMenu+4,r4
	jsr	ImprintRectangle
	LoadW	r0,ircMenu
	rts
; -----------------------------------------------------------
; Load 8-point monospace font.
; -----------------------------------------------------------
loadVip:	LoadW	r7,vipFont
	lda	#MOD_FONT
	clc
	jsr	swapMod
@30:	MoveW	r7,fontEnd
	clc
	rts
; -----------------------------------------------------------
; Open a TCP connection to the server.
;	return:	Carry set on error, clear otherwise.
;		On error, .A contains ip65 error number.
; -----------------------------------------------------------
connect:	LoadW	a3,connMsg
	jsr	putMsg
	ldx	#PRC_POLL
	jsr	EnableProcess
	jsr	RestartProcess	;restart polling
	ldx	#3
@10:	lda	bServer,x
	sta	tcpConn,x
	dex
	bpl	@10
	ldx	bPort
	ldy	bPort+1
	stx	tcpConn+4
	sty	tcpConn+5
	LoadW	tcpConn+6,recvMsg	 ;packet receive handler
	lda	#<tcpConn
	ldx	#>tcpConn
	ldy	#K_TCCONN
	jsr	ip65
	bcs	@20
	rts
@20:	ldy	#K_GETERR
	jsr	ip65
	sec
	rts

; -----------------------------------------------------------
; Draw title bar at top of screen.
; -----------------------------------------------------------
titleBar:	lda	#9	;horizontal stripes
	jsr	SetPattern
	LoadB	r2L,0
	LoadB	r2H,14
	lda	mainMenu+4	;width of main menu
	clc
	adc	#1
	sta	r3L
	lda	mainMenu+5
	adc	#0
	sta	r3H
	LoadW	r4,319
	jsr	Rectangle
	lda	#0
	jsr	SetPattern	;reset to clear
	lda	curChan	;add current channel to title
	beq	@30
	ldx	#0
@10:	lda	curChan,x
	beq	@20
	sta	chanTitl,x
	inx
	bne	@10
@20:	lda	#']'
	sta	chanTitl,x
	inx
	lda	#' '
	sta	chanTitl,x
	inx
	lda	#0
	sta	chanTitl,x
	beq	@50
@30:	ldx	#0
@40:	lda	noChan,x
	sta	chanTitl,x
	beq	@50
	inx
	bne	@40
@50:	LoadW	r0,title
	jsr	strWidth	;returns string width in a0
	LoadB	r1H,10
	LoadW	r11,320
	SubW	mainMenu+4,r11	;320 - menu width
	SubW	a0,r11	;minus string width
	clc
	ror	r11H
	ror	r11L	;divided by two
	AddW	mainMenu+4,r11	;plus menu width (i.e. right edge)
	PushW	rightMargin	;first time through, the margin
	LoadW	rightMargin,318	;is still set from the login screen
	jsr	PutString
	PopW	rightMargin
	rts

; -----------------------------------------------------------
; Draw text input area at bottom of screen.
; -----------------------------------------------------------
textArea:	lda	#0	;clear
	jsr	SetPattern
	LoadB	r2L,15
	LoadB	r2H,TXT_AREA-1
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;text display area
	LoadW	r3,0
	LoadW	r4,319
	LoadW	r11L,TXT_AREA
	lda	#$ff	;solid line
	jsr	HorizontalLine
	LoadB	r2L,TXT_AREA+3
	LoadB	r2H,TXT_AREA+13
	LoadW	r3,TXT_LEDG
	LoadW	r4,TXT_REDG
	jsr	Rectangle	;text input area
	LoadB	r2L,TXT_AREA+3
	LoadB	r2H,TXT_AREA+13
	LoadW	r3,TXT_LEDG
	LoadW	r4,TXT_REDG
	lda	#$ff	;solid line
	jsr	FrameRectangle
	LoadW	r0,sndIcons
	jsr	DoIcons
	rts

; -----------------------------------------------------------
; Process handler for auto-login. Wait five seconds from last packet
; received before sending NICK and USER.
; -----------------------------------------------------------
autoSend:	inc	autoWait	;set to 0 by recvMsg
	lda	nickSent
	bne	@30	;nick already sent
	lda	autoWait
	cmp	#3	;time to send nick?
	bcs	@10
	rts
@10:	jsr	sendNick
	bcc	@20
	inc	autoTry
	ldx	autoTry
	cpx	#3
	bcs	@80	;three strikes and you're out!
	bcc	@60	;retry
@20:	ldx	#0
	stx	autoWait
	stx	autoTry
	inx
	stx	nickSent
	rts
@30:	lda	autoWait
	cmp	#3	;time to send USER command?
	bcs	@40
	rts
@40:	jsr	sendUser
	bcc	@50
	inc	autoTry
	ldx	autoTry
	cpx	#3
	bcs	@80	;three strikes and you're out!
	bcc	@60	;retry
@50:	ldx	#PRC_AUTO	;NICK, USER sent successfully
	jsr	BlockProcess
	ldx	#0
	stx	autoWait
	inx
	stx	userSent
	jsr	scroll
	LoadW	a3,connDone
	jsr	putMsg
	rts

;	------------------------------------------------
@60:	jsr	scroll	;retry
	jsr	bin2hex
	stx	retryErr
	sty	retryErr+1
	LoadW	a3,retrying
	jsr	putMsg
	ldy	#K_TCCLS
	jsr	ip65
	jsr	scroll	;for connect message
	jsr	connect
	bcc	@70
	jsr	showErr
	jmp	enablOpt
@70:	ldx	#0
	stx	nickSent
	stx	userSent
	stx	autoWait
	rts
;	------------------------------------------------
@80:	LoadW	errorMsg,givingUp	 ;abort
	jsr	impDlg
	LoadW	r0,errorDB
	jsr	DoDlgBox
	ldx	#PRC_AUTO
	jsr	BlockProcess
	jmp	enablOpt
; -----------------------------------------------------------
; Send NICK command at start of connection.
; -----------------------------------------------------------
sendNick:	jsr	scroll
	LoadW	a3,aNickMsg
	jsr	putMsg
	ldx	#0
	ldy	#0
@10:	lda	nickCmd,y
	beq	@20
	sta	ipData,x
	inx
	iny
	bne	@10
@20:	ldy	#0
@30:	lda	nick,y
	beq	@40
	sta	ipData,x
	inx
	iny
	bne	@30
@40:	lda	#$0d
	sta	ipData,x
	inx
	lda	#$0a
	sta	ipData,x
	inx
	jsr	sendData
	rts

; -----------------------------------------------------------
; Send USER command at start of connection.
;	destroyed:	a2,a3L
; -----------------------------------------------------------
sendUser:	jsr	scroll
	LoadW	a3,aUserMsg
	jsr	putMsg
	ldx	#0
	ldy	#0
@10:	lda	userCmd,y
	beq	@20
	sta	ipData,x
	inx
	iny
	bne	@10
@20:	ldy	#0
@30:	lda	nick,y	;login user (n/a)
	beq	@40
	sta	ipData,x
	inx
	iny
	bne	@30
@40:	lda	#' '
	sta	ipData,x
	inx
	stx	a3L
	LoadW	a2,ipData
	ldy	a3L
	jsr	addYa2	;point a2 to where IP should be appended
	jsr	addIpMsg	;leaves a2 pointing past IP
	jsr	addIpMsg
	lda	a2L
	sec
	sbc	#<ipData
	tax		;restore pointer into ipData
	lda	#':'
	sta	ipData,x
	inx
	ldy	#0
@50:	lda	nick,y	;user name (use nick again)
	beq	@60
	sta	ipData,x
	inx
	iny
	bne	@50
@60:	lda	#$0d
	sta	ipData,x
	inx
	lda	#$0a
	sta	ipData,x
	inx
	jsr	sendData
	rts

; -----------------------------------------------------------
; Add host's formatted IP address to a message. Called by sendUser.
;	pass:	a2,pointer into ipData
;	return:	a2 points past the formatted address
; -----------------------------------------------------------
addIpMsg:	ldx	#0	;index into IP address
@10:	lda	ipAddr,x
	jsr	byte2asc	;leaves .Y pointing to null at end
	cpx	#3
	bcc	@20
	lda	#' '
	bne	@30
@20:	lda	#'.'	;build dotted quad
@30:	sta	(a2),y
	iny
	jsr	addYa2
	inx
	cpx	#4
	bne	@10
	rts
; -----------------------------------------------------------
; Show ip65 error in a dialog box.
; 	pass:	.A, ip65 error number (binary)
; -----------------------------------------------------------
showErr:	jsr	bin2hex
	stx	netErrNo
	sty	netErrNo+1
	LoadW	errorMsg,netErr
	jsr	impDlg
	LoadW	r0,errorDB
	jsr	DoDlgBox
	rts

; -----------------------------------------------------------
; Handler for click on Send icon or carriage return in input area.
; -----------------------------------------------------------
iSendMsg:	LoadB	keyData,$0d
	lda	keyVector
	ldx	keyVector+1
	jmp	CallRoutine	;simulate hitting Enter
sendMsg:	lda	inputBuf	;handler for Enter key in text area
	bne	@10
	jsr	getInput	;empty input, ignore and retry
	rts
@10:	lda	#0
	jsr	SetPattern
	LoadB	r2L,TXT_AREA+4
	LoadB	r2H,TXT_AREA+12
	LoadW	r3,TXT_LEDG+1
	LoadW	r4,TXT_REDG-1
	jsr	Rectangle	;clear text input area
	jsr	ckSlash	;check for slash-commands
	bcc	@20	;found a match
	lda	curChan	;currently joined to a channel?
	bne	@15
	jsr	scroll	;no, show error message
	LoadW	a3,notJoin
	jsr	putMsg
	jsr	getInput
	rts
@15:	jsr	doChan	;message to channel
	bcc	@30	;always returns carry clear
@20:	PushW	a3	;trashed if dispatch calls ip65
	jsr	doDsptch
	PopW	a3
	bcs	@40	;anything to send?
@30:	jsr	sendData
@40:	jsr	getInput	;get next line from console
	rts
; -----------------------------------------------------------
; Send data to a server over an open TCP socket.
;	pass:	ipData, data to send
;		.X, length of data to send
;	return:	Carry set on error, clear otherwise
;		On error, .A contains ip65 error number.
; -----------------------------------------------------------
sendData:	stx	tcpSend	;TCP payload length
	lda	#0
	sta	tcpSend+1
	LoadW	tcpSend+2,ipData
	lda	#<tcpSend	;send IRC packet
	ldx	#>tcpSend
	ldy	#K_TCSEND
	jsr	ip65
	bcc	@10	;wait for server response
	ldy	#K_GETERR
	jsr	ip65	;returns error code in .A
	sec
@10:	rts

; -----------------------------------------------------------
; Handler for TCP packet receive from server. Since this routine is 
; called from a process handler that banked in I/O, it has to 
; restore the GEOS memory map and bank I/O back in afterward.
; -----------------------------------------------------------
recvMsg:	jsr	bankRst	;restore GEOS memory map
	lda	#<tcpStrc
	ldx	#>tcpStrc
	ldy	#K_PACKET
	jsr	ip65
	bcc	@20
	ldy	#K_GETERR
	jsr	ip65	;returns error code in .A
	jsr	showErr
	jsr	enablOpt	;abort
	jsr	bankNet
	rts		;back to ip65
@20:	MoveW	tcpStrc+10,a2	;packet address
	AddW	tcpStrc+8,a2	;packet length (may be > 256)
	lda	#0
	tay
	sta	(a2),y	;null-terminate for parsing
	MoveW	tcpStrc+10,a2	;a2 points to input packet
@40:	jsr	parseLin	;assembled line at ircMesg, next line §§a3
	bcs	@60	;no next line
	PushW	a3	;trashed if dispatch calls ip65
	LoadW	a2,ircMesg	;needed for parseCmd
	jsr	parseCmd	;get prefix, command
	jsr	matchCmd	;get dispatch routine address
	bcs	@50	;no match
	jsr	doDsptch	;does JMP (dispatch) and RTS
	bcs	@50	;anything to display?
	jsr	scroll	;scroll up existing messages
	jsr	strip	;strip control chars and >= 127
	jsr	showMsg	;show new message (uses a3)
@50:	PopW	a3
	MoveW	a3,a2	;a2 to next line (or null)
	bra	@40
@60:	LoadB	autoWait,0	;reset auto NICK/USER counter
	jsr	bankNet	;bank I/O back in
	rts		;and return to ip65

; -----------------------------------------------------------
; Strip control chars and chars > 127 from the output buffer before
; displaying to screen (but allow BOLDON, ITALICON, and PLAINTEXT).
;	pass:	a3, output buffer
;	return:	output buffer stripped
;	destroyed:	a4
; -----------------------------------------------------------
strip:	PushB	a3H
	ldy	#0
@10:	lda	(a3),y
	beq	@30
	jsr	isJunk
	bcs	@20
	iny
	bne	@10
	inc	a3H
	bne	@10
@20:	tya
	tax		;save
	jsr	suckJunk
	txa
	tay		;restore
	bra	@10
@30:	lda	#PLAINTEXT	;cowardly hack
	sta	(a3),y
	iny
	lda	#0
	sta	(a3),y
	PopB	a3H
	rts
;	------------------------------------------------
isJunk:	cmp	#' '
	bcs	@10
	cmp	#BOLDON
	beq	@20
	cmp	#ITALICON
	beq	@20
	cmp	#PLAINTEXT
	beq	@20
	sec		;control char, purge
	rts
@10:	cmp	#$7f
	bcc	@20
	sec		;char is >= 127, purge
	rts
@20:	clc		;OK to display
	rts
;	------------------------------------------------
suckJunk:	PushB	a3H
	MoveW	a3,a4
	inc	a4L
	bne	@10
	inc	a4H
@10:	lda	(a4),y
	sta	(a3),y
	beq	@20
	iny
	bne	@10
	inc	a3H
	inc	a4H
	bne	@10
@20:	PopB	a3H
	rts

; -----------------------------------------------------------
; Re-enable options menu. Used for logout menu option or when
; this module must be aborted due to a network error.
; -----------------------------------------------------------
enablOpt:	jsr	GotoFirstMenu
	ldx	#PRC_AUTO
	jsr	BlockProcess
	LoadB	chatting,0	;break chat loop
	LoadB	inputBuf,0	;empty input buffer
	php
	sei
	jsr	PromptOff
	LoadB	alphaFlag,0	;turn off text cursor
	LoadW	keyVector,0	;and keyboard input
	plp
	ldy	#K_TCCLS	;close TCP connection
	jsr	ip65
	LoadB	dispBufferOn,(ST_WR_FORE | ST_WR_BACK)
	lda	#2	;50% stipple
	jsr	SetPattern
	LoadB	r2L,0
	LoadB	r2H,199
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;clear screen
	jsr	UseSystemFont
	LoadB	geosWord-1,SUB_MENU
	LoadW	geosWord,geosMenu
	LoadB	optWord-1,SUB_MENU
	LoadW	optWord,optMenu
	LoadW	r0,mainMenu
	lda	#1
	jsr	DoMenu	;re-enable options menu
	rts

	
; -----------------------------------------------------------
; geoLinkParse.s
; -----------------------------------------------------------


; -----------------------------------------------------------
; Parse out a line from the IRC server and assemble at ircMesg.
; A single packet from the server may contain multiple lines, and
; individual lines may be greater than 256 chars. A line may span
; two packets; in this case (since we null-terminate the packet),
; the last message will end with null rather than CR/LF. Note that
; a line can be split between the CR and the LF.
;	pass:	a2, start of input area to parse
;	return:	carry set if no next line, clear otherwise
;		ircMesg holds parsed line (may be incomplete)
;		a3 points to following line (or null)
;		mesgPtr, next line or continuation address
;	destroyed:	a2, a4 (temporary pointer into ircMesg)
; -----------------------------------------------------------
parseLin:	MoveW	mesgPtr,a4	;may have been set for continuation
	LoadW	mesgPtr,ircMesg	;restore unconditionally
	ldy	#0
	lda	(a2),y
	bne	@5
	sec		;no next line
	rts
@5:	cmp	#$0a	;delimiter was split across packets?
	bne	@10
	inc	a2L	;walk past it
	bne	@10
	inc	a2H
@10:	lda	(a2),y
	bne	@15
	tya		;partial message (end of packet)
	clc
	adc	a4L
	sta	mesgPtr	;save continuation pointer
	lda	a4H
	adc	#0
	sta	mesgPtr+1
	sec		;complete when next packet arrives
	rts
@15:	cmp	#$0d	;CR
	beq	@20
	sta	(a4),y
	jsr	incPtr
	bra	@10
@20:	lda	#0
	sta	(a4),y	;null-terminate
	jsr	incPtr		;LF
	lda	(a2),y	;delimiter split across packets?
	bne	@30
	jsr	incPtr
	lda	#0
	sta	(a2),y	;yes, add another "fake" terminator
	beq	@40
@30:	jsr	incPtr		;next line or null
@40:	tya
	clc
	adc	a2L
	sta	a3L	;pointer to following line
	lda	a2H
	adc	#0
	sta	a3H
	clc
	rts
; -----------------------------------------------------------
incPtr:	iny
	bne	@10
	inc	a2H	;overflow!
	inc	a4H
@10:	rts

; -----------------------------------------------------------
; Parse prefix (if present) and IRC command from an input line.
;	pass:	a2 points to input line (null-terminated)
;	return:	from: source (may be truncated server name)
;		command: IRC command
;		a2 points to command parameters
; -----------------------------------------------------------
parseCmd:	lda	#0
	ldx	#NICKLEN
@10:	sta	from,x
	sta	command,x
	dex
	bpl	@10
	tax
	tay
	lda	(a2),y
	cmp	#':'	;prefix present?
	bne	@70
	iny
@30:	lda	(a2),y	;get source
	cmp	#'!'	;end of nick?
	bne	@35
@33:	iny
	lda	(a2),y
	cmp	#' '	;walk past server name
	beq	@50
	bne	@33
@35:	cmp	#' '	;end of server name (no nick)?
	beq	@50
	sta	from,x
	cpx	#NICKLEN
	bcs	@40	;truncate server names
	inx
@40:	iny
	bne	@30
@50:	lda	#0
	sta	from,x	;null-terminate
	ldx	#0
	iny
@60:	lda	(a2),y
	cmp	#' '	;allow for multiple spaces
	bne	@70
	iny
	bne	@60
@70:	sta	command,x
	cpx	#NICKLEN	;command too long?
	bcs	@75
	inx
@75:	iny
	lda	(a2),y
	cmp	#' '
	bne	@70
	lda	#0
	sta	command,x	;null-terminate
	iny
@80:	lda	(a2),y
	cmp	#' '	;allow for multiple spaces
	bne	@90
	iny
	bne	@80
@90:	jsr	addYa2	;point a2 at parameters
	rts

; -----------------------------------------------------------
; Find an IRC command in the dispatch table (input).
;	pass:	command: the command
;	return:	carry set if not found, clear otherwise
;		dispatch: dispatch routine vector if found
; -----------------------------------------------------------
matchCmd:	ldx	#0
	ldy	#0
	lda	command,x
	cmp	#'0'
	bcc	@10
	cmp	#'9'+1
	bcc	@20
@10:	jsr	txtCmd
	rts
@20:	jsr	cmdToBin	;convert numeric command
	jsr	numCmd
	rts
; -----------------------------------------------------------
; Convert numeric command to binary word.
; Numeric IRC commands are three ASCII digits (per RFC).
;	pass:	command: the numeric commad
;	return:	cmdNum: the command as a binary word
;	destroyed:	a8,a9
; -----------------------------------------------------------
cmdToBin:	lda	command
	and	#$0f
	sta	a8L
	lda	#0
	sta	a8H
	LoadB	a9,100	;multiply first digit by 100
	ldx	#a8	;result
	ldy	#a9
	jsr	BBMult
	MoveW	a8,cmdNum
	lda	command+1
	and	#$0f
	sta	a8L
	lda	#0
	sta	a8H
	LoadB	a9,10	;multiply second digit by 10
	ldx	#a8	;result
	ldy	#a9
	jsr	BBMult
	AddW	a8,cmdNum
	lda	command+2	;one's place
	and	#$0f
	clc
	adc	cmdNum
	sta	cmdNum
	lda	cmdNum+1
	adc	#0
	sta	cmdNum+1
	rts

; -----------------------------------------------------------
; Find the dispatch address for a text command from the server.
;	pass:	command: the text command
;	return:	carry set if not found, clear otherwise
;		.A/.X dispatch routine vector if found
;	destroyed: a8, a9
; -----------------------------------------------------------
txtCmd:	ldy	#0
	sty	cmdIndex
@10:	LoadW	a8,command
	lda	cmdAddrs,y
	sta	a9L
	iny
	lda	cmdAddrs,y
	sta	a9H
	iny
	sty	cmdIndex
	ldx	#a8
	ldy	#a9
	jsr	CmpString
	beq	@30
@20:	ldy	cmdIndex	;next command
	cpy	#NUM_CMDS*2
	bne	@10
; for now...	sec		;end of table, not found
	lda	#<debugOut
	ldx	#>debugOut
	sta	dispatch
	stx	dispatch+1
	clc
	rts
@30:	ldy	cmdIndex	;points to next command
	dey		;back up to found command
	lda	cmdVects,y
	sta	dispatch+1
	dey
	lda	cmdVects,y
	sta	dispatch
	clc
	rts

; -----------------------------------------------------------
; Find the dispatch address for a numeric command from the server.
;	pass:	cmdNum: command, converted to binary 
;	return:	carry set if not found, clear otherwise
;		.A/.X dispatch routine vector if found
; -----------------------------------------------------------
numCmd:	CmpWI	cmdNum,372	;motd
	beq	@10
	CmpWI	cmdNum,400
	bcs	@30
	CmpWI	cmdNum,353	;NAMES
	bne	@10
	lda	#<doNamed
	ldx	#>doNamed
	bne	@20
@10:	lda	#<debugOut
	ldx	#>debugOut
@20:	sta	dispatch
	stx	dispatch+1
	clc
	rts
;	------------------------------------------------
@30:	CmpWI	cmdNum,600	;400-600 are error messages
	bcs	@40
	lda	#<doError
	ldx	#>doError
	bne	@20
@40:	sec
	rts
; -----------------------------------------------------------
; Run dispatch routine.
; -----------------------------------------------------------
doDsptch:	jmp	(dispatch)	;assumes it ends w/RTS
	rts
; -----------------------------------------------------------
; Debug output. If debugging is enabled, print the current command,
; else return and do nothing.
; -----------------------------------------------------------
debugOut:	lda	debug
	beq	@10
	LoadW	a3,command
	clc		;print current command
	rts
@10:	sec		;no printing
	rts

; -----------------------------------------------------------
; Dispatch routines for commands received from server. 
; For all routines:
;	pass:	a2, command parameters
;	return:	carry set if nothing to display, clear otherwise
;		a3 points to formatted message to display
;	destroyed:	a8, a9 (some routines only)
; -----------------------------------------------------------
makeMotd:	ldy	#0
@10:	lda	(a2),y
	cmp	#':'
	beq	@20
	iny
	bne	@10
@20:	iny	
	iny
	iny		;past ":- "
	tya
	clc
	adc	a2L
	sta	a3L
	lda	a2H
	adc	#0
	sta	a3H
	clc		;something to display
	rts
; -----------------------------------------------------------
doPong:	MoveW	tcpStrc+10,a2
	ldy	#1
	lda	#'O'	;PING -> PONG
	sta	(a2),y
	dey
@10:	lda	(a2),y
	beq	@20
	sta	ipData,y
	iny
	bne	@10
@20:	lda	#$0d	;put back CR/LF
	sta	ipData,y
	iny
	lda	#$0a
	sta	ipData,y
	iny
	tya
	tax
	jsr	sendData	;(a3 trashed)
	sec		;nothing to display
	rts

; -----------------------------------------------------------
doPriv:	ldx	#0
	ldy	#0
	stx	pm
	stx	action
@10:	lda	(a2),y
	cmp	#' '
	beq	@30
	sta	to,x
	cmp	curChan,x
	beq	@20
	inc	pm
@20:	inx
	iny
	bne	@10
@30:	iny
	lda	(a2),y
	cmp	#':'
	bne	@30
	iny
	sty	cmdIndex	;first char of message
	ldx	#0
@40:	lda	actCmd,x
	beq	@50	;is an action
	cmp	(a2),y
	bne	@60	;not an action
	inx
	iny
	bne	@40
@50:	lda	(a2),y
	cmp	#' '
	bne	@55
	iny
	bne	@50
@55:	sty	cmdIndex
	inc	action
;	------------------------------------------------
@60:	LoadW	a3,ircOut
	ldx	#0
	ldy	#0
	lda	action	;message for ACTION command?
	beq	@70
	lda	#'*'
	sta	(a3),y
	iny
	lda	#BOLDON
	sta	(a3),y
	iny
@70:	lda	pm	;private message?
	beq	@80
	lda	#ITALICON
	sta	(a3),y
	iny
@80:	lda	from,x
	beq	@90
	sta	(a3),y
	inx
	iny
	bne	@70
@90:	lda	action
	beq	@100
	lda	#PLAINTEXT
	bne	@110
@100:	lda	#':'
@110:	sta	(a3),y
	iny
	lda	#' '
	sta	(a3),y
	iny
	sty	msgIndex
	ldy	cmdIndex
	jsr	addYa2
	jsr	copyCmd
	clc		;something to display
	rts
; -----------------------------------------------------------
doJoined:	LoadW	a4,hasJoin	;note that a4 is trashed!
	jsr	joinPart
	rts
; -----------------------------------------------------------
doParted:	LoadW	a4,hasPart	;note that a4 is trashed!
	jsr	joinPart
	rts
; -----------------------------------------------------------
doQuited:	LoadW	a4,hasQuit
	jsr	joinPart
	rts
; -----------------------------------------------------------
joinPart:	LoadW	a3,ircOut
	ldx	#0
	ldy	#0
@10:	lda	from,x	;person joining or parting
	sta	(a3),y
	beq	@20
	inx
	iny
	bne	@10
@20:	sty	msgIndex
	ldy	#0
	sty	cmdIndex
@30:	lda	(a4),y
	beq	@40
	ldy	msgIndex
	sta	(a3),y
	inc	msgIndex
	inc	cmdIndex
	ldy	cmdIndex
	bne	@30
@40:	ldx	#0
	ldy	#0
	sty	cmdIndex
@50:	lda	(a2),y	;channel name
	beq	@70
	cmp	#':'	;ignore leading colon
	beq	@60
	sta	tempChan,x
	inx
	ldy	msgIndex
	sta	(a3),y
	inc	msgIndex
@60:	inc	cmdIndex
	ldy	cmdIndex
	bne	@50
@70:	sta	tempChan,x
	ldy	msgIndex
	sta	(a3),y	;null-terminate message
	LoadW	a8,from
	LoadW	a9,nick	;was it us?
	ldx	#a8L
	ldy	#a9L
	jsr	CmpString
	bne	@110
	lda	curChan
	beq	@80	;no current channel, don't check
	LoadW	a8,curChan
	LoadW	a9,tempChan
	ldx	#a8L
	ldy	#a9L
	jsr	CmpString
	bne	@110
	CmpWI	a4,hasJoin
	bne	@90
	ldx	#0
@80:	lda	tempChan,x
	sta	curChan,x
	beq	@100
	inx
	bne	@80
@90:	lda	#0
	sta	curChan
@100:	jsr	UseSystemFont
	jsr	titleBar
	LoadW	r0,vipFont
	jsr	LoadCharSet
@110:	clc		;something to display
	rts
; -----------------------------------------------------------
doKicked:	LoadW	a3,ircOut
	ldx	#0
	ldy	#0
@10:	lda	(a2),y	;step past channel name
	cmp	#' '
	beq	@20
	iny
	bne	@10
@20:	lda	(a2),y
	cmp	#' '
	bne	@30
	iny
	bne	@20
@30:	lda	(a2),y
	cmp	#' '
	beq	@40
	sta	to,x	;person kicked
	inx
	iny
	bne	@30
@40:	lda	#0
	sta	to,x
@45:	lda	(a2),y
	cmp	#':'
	beq	@50
	iny
	bne	@45
@50:	iny
	sty	cmdIndex	;reason for kick

;	------------------------------------------------
	ldx	#0	;construct "kicked" message
	ldy	#0
@60:	lda	to,x	;person kicked
	beq	@70
	sta	(a3),y
	inx
	iny
	bne	@60
@70:	ldx	#0
@75:	lda	hasKick,x
	beq	@80
	sta	(a3),y
	inx
	iny
	bne	@75
@80:	ldx	#0
@85:	lda	from,x	;person who kicked
	beq	@90
	sta	(a3),y
	inx
	iny
	bne	@85
@90:	lda	#':'
	sta	(a3),y
	iny
	lda	#' '
	sta	(a3),y
	iny
	sty	msgIndex
@100:	ldy	cmdIndex	;reason for kick
	lda	(a2),y
	iny
	sty	cmdIndex
	ldy	msgIndex
	sta	(a3),y
	iny
	sty	msgIndex
	cmp	#0
	bne	@100
	LoadW	a8,to	;person kicked
	LoadW	a9,nick	;was it us?
	ldx	#a8
	ldy	#a9
	jsr	CmpString
	bne	@110
	lda	#0
	sta	curChan	;we're gone!
	jsr	UseSystemFont
	jsr	titleBar
	LoadW	r0,vipFont
	jsr	LoadCharSet
@110:	clc		;something to display
	rts

; -----------------------------------------------------------
doNamed:	LoadW	a3,ircOut
	ldx	#0
	ldy	#0
@10:	lda	hasNames,x
	beq	@20
	sta	(a3),y
	inx
	iny
	bne	@10
@20:	ldx	#0
@30:	lda	curChan,x
	beq	@40
	sta	(a3),y
	iny
	inx
	bne	@30
@40:	lda	#':'
	sta	(a3),y
	iny
	lda	#' '
	sta	(a3),y
	iny
	sty	msgIndex
	ldy	#0
@50:	lda	(a2),y
	cmp	#':'
	beq	@60
	iny
	bne	@50
@60:	iny
@70:	lda	(a3),y
	cmp	#' '
	bne	@80
	iny
	bne	@70
@80:	jsr	addYa2
	jsr	copyCmd
	clc		;something to display
	rts

; -----------------------------------------------------------
doNicked:	LoadW	a3,ircOut
	ldx	#0
	ldy	#0
@10:	lda	from,x
	beq	@20
	sta	(a3),y
	inx
	iny
	bne	@10
@20:	ldx	#0
@30:	lda	hasNick,x	;"is now known as"
	beq	@40
	sta	(a3),y
	inx
	iny
	bne	@30
@40:	sty	msgIndex
	ldx	#0
	ldy	#1	;past ':'
@50:	lda	(a2),y
	sta	to,x
	inx
	iny
	sty	cmdIndex
	ldy	msgIndex
	sta	(a3),y
	iny
	sty	msgIndex
	ldy	cmdIndex
	cmp	#0
	bne	@50
	LoadW	a8,from	;check if our nick has changed
	LoadW	a9,nick
	ldx	#a8
	ldy	#a9
	jsr	CmpString
	beq	@70
@60:	clc		;something to display
	rts
@70:	ldx	#0	;match, change our nick
@80:	lda	to,x
	sta	nick,x
	beq	@60
	inx
	bne	@80
; -----------------------------------------------------------
doError:	LoadW	a3,ircOut
	ldx	#0
	ldy	#0
@10:	lda	hasErr,x
	beq	@20
	sta	(a3),y
	inx
	iny
	bne	@10
@20:	sty	msgIndex
	jsr	copyCmd	;just dump it all to the screen
	clc		;something to display
	rts

; -----------------------------------------------------------
; Copy command parameters to output area.
;	pass:	a2, pointer to command parameters
;		a3, pointer to formatted message
;		msgIndex, location in message to copy to
;	destroyed:	a2 (if it rolls over)
; -----------------------------------------------------------
copyCmd:	PushB	a3H	;save in case it rolls over
	ldy	#0
	sty	cmdIndex
@10:	ldy	cmdIndex
	lda	(a2),y
	beq	@20
	inc	cmdIndex
	bne	@15
	inc	a2H	;message may be > 256 bytes
@15:	cmp	#$01	;ACTION teminator ($01)?
	beq	@10
	ldy	msgIndex
	sta	(a3),y
	inc	msgIndex
	bne	@10
	inc	a3H	;message may be > 256 bytes
	bne	@10
@20:	ldy	msgIndex
	lda	pm
	beq	@30
	lda	#PLAINTEXT
	sta	(a3),y
	iny
@30:	lda	#0
	sta	(a3),y
	PopB	a3H
	rts
; -----------------------------------------------------------
; Add contents of .Y register to pseudo-register a2.
; -----------------------------------------------------------
addYa2:	tya
	clc
	adc	a2L
	sta	a2L
	lda	a2H
	adc	#0
	sta	a2H
	rts

; -----------------------------------------------------------
; Check input buffer for slash command.
;	return:	carry set if not found, clear otherwise
;	destroyed:	a8
; -----------------------------------------------------------
ckSlash:	lda	inputBuf
	cmp	#'/'
	beq	@10
	sec
	rts
@10:	ldy	#0
	sty	reqIndex
@15:	lda	reqAddrs,y
	sta	a8L
	iny
	lda	reqAddrs,y
	sta	a8H
	iny
	sty	reqIndex
	ldy	#0
	ldx	#0
@20:	lda	inputBuf+1,x
	cmp	#' '
	beq	@40
@30:	cmp	(a8),y
	bne	@50	;no match
	inx
	iny
	lda	(a8),y	;end of table entry?
	bne	@20
	lda	inputBuf+1,x	;end of command as well?
	beq	@60	;yes, match
	cmp	#' '
	bne	@50	;no, no match
	beq	@60	;yes, match
@40:	lda	(a8),y	;end of table entry as well?
	beq	@60	;yes, match
@50:	ldy	reqIndex	;next command
	cpy	#NUM_REQS*2
	bne	@15
	LoadW	dispatch,doErr	;end of table, not found
	clc		;show error message
	rts
@60:	ldy	reqIndex	;points to next request
	dey
	lda	reqVects,y
	sta	dispatch+1
	dey
	lda	reqVects,y
	sta	dispatch
	clc
	rts

; -----------------------------------------------------------
; Dispatch routines for commands sent to server. For all routines:
;	pass:	inputBuf, data entered by user
;	return:	carry set if nothing to send, clear otherwise
;		.X holds length of packet to send
; -----------------------------------------------------------
doChan:	lda	#0
	sta	action
	sta	cmdIndex
	jsr	echoChan
	ldx	#0
	stx	cmdIndex
	jsr	sendChan
	rts
; -----------------------------------------------------------
doAct:	ldx	#4
@10:	lda	inputBuf,x	;look for first non-blank past "/me "
	cmp	#' '
	bne	@20
	inx
	bne	@10
@20:	stx	cmdIndex
	stx	action	;any non-zero value will do
	jsr	echoChan
	jsr	sendChan
	rts
;	------------------------------------------------
echoChan:	ldx	#0	;first echo back to screen
	ldy	#0
	lda	action
	beq	@10
	lda	#'*'
	sta	ipData,y
	iny
	lda	#BOLDON
	sta	ipData,y
	iny
@10:	lda	nick,x
	beq	@20
	sta	ipData,y
	inx
	iny
	bne	@10
@20:	lda	action
	beq	@30
	lda	#PLAINTEXT
	bne	@40
@30:	lda	#':'
@40:	sta	ipData,y
	iny
	lda	#' '
	sta	ipData,y
	iny
	ldx	cmdIndex
@50:	lda	inputBuf,x
	sta	ipData,y
	beq	@60
	inx
	iny
	bne	@50
@60:	jsr	scroll
	LoadW	a3,ipData
	jsr	showMsg
	rts

;	------------------------------------------------
sendChan:	ldx	#0	;now send to server
	ldy	#0
@10:	lda	privCmd,x
	beq	@20
	sta	ipData,y
	inx
	iny
	bne	@10
@20:	ldx	#0
@30:	lda	curChan,x
	beq	@40
	sta	ipData,y
	inx
	iny
	bne	@30
@40:	lda	#' '
	sta	ipData,y
	iny
	lda	#':'
	sta	ipData,y
	iny
	lda	action
	beq	@60
	ldx	#0
@50:	lda	actCmd,x
	beq	@60
	sta	ipData,y
	inx
	iny
	bne	@50
@60:	ldx	cmdIndex
@70:	lda	inputBuf,x
	beq	@80
	sta	ipData,y
	inx
	iny
	bne	@70
@80:	lda	action
	beq	@90
	lda	#$01
	sta	ipData,y	;terminate ACTION command
	iny
@90:	lda	#$0d
	sta	ipData,y
	iny
	lda	#$0a
	sta	ipData,y
	iny
	tya
	tax		;length of packet
	clc		;something to send
	rts

; -----------------------------------------------------------
doJoin:	lda	curChan	;already joined to a channel?
	beq	@10
	jsr	doPart	;yes, PART first
	jsr	sendData
@10:	ldx	#0
	ldy	#0
@15:	lda	joinCmd,x
	beq	@20
	sta	ipData,y
	inx
	iny
	bne	@15
@20:	ldx	#5	;look for first non-blank past "/join"
@30:	lda	inputBuf,x
	cmp	#' '
	bne	@40
	inx
	bne	@30
@40:	stx	cmdIndex	;save position of channel name
@45:	sta	ipData,y
	inx
	iny
	lda	inputBuf,x
	bne	@45
	lda	#$0d
	sta	ipData,y
	iny
	lda	#$0a
	sta	ipData,y
	iny		;now holds length of packet
	tya
	tax		;put packet length where caller expects it
	clc
	rts

; -----------------------------------------------------------
doPart:	ldx	#0
	ldy	#0
	lda	curChan,x	;currently joined to a channel?
	bne	@10
	jsr	scroll	;no, show error message
	LoadW	a3,notJoin
	jsr	putMsg
	sec		;nothing to send to server
	rts
@10:	lda	partCmd,x
	beq	@20
	sta	ipData,y
	inx
	iny
	bne	@10
@20:	ldx	#0
@30:	lda	curChan,x	;ignore any operand; part current channel
	beq	@40
	sta	ipData,y
	iny
	inx
	cpx	#CHANLEN
	bne	@30
@40:	lda	#$0d	;terminate command
	sta	ipData,y
	iny
	lda	#$0a
	sta	ipData,y
	iny		;now holds length of packet
	tya
	tax		;put packet length where caller expects it
	clc
	rts

; -----------------------------------------------------------
doNames:	ldx	#0
	ldy	#0
	lda	curChan	;currently joined to a channel?
	bne	@10
	jsr	scroll	;no, show error message
	LoadW	a3,notJoin
	jsr	putMsg
	sec		;nothing to send
	rts
@10:	lda	namesCmd,x
	beq	@20
	sta	ipData,y
	inx
	iny
	bne	@10
@20:	ldx	#0
@30:	lda	curChan,x
	beq	@40
	sta	ipData,y
	inx
	iny
	bne	@30
@40:	lda	#$0d	;terminate command
	sta	ipData,y
	iny
	lda	#$0a
	sta	ipData,y
	iny
	tya
	tax		;packet length in .X
	clc		;something to send
	rts
; -----------------------------------------------------------
doNick:	ldx	#0
	ldy	#0
@10:	lda	nickCmd,x
	beq	@20
	sta	ipData,y
	inx
	iny
	bne	@10
@20:	ldx	#5
@30:	lda	inputBuf,x	;find first non-blank past "/nick"
	cmp	#' '
	bne	@40
	inx
	bne	@30
@40:	sta	ipData,y
	inx
	iny
	lda	inputBuf,x
	bne	@40
	lda	#$0d	;only change nick internally
	sta	ipData,y	;when server sends response
	iny
	lda	#$0a
	sta	ipData,y
	iny
	tya
	tax		;length of packet
	clc		;something to send
	rts

; -----------------------------------------------------------
doMsg:	ldx	#5
	ldy	#0
@10:	lda	inputBuf,x	;look for first non-blank past "/msg"
	cmp	#' '
	bne	@20
	inx
	bne	@10
@20:	sta	to,y
	inx
	iny
	lda	inputBuf,x
	cmp	#' '
	bne	@20
	lda	#0
	sta	to,y
@30:	inx
	lda	inputBuf,x	;to next non-blank
	cmp	#' '
	beq	@30
	stx	inputNdx	;points to message
	jsr	echoMsg
	ldx	#0
	ldy	#0
@40:	lda	privCmd,x
	beq	@50
	sta	ipData,y
	inx
	iny
	bne	@40
@50:	ldx	#0
@60:	lda	to,x
	beq	@70
	sta	ipData,y
	inx
	iny
	bne	@60
@70:	lda	#' '
	sta	ipData,y
	iny
	lda	#':'
	sta	ipData,y
	iny
	ldx	inputNdx	;points to message
@80:	lda	inputBuf,x
	beq	@90
	sta	ipData,y
	inx
	iny
	bne	@80
@90:	lda	#$0d
	sta	ipData,y
	iny
	lda	#$0a
	sta	ipData,y
	iny
	tya
	tax		;length of packet
	clc		;something to send
	rts

; -----------------------------------------------------------
echoMsg:	ldx	#0	;echo /msg to console
	ldy	#2
	lda	#ITALICON
	sta	ipData
	lda	#'['
	sta	ipData+1
@10:	lda	to,x
	beq	@20
	sta	ipData,y
	inx
	iny
	bne	@10
@20:	lda	#']'
	sta	ipData,y
	iny
	lda	#' '
	sta	ipData,y
	iny
	ldx	inputNdx
@30:	lda	inputBuf,x
	beq	@40
	sta	ipData,y
	inx
	iny
	bne	@30
@40:	lda	#PLAINTEXT
	sta	ipData,y
	iny
	lda	#0
	sta	ipData,y
	jsr	scroll
	LoadW	a3,ipData
	jsr	showMsg
	rts

; -----------------------------------------------------------
doCmd:	ldy	#4	;"/cmd"
	ldx	#0
@10:	lda	inputBuf,y
	cmp	#' '	;find beginning of command
	bne	@20
	iny
	bne	@10
@20:	sta	ipData,x
	inx
	iny
	lda	inputBuf,y
	bne	@20
	sta	ipData,x
	txa
	pha
	jsr	scroll
	LoadW	a3,ipData
	jsr	showMsg	;echo to console
	pla
	tax
	lda	#$0d	;add CR/LF
	sta	ipData,x
	inx
	lda	#$0a
	sta	ipData,x
	inx		;length of packet
	clc		;something to send
	rts
; -----------------------------------------------------------
doErr:	ldx	#0
	ldy	#0
@10:	lda	badCmd,x
	beq	@20
	sta	ipData,y
	inx
	iny
	bne	@10
@20:	ldx	#0
@30:	lda	inputBuf,x
	cmp	#' '
	beq	@40
	sta	ipData,y
	inx
	iny
	bne	@30
@40:	lda	#0
	sta	ipData,y
	jsr	scroll
	LoadW	a3,ipData
	jsr	showMsg
	sec		;nothing to send
	rts

	
	
; -----------------------------------------------------------
; geoLinkText.s
; -----------------------------------------------------------

; -----------------------------------------------------------
MAXVISBL	=	53	;max chars in input area
; -----------------------------------------------------------
; Line wrap routine (wrapper around putMsg). 
;	pass:	a3, pointer to output string
; -----------------------------------------------------------
showMsg:	jsr	cntBold	;set maxChars
	ldy	#0
@10:	lda	(a3),y
	bne	@20
	jsr	putMsg	;no line break needed
	rts
@20:	iny
	cpy	maxChars
	bne	@10
@30:	dey		;walk back to last blank
	cpy	#NICKLEN+2	;have we reached the nick?
	bcc	@40	;yes, no word break found
	lda	(a3),y
	cmp	#' '
	bne	@30
	cpy	maxChars	;still too long?
	bcs	@30	;yes, keep trying
	lda	#0
	sta	(a3),y
	iny
	sty	msgIndex
	jsr	putMsg
	jsr	scroll
	lda	msgIndex
	clc
	adc	a3L
	sta	a3L
	lda	a3H
	adc	#0
	sta	a3H
	bra	showMsg
@40:	ldy	maxChars
	lda	(a3),y	;force line break
	pha
	lda	#0
	sta	(a3),y
	jsr	putMsg
	jsr	scroll
	pla
	ldy	maxChars
	sta	(a3),y
	tya
	clc
	adc	a3L
	sta	a3L
	lda	a3H
	adc	#0
	sta	a3H
	bra	showMsg

; -----------------------------------------------------------
; Set maximum chars across screen, taking into account characters
; in boldface. Only check the maximum number of characters that
; would fit across the screen if none were boldface. Note that the
; screen width in characters (63, allowing for a one-pixel margin
; on the left), and the width of a character (5) are hard-coded.
;	pass:	a3, pointer to output string
;	return:	maxChars
; -----------------------------------------------------------
cntBold:	lda	#63
	sta	maxChars
	ldx	#0
	stx	boldon
	ldy	#0
@10:	lda	(a3),y
	beq	@50
	cmp	#BOLDON
	bne	@20
	sta	boldon
	bne	@40
@20:	cmp	#PLAINTEXT
	bne	@30
	lda	#0
	sta	boldon
	beq	@40
@30:	lda	boldon
	beq	@40
	inx
@40:	iny
	cpy	#63	;max chars across screen
	bne	@10
@50:	txa		;every boldface char adds one pixel
	beq	@70
	sec
@60:	dec	maxChars	;one less char for every 5 boldface
	sbc	#5	;character width
	bcc	@70
	bne	@60
@70:	rts
; -----------------------------------------------------------
; Put message to screen. We must save and restore the text input
; state because we are effectively calling GetString and PutString
; at the same time.
;	pass:	a3, address of formatted message to display
; -----------------------------------------------------------
putMsg:	jsr	savTxtSt	;save text status
	LoadW	leftMargin,0
	LoadW	rightMargin,318
	LoadW	StringFaultVec,0
	MoveW	a3,r0
	LoadB	r1H,TXT_AREA-3	;baseline
	LoadW	r11,2	;X position
	jsr	PutString
	jsr	rstTxtSt	;restore text status
	rts

; -----------------------------------------------------------
; Save text status shared between PutString and GetString.
; -----------------------------------------------------------
savTxtSt:	MoveB	$87cf,savTxt	;stringLen
	MoveB	$87d0,savTxt+1	;stringMaxLen
	MoveB	alphaFlag,savTxt+2	 ;save cursor state
	MoveW	leftMargin,savTxt+3
	MoveW	rightMargin,savTxt+5
	MoveW	StringFaultVec,savTxt+7
	rts
; -----------------------------------------------------------
; Restore text status shared between PutString and GetString.
; -----------------------------------------------------------
rstTxtSt:	MoveB	savTxt,$87cf	;stringLen
	MoveB	savTxt+1,$87d0	;stringMaxLen
	MoveB	savTxt+2,alphaFlag	 ;restore cursor state
	MoveW	savTxt+3,leftMargin
	MoveW	savTxt+5,rightMargin
	MoveW	savTxt+7,StringFaultVec
	rts

; -----------------------------------------------------------
; Scroll existing messages upward to make room for a new one.
; Both foreground and background buffers are updated so menus
; will not foul the screen.
;	destroyed: a6L,a7,a8
; -----------------------------------------------------------
scroll:	LoadB	a6L,SCR_AMT
	ldx	#SCR_FROM	;set initial from/to scan lines
	stx	scrFrom
	jsr	GetScanLine
	MoveW	r5,a7	;and screen memory addresses
	ldx	#SCR_TO
	stx	scrTo
	jsr	GetScanLine
	MoveW	r5,a8	;foreground
@10:	ldy	#0
	ldx	#SCR_WD
@20:	lda	(a7),y
	sta	(a8),y
	dex
	beq	@30	;done with one scan line
	cpy	#248	;is .Y about to roll over?
	bcc	@25
	inc	a7H
	inc	a8H
	ldy	#0
	beq	@20
@25:	tya
	clc
	adc	#8
	tay
	bne	@20
@30:	dec	a6L
	beq	@40	;finished scrolling
	inc	scrFrom
	ldx	scrFrom
	jsr	GetScanLine
	MoveW	r5,a7
	inc	scrTo
	ldx	scrTo
	jsr	GetScanLine
	MoveW	r5,a8
	bra	@10
@40:	lda	#0	;clear
	jsr	SetPattern
	LoadB	r2L,174
	LoadB	r2H,183
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;clear previous message
	rts

; -----------------------------------------------------------
; Start input loop for chat text or command entry.
; -----------------------------------------------------------
getInput:	lda	chatting	;(in resident module)
	beq	@20	;chat loop broken by logout
	php
	sei
	LoadW	keyVector, keyInput
	LoadW	stringX,TXT_LEDG+2
	LoadB	stringY,TXT_AREA+5
	LoadW	leftMargin,TXT_LEDG+1
	LoadW	rightMargin,TXT_REDG-1
	plp
	lda	curHeight
	jsr	InitTextPrompt
	jsr	PromptOn
	lda	#0
	sta	inputNdx
	tax
@10:	sta	inputBuf,x	;clear input buffer
	inx
	cpx	#MAXINPUT+2
	bne	@10
@20:	rts
; -----------------------------------------------------------
; Master key handler. Drains keyboard buffer and processes all
; available keystrokes.
; -----------------------------------------------------------
keyInput:	php
	sei
	jsr	PromptOff
	LoadB	alphaFlag,0
	ldy	#0
	lda	keyData
	sta	keyBuf,y
@10:	jsr	GetNextChar	;trashes .X, preserves .Y
	iny
	sta	keyBuf,y
	cmp	#0	;can't depend on Z flag
	bne	@10
	tay
	sty	keyNdx	;reset
	plp		;allow more keystrokes
@20:	lda	keyBuf,y
	beq	@30
	jsr	keyHndlr
	bcs	@30	;too many, ignore the rest
	inc	keyNdx
	ldy	keyNdx
	bne	@20
@30:	jsr	PromptOn
	rts

; -----------------------------------------------------------
; Handler for buffered keystrokes.
;	pass:	Character to process in .A
;	return:	Carry set if input buffer is full.
; -----------------------------------------------------------
keyHndlr:	sta	keyTemp
	cmp	#KEY_DELETE	;allow delete if buffer full
	beq	@5
	cmp	#KEY_LEFT	;and cursor left
	beq	@5
	cmp	#KEY_CLEAR	;and clear
	beq	@5
	cmp	#KEY_HOME	;and home
	beq	@5
	cmp	#KEY_F1	;sama-sama
	beq	@5
	cmp	#CR	;and Return
	beq	@5
	ldy	inputNdx
	cpy	#MAXINPUT
	bcc	@5
	jsr	beep
	sec
	rts
@5:	lda	keyTemp	;reset flags
	bmi	@10	;shortcut key?
	jsr	doNormal
	rts
@10:	jsr	doShort
doShort:	rts		;not implemented
;	------------------------------------------------
doNormal:	MoveW	stringX,r11
	lda	stringY
	clc
	adc	baselineOffset
	sta	r1H
	lda	keyTemp
	cmp	#' '
	bcs	@30	;printable character?
;	------------------------------------------------
	ldy	#NUM_CTRL-1	;no, check control characters
@10:	cmp	ctrlKeys,y
	beq	@20
	dey
	bpl	@10
	clc		;not handled
	rts
@20:	tya
	asl	a
	tay
	lda	ctrlVect,y
	iny
	ldx	ctrlVect,y
	jsr	CallRoutine
	clc
	rts
;	------------------------------------------------
@30:	ldx	inputNdx	;handle printable character
	inx
	lda	inputBuf,x
	beq	@35		;at end of input string?
	jmp	insert	;no, insert
@35:	lda	keyTemp
	ldy	inputNdx
	sta	inputBuf,y
	iny
	lda	#0
	sta	inputBuf,y
	sty	inputNdx	;point to next char
	CmpWI	r11,TXT_REDG-2
	bcc	@40
	lda	inputNdx	;no more room on right edge
	sec
	sbc	#MAXVISBL	;start one char further into string
	tay
	LoadW	r11,TXT_LEDG+2
	jsr	reprint	;up to and including new char
	clc
	rts
@40:	lda	keyTemp
	jsr	SmallPutChar
	AddVW	5,stringX	;advance cursor
@50:	clc
	rts
;	------------------------------------------------
insert:	ldy	inputNdx
@10:	iny
	lda	inputBuf,y
	bne	@10
	cpy	#MAXINPUT
	bne	@20
	jsr	beep	;no room to insert
	sec
	rts
@20:	iny
	lda	#0
	sta	inputBuf,y	;Y is destination
	dey
	tya
	tax
	dex		;X is source
@30:	lda	inputBuf,x
	sta	inputBuf,y
	cpx	inputNdx
	beq	@40
	dey
	dex
	bpl	@30
@40:	lda	keyTemp
	sta	inputBuf,x
	sty	inputNdx
	PushW	r11
	dey
	jsr	reprint
	PopW	r11
	AddVW	5,r11	;update output
	MoveW	r11,stringX	;and input positions
	clc
	rts

; -----------------------------------------------------------
; Handlers for keystrokes corresponding to non-printable characters.
; -----------------------------------------------------------
doCr:	jmp	sendMsg
; -----------------------------------------------------------
doBksp:	ldy	inputNdx
	bne	@10
	jsr	beep
	rts
@10:	lda	inputBuf,y	;at end of buffer?
	bne	@20
	MoveW	r11,r4	;yes, erase last character
	jsr	backUp	;move cursor left
	MoveW	r11,r3
	LoadB	r2L,TXT_AREA+4
	LoadB	r2H,TXT_AREA+12
	jsr	Rectangle	;erase character
	dec	inputNdx
	ldy	inputNdx
	lda	#0
	sta	inputBuf,y
	rts
@20:	CmpWI	r11,TXT_LEDG+7
	bcc	@30
	jsr	suckChar
	jsr	backUp	;move cursor left (trashes .Y)
	ldy	inputNdx
	jsr	reprint
	rts
@30:	jsr	suckChar
	LoadW	r3,TXT_LEDG+1
	lda	r3L
	clc
	adc	#5
	sta	r4L
	lda	r3H
	adc	#0
	sta	r4H
	LoadB	r2L,TXT_AREA+4
	LoadB	r2H,TXT_AREA+12
	jsr	Rectangle	;erase in case partial character is showing
	LoadW	r11,TXT_LEDG+2
	jsr	reprint
	rts
; -----------------------------------------------------------
doLeft:	ldy	inputNdx
	bne	@10
	jsr	beep	;already at start of buffer
	rts
@10:	CmpWI	r11,TXT_LEDG+7	;can we just move cursor?
	bcs	@20
	LoadW	r11,TXT_LEDG+2	;no, reprint from left edge
	dec	inputNdx
	ldy	inputNdx
	jsr	reprint
	LoadW	r11,TXT_LEDG+2	;reset
	clc
	rts
@20:	dec	inputNdx	;just move index
	jsr	backUp	;and cursor
	rts

; -----------------------------------------------------------
doRight:	ldy	inputNdx
	lda	inputBuf,y	;at end of entered characters?
	bne	@10
	jsr	beep
	rts
@10:	iny
	sty	inputNdx
	CmpWI	r11,TXT_REDG-2	;cursor and one blank pixel
	bcc	@20	;can we just move cursor?
	lda	inputNdx	;no, reprint from left edge
	sec
	sbc	#MAXVISBL-1
	tay
	PushW	r11
	LoadW	r11,TXT_LEDG+2
	jsr	reprint
	PopW	r11
	rts
@20:	AddVW	5,r11
	MoveW	r11,stringX
	rts
; -----------------------------------------------------------
doHome:	ldy	#0
	sty	inputNdx
	LoadW	r11,TXT_LEDG+2
	jsr	reprint
	LoadW	r11,TXT_LEDG+2	;reset
	MoveW	r11,stringX
	rts
; -----------------------------------------------------------
doEnd:	ldy	#0
@10:	lda	inputBuf,y	;get length of input string
	beq	@20
	iny
	bne	@10
@20:	sty	inputNdx
	cpy	#MAXVISBL+1	;fits in input field?
	bcs	@30
	sty	a8L	;yes, move cursor and index
	LoadB	a9L,5
	ldx	#a9L	;destination
	ldy	#a8L
	jsr	BBMult	;calculate cursor offset
	LoadW	r11,TXT_LEDG+2	;and reposition cursor
	lda	r11L
	clc
	adc	a9L
	sta	r11L
	lda	r11H
	adc	a9H
	sta	r11H
	MoveW	r11,stringX
	rts
@30:	tya		;reprint entire text area
	sec
	sbc	#MAXVISBL+1	;figure starting index
	tay
@40:	LoadW	r11,TXT_LEDG-3	;clip leftmost character
	jsr	reprint	;leave r11 where it falls
	MoveW	r11,stringX
	rts

; -----------------------------------------------------------
doClear:	lda	#0
	jsr	SetPattern
	LoadB	r2L,TXT_AREA+4
	LoadB	r2H,TXT_AREA+12
	LoadW	r3,TXT_LEDG+1
	LoadW	r4,TXT_REDG-1
	jsr	Rectangle	;clear text input area
	lda	#0
	sta	inputNdx
	tax
@10:	sta	inputBuf,x	;clear input buffer
	inx
	cpx	#MAXINPUT+2
	bne	@10
	LoadW	r11,TXT_LEDG+2	;reset text position
	MoveW	r11,stringX
	rts

; -----------------------------------------------------------
; Reprint a portion of the input buffer. Printing stops on a margin
; fault. If printing stops before the right margin, the rest of the 
; input area is cleared. Caller is responsible for restoring r11.
;	destroyed:	.Y, r11, a9L
; -----------------------------------------------------------
reprint:	sty	a9L
@10:	lda	inputBuf,y	;end reached before right margin?
	beq	@20
	jsr	SmallPutChar	;partial clip character on fault
	CmpWI	r11,TXT_REDG
	bcs	@30	;reached right margin, done
	inc	a9L
	ldy	a9L
	bne	@10
@20:	MoveW	r11,r3	;clear remainder of input area
	LoadW	r4,TXT_REDG-1
	LoadB	r2L,TXT_AREA+4
	LoadB	r2H,TXT_AREA+12
	PushW	r11
	jsr	Rectangle
	PopW	r11	;restore so caller can use
@30:	rts
; -----------------------------------------------------------
; Back up cursor by one character (leave input index untouched).
; Updates both r11 (for output) and stringX (for input).
; -----------------------------------------------------------
backUp:	lda	r11L
	sec
	sbc	#5
	sta	r11L
	lda	r11H
	sbc	#0
	sta	r11H
	MoveW	r11,stringX
	rts
; -----------------------------------------------------------
; Destructive backspace with index decrement.
; -----------------------------------------------------------
suckChar:	tya
	tax
	dex
	stx	inputNdx
@10:	lda	inputBuf,y
	sta	inputBuf,x
	beq	@20
	inx
	iny
	bne	@10
@20:	rts


; -----------------------------------------------------------
; geoLinkIRCd.s
; -----------------------------------------------------------

; -----------------------------------------------------------
; geoLinkIRCd (data for IRC module)
; -----------------------------------------------------------

; -----------------------------------------------------------
fontEnd:	.word	0
scrFrom:	.res	2	;scan line being scrolled from
scrTo:	.res	2	;scan line being scrolled to
autoWait:	.byte	0
autoTry:	.byte	0
nickSent:	.byte	0
userSent:	.byte	0
connMsg:	.byte	"connecting...",0
aNickMsg:	.byte	"sending NICK command...",0
aUserMsg:	.byte	"sending USER command...",0
userCmd:	.byte	"USER ",0
retrying:	.byte	"Error $"
retryErr:	.res	2
	.byte	", retrying...",0
givingUp:	.byte	"I give up! Try again.",0
connDone:	.byte	"Connected to server.",0
netErr:	.byte	"Network error $"
netErrNo:	.res	2
	.byte	0
closed:	.byte	"Connection closed.",0
notJoin:	.byte	"ERROR: not joined to a channel.",0
badCmd:	.byte	"ERROR: bad command: ",0
inputBuf:	.res	MAXINPUT+2	;allow for CR/LF
inputNdx:	.byte	0	;index into inputBuf
keyBuf:	.res	17	;GEOS keyboard buffer is 16 bytes
keyNdx:	.byte	0
keyTemp:	.byte	0
savTxt:	.res	9
ctrlKeys:	.byte	CR,KEY_DELETE,KEY_LEFT,KEY_RIGHT
	.byte	KEY_F1,KEY_F7,KEY_HOME,KEY_CLEAR
NUM_CTRL	=	(*-ctrlKeys)
ctrlVect:	.word	doCr,doBksp,doLeft,doRight
	.word	doHome,doEnd,doHome,doClear
motdMsg:	.byte	"[server message]",0
motdMLen	=	(*-motdMsg)
motds:	.byte	0
dotX:	.res	2
ircMesg:	.res	512	;buffer to build IRC message
ircOut:	.res	512	;buffer to build display message
mesgPtr:	.word	ircMesg	;pointer into ircMesg
curChan:	.res	24	;current IRC channel
CHANLEN	=	(*-curChan)
tempChan:	.res	CHANLEN
title:	.byte	" geoLink IRC ["
chanTitl:	.res	CHANLEN+3
noChan:	.byte	"no channel] ",0
from:	.res	NICKLEN+1	;IRC command source
to:	.res	CHANLEN	;target of PRIVMSG
pm:	.byte	0	;is message a PM?
action:	.byte	0	;is message an ACTION?
command:	.res	NICKLEN+1	;IRC command as text
cmdNum:	.word	0	;converted numeric command
cmdIndex:	.byte	0	;index into command (or command table)
msgIndex:	.byte	0	;index into message being built

;.if	((* & $ff) = $ff)
;	.res	1	;align dispatch vector if necessary
;.endif

dispatch:	.res	2
maxChars:	.byte	0	;maximum chars across screen
boldon:	.byte	0	;counting bold characters?
;	------------------------------------------------
;	text commands and their vectors
;	------------------------------------------------
ping:	.byte	"PING",0
privmsg:	.byte	"PRIVMSG",0
joinMsg:	.byte	"JOIN",0
partMsg:	.byte	"PART",0
quitMsg:	.byte	"QUIT",0
kickMsg:	.byte	"KICK",0
nickMsg:	.byte	"NICK",0
errMsg:	.byte	"ERROR",0
cmdAddrs:	.word	ping,privmsg,joinMsg,partMsg,quitMsg,kickMsg,nickMsg,errMsg
cmdVects:	.word	doPong,doPriv,doJoined,doParted,doQuited,doKicked,doNicked,doError
NUM_CMDS	=	(cmdVects-cmdAddrs)/2
hasJoin:	.byte	" has joined ",0
hasPart:	.byte	" has left ",0
hasQuit:	.byte	" has quit: ",0
hasKick:	.byte	" was kicked by ",0
hasNames:	.byte	"Names in ",0
hasNick:	.byte	" is now known as ",0
hasErr:	.byte	"ERROR: ",0
join:	.byte	"join",0
part:	.byte	"part",0
names:	.byte	"names",0
newnick:	.byte	"nick",0
act:	.byte	"me",0
msg:	.byte	"msg",0
cmd:	.byte	"cmd",0
reqAddrs:	.word	join,part,names,newnick,act,msg,cmd
reqVects:	.word	doJoin,doPart,doNames,doNick,doAct,doMsg,doCmd
NUM_REQS	=	(reqVects-reqAddrs)/2
reqIndex:	.byte	0	;index into request table
privCmd:	.byte	"PRIVMSG ",0	;for building PRIVMSG command
joinCmd:	.byte	"JOIN ",0
partCmd:	.byte	"PART ",0
namesCmd:	.byte	"NAMES ",0
nickCmd:	.byte	"NICK ",0
actCmd:	.byte	$01,"ACTION ",0

; -----------------------------------------------------------
ircMenu:	.byte	15,30
	.word	28,67
	.byte	VERTICAL | CONSTRAINED | 1
;	------------------------------------------------
	.word	logtText
	.byte	MENU_ACTION
	.word	enablOpt
;	------------------------------------------------
logtText:	.byte	"logout",0
; -----------------------------------------------------------
sndIcons:	.byte	1	;one icon
	.word	300	;TBD
	.byte	192
;	------------------------------------------------
	.word	sendIcon
	.byte	35,TXT_AREA+3	;x in cards, y in pixels
	.byte	4,11	;width in cards, height in pixels
	.word	iSendMsg
;	------------------------------------------------
sendIcon:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-send.pcx (32x11, 2 colors, indexed)
;
        .byte   $04,$FF,$A4,$80,$00,$00,$01,$87,$80,$00,$61,$8C,$00,$00,$61,$86
        .byte   $1C,$F1,$E1,$83,$36,$DB,$61,$81,$BE,$DB,$61,$81,$B0,$DB,$61,$8F
        .byte   $1E,$D9,$E1,$80,$00,$00,$01,$04,$FF

vipFont:	.byte	0	;mono font loads here

