# this gnuplot file
# tries to plot and generate dbpsk wav file
# wave shape looks close but is different than
# original costable.txt

reset

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

T=sqrt(2.0)/2.0 # symbol rate visually adjuested for nice double peak shape
B=0.25
cosfilter(t) = cos(pi*t*B/T)/(1-4*(t*B/T)**2)
sinc(x) = x == 0 ? 1 : sin(x*pi)/(x*pi)
fsinc(x) = sinc(x) * cosfilter(x)

# phase changing double-peak dbpsk
function1(x) =-fsinc(x-0/T) -fsinc(x-1/T) \
              +fsinc(x-2/T) +fsinc(x-3/T) \
              -fsinc(x-4/T) -fsinc(x-5/T) \
              +fsinc(x-6/T) +fsinc(x-7/T) \
              -fsinc(x-8/T) -fsinc(x-9/T) \
              +fsinc(x-10/T)+fsinc(x-11/T) \
              -fsinc(x-12/T)-fsinc(x-13/T) \

# ordinary sine
function2(x) =-fsinc(x-0/T) +fsinc(x-1/T) \
              -fsinc(x-2/T) +fsinc(x-3/T) \
              -fsinc(x-4/T) +fsinc(x-5/T) \
              -fsinc(x-6/T) +fsinc(x-7/T) \
              -fsinc(x-8/T) +fsinc(x-9/T) \
              -fsinc(x-10/T)+fsinc(x-11/T) \
              -fsinc(x-12/T)+fsinc(x-13/T) \

# increase X-range resolution
set samples 1000
wav1start = 5.5
wav1stop = 7.5
wav2start = 7.5
wav2stop = 8.5
# set xrange[wav1start:wav2stop]
set xrange[0:10]

plot function1(x/T),function2(x/T)

TXT=""
pr_i(x) = (TXT = TXT.sprintf("%f ", x))
pr_x(i) = (TXT = TXT.sprintf("%f\n", x))

# steps per half-period
steps=16

# y-scale
ys=45.5
xo=0.42 # small x offset
set print "wavtable-dbpskgen.csv"
do for [i=wav1start*steps:wav1stop*steps-1] {
  TXT = TXT.sprintf("%d ", i-wav1start*steps);
  TXT = TXT.sprintf("%d\n", 64+floor(0.5+ys*function1((i*1.0+xo)/steps/T)));
}
do for [i=wav2start*steps:wav2stop*steps-1] {
  TXT = TXT.sprintf("%d ", i-wav1start*steps);
  TXT = TXT.sprintf("%d\n", 64+floor(0.5+ys*function2((i*1.0+xo)/steps/T)));
}
print TXT
set print
 
pause -1
