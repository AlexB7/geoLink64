; -----------------------------------------------------------
; geoLink: A networked GEOS application for the Commodore 64 
;          which includes an IRC client.
;
; Written by Glenn Holmer (a.k.a "Shadow", a.k.a "Cenbe")
; -----------------------------------------------------------

; -----------------------------------------------------------
; geoLinkVal: validation routines for geoLink
; -----------------------------------------------------------
	.include	"geoLink.inc"
	.include	"geosmac.inc"
	.include	"geossym.inc"
	.include	"geossym2.inc"
	.include	"const.inc"
	.include	"jumptab.inc"
	.export		bin2hex
	.export		byte2asc
	.export		hexChars
	.export		valIp
	.export		valMac
	.export		valWork
	.export		modLoad

modLoad		:= 	$fa7	; Location for overlays, just above main program.
	
; -----------------------------------------------------------
; Validate an input field as an IP address ("dotted quad"). Binary 
; address is built at valWork.
;	pass:	a0, address of input field
;	return:	carry clear if valid, set otherwise
;	destroyed:	a1 (octet work area)
;		a2 (constant for multiplication by 10)
;		a3L (octet counter)
;		a3H (temp. storage for .Y)
; -----------------------------------------------------------
valIp:	ldx	#3
	lda	#0
@10:	sta	valWork,x
	dex
	bpl	@10
	sta	a1L	;where one octet is built
	sta	a1H
	sta	a2H
	sta	a3L	;octet counter
	lda	#10	;constant for BMult
	sta	a2L
nextOct:	ldy	#0
@20:	lda	(a0),y
	beq	lastVal
	sty	a3H	;save index
	jsr	isNum
	bcc	notNum
	cpy	#3
	bcs	bogus	;too many digits
	ldx	#a1	;multiply octet being built by 10
	ldy	#a2
	jsr	BMult
	ldy	a3H
	lda	(a0),y	;and add current digit
	and	#$0f
	clc
	adc	a1L
	sta	a1L
	lda	#0
	adc	a1H
	sta	a1H
	iny		;next digit
	bne	@20
notNum:	cmp	#'.'
	bne	bogus
	lda	a3H	;any digits entered?
	beq	bogus
	lda	a1H
	bne	bogus	;built octet is too big (>255)
	lda	a1L
	ldx	a3L
	sta	valWork,x
	iny		;point a0 to next octet
	tya
	clc
	adc	a0L
	sta	a0L
	lda	#0
	adc	a0H
	sta	a0H
	lda	#0
	sta	a1L
	sta	a1H
	inc	a3L	;octet count
	lda	a3L
	cmp	#4
	bcs	bogus
	jmp	nextOct
lastVal:	tya
	beq	bogus
	ldx	a3L
	cpx	#3
	bne	bogus
	lda	a1L	;save last octet
	sta	valWork,x
	clc
	rts
bogus:	sec
	rts
; -----------------------------------------------------------
; Check if value in .A is numeric digit.
;	pass:	.A, character to test
;	return:	Carry set if numeric, clear otherwise.
; -----------------------------------------------------------
isNum:	cmp	#$30
	bcc	@10
	cmp	#$3a
	bcc	@20
	clc
	rts
@20:	sec
@10:	rts

; -----------------------------------------------------------
; Validate an input field as a MAC address (12:34:56:ab:cd:ef). Binary
; address is built at valWork.
;	pass:	a0, address of input field
;	return:	carry clear if valid, set otherwise
;	destroyed:	a1L (byte work area)
;		a3L (byte counter)
; -----------------------------------------------------------
valMac:	ldx	#5
	lda	#0
@10:	sta	valWork,x
	dex
	bpl	@10
	sta	a1L
	sta	a3L
nextByte:	ldy	#0
@20:	lda	(a0),y
	beq	lastHex
	jsr	isHex
	bcc	notHex
	cpy	#2	;too many digits
	bcs	bogusHex
	txa		;isHex returns binary value in .X
	cpy	#1	;second digit of two?
	beq	@30
	clc
	asl	a
	asl	a
	asl	a
	asl	a
	bra	@40
@30:	ora	a1L
@40:	sta	a1L
	iny
	bne	@20
notHex:	cmp	#':'
	bne	bogusHex
	cpy	#2	;must be two digits
	bne	bogusHex
	lda	a1L
	ldx	a3L
	sta	valWork,x
	iny
	tya
	clc
	adc	a0L
	sta	a0L
	lda	#0
	adc	a0H
	sta	a0H
	lda	#0
	sta	a1L
	inc	a3L
	lda	a3L
	cmp	#6
	bcs	bogusHex
	jmp	nextByte
lastHex:	cpy	#2	;must be two digits
	bne	bogusHex
	ldx	a3L
	cpx	#5	;must be six pairs
	bne	bogusHex
	lda	a1L
	sta	valWork,x
@10:	cmp	#$ff	;broadcast address is invalid
	bne	@20
	dex
	bmi	bogusHex	;all values are $ff
	lda	valWork,x
	bne	@10
@20:	ldx	#5	;all zeros are invalid
@30:	lda	valWork,x
	bne	@40
	dex
	bpl	@30
	bmi	bogusHex
@40:	clc		;validation successful
	rts
bogusHex:	sec		;validation failed
	rts
; -----------------------------------------------------------
; Check if value in .A is hex digit.
;	pass:	.A, character to test
;	return:	Carry set if hex digit, clear otherwise
;		.X contains value of hex character.
; -----------------------------------------------------------
isHex:	ldx	#15
@10:	cmp	hexChars,x
	beq	@20
	cpx	#10
	bcc	@30
	cmp	hexChars+6,x
	beq	@20
@30:	dex
	bpl	@10
	clc
	rts
@20:	sec
	rts
; -----------------------------------------------------------
; Convert binary byte (e.g. ip65 error code) to ASCII hex string.
;	pass:	byte to be converted in .A
;	return:	hex string in .X and .Y
; -----------------------------------------------------------
bin2hex:	pha
	and	#$f0
	clc
	ror	a
	ror	a
	ror	a
	ror	a
	tax
	lda	hexChars,x
	tax
	pla
	and	#$0f
	tay
	lda	hexChars,y
	tay
	rts	

; -----------------------------------------------------------
; Convert binary byte to decimal string by repeated subtraction.
;	pass:	.A, binary number
;		a2, address to put string (four bytes)
;	return:	null-terminated decimal string at (a2)
;		.Y points to null byte at end
;	destroyed:	a0L (minuend)
;		a1L (accumulator)
;		a1H (division constant)
; -----------------------------------------------------------
byte2asc:	sta	a0L
	ldy	#0
	sty	a1L
	lda	#100
	sta	a1H
@10:	lda	a0L
@20:	cmp	a1H
	bcc	@30
	sec
	sbc	a1H
	sta	a0L
	inc	a1L
	bne	@20
@30:	lda	a1L
	bne	@35
	cpy	#0	;no leading zeros
	beq	@37
@35:	ora	#$30
	sta	(a2),y
	iny
	lda	#0
	sta	a1L
@37:	lda	a1H
	cmp	#10
	beq	@40
	lda	#10
	sta	a1H
	bne	@10
@40:	lda	a0L
	ora	#$30
	sta	(a2),y
	iny
	lda	#0
	sta	(a2),y
	rts
; -----------------------------------------------------------
valWork:	.res	6	;work area for validation
hexChars:	.byte	"0123456789abcdefABCDEF"


