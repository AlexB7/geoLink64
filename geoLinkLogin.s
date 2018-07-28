
; MOD_LOGIN
.segment	"OVERLAY3"

; -----------------------------------------------------------
; geoLinkLogin (login dialog for geoLink IRC module)
; -----------------------------------------------------------
	.forceimport	bServer
	.forceimport	ip65
	.forceimport	dnsStrc
	.forceimport	bPort
	.forceimport	errorMsg
	.forceimport	mainMenu
	.forceimport	optWord
	.forceimport	optMenu
	.forceimport	loadIRC
	.forceimport	noIcons
	.forceimport	server
	.forceimport	errorDB
	.forceimport	strWidth
	.include	"geoLink.inc"
	.include	"geosmac.inc"
	.include	"geossym.inc"
	.include	"geossym2.inc"
	.include	"const.inc"
	.include	"jumptab.inc"
; -----------------------------------------------------------
; note: 320-BOX_WIDE must divide by 8 evenly (to position icons)
; -----------------------------------------------------------
TTL_HIGH	=	12	;title height
ITM_HIGH	=	20	;height of text item, with offset
NUM_ITEM	=	3
BOX_HIGH	=	116	;allow for status bar at bottom
BOX_TOP	=	(200-BOX_HIGH)/2
TXT_TOP	=	BOX_TOP+20	;top of input text string
TXT_HIGH	=	12	;height of input text area
TXT_LEFT	=	56
TXT_WIDE	=	112
BOX_WIDE	=	TXT_LEFT+TXT_WIDE+8
BOX_LEFT	=	(320-BOX_WIDE)/2
LBL_LEFT	=	BOX_LEFT+8
LBL_BOT	=	BOX_TOP+28	;baseline of prompt string
OK_LEFT	=	BOX_LEFT+32
CNC_LEFT	=	OK_LEFT+48+16
ICON_TOP	=	BOX_TOP+(TTL_HIGH+8)+(ITM_HIGH*NUM_ITEM)
modLogin:	jsr	boxDims
	AddVB	8,r2L
	AddVB	8,r2H
	AddVW	8,r3
	AddVW	8,r4
	lda	#1	;solid (shadow box)
	jsr	SetPattern
	jsr	Rectangle
	jsr	boxDims
	lda	#0	;clear
	jsr	SetPattern
	jsr	Rectangle
	jsr	titleBar
	jsr	boxDims
	lda	#$ff	;solid line
	jsr	FrameRectangle
;	------------------------------------------------
	LoadB	a0L,0	;item counter
	LoadB	a1L,LBL_BOT
	LoadB	a1H,TXT_TOP
@10:	jsr	showItem	;shows label and draws box for text area
	AddVB	ITM_HIGH,a1L
	AddVB	ITM_HIGH,a1H
	inc	a0L
	lda	a0L
	cmp	#NUM_ITEM
	bne	@10
	LoadW	r3,BOX_LEFT
	LoadW	r4,(BOX_LEFT+BOX_WIDE)-1
	LoadW	r11L,(BOX_TOP+BOX_HIGH)-12
	lda	#$ff
	jsr	HorizontalLine
	LoadW	r0,iconData
	jsr	DoIcons
	jsr	getInput
	rts

; -----------------------------------------------------------
; draw striped title bar at top of window
; -----------------------------------------------------------
titleBar:	lda	#9	;horizontal stripes
	jsr	SetPattern
	LoadB	r2L,BOX_TOP
	LoadB	r2H,BOX_TOP+TTL_HIGH
	LoadW	r3,BOX_LEFT
	LoadW	r4,(BOX_LEFT+BOX_WIDE)-1
	jsr	Rectangle
	LoadW	r0,title
	jsr	strWidth	;returns string width in a0
	LoadB	r1H,BOX_TOP+8
	; ((box width - string width) / 2) + box left
	LoadW	r11,BOX_WIDE
	SubW	a0,r11
	clc
	ror	r11H
	ror	r11L
	lda	r11L
	clc
	adc	#<BOX_LEFT
	sta	r11L
	lda	r11H
	adc	#>BOX_LEFT
	sta	r11H
	jsr	PutString
	rts
