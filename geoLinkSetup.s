; -----------------------------------------------------------
; geoLink: GEOS 64 IRC client
;
; Written by Glenn Holmer (a.k.a "Shadow", a.k.a "Cenbe")
; -----------------------------------------------------------

; MOD_SETUP
.segment	"OVERLAY1"

; -----------------------------------------------------------
; geoLinkSetup (setup module for geoLink)
; -----------------------------------------------------------
	.forceimport	mainMenu
	.forceimport	optMenu
	.forceimport	optWord
	.forceimport	errHndlr
	.forceimport	setupOK
	.forceimport	setName
	.forceimport	okDB
	.forceimport	okMsg
	.forceimport	cfg2geos
	.forceimport	noDhcp
	.forceimport	ip65
	.forceimport	cfg2ip65
	.forceimport	errorDB
	.forceimport	errorMsg
	.forceimport	valIp
	.forceimport	macAddr
	.forceimport	valMac
	.forceimport	strWidth
	.forceimport	hexChars
	.forceimport	byte2asc
	.forceimport	valWork
	.forceimport	ipAddr
	.forceimport	dhcp
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
NUM_ITEM	=	5	;not counting checkbox (add extra ITM_HIGH)
BOX_OFFS	=	(TTL_HIGH+8)+(16+8)
BOX_HIGH	=	BOX_OFFS+(ITM_HIGH*NUM_ITEM)+ITM_HIGH
BOX_TOP	=	(200-BOX_HIGH)/2
TXT_TOP	=	BOX_TOP+20	;top of input text string
TXT_HIGH	=	12	;height of input text area
TXT_LEFT	=	72
TXT_WIDE	=	80
BOX_WIDE	=	TXT_LEFT+TXT_WIDE+8
BOX_LEFT	=	(320-BOX_WIDE)/2
LBL_LEFT	=	BOX_LEFT+8
LBL_BOT	=	BOX_TOP+28	;baseline of prompt string
OK_LEFT	=	BOX_LEFT+24
CNC_LEFT	=	OK_LEFT+48+16
ICON_TOP	=	BOX_TOP+(TTL_HIGH+8)+(ITM_HIGH*NUM_ITEM)+ITM_HIGH
; -----------------------------------------------------------

modSetup:	ldx	#PRC_POLL
	jsr	BlockProcess	;don't poll network card during setup
	lda	#2	;50% stipple
	jsr	SetPattern
	LoadB	r2L,15	;don't erase menu
	LoadB	r2H,199
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;clear screen
	jsr	boxDims
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
	LoadW	r0,lblDhcp	;label for checkbox icon
	MoveB	a1L,r1H
	LoadW	r11,BOX_LEFT+TXT_LEFT ;beneath text boxes
	jsr	PutString
	lda	dhcp	;in DHCP mode?
	beq	@15
	LoadW	checkbox,ckIcon ;select checkbox
@15:	LoadW	r0,iconData
	jsr	DoIcons
	ldx	#((4*NUM_ITEM)+2)
	lda	#0
@20:	ora	ipAddr-1,x	;if all addresses are zero,
	dex		;don''t pre-fill input fields
	bne	@20
	tax		;force flags to be set
	beq	@30
	jsr	fillText
@30:	jsr	getInput
	rts

; -----------------------------------------------------------
; Fill text fields with ASCII values (convert binary to dotted quads).
;	destroyed:	a2 (text address)
;		a3L (field counter)
;		a3H (temp. storage for .X)
;		valWork (six bytes)
; -----------------------------------------------------------
fillText:
	lda	#0
	sta	a3L
doNext:
	asl	a
	tax
	lda	txtAddrs,x	;set destination address
	sta	a2L
	lda	txtAddrs+1,x
	sta	a2H
	txa
	asl	a
	tax
	ldy	#0
@10:
	lda	ipAddr,x	;ipAddr refers to entire table
	sta	valWork,y	;set source bytes
	inx
	iny
	cpy	#6	;MAC address uses all 6 (overrun OK)
	bne	@10
	lda	a3L
	cmp #NUM_ITEM-1			; cmp	#(NUM_ITEMS-1)
	beq	fillHex
; -----------------------------------------------------------
	ldx	#0	; inner loop (ASCII)
@20:
	lda	valWork,x
	jsr	byte2asc
	cpx	#3
	beq	fillNext
	lda	#'.'
	sta	(a2),y	;.Y''s last value from byte2asc
	iny
	tya
	clc
	adc	a2L
	sta	a2L
	lda	#0
	adc	a2H
	sta	a2H
	inx
	bne	@20
