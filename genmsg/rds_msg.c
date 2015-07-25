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
    static uint8_t bit_buffer[BITS_PER_GROUP/8];
    uint16_t pi;
    char *ps, *rt;

    if(argc < 4) {
        fprintf(stderr, "Error: missing argument.\n");
        fprintf(stderr, "Syntax: rds_wav PI \"station 1-8 chars\" \"message 1-64 chars\"\n");
        fprintf(stderr, "Example: rds_wav 0x1234 \"TEST1234\" \"LONG MESSAGE\"\n");
        return EXIT_FAILURE;
    }
    pi = strtoul(argv[1], NULL, 0);
    ps = argv[2];
    rt = argv[3];
    set_rds_pi(pi);
    set_rds_ps(ps);
    set_rds_rt(rt);
    printf("-- automatically generated with rds_msg\n");
    printf("library ieee;\n");
    printf("use ieee.std_logic_1164.all;\n");
    printf("use ieee.std_logic_arith.all;\n");
    printf("use ieee.std_logic_unsigned.all;\n");
    printf("use ieee.numeric_std.all;\n");
    printf("package message is\n");
    printf("type rds_msg_type is array(0 to %d) of std_logic_vector(7 downto 0);\n", NGROUPS*13-1);
    printf("-- PI=0x%04X\n", pi);
    printf("-- PS=\"%s\"\n", ps);
    printf("-- RT=\"%s\"\n", rt);
    printf("constant rds_msg_map: rds_msg_type := (\n");
    for(int i = 0; i < NGROUPS; i++)
    {
      get_rds_group(bit_buffer);
      for(int j = 0; j < BITS_PER_GROUP/8; j++)
        printf("x\"%02x\",", bit_buffer[j]);
      printf("\n");
    }
    printf("others => (others => '0')\n");
    printf(");\n");
    printf("end message;\n");

    return EXIT_SUCCESS;
}
