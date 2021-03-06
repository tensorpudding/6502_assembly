;;;  worm - The classic bsdgames version, implemented for Commodore 128
	!to "worm.prg", cbm
	* = $1300
	
;;; address defines
	!addr SCREEN = $0400	; start of screen memory
	!addr BLINE = $07c0	; bottom line
	!addr RANDOM = $d41b
	!addr VICCURSOR = $0a27	; disable cursor
	!addr BORDERCOLOR = $d020
	!addr BGCOLOR = $d021
	!addr COLORRAM = $d800
	!addr BASIC = $4000	; start of basic, head here when done!

	!addr HEADADDR = $fa	; 16-bit, byte with offset of worm head in display memory
	!addr NUMADDR = $fc	; 16-bit, pointer to where we place random numbers in screen memory
	!addr TAILADDR = $b0	; 16-bit, pointer to location of tail
	!addr LENGTH = $b2	; 16-bit, length of worm
	!addr MOREBODY = $b4
	!addr KEYPRESS = $d4
	!addr LASTKEY = $fe
	!addr JIFFIES = $a2
	;; list of pointers to worm body pieces stored in $2000 - $27ff
	!addr HEADP = $b6 	; pointer to the head location pointer
	!addr TAILP = $b8	; pointer to the tail location pointer
	!addr SP = $ba		; save stack pointer
	!addr PRINTLOC = $b6
;;; constants
	HEADCHAR = $0f	; filled circle
	BODYCHAR = $51	; 0
	EDGECHAR = $2a	; Asterisk
	SPACE = $20	; blank space
	BLACK = $0	; background colors
	WHITE = $1
	CYAN = $3
	YKEY = $19
	NKEY = $27
	
;;; program loop
start:
	tsx
	stx SP			; save stack pointer so we can reset stack
	lda #0			; banks in IO bank
	sta $ff00
	sta LASTKEY		; initialize LASTKEY to 0
	jsr setuprand		; setup RNG
	lda #BLACK		; setup colors
	sta BORDERCOLOR
	sta BGCOLOR
	lda #WHITE
	jsr fillcolorram
	lda #SPACE		;
	jsr fillscreen		; fill screen with blanks
	lda #1
	sta VICCURSOR		; disable cursor during game
	lda #5
	sta MOREBODY		; initialize MOREBODY to 5
	lda #0	
	sta HEADP		; initialize HEADP/TAILP to $2000
	sta TAILP
	lda #$20
	sta HEADP+1
	sta TAILP+1
	jsr drawborder
	jsr startworm
	jsr placeanum
	jsr mainloop
	rts

;;; place worm at starting location
;;; also initialize pointer table so that HEADP is a pointer to the head, and TAILP to a pointer for tail
startworm:
	lda #$f4
	ldy #0
	sta HEADADDR		; we're storing $0600 as the starting location
	sta TAILADDR		; of the head in HEADADDR, then storing $0600
	sta (HEADP),y		; in our pointer table for HEADP and TAILP
	sta (TAILP),y
	lda #5			; therefore $2000-$2001 = 00 60
	sta HEADADDR+1		; and HEADP/TAILP already point to $2000
	sta TAILADDR+1
	iny
	sta (HEADP),y
	sta (TAILP),y
	dey
	lda #HEADCHAR		; character for worm
	sta (HEADADDR),y	; stores @ at the location where head starts
	rts
	
;;;  main loop, waits for input, then moves worm, and repeats
mainloop:
	jsr gamekeypress	; gets keypress, stores in A
	jsr printbody
	cmp #$1d		; is it h (left?)
	bne ++
;;; subtract 1 from HEADADDR, then print @ in screen memory in its new location
	lda HEADADDR
	bne +
	dec HEADADDR+1
+	dec HEADADDR
	jsr printhead
	jmp mainloop
++	cmp #$2a		; is it l (right?)
	bne ++
	inc HEADADDR
	bne +
	inc HEADADDR+1
+	jsr printhead
	jmp mainloop
++	cmp #$25		; is it k (up?)
	bne ++
	lda HEADADDR
	sec
	sbc #$28
	bcs +
	dec HEADADDR+1
+	sta HEADADDR
	jsr printhead
	jmp mainloop
++	cmp #$22		; is it j (down?)
	bne ++
	lda HEADADDR
	clc
	adc #$28
	sta HEADADDR
	bcc +
	inc HEADADDR+1
+	jsr printhead
	jmp mainloop
++	cmp #$3e
	beq +
	lda #88
	sta KEYPRESS
	jmp mainloop
+	rts
	
;;; check for collisions. Is there already a worm character or wall in HEADADDR?
;;; also add to MOREBODY if we run into a number
collision:
	ldy #0
	lda (HEADADDR),y
	cmp #BODYCHAR
	bne +
	jmp endgame
+	cmp #HEADCHAR
	bne +
	jmp endgame
+	cmp #EDGECHAR
	bne +
	jmp endgame
+	cmp #SPACE
	bne +
	rts
	;; If we get down here, we've collided with a number. Add the number value to MOREBODY. Remember '1' = #$31, etc. so subtract #$30
+	sec
	sbc #$30
	sta MOREBODY
	;; Now we place a new number on screen
	jsr placeanum
	rts
	
;;; close down the game, print the score?
endgame:
	ldy #0
-	lda endmsg1,y
	beq +
	sta $0572,y
	iny
	bne -
+	ldy #0
-	lda endmsg2,y
	beq +
	sta $059a,y
	iny
	bne -