; -----------------------------------------------------------
; Display a text prompt, the bounding box for its input, and the
; default text for the input.
;	pass:	a0L, item counter
;		a1L, baseline of prompt string
;		a1H, top of input text string
; -----------------------------------------------------------
showItem:	lda	a0L
	asl	a
	tay
	lda	lblAddrs,y
	sta	r0L
	iny
	lda	lblAddrs,y
	sta	r0H
	MoveB	a1L,r1H
	LoadW	r11,LBL_LEFT
	jsr	PutString
	lda	a1H
	sta	r2L
	clc
	adc	#(TXT_HIGH-1)
	sta	r2H
	LoadW	r3,BOX_LEFT+TXT_LEFT
	LoadW	r4,(BOX_LEFT+TXT_LEFT+TXT_WIDE)-1
	lda	#$ff	;solid line
	jsr	FrameRectangle
	lda	a0L
	asl	a
	tay
	lda	txtAddrs,y
	sta	r0L
	iny
	lda	txtAddrs,y
	sta	r0H
	MoveB	a1L,r1H
	LoadW	r11,BOX_LEFT+TXT_LEFT+3
	jsr	PutString
	rts

; -----------------------------------------------------------
; Get the dimensions of the login dialog.
; -----------------------------------------------------------
boxDims:	LoadB	r2L,BOX_TOP
	LoadB	r2H,(BOX_TOP+BOX_HIGH)-1
	LoadW	r3,BOX_LEFT
	LoadW	r4,(BOX_LEFT+BOX_WIDE)-1
	rts
; -----------------------------------------------------------
; Loop through input fields. Mouse click will select field.
; -----------------------------------------------------------
getInput:	LoadW	rightMargin,(BOX_LEFT+TXT_LEFT+TXT_WIDE)-1
	LoadW	StringFaultVec,0
	LoadW	otherPressVec,chkMouse
	LoadB	getting,$ff	;enable input
reGet:	LoadB	a0L,0	;loop counter
	LoadB	a0H,TXT_TOP+2
getStrs:	lda	a0L
mGetStrs:	asl	a
	tax
	lda	txtAddrs,x
	sta	r0L
	lda	txtAddrs+1,x
	sta	r0H
	LoadB	r1L,0	;no string fault
	MoveB	a0H,r1H	;y position
	ldx	a0L
	lda	txtLens,x
	sta	r2L	;max. input length
@5:	LoadW	r11,BOX_LEFT+TXT_LEFT+3	  ;x position
	LoadW	keyVector,gotInput
	jsr	GetString
	rts
gotInput:	lda	getting
	bne	@10
	rts
@10:	AddVB	ITM_HIGH,a0H
	inc	a0L
	lda	a0L
	cmp	#NUM_ITEM
	bne	getStrs
	beq	reGet

; -----------------------------------------------------------
chkMouse:	LoadB	r2L,TXT_TOP
	LoadB	r2H,(TXT_TOP+TXT_HIGH)-1
	LoadW	r3,BOX_LEFT+TXT_LEFT
	LoadW	r4,(BOX_LEFT+TXT_LEFT+TXT_WIDE)-1
	ldx	#0
@10:	jsr	IsMseInRegion
	tay		;force flags to be set
	bne	@30
	inx
	cpx	#NUM_ITEM
	bne	@20
	rts
@20:	AddVB	ITM_HIGH,r2L
	AddVB	ITM_HIGH,r2H
	bne	@10
@30:	txa
	pha
	lda	#TXT_TOP+2
@40:	dex
	bmi	@50
	clc
	adc	#ITM_HIGH
	bne	@40
@50:	sta	a0H
	pla
	sta	a0L
	jmp	mGetStrs
; -----------------------------------------------------------
; handler for OK icon
; -----------------------------------------------------------
doOK:	LoadW	r0,iconDis	;disable icons
	jsr	DoIcons
	jsr	killText	;turn off text input
	jsr	valLogin	;validate input
	bcs	@10
	jsr	resolve	;DNS does its own polling
	bcc	@40
@10:	LoadW	r0,errorDB	;show error dialog
	jsr	DoDlgBox
	jsr	clrSts	;clear status area
	LoadB	a0H,TXT_TOP+2	;position to error field
	ldx	a0L	;field counter for input
@20:	dex
	bmi	@30
	AddVB	ITM_HIGH,a0H
	bne	@20
@30:	LoadW	otherPressVec,chkMouse
	LoadB	getting,$ff
	LoadW	r0,iconData	;re-enable icons
	jsr	DoIcons
	jmp	getStrs
@40:	ldx	#51	;tEnd-tServer
@50:	lda	tServer-1,x
	sta	server-1,x	;copy entered values to resident module
	dex
	bpl	@50
	LoadW	r0,noIcons
	jsr	DoIcons	;kill icons
	jmp	loadIRC	;load IRC module from resident module

