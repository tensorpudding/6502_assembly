;;; routines for manipulating 32-bit values
;;; used by: sha256.s
	
	
;;; Copies series of zero-page byte to another address
;;; Y = address of first byte of source
;;; A = address of first byte of destination
;;; X = # of bytes
!zone fcopyzz_zone {
fcopyzz:
	sta .here+3
	sty .here+1
	dex
.here	lda $00,x
	sta $00,x
	dex
	bpl .here
	rts
}

	
;;; Returns the AND of E and F inside the cell E
;;; X = zero-page address of E
;;; A = zero page address of F
;;; X is clobbered, A is clobbered
!zone fand_zone {
fand:
	sta .here+3		; modify address at II, III
	stx .here+1		; modify address at I
	stx .here+5
	ldx #3
.here:	lda $00,x		; I
	and $00,x		; II
	sta $00,x		; III
	dex
	bpl .here
	rts
}
	
;;; Returns the XOR of E and F inside the cell E
;;; X = zero-page address of E
;;; A = zero page address of F
;;; X is clobbered, A is clobbered
!zone feor_zone {
feor:
	sta .here+3		; modify address at II, III
	stx .here+1		; modify address at I
	stx .here+5
	ldx #3
.here:	lda $00,x		; I
	eor $00,x		; II
	sta $00,x		; III
	dex
	bpl .here
	rts
}
	
;;; Returns the complement of E, leave result in place
;;; A = zero-page address of E
!zone fnot_zone {
fnot:
	sta .here+1
	sta .here+5
	ldx #3
.here:  lda $00,x
	eor #$ff
	sta $00,x
	dex
	bpl .here
	rts
}

;;; Rotate the 32-bit value N times to the right ROTR-N(M)
;;; Y = N
;;; X = zero page address of first byte of M
;;; Leaves Y = 0 at the end
!zone rotr_n {
rotr_n:
.here:	lsr $00,x
	inx
	ror $00,x
	inx
	ror $00,x
	inx
	ror $00,x
	dex
	dex
	dex
	bcc +	
	lda $00,x
	ora #$80
	sta $00,x
+	dey
	bne .here
	rts
}

;;; Rotate the 32-bit value N times to the left ROTL-N(M)
;;; Y = N
;;; X = zero page address of first byte of M
;;; Leaves Y = 0 at the end
!zone rotl_n {
rotl_n:
	inx
	inx
	inx
.here:	asl $00,x
	dex
	rol $00,x
	dex
	rol $00,x
	dex
	rol $00,x
	inx
	inx
	inx
	bcc +	
	lda $00,x
	ora #$01
	sta $00,x
+	dey
	bne .here
	dex
	dex
	dex
	rts
}

;;; Shift the 32-bit value N times to the right SHR-N(M)
;;; Y = N
;;; X = zero page address of first byte of M
;;; Leave Y = 0 at the end
!zone shr_n {
shr_n:
.here:	lsr $00,x
	inx
	ror $00,x
	inx
	ror $00,x
	inx
	ror $00,x
	dex
	dex
	dex
+	dey
	bne .here
	rts
}

;;; Returns the AND of E and F inside the cell E
;;; X =
;;; Y = 
