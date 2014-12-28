
RRPGE User Library
==============================================================================

.. image:: https://cdn.rawgit.com/Jubatian/rrpge-spec/00.013.002/logo_txt.svg
   :align: center
   :width: 100%

:Author:    Sandor Zsuga (Jubatian)
:Copyright: 2013 - 2014, GNU GPLv3 (version 3 of the GNU General Public
            License) extended as RRPGEvt (temporary version of the RRPGE
            License): see LICENSE.GPLv3 and LICENSE.RRPGEvt in the project
            root.




Introduction
------------------------------------------------------------------------------


The RRPGE User Library is a set of routines built into the RRPGE system to be
used by RRPGE Applications, realized as a binary image consisting instructions
for the RRPGE CPU. This project provides such a binary image to be used with
RRPGE implementations.

The specification of the functions to be provided by the RRPGE User Library
are found on the specs/userlib path in the RRPGE System Specification.


Related projects
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- RRPGE Specification: https://www.github.com/Jubatian/rrpge-spec
- RRPGE Assembler: https://www.github.com/Jubatian/rrpge-asm
- RRPGE Emulator & Library: https://www.github.com/Jubatian/rrpge-libminimal
- Example programs: https://www.github.com/Jubatian/rrpge-examples


Temporary license notes
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Currently the project is developed under a temporary GPL compatible license.
The intention for later is to add some permissive exceptions to this license,
allowing for creating derivative works (most importantly, applications) under
other licenses than GPL.

For more information, see http://www.rrpge.org/community/index.php?topic=30.0




Compiling and usage
------------------------------------------------------------------------------


First in the Makefile the path for the RRPGE Assembler should be specified.

On Linux and other similar systems, then simply doing a "make" should generate
a suitable output: an "userlib.bin" and an "userlib.txt" file.

On Windows building the generator for "userlib.txt" might not work, however
using other tools it may be reproduced.

The "userlib.bin" file is the raw binary to be loaded beginning with 0xF000 in
the Code address space.

The "userlib.txt" file is a 16 bit hexadecimal value list which may be copied
directly into a C array initialization to build it into an emulator.