; -----------------------------------------------------------
fillNext:
	inc	a3L	;outer loop end
	lda	a3L
	cmp	#NUM_ITEM
	bne	doNext
	beq	showAll

; -----------------------------------------------------------
fillHex:	ldx	#0	;inner loop (hex)
	ldy	#0
@10:	lda	valWork,x
	stx	a3H
	jsr	byte2hex
	ldx	a3H
	cpx	#5
	beq	fillNext
	lda	#':'
	sta	(a2),y
	iny
	inx
	bne	@10
;	------------------------------------------------
;	text strings loaded, show all before input:
;	------------------------------------------------
showAll:	LoadB	a0L,0
	LoadB	a0H,(TXT_TOP+TXT_HIGH)-4
	lda	a0L
showText:	asl	a
	tax
	lda	txtAddrs,x
	sta	r0L
	lda	txtAddrs+1,x
	sta	r0H
	LoadB	r1L,0	;no string fault
	MoveB	a0H,r1H
	LoadW	r11,BOX_LEFT+TXT_LEFT+3
	jsr	PutString
	AddVB	ITM_HIGH,a0H
	inc	a0L
	lda	a0L
	cmp	#NUM_ITEM
	bne	showText
	rts

; -----------------------------------------------------------
; Convert binary byte to hex string.
;	pass:	.A, binary number
;		a2, address to put string
;	return:	two-byte hex string at (a2)
;	destroyed:	a0L (temporary storage)
; -----------------------------------------------------------
byte2hex:	sta	a0L
	and	#$f0
	clc
	ror	a
	ror	a
	ror	a
	ror	a
	tax
	lda	hexChars,x
	sta	(a2),y
	iny
	lda	a0L
	and	#$0f
	tax
	lda	hexChars,x
	sta	(a2),y
	iny
	rts

; -----------------------------------------------------------
; Loop through input fields. Mouse click will select field.
; -----------------------------------------------------------
getInput:	LoadW	rightMargin,(BOX_LEFT+TXT_LEFT+TXT_WIDE)-1
	LoadW	StringFaultVec,0
	LoadW	otherPressVec,chkMouse
	LoadB	getting,$ff	;enable input
reGet:	lda	dhcp	;in DHCP mode?
	beq	@10
	LoadB	a0L,NUM_ITEM-1 ;skip all but MAC input
	LoadB	a0H,(TXT_TOP+2)+(ITM_HIGH*(NUM_ITEM-1))
	bne	getStrs
@10:	LoadB	a0L,0	;loop counter
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
	LoadB	r2L,15	;max. length
	lda	a0L
	cmp	#(NUM_ITEM-1)	;MAC address
	bcc	@5
	inc	r2L
	inc	r2L
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
	cpx	#NUM_ITEM			; cpx	#NUM_ITEMS
	bne	@20
	rts
@20:	AddVB	ITM_HIGH,r2L
	AddVB	ITM_HIGH,r2H
	bne	@10
@30:	lda	dhcp	;mouse was in region
	beq	@35
	cpx	#(NUM_ITEM)-1
	beq	@35	;if in DHCP mode, ignore mouse click
	rts		;in any area but MAC address
@35:	txa
	pha		;save field counter
	lda	#TXT_TOP+2
@40:	dex
	bmi	@50
	clc
	adc	ITM_HIGH
	bne	@40
@50:	sta	a0H	;Y-position
	pla
	sta	a0L	;restore field counter for output
	jmp	mGetStrs

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
; Display a prompt and the bounding box for its text input.
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
	rts
; -----------------------------------------------------------
; Get the dimensions of the setup dialog.
; -----------------------------------------------------------
boxDims:	LoadB	r2L,BOX_TOP
	LoadB	r2H,(BOX_TOP+BOX_HIGH)-1
	LoadW	r3,BOX_LEFT
	LoadW	r4,(BOX_LEFT+BOX_WIDE)-1
	rts

; -----------------------------------------------------------
; handler for DHCP checkbox toggle
; -----------------------------------------------------------
dhToggle:	lda	dhcp
	beq	@10
	jmp	dhOff
@10:	lda	#$ff	;switch to DHCP mode
	sta	dhcp
	jsr	killText
	LoadW	checkbox,ckIcon ;switch checkbox icons
	LoadW	r0,iconData
	jsr	DoIcons
	LoadB	a0L,0
	LoadB	a1H,TXT_TOP
