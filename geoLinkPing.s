
; MOD_PING
.segment	"OVERLAY2"

; -----------------------------------------------------------
; geoLinkPing (ping module for geoLink)
; -----------------------------------------------------------
	.forceimport	mainMenu
	.forceimport	optMenu
	.forceimport	optWord
	.forceimport	ip65
	.forceimport	dnsStrc
	.forceimport	beep
	.forceimport	errorDB
	.forceimport	errorMsg
	.forceimport	bankNet
	.forceimport	bankRst
	.forceimport	bin2hex
	.forceimport	pingAddr
	.forceimport	strWidth
	.include	"geoLink.inc"
	.include	"geosmac.inc"
	.include	"geossym.inc"
	.include	"geossym2.inc"
	.include	"const.inc"
	.include	"jumptab.inc"
; -----------------------------------------------------------
PNG_TOP	=	58
PNG_LEFT	=	72
PNG_HIGH	=	84
PNG_WIDE	=	176
TTL_HIGH	=	12
; -----------------------------------------------------------

.segment	"OVERLAY2"

.proc	modPing: near

.segment	"OVERLAY2"

modPing:	lda	#2	;50% stipple
	jsr	SetPattern
	LoadB	r2L,15	;do not erase menu
	LoadB	r2H,199
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	; clear screen
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
	LoadW	r0,lblHost
	LoadB	r1H,PNG_TOP+29
	LoadB	r11,PNG_LEFT+16
	jsr	PutString
	LoadB	r2L,PNG_TOP+20	;input field bounding box
	LoadB	r2H,(PNG_TOP+20)+12
	LoadW	r3,PNG_LEFT+48
	LoadW	r4,(PNG_LEFT+48)+112
	lda	#$ff
	jsr	FrameRectangle
	LoadW	r2L,PNG_TOP+72	;status area
	LoadW	r2H,(PNG_TOP+PNG_HIGH)-1
	LoadW	r3,PNG_LEFT
	LoadW	r4,(PNG_LEFT+PNG_WIDE)-1
	lda	#$ff
	jsr	FrameRectangle
	LoadW	r0,pngIcons
	jsr	DoIcons
	jmp	getPngIp

.endproc
	
; -----------------------------------------------------------
; set up for ping address input
; -----------------------------------------------------------
getPngIp:	ldx	#ADDRLEN
	lda	#0
@10:	sta	pngAddr-1,x	;clear input area
	dex
	bpl	@10
rePngIp:	LoadB	getting,$ff
	LoadW	rightMargin,(PNG_LEFT+48)+109
	LoadW	StringFaultVec,0
	LoadW	r0,pngAddr
	LoadB	r1L,0	;no string fault
	LoadB	r1H,PNG_TOP+23
	LoadW	r2L,24	;max. characters
	LoadW	r11,PNG_LEFT+51
	LoadW	keyVector,pngStart
	jsr	GetString
	rts		;to MainLoop
; -----------------------------------------------------------
; clear status area
; -----------------------------------------------------------
clearSts:	LoadW	r2L,PNG_TOP+73
	LoadW	r2H,(PNG_TOP+PNG_HIGH)-2
	LoadW	r3,PNG_LEFT+1
	LoadW	r4,(PNG_LEFT+PNG_WIDE)-2
	lda	#0	;clear
	jsr	SetPattern
	jsr	Rectangle
	rts
; -----------------------------------------------------------
; get dimensions of ping window
; -----------------------------------------------------------
boxDims:	LoadB	r2L,PNG_TOP
	LoadB	r2H,(PNG_TOP+PNG_HIGH)-1
	LoadW	r3,PNG_LEFT
	LoadW	r4,(PNG_LEFT+PNG_WIDE)-1
	rts
; -----------------------------------------------------------
; draw title bar
; -----------------------------------------------------------
titleBar:	lda	#9	;horizontal stripes
	jsr	SetPattern
	LoadB	r2L,PNG_TOP
	LoadB	r2H,PNG_TOP+TTL_HIGH
	LoadW	r3,PNG_LEFT
	LoadW	r4,(PNG_LEFT+PNG_WIDE)-1
	jsr	Rectangle
	LoadW	r0,pngTitle
	jsr	strWidth	;returns string width in a0
	LoadB	r1H,PNG_TOP+8
	; ((box width - string width) / 2) + box left
	LoadW	r11,PNG_WIDE
	SubW	a0,r11
	clc
	ror	r11H
	ror	r11L
	lda	r11L
	clc
	adc	#<PNG_LEFT
	sta	r11L
	lda	r11H
	adc	#>PNG_LEFT
	sta	r11H
	jsr	PutString
	rts

