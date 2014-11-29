/**
**  \file      RRPGE User Library math component, 16 bit reciprocal test
**  \brief     The main program file
**  \author    Sandor Zsuga (Jubatian)
**  \copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
**             License) extended as RRPGEvt (temporary version of the RRPGE
**             License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
**             root.
**  \date      2014.11.29
**
**  Tests the code designed for the RRPGE User Library's math component, the
**  us_rec16 function.
**
**  This code was used to design and test this RRPGE library component.
*/


#include <stdio.h>


int main(void)
{
 unsigned int a;
 unsigned int x;
 unsigned int d;
 unsigned int r;
 unsigned int dc = 0U;


 printf("0x0000: -");

 for (a = 1U; a < 0x10000U; a++){

  r = 0x10000U / a; /* True result for checking */

  x = 0xFFFFU / a;
  if (((a * x) + a) == 0x10000U){ x++; }

  d = r - x;

  if ((a & 0x3F) == 0x00){ printf("\n0x%04X: ", a); }
  if (d != 0U){ printf("%i", d); dc++; }
  else        { printf("."); }

 }

 printf("\nDiffs: %i\n", dc);

 return 0;
}
