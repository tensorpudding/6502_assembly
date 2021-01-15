	;;  game-life.s - Conway's Game of Life simulator

	!to "life", cbm
	* = $1300
	
	!addr SCREEN = $0400
	!addr WORK   = $2000
	!addr RANDOM = $d41b 	; random # from SID
	!addr xx     = $fa	; pseudocoordinates
	!addr yy     = $fb	; pseudocoordinates
	!addr cell   = $fc	; 16 bit address
	!addr turns  = $fe	; number of generations to generate
	!addr temp   = $b00	; placeholder address
	!addr OFFSET = $b02	; high byte memory offset for xytocell routine

setuprand:			; setup SID chip for RNG
	lda #$ff		; set frequency to max
	sta $d40e		; and store in voice 3 high and low bytes
	sta $d40f
	lda #$80		; send 80 to voice control register
	sta $D412
start:	
	lda #32
	jsr fillscreen
				; fill with random cells to seed live char
	jsr randomcells
	lda #$ff
	sta turns
taketurn:	
	jsr clearwork
	
checkcells:			; sweep 40x25 grid

	ldx #0
	stx xx
xloop:	
	ldy #0
	sty yy
yloop:	
	ldx xx
	ldy yy
	lda #$04		; we're setting offset to screen first
	sta OFFSET		; xytocell

	jsr xytocell		; set cell value to yy*40+xx+$WORK,
	ldy #$0
	lda (cell),y		; get value in SCREEN pointed by cell
	cmp #$20		; is the cell empty? then dead
	beq deadcell
;;;  live cell, so increment each of eight neighbors in term
;;;  xx and yy contain the value of current cell, X and Y offset from cell
	ldx xx
	ldy yy
	dex			; UP+LEFT
	dey
	jsr incneighbor
	ldx xx			; UP
	ldy yy
	dey
	jsr incneighbor
	ldx xx			; UP+RIGHT
	ldy yy
	inx
	dey
	jsr incneighbor
	ldx xx			; RIGHT
	ldy yy
	inx
	jsr incneighbor
	ldx xx			; DOWN+RIGHT
	ldy yy
	iny
	inx
	jsr incneighbor
	ldx xx			; DOWN
	ldy yy
	iny
	jsr incneighbor
	ldx xx			; DOWN+LEFT
	ldy yy
	iny
	dex
	jsr incneighbor
	ldx xx			; LEFT
	ldy yy
	dex
	jsr incneighbor
deadcell:	
	inc yy
	lda yy
	cmp #25
	bne yloop
	inc xx
	lda xx
	cmp #40
	bne xloop

	
;;; Now we check WORK, and if the cell is 2, leave it alone, 3, make alive, otherwise make dead
	
newboard:
	ldy #4
newboardy:
	ldx #0
newboardx:	
	lda $1fff,X
	cmp #2
	beq twocell	       ; do nothing if cell has two neighbors
	cmp #3			; if cell is not 3 or 2, it's dead
	bne dead
	lda #$53
	jmp storecell
dead:	lda #$20
storecell:
	sta $03ff,X
twocell:
	inx
	bne newboardx
	inc newboardx+2		; modify the code to change the bounds of loop
	inc storecell+2
	dey
	bne newboardy
	lda #$1f
	sta newboardx+2		; switch code back after we change the board
	lda #$03
	sta storecell+2
;;; end of generation, increment turns
	dec turns
	beq turndone
	;; 	jsr waitforkey
	jmp taketurn
turndone:
	rts
	
;;; Wait until key pressed, by checking the key buffer in an infinite loop
waitforkey:			
	lda $d4
	cmp #$58
	beq waitforkey
	rts
	
incneighbor:			; increments cell offset by X,Y, if in bounds
	jsr isinbounds
	cmp #0
	beq +
	lda #$20		; switch so we're working in WORKING
	sta OFFSET		;
	jsr xytocell		; now CELL has address of neighbor
	ldy #0
	lda (cell),y
	clc
	adc #1
	sta (cell),y
+	rts

	
;;; isinbounds: checks if the cell location is on screen
;;; returns 1 in A if coordinates are in bounds
;;; 0 if not
;;;  coordinates in X and Y registers, bounds 0-39 for X, 0-24 for Y
isinbounds:
	cpx #40 		; if x too far left, now $FF
	bcs +			; so no need to check if < 0
	cpy #25
	bcs +
	lda #1
	rts
+	lda #0
	rts

xytocell:     ; makes $cell equl to Y*40+X+$offset
	lda #0
	sta cell+1		; high byte
	sta temp+1
	tya
	sta cell
	sta temp
	;;  multiply cell by 40 is equal to multiplying a copy by 32, another by 8, and adding them together
	clc
	asl cell
	rol cell+1
	asl cell
	rol cell+1
	asl cell
	rol cell+1
	asl cell
	rol cell+1
	asl cell
	rol cell+1 		; we have yy*32 in cell now
	lda #0
	sta temp+1
	tya
	asl temp
	rol temp+1
	asl temp
	rol temp+1
	asl temp
	rol temp+1		; now we have yy*8 in temp
	lda temp
	clc
	adc cell		; now we do the two bytewise additions
	sta cell		; to get yy*40 across cell
	lda temp+1
	adc cell+1
	sta cell+1
	clc
	txa			; finally add xx across the two
	adc cell		; if this adc carries...
	sta cell
	lda #0
	adc cell+1		; ...it is added to cell+1
	sta cell+1
	;; Now we add all this to $2000 to find the actually memory address
	clc
	lda OFFSET		; we're loading offset value here, $20 or $04
	adc cell+1
	sta cell+1
	rts
clearwork:			; zero working area memory
	ldx #250
	lda #0
-	sta WORK-1,x
	sta WORK+249,x
	sta WORK+499,x
	sta WORK+749,x
	dex
	bne -
	rts
	

randomcells: 			; fill random cells on screen with heart char
	ldx #250
	lda #$53
-	bit RANDOM
	bvs +
	sta SCREEN-1,X
+	bit RANDOM
	bvs +
	sta SCREEN+249,X
+	bit RANDOM
	bvs +
	sta SCREEN+499,X
+	bit RANDOM
	bvs +
	sta SCREEN+749,X	
+	dex
	bne -
	rts	
	


fillscreen: 			; fills whole screen mem with value in A
	ldx #250
-	sta SCREEN-1,X
	sta SCREEN+249,X
	sta SCREEN+499,X
	sta SCREEN+749,X
	dex
	bne -
	rts


fillglider:			; puts a single glider on the board
	lda #$53
	sta SCREEN+42
	sta SCREEN+83
	sta SCREEN+121
	sta SCREEN+122
	sta SCREEN+123
	rts
