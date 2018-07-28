; -----------------------------------------------------------
; geoLink: A networked GEOS application for the Commodore 64 
;          which includes an IRC client.
;
; Written by Glenn Holmer (a.k.a "Shadow", a.k.a "Cenbe")
; -----------------------------------------------------------

; -----------------------------------------------------------
; geoLinkEmbed: embed IP stack and mono font in geoLink
; -----------------------------------------------------------
	.forceimport	__STARTUP__
	.export		_main
	.include	"geoLink.inc"
	.include	"geosmac.inc"
	.include	"geossym.inc"
	.include	"geossym2.inc"
	.include	"const.inc"
	.include	"jumptab.inc"
; -----------------------------------------------------------
LOADADDR	=	$2e00
; -----------------------------------------------------------

.segment	"STARTUP"

.proc	_main: near

.segment	"STARTUP"

start:	lda	#0	;blank pattern
	jsr	SetPattern
	LoadB	r2L,0
	LoadB	r2H,199
	LoadW	r3,0
	LoadW	r4,319
	jsr	Rectangle	;clear screen
	LoadW	r0,embed
	jsr	showMsg
;	------------------------------------------------
	LoadW	r0,opening	;open geoLink as VLIR file
	jsr	showMsg
	LoadW	r0,geoLink
	jsr	OpenRecordFile
	jsr	errCheck
;	------------------------------------------------

.endproc

doStack:	LoadW	r0,loadIp65	;load IP stack into memory
	jsr	showMsg
	LoadW	r6,ip65File
	jsr	FindFile
	jsr	errCheck
	lda	dirEntryBuf+1	;track
	sta	r1L
	lda	dirEntryBuf+2	;sector
	sta	r1H
	LoadW	r7,LOADADDR
	lda	#<$6000
	sec
	sbc	#<LOADADDR
	sta	r2L
	lda	#>$6000
	sbc	#>LOADADDR
	sta	r2H	;r2 = max. length for load
	jsr	ReadFile	;read linked listof blocks
	jsr	errCheck
	MoveW	r7,endAddr
;	------------------------------------------------
emStack:	LoadW	r0,wrtIp65
	jsr	showMsg
	lda	#9	;store stack in record 9
	jsr	doPoint
	lda	endAddr
	sec
	sbc	#<LOADADDR
	sta	r2L
	lda	endAddr+1
	sbc	#>LOADADDR
	sta	r2H
	LoadW	r7,LOADADDR
	jsr	WriteRecord
	jsr	errCheck
	LoadW	r0,closing
	jsr	showMsg
	jsr	CloseRecordFile
	jsr	errCheck

;	------------------------------------------------
doFont:	LoadW	r0,openFont
	jsr	showMsg
	LoadW	r0,vipFont
	jsr	OpenRecordFile
	jsr	errCheck
	LoadW	r0,loadFont
	jsr	showMsg
	lda	#<$6000
	sec
	sbc	#<LOADADDR
	sta	r2L
	lda	#>$6000
	sbc	#>LOADADDR
	sta	r2H	;r2 = max. length for load
	LoadW	r7,LOADADDR
	LoadB	curRecord,8	;for 8-point
	jsr	ReadRecord
	jsr	errCheck
	MoveW	r7,endAddr
	LoadW	r0,clsFont
	jsr	showMsg
	jsr	CloseRecordFile
	jsr	errCheck
;	------------------------------------------------
emFont:	LoadW	r0,opening
	jsr	showMsg
	LoadW	r0,geoLink
	jsr	OpenRecordFile
	jsr	errCheck
	LoadW	r0,wrtFont
	jsr	showMsg
	lda	#8	;store font in record 8
	jsr	doPoint
	lda	endAddr
	sec
	sbc	#<LOADADDR
	sta	r2L
	lda	endAddr+1
	sbc	#>LOADADDR
	sta	r2H
	LoadW	r7,LOADADDR
	jsr	WriteRecord
	jsr	errCheck
	LoadW	r0,closing
	jsr	showMsg
	jsr	CloseRecordFile
	jsr	errCheck
	LoadW	r0,neoj
	jsr	showMsg
	LoadW	r0,300	;five seconds
	jsr	Sleep
	jmp	EnterDeskTop

; -----------------------------------------------------------
doPoint:	sta	recNo
	jsr	PointRecord
	jsr	errCheck
	tya
	beq	@20
	lda	recNo
	and	#$30
	sta	usedRec
	LoadW	r0,recInUse
	jmp	fatalErr
@20:	rts
; -----------------------------------------------------------
errCheck:	txa
	beq	@10
	jsr	decodErr
	LoadW	r0,errorMsg
	jmp	fatalErr
@10:	rts
; -----------------------------------------------------------
decodErr:	tay
	and	#$f0
	clc
	ror	a	
	ror	a	
	ror	a	
	ror	a
	tax
	lda	hexChars,x
	sta	errNo
	tya
	and	#$0f
	tax
	lda	hexChars,x
	sta	errNo+1
	rts	
; -----------------------------------------------------------
showMsg:	MoveB	yPos,r1H
	LoadW	r11,5
	jsr	PutString
	AddVB	10,yPos
	rts
; -----------------------------------------------------------
fatalErr:	jsr	showMsg
	LoadW	r0,300	;five seconds
	jsr	Sleep
	jmp	EnterDeskTop

geoLink:	.byte	"geoLink",0
vipFont:	.byte	"VIP64-mono",0
ip65File:	.byte	"ip65-geos",0
endAddr:	.res	2
recNo:	.byte	0
yPos:	.byte	10
embed:	.byte	BOLDON,"geoLink IP stack/font embedder",PLAINTEXT,0
opening:	.byte	"opening geoLink VLIR file",0
closing:	.byte	"closing geoLink VLIR file",0
loadIp65:	.byte	"loading ip65",0
wrtIp65:	.byte	"embedding ip65",0
openFont:	.byte	"opening mono font VLIR file",0
loadFont:	.byte	"loading mono font",0
clsFont:	.byte	"closing mono font VLIR file",0
wrtFont:	.byte	"embedding mono font",0
recInUse:	.byte	"record "
usedRec:	.byte	0," is in use!",0
errorMsg:	.byte	"Error $"
errNo:	.byte	0,0,", aborting!",0
neoj:	.byte	"Normal end of job.",0
hexChars:	.byte	"0123456789abcdef"

