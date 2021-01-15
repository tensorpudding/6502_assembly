;;; 10print - implement the famous BASIC program 10 PRINT for the Commodore
	!to "10print", cbm
	* = $1300

	!addr SCREEN= $0400	; start of screen memory
	!addr BLINE = $07c0 	; address of bottom line in screen memory
	!addr CLINE = $fb	; address of current line (16-bit)
	!addr NLINE = $fd	; address of new line (16-bit)
	!addr RANDOM = $d41b
	!addr DELAY = $fa

initialize:
	jsr setuprand		; call SID initialization routine
	
start:				; set CLINE to $0400 and NLINE to $0428
	lda #$04
	sta CLINE+1
	sta NLINE+1
	lda #$0
	sta CLINE
	lda #$28
	sta NLINE
scrollscreen:
	ldx #24			; gonna loop through line 2 through 25
xloop:	
	ldy #0 		; 40 characters per line
yloop:	
	lda (NLINE),y
	sta (CLINE),y
	iny
	cpy #40
	bne yloop
;;;  now we copy NLINE address to CLINE, then add #40 to NLINE
	lda NLINE
	sta CLINE
	lda NLINE+1
	sta CLINE+1
	clc
	lda NLINE
	adc #40
	sta NLINE
	lda NLINE+1
	adc #0
	sta NLINE+1

	dex
	bne xloop
	
;;; now we fill the bottom line with blanks
	lda #$20
	ldy #0
spaceloop:
	sta BLINE,y
	iny
	cpy #40
	bne spaceloop

;;; now we fill the bottom with 40 random / and \ characters

	ldy #0
printloop:
	jmp delay1sec
	lda RANDOM
	rol			; pop off high digit to carry
	lda #0	
	adc #77			; now A is 77 or 78 depending on high bit
	sta BLINE,y
	iny
	cpy #40
	bne printloop

	jmp start

setuprand:			; setup SID chip for RNG
	lda #$ff		; set frequency to max
	sta $d40e		; and store in voice 3 high and low bytes
	sta $d40f
	lda #$80		; send 80 to voice control register
	sta $D412
	rts

delay1sec:
	lda #0
	sta DELAY
delayloop:	
	dec DELAY
	bne delayloop
	rts
