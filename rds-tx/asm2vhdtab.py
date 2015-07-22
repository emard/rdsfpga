#!/usr/bin/python3
# -*- coding: utf-8 -*-

import sys
# convert lookuptable to vhdl table

filename = 'rds-hello.asm'
# count data in the file
n = 0
array = ()
with open(filename) as f:
  for line in f:
    a = line.split()
    if a[0] == "movlw":
      n += 1
      array += (int(a[3], 10), a[1]),
print("constant C_rds_msg_len: std_logic_vector(15 downto 0) := %d;" % len(array));
print("type rds_msg_type is array(0 to %d) of std_logic_vector(7 downto 0);" % (len(array)-1));
print("constant rds_msg_map: rds_msg_type := (");
j = 0
for a in array:
      j += 1
      code = a[1]
      i = a[0]
      string = "x\"%02x\"" % (int(a[1], 0))
      if j < len(array):
        string += ","
      if i == 12:
        string += "\n"
      sys.stdout.write(string)
print(");")
