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
#include <string.h>

#include <RDS.h>

RDS rds = RDS();

uint16_t pi = 0xCAFE;
char ps[] = "TEST1234";
char rt[] = "ZZZZZZZZZZZZZZZZZZZZZZZZ";

/* Simple test program */
void setup() {

    rds.set_rds_pi(pi);
    rds.set_rds_ps(ps);
    rds.set_rds_rt(rt);

    Serial.begin(115200);
}

void loop()
{
  static uint8_t i;

  i++;
  rt[0] = 'A' + (i & 15);
  rds.set_rds_rt(rt);  
  rds.update();
  Serial.println("RDS");
  delay(5000);
}
