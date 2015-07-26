#ifndef _RDS_h
#define _RDS_h

#include <stdint.h>

#define GROUP_LENGTH 4
#define BITS_PER_GROUP (GROUP_LENGTH * (BLOCK_SIZE+POLY_DEG))

/* The RDS error-detection code generator polynomial is
   x^10 + x^8 + x^7 + x^5 + x^4 + x^3 + x^0
*/
#define POLY 0x1B9
#define POLY_DEG 10
#define MSB_BIT 0x8000
#define BLOCK_SIZE 16

#define RT_LENGTH 64
#define PS_LENGTH 8

class RDS {
  public:
    RDS();

    void set_rds_pi(uint16_t pi_code);
    void set_rds_rt(char *rt);
    void set_rds_ps(char *ps);
    void set_rds_ta(int ta);

    void get_rds_group(uint8_t *buffer);
    void update();

  private:
  
    uint16_t crc(uint16_t block);

    uint16_t pi;
    int ta;
    char ps[PS_LENGTH];
    char rt[RT_LENGTH];

    const uint16_t offset_words[4] = {0x0FC, 0x198, 0x168, 0x1B4};
    // We don't handle offset word C' here for the sake of simplicity

};
#endif
