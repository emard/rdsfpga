#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define N 500
#define T 8

void sinc (double in[], double out[])
{
    for (int i1 = 0; i1 < N; i1++)
    {
        for (int t = -T; t < 2*T; t++) 
        {
            int index = i1 + t;
            double d1 = ((index < N) && (index >= 0)) ? in[index]: 0.0;

            if (t != 0)
               out[i1] += d1 * (sin(M_PI*t/T) / (M_PI*t/T));
            else
               out[i1] += d1;
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
  int start = 220, width = 2*T;
  
  zero(out);
  
  for(j = 0; j < N - 8*width; j+=width*8)
  {
  zero(in);
  for(i = j; i < j+width/2; i++)
    in[i] = 1.0;
  sinc(in, out);

  zero(in);  
  for(i = j+width; i < j+width+width/2; i++)
    in[i] = 1.0;
  sinc(in, out);

  zero(in);  
  for(i = j+2*width; i < j+2*width+width/2; i++)
    in[i] = -1.0;
  sinc(in, out);

  zero(in);  
  for(i = j+3*width; i < j+3*width+width/2; i++)
    in[i] = 1.0;
  sinc(in, out);
  }
  
  for(i = start-2*width; i < start+6*width; i++)
  printf("%lf\n", out[i]);

  return 0;
} 