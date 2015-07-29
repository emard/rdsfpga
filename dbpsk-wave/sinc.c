/*
this is attempt to reconstruct math
from http://www.anotherurl.com/library/rds_formulae.htm

some info is missing, so waveform is not correctly
created with this like in
original costable.txt / wavtable.csv

this needs fixing and further work
*/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define N 500
#define B 0.01
#define T 8

double sinc(int t)
{
  if(t)
    return (sin(M_PI*t/T) / (M_PI*t/T));
  else
    return 1.0;
}

double cosfilter(int t)
{
  double arg = t*B/T;
  return cos(M_PI*arg)/(1-4*arg*arg);
}

void sinctable(double in[], double out[])
{
    for (int i1 = 0; i1 < N; i1++)
    {
        for (int t = -T; t < 2*T; t++) 
        {
            int index = i1 + t;
            double d1 = ((index < N) && (index >= 0)) ? in[index]: 0.0;

            out[i1] += d1 * sinc(t);
        }
        out[i1] /= 1;
    }
}

void zero(double in[])
{
  int i;
  for(i = 0; i < N; i++)
    in[i] = 0.0;
}

int main(int argc, char *argv[])
{
  int i, j;
  double in[N], out[N];
  int width = 2*T;
  int start = 8*width-6;
  
  zero(out);
  
  for(j = 0; j < N - 8*width; j+=width*8)
  {
  zero(in);
  for(i = j; i < j+width/4; i++)
    in[i] = 1.0;
  sinctable(in, out);

  zero(in);  
  for(i = j+width; i < j+width+width/4; i++)
    in[i] = 1.0;
  sinctable(in, out);

  zero(in);  
  for(i = j+2*width; i < j+2*width+width/4; i++)
    in[i] = -1.0;
  sinctable(in, out);

  zero(in);  
  for(i = j+3*width; i < j+3*width+width/4; i++)
    in[i] = 1.0;
  sinctable(in, out);
  }
  
  for(i = start; i < start+48; i++)
  {
    int v = out[i]*16.0;
    printf("%d\n", v);
  }

  return 0;
} 