+	ldy #0
-	lda endmsg1,y
	beq +
	sta $05c2,y
	iny
	bne -
+	ldy #0
-	lda endmsg3,y
	beq +
	sta $05ea,y
	iny
	bne -
+	ldy #0
-	lda endmsg1,y
	beq +
	sta $0612,y
	iny
	bne -
+	ldy #0	
-	lda endmsg4,y
	beq +
	sta $063a,y
	iny
	bne -
+	ldy #0
-	lda endmsg1,y
	beq +
	sta $0662,y
	iny
	bne -
;; now we're filling the score in $06f7
+	lda #6
	sta PRINTLOC+1
	lda #$f7
	sta PRINTLOC
	lda LENGTH
	sta dividend
	lda LENGTH+1
	sta dividend+1
	jsr print16bit
	;;  now we wait for y/n from the player
	jsr waitforyn

;;; After we've updated the new head location, check to see if there is a collision and then print the new head if we can. Update the location of HEADADDR in HEADP
printhead:
	pha
	jsr collision
	lda #HEADCHAR
	ldy #0
	sta (HEADADDR),y
	;; move HEADP up two spots
	inc HEADP
	inc HEADP
	bne +
	inc HEADP+1
	lda HEADP+1
	cmp #$28
	bne +
	lda #$20
	sta HEADP+1
	;; store HEADADDR where HEADP points
+	lda HEADADDR
	sta (HEADP),y
	iny
	lda HEADADDR+1
	sta (HEADP),y
	pla
	jsr removetail
	rts
	
;;; Remove tail character if necessary, move TAILP, depending on the value of MOREBODY.
removetail:
	pha
	lda MOREBODY
	beq +
	;; MOREBODY is positive, so no need to remove tail
	dec MOREBODY
	inc LENGTH
	bne ++
	inc LENGTH+1
++	pla
	jsr delay1sec
	rts
	;; MOREBODY == 0, we remove character at (TAILADDR) and increment TAILP
+	lda #SPACE
	ldy #0
	sta (TAILADDR),y
	inc TAILP
	inc TAILP
	bne +
	inc TAILP+1
	lda TAILP+1
	cmp #$28
	bne +
	lda #$20
	sta TAILP+1
	;; we get our new value of TAILADDR from the pointer list
+	lda (TAILP),y
	sta TAILADDR
	iny
	lda (TAILP),y
	sta TAILADDR+1
	pla
	jsr delay1sec
	rts
	
delay1sec:			; nop for 65k loops
	ldx #$b0
	stx delay+1
--	stx delay
-	inc delay
	bne -
	inc delay+1
	bne --
	rts


;;; We need to draw the body character on the character we were at, before we move the head
printbody:
	pha
	lda #BODYCHAR
	ldy #0
	sta (HEADADDR),y
	pla
	rts

;;; Place a number 1-9 on an empty space on the screen
placeanum:
	ldx RANDOM 		; low byte 00-ff
	lda RANDOM		; high byte needs to be between 04 and 07
	and #$03		; aka 00000100 to 00000111
	ora #$04
	;; but if A is 7, and X is greater than $e7, we are too big
	cmp #$07
	bne +
	cpx #$e6		; carry set if location is off screen
	bcc +
	jmp placeanum
+	stx NUMADDR
	sta NUMADDR+1
	ldy #0
	lda (NUMADDR),y
	cmp #SPACE
	bne placeanum
	lda RANDOM		; get a random # and place it at NUMADDR
	and #$07		; 0-7
	clc
	adc #$31		; convert the # to screencode '1' is 49, etc.
	sta (NUMADDR),y
	rts

;;; wait for keypress, keycode will be in A
gamekeypress:
	lda #$c4 		; 256-60 jiffies
	sta JIFFIES
-	lda KEYPRESS
	cmp #88			; has a key not been pressed?
	bne +
	lda JIFFIES
	bne -
	lda LASTKEY
+	sta LASTKEY
	rts
	
waitforyn:
- 	lda KEYPRESS 		; wait in loop until we have a key depressed
	cmp #88
	beq -
	pha			; save keypress
-	lda KEYPRESS		; now loop until key is released
	cmp #88
	bne -
	pla
	cmp #YKEY
	bne +
	;; y stuff goes here
	;; fix SP, then jmp to start
	ldx SP
	txs
	jmp start
+	cmp #NKEY
	bne waitforyn
	;; n stuff goes here
;;; quit game here
	lda #0
	sta $d0
	jmp BASIC

;;; draw the border on the screen for initial setup
drawborder:
	lda #EDGECHAR			; *
	ldx #40
-	sta SCREEN-1,x
	sta BLINE-1,x
	dex
	bne -
	lda #$27		; start temp address at $0427, end of first line
	sta HEADADDR
	lda #4
	sta HEADADDR+1
	ldx #24	
-	lda #EDGECHAR
	ldy #0
	sta (HEADADDR),y
	iny
	sta (HEADADDR),y
	;; store asterisk, add 40 to HEADADDR
	pha
	lda HEADADDR
	clc
	adc #40
	sta HEADADDR
	lda HEADADDR+1
	adc #0
	sta HEADADDR+1
	pla
	dex
	bne -
	rts
	

;;; imports
	!src "setuprand.asm"
	!src "textscreenlib.asm"
	!src "printnumbers.asm"

delay:	!hex 00 00
endmsg1: !scr "                 ", 0	
endmsg2: !scr "    game over!   ", 0
endmsg3: !scr " your score:     ", 0
endmsg4: !scr " play again? y/n ", 0
