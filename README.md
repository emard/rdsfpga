RDS modulator for FPGA

This code comes complete with FM transmitter.
No external components are needed, not even antenna
if FPGA is 1m close to the receiver.

Tune FM radio to 108 MHz (or change freq in main.v)
and RDS example text "TEST1234" should appear.

There's a simple audio tone synth, pressing
buttons will play notes.

Currently MONO only, STEREO is planned but not yet ready.

Tested with ULX2S, porting to other FPGAs should be
very possible.

Credits:

Marko Zec, svirajfm FM radio lab excercise for ULX2S,
fm transmitter and audio midi synth copypasted

N. G. Hubbard RDS transmitter for PIC microcontroller
DBPSK waveform copypasted

Christophe Jacquet, F8FTK RDS for Raspberry PI
Bit message generator in C code copypasted from
https://github.com/ChristopheJacquet/PiFmRds

Oona Räisänen OH2EIQ
RDS receiver "redsea" for RTL-SDR
used as receiver and for debugging
https://github.com/windytan/redsea

SoftFM
https://github.com/jorisvr/SoftFM
