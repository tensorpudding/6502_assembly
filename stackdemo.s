;;; stackdemo.s - demonstrate stack usage for 6502

	!to "stackdemo", cbm
	* = $1300

level1:
	lda #$aa
	pha
	nop
	jsr level2
here:	nop
	pla
	rts
	nop
	nop
level2:
	lda #$bb
	pha
	nop
	jsr level3
	nop
	pla
	rts
	nop
	nop
level3:
	lda #$cc
	pha
	nop
	jsr endgame
	nop
	pla
	rts
	nop
	nop
	
endgame:
	nop
	tsx
	inx
	inx
	inx
	inx
	inx
	inx
	txs
	rts
