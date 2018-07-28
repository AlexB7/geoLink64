

------------page 1--------------


.if	Pass1
	.include	shadowSym
.endif
; ===========================================
.header
	.word 0
	.byte 3
	.byte 21

; .RTF has icon image *******************
 

	.byte $80 ö USR
	.byte APPLICATION
	.byte VLIR
	.word $0400
	.word $03FF
	.word $0400
	.byte "geoLink     V1.0",0,0,0,$00 
	.byte "ShadowM            ",0
	.block 43
	.byte "Links GEOS users together over the 'net.",0
.endh

