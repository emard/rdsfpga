#include <string.h>
#include "RDS.h"

/* constructor does nothing */
RDS::RDS()
{
}

/* Classical CRC computation */
uint16_t RDS::crc(uint16_t block) {
    uint16_t crc = 0;
    
    for(int j=0; j<BLOCK_SIZE; j++) {
        int bit = (block & MSB_BIT) != 0;
        block <<= 1;

        int msb = (crc >> (POLY_DEG-1)) & 1;
        crc <<= 1;
        if((msb ^ bit) != 0) {
            crc = crc ^ POLY;
        }
    }
    
    return crc;
}

/* Creates an RDS group. This generates sequences of the form 4x 0A, 16x 2A, etc.
   The pattern is of length 20, the variable 'state' keeps track of where we are in the
   pattern. 'ps_state' and 'rt_state' keep track of where we are in the PS (0A) sequence
   or RT (2A) sequence, respectively.
*/
void RDS::get_group(uint8_t *buffer) {
    static int state = 0;
    static int ps_state = 0;
    static int rt_state = 0;
    int bitptr = 0; // pointer to a bit in the buffer

    /* erase buffer */
    for(int i = 0; i < BITS_PER_GROUP/8; i++)
      buffer[i] = 0;

    uint16_t blocks[GROUP_LENGTH] = {this->pi, 0, 0, 0};
    #ifdef DEBUG
    printf("state=%d ps_state=%d rt_state=%d\n", state, ps_state, rt_state);
    #endif
    int clock_enabled = 0;
    int clock_generated = 0;
    // Generate block content
    #if 0
    if(clock_enabled)
      clock_generated = get_ct_group(blocks);
    #endif        
    if( clock_generated == 0 )
    // CT (clock time) if enabled has priority on other group types
    {
        if(state < 4) {
            blocks[1] = 0x0400 | ps_state;
            if(this->ta) blocks[1] |= 0x0010;
            blocks[2] = 0xCDCD;     // no AF
            blocks[3] = this->ps[ps_state*2]<<8 | this->ps[ps_state*2+1];
            ps_state++;
            if(ps_state >= 4) ps_state = 0;
        } else { // state 4 .. 19
            blocks[1] = 0x2400 | rt_state;
            blocks[2] = this->rt[rt_state*4+0]<<8 | this->rt[rt_state*4+1];
            blocks[3] = this->rt[rt_state*4+2]<<8 | this->rt[rt_state*4+3];
            rt_state++;
            if(rt_state >= 16) rt_state = 0;
        }
    
        state++;
        if(state >= 20) state = 0;
    }
    
    // Calculate the checkword for each block and emit the bits
    for(int i=0; i<GROUP_LENGTH; i++) {
        uint16_t block = blocks[i];
        uint16_t check = crc(block) ^ this->offset_words[i];
        for(int j=0; j<BLOCK_SIZE; j++) {
            buffer[bitptr/8] |= ((block & (1<<(BLOCK_SIZE-1))) != 0) << (7 - bitptr % 8);
            bitptr++;
            block <<= 1;
        }
        for(int j=0; j<POLY_DEG; j++) {
            buffer[bitptr/8] |= ((check & (1<<(POLY_DEG-1))) != 0) << (7 - bitptr % 8);
            bitptr++;
            check <<= 1;
        }
    }
}

void RDS::send(void)
{
    volatile uint32_t *rdsmem = (volatile uint32_t *)0xA0000000;
    uint8_t bit_buffer[BITS_PER_GROUP/8];
    int i, j, k = 0;
    int ngroups = 20;

    for(i = 0; i < ngroups; i++)
    {
      get_group(bit_buffer);
      for(j = 0; j < BITS_PER_GROUP/8; j++)
        rdsmem[k++] = bit_buffer[j];
    }
}

void RDS::set_pi(uint16_t pi_code) {
    this->pi = pi_code;
}

void RDS::set_rt(char *rt) {
    strncpy(this->rt, rt, 64);
    for(int i=0; i<64; i++) {
        if(this->rt[i] == 0) this->rt[i] = 32;
    }
}

void RDS::set_ps(char *ps) {
    strncpy(this->ps, ps, 8);
    for(int i=0; i<8; i++) {
        if(this->ps[i] == 0) this->ps[i] = 32;
    }
}

void RDS::set_ta(int ta) {
    this->ta = ta;
}