@20:	lda	a1H	;clear text areas in GUI
	clc
	adc	#1	;don't touch border
	sta	r2L
	adc	#(TXT_HIGH-3)
	sta	r2H
	LoadW	r3,(BOX_LEFT+TXT_LEFT)+1
	LoadW	r4,(BOX_LEFT+TXT_LEFT+TXT_WIDE)-2
	lda	#0	;clear
	jsr	SetPattern
	jsr	Rectangle
	AddVB	ITM_HIGH,a1H
	inc	a0L
	lda	a0L
	cmp	#NUM_ITEM-1	;don't clear MAC address
	bne	@20
	lda	#0
	ldx	#16
@30:	sta	ipAddr-1,x	;clear IP address fields
	sta	tipAddr-1,x	;and text input data
	sta	tnetmask-1,x
	sta	tgateway-1,x
	sta	tdnsAddr-1,x
	dex
	bne	@30
	LoadW	a0,tmacAddr	;if valid MAC address
	jsr	valMac	;was entered, save it
	bcs	@50
	ldx	#5
@40:	lda	valWork,x
	sta	macAddr,x
	dex
	bpl	@40
@50:	jsr	fillText	;show 0.0.0.0
	jsr	getInput
	rts
; -----------------------------------------------------------
dhOff:	lda	#0	;switch off DHCP mode
	sta	dhcp
	jsr	killText
	LoadW	checkbox,unckIcon ;switch checkbox icons
	LoadW	r0,iconData
	jsr	DoIcons
	jsr	getInput	;start text input loop
	rts

; -----------------------------------------------------------
; handler for OK icon
; -----------------------------------------------------------
doOK:	LoadW	okPtr,okDis	;disable icons
	LoadW	okVect,iconNop
	LoadW	cnclPtr,cnclDis
	LoadW	cnclVect,iconNop
	LoadW	r0,iconData
	jsr	DoIcons
	jsr	killText	;kill text input
	lda	dhcp	;in DHCP mode,
	beq	@10	;only validate MAC address
	ldx	#(NUM_ITEM-1)
	bne	nextVal
@10:	ldx	#0	;field counter
;	------------------------------------------------
nextVal:	txa
	pha
	asl	a
	tax
	lda	txtAddrs,x
	sta	a0L
	lda	txtAddrs+1,x
	sta	a0H
	pla
	cmp	#(NUM_ITEM-1)
	beq	@10
	pha
	jsr	valIp
	bra	@20
@10:	pha
	jsr	valMac
@20:	pla
	sta	a0L	;prepare to re-enter offender
	bcc	valOK	;carry set by validators
	asl	a	;get index to error message
	tax
	ldy	#0
	lda	bogosity,x
	sta	errorMsg,y
	iny
	inx
	lda	bogosity,x
	sta	errorMsg,y
	LoadW	r0,errorDB
	jsr	DoDlgBox
	LoadB	a0H,TXT_TOP+2	;set location for re-entry
	ldx	a0L
@30:	dex
	bmi	@40
	AddVB	ITM_HIGH,a0H
	bne	@30
@40:	LoadB	getting,$ff
	LoadW	okPtr,okIcon	;re-enable icons
	LoadW	okVect,doOK
	LoadW	cnclPtr,cnclIcon
	LoadW	cnclVect,doCancel
	LoadW	r0,iconData
	jsr	DoIcons
	jmp	getStrs	;re-enter offending field
;	------------------------------------------------
valOK:	pha		;put address to hold area
	asl	a
	asl	a
	tay
	ldx	#0
@10:	lda	valWork,x
	sta	wipAddr,y
	iny
	inx
	cpx	#6	;MAC address uses all 6 (overrun OK)
	bne	@10
	pla
	tax
	inx
	cpx	#NUM_ITEM
	beq	allValOK
	jmp	nextVal
;	------------------------------------------------
;	input validation successful, set up IP stack config
;	------------------------------------------------
allValOK:	ldx	#((4*NUM_ITEM)+2)  ;+2 for MAC
@10:	lda	wipAddr-1,x	;copy settings from hold area
	sta	ipAddr-1,x	;to resident module
	dex
	bpl	@10
	jsr	cfg2ip65	;copy config to ip65
	ldy	#K_CINIT	;initialize card
	jsr	ip65	;(to write MAC address)
	ldy	#K_SINIT	;initialize IP stack variables
	jsr	ip65
