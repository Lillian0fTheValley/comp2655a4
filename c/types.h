#ifndef TYPES_H
#define TYPES_H

#define CR 13
#define LF 10

#define bool int
#define true 1
#define false 0

typedef struct
{
  int stones;
  int owner;    /* 1 or 2 */
  bool isStore; /* false = pit, true = store */
} PIT;

#endif