; -----------------------------------------------------------
; Start pinging a remote host (start network poll process, ping
; timeout process). Handler for "Start" icon.
; -----------------------------------------------------------
pngClick:	LoadB	keyData,$0d	;entry point when user clicks "Start" icon
	lda	keyVector
	ldx	keyVector+1	;keyVector points to pngStart
	jmp	CallRoutine	;simulate hitting Return
pngStart:	lda	getting	;entry point when user hits Return
	bne	@10
	rts
@10:	lda	pngAddr
	bne	@20
	LoadW	errorMsg,noAddr
	LoadW	r0,errorDB
	jsr	beep
	jsr	DoDlgBox
	jmp	rePngIp
@20:	lda	#<pngAddr
	ldx	#>pngAddr
	sta	dnsStrc	;populate DNS structure
	stx	dnsStrc+1
	lda	#<dnsStrc
	ldx	#>dnsStrc
	ldy	#K_DNRES	;resolve DNS
	jsr	ip65
	bcc	@30
	jsr	clearSts
	LoadW	r0,msgBogus	;put error message to status area
	LoadB	r1H,PNG_TOP+80
	LoadW	r11,PNG_LEFT+8
	jsr	PutString
	jsr	beep
	jmp	rePngIp	;re-enable IP address entry
@30:	ldx	#3
@40:	lda	dnsStrc,x	;copy resolved IP to ping IP
	sta	pingAddr,x
	dex
	bpl	@40
	jsr	clearSts	;clear status area
	LoadW	r0,msgPing
	LoadB	r1H,PNG_TOP+80
	LoadW	r11,PNG_LEFT+8
	jsr	PutString	;show "pinging "
	jsr	ipDots	;show address and ellipsis
	LoadW	doStrIcn,stpIcon	;switch icons
	LoadW	doStart,pngStop
	LoadW	r0,pngIcons
	jsr	DoIcons
	lda	#<pongStrc	;ip65 ICMP param struct
	ldx	#>pongStrc
	ldy	#K_ICLIST	;add echo reply listener
	jsr	ip65
	bcc	@50
	ldy	#K_GETERR
	jsr	ip65
	jsr	bin2hex
	stx	pLerrNo
	sty	pLerrNo+1
	LoadW	errorMsg,pLerr
	LoadW	r0,errorDB
	jsr	DoDlgBox
	rts

@50:	LoadW	pongs,0
	ldx	#PRC_POLL
	jsr	RestartProcess	;enable network polling
	ldx	#PRC_PING
	jsr	RestartProcess	;enable pings once/second
	rts

; -----------------------------------------------------------
; Stop pinging a remote host. Handler for "Stop" icon.
; -----------------------------------------------------------
pngStop:	ldx	#PRC_PING
	jsr	BlockProcess	;block ping send process
	lda	#0	;ICMP reply
	ldy	#K_ICULIS	;remove ICMP listener
	jsr	ip65
	jsr	clearSts
	LoadW	doStrIcn,strIcon	;switch icons
	LoadW	doStart,pngClick
	LoadW	r0,pngIcons
	jsr	DoIcons
	jmp	rePngIp	;re-enable IP address entry
; -----------------------------------------------------------
; Ping reply service routine. This routine gets called from within
; the ip65 polling routine, so we have to bank I/O out to use 
; PutString, then bank it back in to return to ip65. 
; -----------------------------------------------------------
pngPong:	jsr	bankRst	;restore as if returning from ip65
	inc	pongs
	bne	@10
	inc	pongs+1
@10:	LoadW	r0,msgRecv
	LoadB	r1H,PNG_TOP+80
	LoadW	r11,PNG_LEFT+8
	LoadW	rightMargin,(PNG_LEFT+PNG_WIDE)-9
	jsr	PutString	;show "pong #"
	MoveW	pongs,r0
	lda	#$c0	;left-justify, supress leading zeros
	jsr	PutDecimal	;show pong count
	LoadW	r0,pongFrom
	jsr	PutString	;show " from "
	jsr	ipDots	;show IP address and ellipsis
	jsr	bankNet	;set up as if calling ip65
	rts
; -----------------------------------------------------------
; Print the ping IP address followed by an ellipsis.
;	destroyed:	a0L
; -----------------------------------------------------------
ipDots:	ldx	#0
	stx	a0L
@10:	lda	pingAddr,x
	sta	r0L
	lda	#0
	sta	r0H
	lda	#$c0	;left-justify, suppress leading zeros
	jsr	PutDecimal
	lda	#'.'
	jsr	PutChar