;	------------------------------------------------
	lda	dhcp	;in DHCP mode?
	beq	@30
	ldy	#K_DINIT	;initialize DHCP (get address)
	jsr	ip65	;does its own polling!
	bcc	@20
	LoadW	errorMsg,noDhcp
	LoadW	r0,errorDB
	jsr	DoDlgBox
	LoadW	okPtr,okIcon	;re-enable icons
	LoadW	okVect,doOK
	LoadW	cnclPtr,cnclIcon
	LoadW	cnclVect,doCancel
	LoadW	r0,iconData
	jsr	DoIcons
	jmp	getInput
@20:	jsr	cfg2geos	;copy ip65 config to application
;	------------------------------------------------
@30:	ldx	#PRC_POLL
	jsr	RestartProcess	;start network card polling
	LoadW	okMsg,connOK
	LoadW	r0,okDB
	jsr	DoDlgBox

;	------------------------------------------------
;	save settings file
;	------------------------------------------------
saveData:	lda	#0
	ldx	#16
@10:	sta	setName,x
	dex
	bpl	@10
reSave:	LoadW	r0,saveDB
	LoadW	r5,setName
	jsr	DoDlgBox
	lda	r0L
	cmp	#DBGETSTRING
	beq	@10
	jsr	cleanup	;user clicked Cancel
	LoadB	setupOK,$ff	;mark setup OK anyway
	rts
@10:	LoadW	r6,setName
	jsr	FindFile
	cpx	#FILE_NOT_FOUND
	beq	@30
	txa
	beq	@20
	jmp	errHndlr
@20:	LoadW	r0,replDB	;file exists, prompt for replace
	jsr	DoDlgBox
	lda	r0L
	cmp	#YES
	bne	reSave	;user clicked NO, try again
	LoadW	r0,setName
	jsr	DeleteFile	;ignore any error
@30:	LoadW	r9,setHead
	LoadB	r10L,0	;put at start of directory
	jsr	SaveFile
	txa
	beq	@40
	jmp	errHndlr
@40:	LoadB	setupOK,$ff
	LoadW	okMsg,savedMsg
	LoadW	r0,okDB
	jsr	DoDlgBox
	jsr	cleanup	;return to main module
	rts

; -----------------------------------------------------------
; Turn off string input and disable mouse; clear screen except menu.
; -----------------------------------------------------------
cleanup:	jsr	killText	;kill text input
	LoadW	otherPressVec,0
	lda	#2	;50% stipple
	jsr	SetPattern
	LoadB	r2L,15	;don''t erase menu
	LoadB	r2H,199
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;clear screen
	LoadW	optWord,optMenu
	LoadW	r0,mainMenu
	lda	#1
	jsr	DoMenu	;re-enable options menu
	rts
; -----------------------------------------------------------
; handler for Cancel icon
; -----------------------------------------------------------
doCancel:	jsr	killText	;kill text input
	LoadW	keyVector,0	;kill string input
	lda	setupOK	;setup completed successfully?
	bne	@10
	jmp	EnterDeskTop	;no setup, can''t continue
@10:	jsr	cleanup
	rts
; -----------------------------------------------------------
; Icon NOP (for disabled icons)
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

title:	.byte	" Network Settings ",0
lipAddr:	.byte	"IP address:",0
lnetmask:	.byte	"Netmask:",0
lgateway:	.byte	"Gateway:",0
ldnsAddr:	.byte	"DNS server:",0
lmacAddr:	.byte	"MAC address:",0
lblDhcp:	.byte	"use DHCP",0
lblAddrs:	.word	lipAddr,lnetmask,lgateway,ldnsAddr,lmacAddr
tipAddr:	.res	16
tnetmask:	.res	16
tgateway:	.res	16
tdnsAddr:	.res	16
tmacAddr:	.res	18
txtAddrs:	.word	tipAddr,tnetmask,tgateway,tdnsAddr,tmacAddr
getting:	.byte	0	;accepting input?
wipAddr:	.res	4	;hold area for setup data
wnetmask:	.res	4
wgateway:	.res	4
wdnsAddr:	.res	4
wmacAddr:	.res	6
; -----------------------------------------------------------
; header block prototype for settings file
; -----------------------------------------------------------
setHead:	.word	setName	;in resident module
	.byte	3,21,$bf	;icon metadata
	.byte	$ff,$ff,$ff	;icon data
	.byte	$80,$00,$01
	.byte	$80,$00,$01
	.byte	$80,$00,$ff
	.byte	$80,$03,$ff
	.byte	$80,$1e,$ff
	.byte	$81,$e3,$ff
	.byte	$82,$00,$ff
	.byte	$82,$00,$01
	.byte	$81,$e0,$01
	.byte	$80,$1c,$01
	.byte	$80,$03,$81
	.byte	$80,$00,$41
	.byte	$ff,$00,$41
	.byte	$ff,$c3,$81
	.byte	$ff,$7c,$01
	.byte	$ff,$c0,$01
	.byte	$ff,$00,$01
	.byte	$80,$00,$01
	.byte	$80,$00,$01
	.byte	$ff,$ff,$ff
	.byte	$80 | USR
	.byte	DATA	;GEOS file type
	.byte	SEQUENTIAL 	;Commodore file type
	.word	ipAddr	;load address
	.word	ipAddr+23	;end addr
	.word	0	;init addr
	;Note that this perm string is in the resident module as well!
	.byte	"geoLinkSettingsV1.0",0  ;permanent name string
	.byte	"ShadowM            ",0
	.byte	"geoLink        V1.0",0  ;parent application
	.byte	"geoLink network settings",0

