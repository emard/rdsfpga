#!/usr/bin/python
# -*- coding: utf-8 -*-

# convert lookuptable to vhdl table

import sys
with open('wavtable.csv') as f:
  array = [[int(x) for x in line.split()] for line in f]
print("constant C_dbpsk_wav_len: std_logic_vector(7 downto 0) := %d;" % len(array));
print("type dbpsk_wav_type is array(0 to %d) of std_logic_vector(7 downto 0);" % (len(array)-1));
print("constant dbpsk_wav_map: dbpsk_wav_type := (");
j = 0
for a in array:
  j += 1
  i = a[0]
  string = "x\"%02x\"" % a[1]
  if j < len(array):
    string += ","
  if i % 16 == 15:
    string += "\n"
  sys.stdout.write(string)
print(");")
