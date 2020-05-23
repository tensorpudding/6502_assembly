;;; sha256 - calculate a sha256 hash for a file
;;;

	!to "sha256", cbm
	* = $1300

	!src "shainc.s"		; source our project includes

start:
	lda #$aa
	sta TEMP1
	sta TEMP1+1
	sta TEMP1+2
	sta TEMP1+3
	lda #$66
	sta TEMP2
	sta TEMP2+1
	sta TEMP2+2
	sta TEMP2+3
	ldx #$06
	ldy #TEMP1
	lda #TEMP3
	jsr fcopyzz
	brk

;;; Returns f1 function from SHA
!zone f1_zone {
f1:	
}


	!src "32bitlib.s"	; source our 32-bit utility library
