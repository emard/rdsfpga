sram write:
1. chip high-z: sram_lbl = 1, sram_ubl = 1, sram_wel = 1
2. wait
3. set address
4. wait tSA = 0ns (don't need to vait :)
5. chip enable: sram_lbl = 0, sram_ubl = 0, sram_wel = 1
5. set data
6. wait tSD = 60ns (but max 15us)
7. write: sram_wel = 0
8. wait tHD = 0ns (don't need to vait :)
9. release data pins
10. read: sram_wel = 1
11. optionally verify by reading data
12. chip high-z: sram_lbl = 1, sram_ubl = 1, sram_wel = 1

16-bit latch to ram
