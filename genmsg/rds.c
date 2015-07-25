/*
    PiFmRds - FM/RDS transmitter for the Raspberry Pi
    Copyright (C) 2014 Christophe Jacquet, F8FTK
    
    See https://github.com/ChristopheJacquet/PiFmRds

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    Modification:
    Davor Jadrijevic, deleted everything except RDS bit generator
*/

#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include "rds.h"

#define RT_LENGTH 64
#define PS_LENGTH 8

struct {
    uint16_t pi;
    int ta;
    char ps[PS_LENGTH];
    char rt[RT_LENGTH];
} rds_params = { 0 };
/* Here, the first member of the struct must be a scalar to avoid a
   warning on -Wmissing-braces with GCC < 4.8.3 
   (bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=53119)
*/


#define SAMPLES_PER_BIT 192
#define FILTER_SIZE (sizeof(waveform_biphase)/sizeof(float))
#define SAMPLE_BUFFER_SIZE (SAMPLES_PER_BIT + FILTER_SIZE)

int bitptr = 0;

uint16_t offset_words[] = {0x0FC, 0x198, 0x168, 0x1B4};
// We don't handle offset word C' here for the sake of simplicity

/* Classical CRC computation */
uint16_t crc(uint16_t block) {
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

/* Possibly generates a CT (clock time) group if the minute has just changed
   Returns 1 if the CT group was generated, 0 otherwise
*/
int get_rds_ct_group(uint16_t *blocks) {
    static int latest_minutes = -1;

    // Check time
    time_t now;
    struct tm *utc;
    
    now = time (NULL);
    utc = gmtime (&now);

    if(utc->tm_min != latest_minutes) {
        // Generate CT group
        latest_minutes = utc->tm_min;
        
        int l = utc->tm_mon <= 1 ? 1 : 0;
        int mjd = 14956 + utc->tm_mday + 
                        (int)((utc->tm_year - l) * 365.25) +
                        (int)((utc->tm_mon + 2 + l*12) * 30.6001);
        
        blocks[1] = 0x4400 | (mjd>>15);
        blocks[2] = (mjd<<1) | (utc->tm_hour>>4);
        blocks[3] = (utc->tm_hour & 0xF)<<12 | utc->tm_min<<6;
        
        utc = localtime(&now);
        
        int offset = utc->tm_gmtoff / (30 * 60);
        blocks[3] |= abs(offset);
        if(offset < 0) blocks[3] |= 0x20;
        
        //printf("Generated CT: %04X %04X %04X\n", blocks[1], blocks[2], blocks[3]);
        return 1;
    } else return 0;
}

/* Creates an RDS group. This generates sequences of the form 4x 0A, 16x 2A, etc.
   The pattern is of length 20, the variable 'state' keeps track of where we are in the
   pattern. 'ps_state' and 'rt_state' keep track of where we are in the PS (0A) sequence
   or RT (2A) sequence, respectively.
*/
void get_rds_group(uint8_t *buffer) {
    static int state = 0;
    static int ps_state = 0;
    static int rt_state = 0;
    int bitptr = 0; // pointer to a bit in the buffer

    /* erase buffer */
    for(int i = 0; i < BITS_PER_GROUP/8; i++)
      buffer[i] = 0;

    uint16_t blocks[GROUP_LENGTH] = {rds_params.pi, 0, 0, 0};
    #ifdef DEBUG
    printf("state=%d ps_state=%d rt_state=%d\n", state, ps_state, rt_state);
    #endif
    int clock_enabled = 0;
    int clock_generated = 0;
    // Generate block content
    if(clock_enabled)
      clock_generated = get_rds_ct_group(blocks);
        
    if( clock_generated == 0 )
    // CT (clock time) if enabled has priority on other group types
    {
        if(state < 4) {
            blocks[1] = 0x0400 | ps_state;
            if(rds_params.ta) blocks[1] |= 0x0010;
            blocks[2] = 0xCDCD;     // no AF
            blocks[3] = rds_params.ps[ps_state*2]<<8 | rds_params.ps[ps_state*2+1];
            ps_state++;
            if(ps_state >= 4) ps_state = 0;
        } else { // state 4 .. 19
            blocks[1] = 0x2400 | rt_state;
            blocks[2] = rds_params.rt[rt_state*4+0]<<8 | rds_params.rt[rt_state*4+1];
            blocks[3] = rds_params.rt[rt_state*4+2]<<8 | rds_params.rt[rt_state*4+3];
            rt_state++;
            if(rt_state >= 16) rt_state = 0;
        }
    
        state++;
        if(state >= 20) state = 0;
    }
    
    // Calculate the checkword for each block and emit the bits
    for(int i=0; i<GROUP_LENGTH; i++) {
        uint16_t block = blocks[i];
        uint16_t check = crc(block) ^ offset_words[i];
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

void set_rds_pi(uint16_t pi_code) {
    rds_params.pi = pi_code;
}

void set_rds_rt(char *rt) {
    strncpy(rds_params.rt, rt, 64);
    for(int i=0; i<64; i++) {
        if(rds_params.rt[i] == 0) rds_params.rt[i] = 32;
    }
}

void set_rds_ps(char *ps) {
    strncpy(rds_params.ps, ps, 8);
    for(int i=0; i<8; i++) {
        if(rds_params.ps[i] == 0) rds_params.ps[i] = 32;
    }
}

void set_rds_ta(int ta) {
    rds_params.ta = ta;
}
