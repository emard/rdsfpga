all: vhdls

VHDLS=msg.vhd wav.vhd
vhdls: $(VHDLS)

msg.vhd: rds-hello.asm
	./asm2vhdtab.py > $@

wav.vhd: wavtable.csv
	./wav2vhdtab.py > $@

sinc: sinc.c
	gcc -Wall -std=gnu99 -Os $< -lm -o $@

sinc.csv: sinc
	./sinc > sinc.csv

plot: sinc.csv
	gnuplot sinc.gnuplot

clean:
	rm -f $(VHDLS) sinc.csv wavtable-dbpskgen.csv *~
