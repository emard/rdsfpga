all: vhdls

VHDLS=msg.vhd wav.vhd
vhdls: $(VHDLS)

msg.vhd: rds-hello.asm
	./asm2vhdtab.py > $@

wav.vhd: wavtable.csv
	./wav2vhdtab.py > $@

clean:
	rm -f $(VHDLS)
