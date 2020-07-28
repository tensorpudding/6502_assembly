;;; sha256 - calculate a sha256 hash for a file
;;;

	!to "sha256.prg", cbm
	* = $1300

	!src "shainc.asm"		; source our project includes

start:
	lda #$1
	sta TEMP1
	sta TEMP1+1
	sta TEMP1+2
	sta TEMP1+3
	lda #$66
	sta TEMP2
	sta TEMP2+1
	sta TEMP2+2
	sta TEMP2+3
	ldx #TEMP1
	ldy #1
	jsr rotr_n
	brk

;;; Returns f1 function from SHA
;;; f1(a) = ROTR-2(a) XOR ROTR-13(a) XOR ROTR-22(a)
!zone f1_zone {
f1:
	
}


	!src "32bitlib.asm"	; source our 32-bit utility library
