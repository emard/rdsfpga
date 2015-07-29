reset
input_file = 'wavtable.csv' # original wav table
# input_file = 'wavtable-dbpskgen.csv' # gnuplot generated (wave shape not 100% correct)

# every 1::<first>::<last>

# positive half-sine:    32::47  (x-32, 128-y)
# negative half-sine:    32::47  (x-32,     y)
# positive phase change:  0::31  (x   ,     y)
# negative phase change:  0::31  (x   , 128-y)

# suggest code input:      start1  sign1   start2  sign2
# 0: +1/2 sin,  -1/2 sin       32      1       32      0
# 1: -1/2 sin,  +1/2 sin       32      0       32      1
# 2: +change                    0      0       16      0
# 3: -change                    0      1       16      1

# if (counter & 31) == 0 fetch new bit

# if bit == 0:
# index = 32 + (counter & 15) = counter | 32
# index = ((bit^1) * 32) | ( ((bit) * 16) & counter);
# sign = ((counter & 16) / 16) ^ phase ^ 1

# if bit == 1:
# index = (counter & 31) = counter
# index = ((bit^1) * 32) | ( ((bit) * 16) & counter);
# sign = phase
# phase ^= 1


plot \
   input_file every 1::32::47 using  (  0  -32+$1):(128-$2), \
   input_file every 1::32::47 using  ( 16  -32+$1):($2), \
   input_file every 1::0::31  using  ( 32     +$1):($2), \
   input_file every 1::32::47 using  ( 64  -32+$1):($2), \
   input_file every 1::0::31  using  ( 80     +$1):($2), \
   input_file every 1::32::47 using  (112  -32+$1):($2), \
   input_file every 1::32::47 using  (128  -32+$1):(128-$2), \
   input_file every 1::0::47  using  (144     +$1):(128-$2), \

pause -1