; -----------------------------------------------------------
; handler for Cancel icon
; -----------------------------------------------------------
doCancel:	jsr	killText	;turn off text input
	LoadW	r0,noIcons	;dummy icon table
	jsr	DoIcons
	lda	#2	;50% stipple
	jsr	SetPattern
	LoadB	r2L,15	;don't erase menu
	LoadB	r2H,199
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;clear screen	
	LoadW	optWord,optMenu
	LoadW	r0,mainMenu
	lda	#1
	jsr	DoMenu	;re-enable options menu
	rts		;back to MainLoop
; -----------------------------------------------------------
;	Icon NOP (for disabled icons)
; -----------------------------------------------------------
iconNop:	rts
; -----------------------------------------------------------
; kill text input
; -----------------------------------------------------------
killText:	LoadW	otherPressVec,0
	LoadB	getting,0	;flag to ignore carriage return
	LoadB	keyData,$0d
	lda	keyVector
	ldx	keyVector+1
	jsr	CallRoutine	;simulate hitting Enter
	rts
; -----------------------------------------------------------
; clear status area
; -----------------------------------------------------------
clrSts:	LoadB	r2L,(BOX_TOP+BOX_HIGH)-11
	LoadB	r2H,(BOX_TOP+BOX_HIGH)-2
	LoadW	r3,BOX_LEFT+1
	LoadW	r4,(BOX_LEFT+BOX_WIDE)-2
	lda	#0	;clear
	jsr	SetPattern
	jsr	Rectangle
	rts
; -----------------------------------------------------------
; show status message
;	pass:	r0, address of string to display
; -----------------------------------------------------------
showSts:	LoadB	r1H,(BOX_TOP+BOX_HIGH)-4
	LoadW	r11,BOX_LEFT+8
	jsr	PutString
	rts

; -----------------------------------------------------------
; Validate data entry. Returns carry clear on success, set otherwise.
; -----------------------------------------------------------
valLogin:	lda	tServer
	bne	@10
	LoadW	errorMsg,noServer	
	LoadB	a0L,0
	sec
	rts
@10:	lda	tPort
	bne	@11
	LoadW	errorMsg,noPort	
	LoadB	a0L,1
	sec
	rts
@11:	ldx	#0
@12:	lda	tPort,x	;is entered port numeric?
	beq	@14
	cmp	#$30
	bcc	@13
	cmp	#$3a
	bcs	@13
	inx
	bne	@12
@13:	LoadW	errorMsg,badPort	
	LoadB	a0L,1
	sec
	rts
@14:	ldy	#0	;convert port to numeric
	sty	a1L
	sty	a1H
	sty	a3H	;temp. storage for .Y
@15:	ldy	a3H
	lda	tPort,y
	beq	@16
	LoadB	a2L,10	;work area * 10
	ldx	#a1
	ldy	#a2
	jsr	BMult	;a1 = a1 * a2L	
	ldy	a3H
	lda	tPort,y	;and add next digit
	and	#$0f	;convert to binary
	clc
	adc	a1L
	sta	a1L
	lda	a1H
	adc	#0
	sta	a1H
	inc	a3H
	bne	@15
@16:	CmpWI	a1,1024
	bcc	@13	;invalid port number
	MoveW	a1,bPort	;save binary port number
	lda	tNick
	bne	@40
	LoadW	errorMsg,noNick	
	LoadB	a0L,2
	sec
	rts
@40:	clc
	rts

; -----------------------------------------------------------
; Resolve host address.
; -----------------------------------------------------------
resolve:	LoadW	r0,msgReslv
	jsr	showSts
	lda	#<tServer
	ldx	#>tServer
	sta	dnsStrc	;populate DNS structure
	stx	dnsStrc+1
	lda	#<dnsStrc
	ldx	#>dnsStrc
	ldy	#K_DNRES	;resolve DNS
	jsr	ip65
	bcc	@10
	LoadW	errorMsg,noResolv
	LoadB	a0L,0
	sec
	rts
@10:	ldx	#3
@20:	lda	dnsStrc,x
	sta	bServer,x	;save binary address
	dex
	bpl	@20
	clc
	rts

title:	.byte	" Login ",0
lServer:	.byte	"Server:",0
lPort:	.byte	"Port:",0
lNick:	.byte	"Nickname:",0
lblAddrs:	.word	lServer,lPort,lNick
tServer:	.byte	"irc.tobug.net",0
	.res	11	;pad to 25
tPort:	.byte	"6667",0,0
tNick:	.res	16
tEnd:	.res	1	;marker
txtLens:	.byte	24,5,15
txtAddrs:	.word	tServer,tPort,tNick
getting:	.byte	0	;accepting input?
noServer:	.byte	"You must enter a server.",0
noResolv:	.byte	"Can't resolve server.",0
noPort:	.byte	"You must enter a port.",0
badPort:	.byte	"Port must be 1024 or higher.",0	
noNick:	.byte	"You must enter a nickname.",0
msgReslv:	.byte	"resolving host...",0
; -----------------------------------------------------------
iconData:	.byte	2
	.word	OK_LEFT+24
	.byte	ICON_TOP+8
