;;; textscreenlib.a - utility routines for manipulating the screen
fillscreen: 			; fills whole screen mem with value in A
	ldx #250
-	sta SCREEN-1,X
	sta SCREEN+249,X
	sta SCREEN+499,X
	sta SCREEN+749,X
	dex
	bne -
	rts
