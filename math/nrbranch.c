/**
**  \file      Newton-Raphson divisor, branch set generator
**  \brief     The main program file
**  \author    Sandor Zsuga (Jubatian)
**  \copyright 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
**             License) extended as RRPGEvt (temporary version of the RRPGE
**             License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
**             root.
**  \date      2014.11.29
**
**  Generates branch block for Newton-Raphson division, aiming for a maximal
**  difference produced by the Newton-Raphson steps. The Newton-Raphson
**  division is performed by the same code as in nrtest.c, and in the RRPGE
**  math library.
**
**  This code was used to optimize the 32 bit reciprocal function of the math
**  component in the RRPGE User Library.
*/


#include <stdio.h>


#define DIFFMAX 0xFU


void rrpgebranch(unsigned int const* ca, unsigned int b, unsigned int h, unsigned int d, unsigned int e);


int main(void)
{
 unsigned int a = 0x42CE8U;
 unsigned int b;
 unsigned int x;
 unsigned int d;
 unsigned int r;
 unsigned int p;
 unsigned int cc;
 unsigned int ca[256U];
 unsigned int cb[256U];


 a = (a + 15U) | 0x7U;
 b = 0x100000000ULL / a;
 printf("Comp: %05X (%04X), base: %08X\n", a, a >> 3, b);
 ca[0] = a;
 cc    = 1U;


 do{

  r = (0x100000000ULL / a); /* True result to check against */

  x = b;

  /* 2 steps of RRPGE Newton-Raphson division. */

  x >>= 2;
  a <<= 2;
  p  = ((0U - a) * x) & 0xFFFFFFFFU;
  x += (((p >> 16) * (x & 0xFFFFU)) >> 16);
  p  = ((0U - a) * x) & 0xFFFFFFFFU;
  x += (((p >> 16) * (x & 0xFFFFU)) >> 16);
  a >>= 2;
  x <<= 2;

  /* Difference from the truth (Result of N-R is always smaller) */

  d = r - x;

  if (d > DIFFMAX){

   /* Maximal allowed difference reached, need to generate a new base
   ** approximation. The value for which the approximation is generated is
   ** not the current 'a', but one for comparing using 'a >> 3' (so a 16
   ** bit comparison is sufficient). */

   a = (a + 15U) | 0x7U;
   b = 0x100000000ULL / a;
   printf("Comp: %05X (%04X), base: %08X\n", a, a >> 3, b);
   ca[cc] = a;
   cc ++;

  }

  a --;

 }while (a >= 0x4000U);

 printf("\n");
 printf("Finished; compares: %u\n", cc);
 printf("\n");

 /* Output coarse C code */

 x = cc;
 while (x){
  x -= 1U;
  printf("   }else if (a <= 0x%05XU){ /* 0x%04X */\n", ca[x], ca[x] >> 3);
  printf("    x = 0x%05XU;\n", (unsigned)(0x100000000ULL / ca[x]));
 }
 printf("\n");

 /* Output coarse RRPGEASM code */

 ca[cc] = 0U;
 cc++;
 for (x = 0U; x < cc; x++){ cb[x] = ca[cc - x - 1U]; }
 cb[cc] = 0x7FFFFU;
 rrpgebranch(cb, 0, cc, 8, 0);

 return 0;
}




/* Recursive RRPGEASM branch set construction.
** Splits region passed using the depth preference passed (lowers it if
** necessary), outputs branching instructions.
** ca: Array of branch points
** b:  Low bound in array, inclusive
** h:  High bound in array, exclusive (at least l + 1)
** d:  Depth preference (2 ^ d = width of first half)
** e:  Set if entry label is needed, clear otherwise */
void rrpgebranch(unsigned int const* ca, unsigned int b, unsigned int h, unsigned int d, unsigned int e)
{
 unsigned int w = h - b; /* Width of covered area */
 unsigned int s;
 unsigned int t;

 if (w == 0U){
  printf("Branch: Error!\n");
  return;
 }

 while ((1U << d) > w){ d --; } /* Reduce depth preference to fit */

 s = b + (1U << d);             /* Split / leaf position */
 if (s == h){ s--; }

 /* Print label if necessary */

 if (e){
  if (ca[h] < 0x7FFFFU){
   printf(".x%03x:", (ca[h] >> 7));
  }else{
   printf(".xfff:");
  }
 }

 if (w == 1U){

  /* Reached a leaf node, output it */

  if (ca[s + 1U] < 0x7FFFFU){
   t = (unsigned)(0x100000000ULL / ca[s + 1U]) >> 2;
   printf("\tmov x1,    0x%04X\n", t);
   printf("\tjms .xend\n");
  }else{
   printf("\tjms .xdiv\t\t; Do approximation with division\n");
  }

 }else{

  /* Do a splitting branch and go on with the tree */

  printf("\txug x3,    0x%04X", ca[s] >> 3);
  if (ca[h] < 0x7FFFFU){
   printf("\t; 0x%04X < x3 <= 0x%04X\n", ca[s] >> 3, ca[h] >> 3);
  }else{
   printf("\t; 0x%04X < x3\n", ca[s] >> 3);
  }
  printf("\tjms .x%03x\t", ca[s] >> 7);
  if (ca[b] != 0U){
   printf("\t; 0x%04X < x3 <= 0x%04X\n", ca[b] >> 3, ca[s] >> 3);
  }else{
   printf("\t;          x3 <= 0x%04X\n", ca[s] >> 3);
  }

  if (d != 0U){ d--; }
  rrpgebranch(ca, s, h, d, 0U);
  rrpgebranch(ca, b, s, d, 1U);

 }

}