; -----------------------------------------------------------
; OK, Cancel, and DHCP checkbox icons in data entry box
; -----------------------------------------------------------
iconData:	.byte	3
	.word	OK_LEFT+24
	.byte	ICON_TOP+8
;	------------------------------------------------
checkbox:	.word	unckIcon	;or ckIcon
	.byte	((BOX_LEFT+TXT_LEFT)-32)/8
	.byte	BOX_TOP+(TTL_HIGH+8)+(ITM_HIGH*NUM_ITEM)-4
	.byte	3,16
	.word	dhToggle
;	------------------------------------------------
okPtr:	.word	okIcon
	.byte	OK_LEFT/8,ICON_TOP
	.byte	6,16
okVect:	.word	doOK
;	------------------------------------------------
cnclPtr:	.word	cnclIcon
	.byte	CNC_LEFT/8,ICON_TOP
	.byte	6,16
cnclVect:	.word	doCancel
;	------------------------------------------------
unckIcon:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-unck.pcx (24x16, 2 colors, indexed)
;
        .byte   $09,$00,$A7,$FF,$FE,$00,$80,$02,$00,$80,$02,$00,$80,$02,$00,$80
        .byte   $02,$00,$80,$02,$00,$80,$02,$00,$80,$02,$00,$80,$02,$00,$80,$02
        .byte   $00,$80,$02,$00,$80,$02,$00,$FF,$FE,$00
 
ckIcon:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-ck.pcx (24x16, 2 colors, indexed)
;
        .byte   $05,$00,$AB,$70,$00,$00,$F0,$FF,$FF,$F0,$80,$07,$F0,$80,$0F,$C0
        .byte   $80,$1F,$00,$88,$3E,$00,$9C,$7A,$00,$BE,$F2,$00,$BF,$E2,$00,$9F
        .byte   $C2,$00,$8F,$82,$00,$87,$02,$00,$80,$02,$00,$FF,$FE,$00

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

; -----------------------------------------------------------
; save settings file prompt (dialog box)
; -----------------------------------------------------------
saveDB:	.byte	DEF_DB_POS | 1
	.byte	DBTXTSTR,14,28
	.word	savePrpt
	.byte	DBGETSTRING,14,42,r5,16
	.byte	CANCEL,16,72
	.byte	0
savePrpt:	.byte	BOLDON,"Save settings as:",PLAINTEXT,0
; -----------------------------------------------------------
; replace settings file prompt (dialog box)
; -----------------------------------------------------------
replDB:	.byte	DEF_DB_POS | 1
	.byte	DBTXTSTR,14,28
	.word	exists
	.byte	YES,9,72
	.byte	NO,16,72
	.byte	0
exists:	.byte	BOLDON,"File exists, replace?",PLAINTEXT,0
; -----------------------------------------------------------
badIp:	.byte	"Invalid IP address.",0
badMask:	.byte	"Invalid netmask.",0
badGw:	.byte	"Invalid gateway address.",0
badDns:	.byte	"Invalid DNS server address.",0
badMac:	.byte	"Invalid MAC address.",0
bogosity:	.word	badIp,badMask,badGw,badDns,badMac
noRouter:	.byte	"Can't contact gateway router.",0
connOK:	.byte	"Connected to network.",0
savedMsg:	.byte	"Settings saved.",0

