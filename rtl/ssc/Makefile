PROJ = top

PIN_DEF = pins.pcf
DEVICE = hx1k
PKG = tq144

all: $(PROJ).bin
	sudo tinyprog -p $(PROJ).bin

ssc.mem:
	hexdump -e '1/1 "%02X" "\n"' rom/ssc.bin -v > rom/$@

%.json: *.v
	yosys -q -l $(PROJ).log -p 'synth_ice40 -top $(PROJ) -json $@' $^

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) --package $(PKG) --freq 20 --json $(PROJ).json --pcf $(PIN_DEF) --asc $(PROJ).asc

%.bin: %.asc
	icepack $< $@

clean:
	rm -f $(PROJ).blif $(PROJ).log $(PROJ).json $(PROJ).asc $(PROJ).bin

.SECONDARY:
.PHONY: all clean