;	------------------------------------------------
	.word	okIcon
	.byte	OK_LEFT/8,ICON_TOP
	.byte	6,16
	.word	doOK
;	------------------------------------------------
	.word	cnclIcon
	.byte	CNC_LEFT/8,ICON_TOP
	.byte	6,16
	.word	doCancel
;	------------------------------------------------
okIcon:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-ok.pcx (48x16, 2 colors, indexed)
;
        .byte   $05,$FF,$82,$FE,$80,$04,$00,$82,$03,$80,$04,$00,$B8,$03,$80,$00
        .byte   $7C,$C6,$00,$03,$80,$00,$C6,$CC,$00,$03,$80,$00,$C6,$D8,$00,$03
        .byte   $80,$00,$C6,$F0,$00,$03,$80,$00,$C6,$E0,$00,$03,$80,$00,$C6,$F0
        .byte   $00,$03,$80,$00,$C6,$D8,$00,$03,$80,$00,$C6,$CC,$00,$03,$80,$00
        .byte   $7C,$C6,$00,$03,$80,$04,$00,$82,$03,$80,$04,$00,$81,$03,$06,$FF
        .byte   $81,$7F,$05,$FF

 
cnclIcon:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-cncl.pcx (48x16, 2 colors, indexed)
;
        .byte   $05,$FF,$82,$FE,$80,$04,$00,$82,$03,$80,$04,$00,$83,$03,$87,$C0
        .byte   $03,$00,$83,$E3,$8C,$60,$03,$00,$AC,$63,$8C,$07,$9F,$1E,$3C,$63
        .byte   $8C,$0C,$DD,$B3,$66,$63,$8C,$07,$D9,$B0,$66,$63,$8C,$0C,$D9,$B0
        .byte   $7E,$63,$8C,$0C,$D9,$B0,$60,$63,$8C,$6C,$D9,$B3,$66,$63,$87,$C7
        .byte   $D9,$9E,$3C,$63,$80,$04,$00,$82,$03,$80,$04,$00,$81,$03,$06,$FF
        .byte   $81,$7F,$05,$FF
 

; -----------------------------------------------------------
iconDis:	.byte	2
	.word	OK_LEFT+24
	.byte	ICON_TOP+8
;	------------------------------------------------
	.word	okDis
	.byte	OK_LEFT/8,ICON_TOP
	.byte	6,16
	.word	iconNop
;	------------------------------------------------
	.word	cnclDis
	.byte	CNC_LEFT/8,ICON_TOP
	.byte	6,16
	.word	iconNop
;	------------------------------------------------
okDis:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-okDis.pcx (48x16, 2 colors, indexed)
;
        .byte   $05,$FF,$82,$FE,$80,$04,$00,$82,$03,$80,$03,$00,$B9,$80,$03,$80
        .byte   $00,$1F,$31,$80,$03,$80,$00,$31,$B3,$00,$03,$80,$00,$63,$6C,$00
        .byte   $03,$80,$00,$63,$78,$00,$03,$80,$00,$C6,$E0,$00,$03,$80,$00,$C6
        .byte   $F0,$00,$03,$80,$01,$8D,$B0,$00,$03,$80,$01,$8D,$98,$00,$03,$80
        .byte   $01,$F3,$18,$00,$03,$80,$04,$00,$82,$03,$80,$04,$00,$81,$03,$06
        .byte   $FF,$81,$7F,$05,$FF
 
cnclDis:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-cnclDis.pcx (48x16, 2 colors, indexed)
;
        .byte   $05,$FF,$82,$FE,$80,$04,$00,$82,$03,$80,$04,$00,$83,$03,$81,$F0
        .byte   $03,$00,$83,$3B,$83,$18,$03,$00,$AC,$1B,$86,$03,$CF,$8F,$1E,$33
        .byte   $86,$06,$6E,$D9,$B3,$33,$8C,$07,$D9,$B0,$66,$63,$8C,$0C,$D9,$B0
        .byte   $7E,$63,$98,$19,$B3,$60,$C0,$C3,$98,$D9,$B3,$66,$CC,$C3,$9F,$1F
        .byte   $66,$78,$F1,$83,$80,$04,$00,$82,$03,$80,$04,$00,$81,$03,$06,$FF
        .byte   $81,$7F,$05,$FF
 