@20:	inc	a0L
	ldx	a0L
	cpx	#4
	bne	@10
	lda	#'.'	;and two more...
	jsr	PutChar
	lda	#'.'	;...make an ellipsis
	jsr	PutChar
	lda	#' '
	jsr	PutChar	;in case next sequence no. is narrower
	lda	#' '
	jsr	PutChar	;in case next sequence no. is narrower
	rts

; -----------------------------------------------------------
; Handler for exit icon. Turn off string input and disable mouse; 
; clear screen except menu.
; -----------------------------------------------------------
cleanup:	ldx	#PRC_PING
	jsr	BlockProcess	;turn off pings
	lda	#0	;ICMP reply
	ldy	#K_ICULIS	;remove ICMP listener
	jsr	ip65
	LoadB	getting,0
	jsr	pngClick	;turn off text input
	LoadW	otherPressVec,0
	lda	#2	;50% stipple
	jsr	SetPattern
	LoadB	r2L,15	;do not erase menu
	LoadB	r2H,199
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;clear screen
	LoadW	optWord,optMenu
	LoadW	r0,mainMenu
	lda	#1
	jsr	DoMenu	;re-enable options menu
	rts

getting:	.byte	0
pngTitle:	.byte	" Ping ",0
lblHost:	.byte	"Host:",0
noAddr:	.byte	"You must enter an address.",0
msgPing:	.byte	"pinging ",0
pngAddr:	.res	129
ADDRLEN	=	(*-pngAddr)
msgBogus:	.byte	"Invalid host.",0

msgRecv:	.byte	"response #",0
pongFrom:	.byte	" from ",0
pongStrc:	.byte	0	;ICMP reply
	.word	pngPong	;callback address
pLerr:	.byte	"Error $"
pLerrNo:	.res	2
	.byte	0
	.byte	" adding ping reply listener.",0
pongs:	.byte	0,0	;number of ping replies heard
; -----------------------------------------------------------
; Start/stop icons for ping test (enabled and disabled).
; -----------------------------------------------------------
pngIcons:	.byte	2
	.word	PNG_LEFT+84
	.byte	PNG_TOP+56
;	------------------------------------------------
	.word	exitIcon
	.byte	((PNG_LEFT+PNG_WIDE)-24)/8,PNG_TOP
	.byte	2,12
	.word	cleanup
;	------------------------------------------------
doStrIcn:	.word	strIcon	;or stpIcon
	.byte	(PNG_LEFT/8)+8, PNG_TOP+48
	.byte	6,16
doStart:	.word	pngClick	;or pngStop
;	------------------------------------------------
strIcon:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-str.pcx (48x16, 2 colors, indexed)
;
        .byte   $05,$FF,$82,$FE,$80,$04,$00,$82,$03,$80,$04,$00,$B8,$03,$80,$F8
        .byte   $C0,$00,$0C,$03,$81,$8C,$C0,$00,$0C,$03,$81,$81,$E3,$CF,$DE,$03
        .byte   $81,$80,$C6,$6E,$0C,$03,$80,$F8,$C3,$EC,$0C,$03,$80,$0C,$C6,$6C
        .byte   $0C,$03,$80,$0C,$C6,$6C,$0C,$03,$81,$8C,$C6,$6C,$0C,$03,$80,$F8
        .byte   $73,$EC,$07,$03,$80,$04,$00,$82,$03,$80,$04,$00,$81,$03,$06,$FF
        .byte   $81,$7F,$05,$FF
 
stpIcon:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-stp.pcx (48x16, 2 colors, indexed)
;
        .byte   $05,$FF,$82,$FE,$80,$04,$00,$82,$03,$80,$04,$00,$C3,$03,$80,$1F
        .byte   $18,$00,$00,$03,$80,$31,$98,$00,$00,$03,$80,$30,$3C,$79,$F0,$03
        .byte   $80,$30,$18,$CD,$98,$03,$80,$1F,$18,$CD,$98,$03,$80,$01,$98,$CD
        .byte   $98,$03,$80,$01,$98,$CD,$98,$03,$80,$31,$98,$CD,$98,$03,$80,$1F
        .byte   $0E,$79,$F0,$03,$80,$00,$00,$01,$80,$03,$80,$00,$00,$01,$80,$03
        .byte   $06,$FF,$81,$7F,$05,$FF
 
exitIcon:
;
; This file was generated by sp65 2.17 - Git cc5c093 from
; button-exit.pcx (16x12, 2 colors, indexed)
;
        .byte   $04,$FF,$94,$80,$01,$80,$01,$80,$01,$87,$E1,$87,$E1,$87,$E1,$80
        .byte   $01,$80,$01,$80,$01,$FF,$FF





 


