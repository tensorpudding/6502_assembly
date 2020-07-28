TARGETS := sha256.prg 10print.prg game-life.prg stackdemo.prg worm.prg
all: $(TARGETS)
%.prg: %.asm
	acme $^
%.d64: %.prg
	c1541 -format foo,di d64 $@ -write $<
%: %.d64
	x128 $<

.PHONY: clean
clean:
	rm -f $(TARGETS) *.d64 *.prg