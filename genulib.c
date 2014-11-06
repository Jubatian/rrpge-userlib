/**
**  \file
**  \brief     Generates Big Endian 16 bit hexadecimal dump for includes
**  \author    Sandor Zsuga (Jubatian)
**  \copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
**             License) extended as RRPGEvt (temporary version of the RRPGE
**             License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
**             root.
**  \date      2014.11.06
**
**  Uses the standard input for reading, standard output for generating. The
**  output is suitable for initializing a 16 bit unsigned array in C.
*/


#include <stdio.h>
#include <stdlib.h>


int main(int argc, char** argv)
{
 unsigned char c[2];
 unsigned int  i;

 while (1){

  if (fread(&(c[0]), 1, 2, stdin) != 2U){
   if (feof(stdin)){ return 0; } /* Terminated OK */
   else            { return 1; } /* Other error */
  }

  printf(" 0x%04XU,", (((unsigned int)(c[0])) << 8) + ((unsigned int)(c[1])));
  i ++;
  if (i == 8U){
   printf("\n");
   i = 0U;
  }

 }
}
