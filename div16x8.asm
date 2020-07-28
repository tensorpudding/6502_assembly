	;; div16x8.s
	!addr dividend = $c00
	!addr quotient = $c02
	!addr divisor = $c04
	!addr remainder = $c05

	;;  prepare dividend and divisor
	lda #$64
	sta dividend
	sta dividend+1
	lda #9
	sta divisor

div16x8:
	lda #0
	sta quotient
	sta quotient+1
	ldx #16
	nop
dloop:	asl dividend
	rol dividend+1
	rol
	cmp divisor
	php
	rol quotient
	rol quotient+1
	plp
	bcc nosbc
	sec
	sbc divisor
	nop
nosbc:	dex
	nop
	bne dloop
	sta remainder
	nop
	rts			
