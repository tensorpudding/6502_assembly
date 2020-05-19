;;; setuprand - utility routine to initialize RNG
setuprand:			
	lda #$ff		; set frequency to max
	sta $d40e		; and store in voice 3 high and low bytes
	sta $d40f
	lda #$80		; send 80 to voice control register
	sta $D412
	rts
