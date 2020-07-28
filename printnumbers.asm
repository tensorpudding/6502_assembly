;;;  place the 16-bit number to be printed at the dividend location
;;; place the address to start printing in $b6-$b7
	!addr PRINTLOC = $b6
print16bit:	
	;; set the divisor to 10
	lda #$a
	sta divisor

	;; set counter to 0
	ldy #0
	sty printcounter

div10:
	jsr div16x8
	lda remainder
	pha
	inc printcounter
	
;; check if each quotient byte is zero
	lda #$0
	cmp quotient
	bne copyq
	cmp quotient+1
	bne copyq
	jmp loop2
	
copyq:	ldx #$2
copyq2:	lda quotient-1,x
	sta dividend-1,x
	dex
	bne copyq2
	ldy #0	
	jmp div10


	
loop2:	pla
	clc
	adc #$30
	ldy #0
	sta (PRINTLOC),y
	dec printcounter
	bne loop2
	rts
	
	!src "div16x8.asm"
	
printcounter:	!hex 00
