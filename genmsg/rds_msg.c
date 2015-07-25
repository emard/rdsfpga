/*
    Copyright (C) Davor Jadrijevic
    
    See https://github.com/ChristopheJacquet/PiFmRds
    
    rds_wav.c is a test program that generates RDS
    bit message in VHDL format.

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
*/


#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sndfile.h>
#include <string.h>

#include "rds.h"

#define NGROUPS 20

/* Simple test program */
int main(int argc, char **argv) {
    static int bit_buffer[BITS_PER_GROUP];

    if(argc < 4) {
        fprintf(stderr, "Error: missing argument.\n");
        fprintf(stderr, "Syntax: rds_wav <pid 16 bit dec/hex> <station name 1-8 chars> <message 1-64 chars>\n");
        return EXIT_FAILURE;
    }
    
    set_rds_pi(strtoul(argv[1], NULL, 0));
    set_rds_ps(argv[2]);
    set_rds_rt(argv[3]);
    printf("-- automatically generated with rds_msg\n");
    printf("library ieee;\n");
    printf("use ieee.std_logic_1164.all;\n");
    printf("use ieee.std_logic_arith.all;\n");
    printf("use ieee.std_logic_unsigned.all;\n");
    printf("use ieee.numeric_std.all;\n");
    printf("package message is\n");
    printf("type rds_msg_type is array(0 to %d) of std_logic_vector(7 downto 0);\n", NGROUPS*13-1);
    printf("constant rds_msg_map: rds_msg_type := (\n");
    for(int i = 0; i < NGROUPS; i++)
    {
                get_rds_group(bit_buffer);
                for(int j = 0; j < BITS_PER_GROUP; j += 8)
                {
                  uint8_t gbyte = 0;
                  for(int k = 0; k < 8; k++)
                  {
                    gbyte <<= 1;
                    if(bit_buffer[j+k])
                      gbyte |= 1;
                  }
                  printf("x\"%02x\"", gbyte);
                  // vhdl syntax: no last comma
                  // if(i != NGROUPS-1 || j != BITS_PER_GROUP-8)
                    printf(",");
                }
                printf("\n");
    }
    printf("others => (others => '0')\n");
    printf(");\n");
    printf("end message;\n");

    return EXIT_SUCCESS;
}
