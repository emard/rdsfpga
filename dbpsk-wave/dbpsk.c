void sinc (const double in[], double out[])
{
    for (int i1 = 0; i1 < N; i1++)
    {
        for (int i2 = -8; i2 < 16; i2++) 
        {
            int index = i1 + i2;
            double d1 = ((index < N) && (index >= 0)) ? in[index]: 0.0;

            if (i2 != 0)
               out[i1] += d1 * (sin((TWOPI * i2) / 16.0) / ((TWOPI * i2 )/ 16.0)) ;
            else
               out[i1] += d1;
        }
        out[i1] /= 1;
    }
}
