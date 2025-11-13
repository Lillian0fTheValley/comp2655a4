#ifndef A4LIB_H
#define A4LIB_H

#include <stdio.h>
#include <stdlib.h>
#include "types.h"

void read_char();    /* output passed back in low 8 bits of d0 */
void write_char();   /* input passed in low 8 bits of d0 */
void print_string(char str[]); /* outputs to the screen the null-terminated string, str */
void print_number(int number); /* outputs to the screen the word sized unsigned integer */
void print_board(int pits_per_side, PIT board[]);
                     /* outputs the PIT array, board, where there are pits_per_side for */
                     /* each player, this value excludes each player's store */

/* simulate 68000 data registers */
extern int d0, d1, d2, d3, d4, d5, d6, d7;


#endif
