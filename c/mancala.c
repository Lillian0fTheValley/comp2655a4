/*

*/

#include "a4lib.h"

#define PITS_PER_SIDE 4 /* More pits makes for a longer game */
#define START_STONES 3 /* More startng stones makes for a longer game */
#define TOTAL_PITS (2 * PITS_PER_SIDE + 2) /* Adding 2 because of each "Store" pit */

#define P1_STORE_INDEX 0
#define P2_STORE_INDEX (PITS_PER_SIDE + 1)


int main()
{
  PIT board[TOTAL_PITS];
  int player = 1;
  int move;
  int start;
  bool gameOver, playerQuit, validInput, isEmpty;
  int i;
  int startIndex;
  int storeIndex;
  int index;
  int stones;
  int opposite;
  int opponentStones;

  /*  Initializing Board with initial stones */
  for (i = 0; i < TOTAL_PITS; i++)
  {
    board[i].stones = START_STONES; 
    board[i].isStore = false;       
    if (i <= PITS_PER_SIDE)
    {
      board[i].owner = 1;
      if (i == P1_STORE_INDEX)
      {
        board[i].isStore = true;
        board[i].stones = 0; /* P1 is first, so store == 0 */
      }
    }
    else
    {
      board[i].owner = 2;
      if (i == P2_STORE_INDEX)
      {
        board[i].isStore = true;
        board[i].stones = 0; /* P2 is second, store == PITS_PER_SIDE+1 */
      }
    }
  }

  gameOver = false;
  playerQuit = false;

  while (!gameOver && !playerQuit)
  {
    print_board (PITS_PER_SIDE, board);
    validInput = false;
    do
    {
      print_string ("Player ");
      print_number (player);
      print_string (" - choose pit (1-");
      print_number (PITS_PER_SIDE);
      print_string (") or 'q' to quit: ");
      read_char ();
      d0 = d0 & 0xFF;
      d1 = d0;

      d0 = CR; /* go to a new line */
      write_char ();
      d0 = LF;
      write_char ();
      d0 = d1;

      if (d0 == 'q')
      {
        playerQuit = true;
      }
      else
      {
        if (d0 >= '1' && d0 <= ('0' + PITS_PER_SIDE))
        {
          move = d0 - '0';
          if (player == 1)
            start = PITS_PER_SIDE + 1;
          else
            start = TOTAL_PITS;
          if (board[start - move].stones != 0)
            validInput = true;
          else
            print_string ("Empty pit selected - ");
        }
        else
        {
          print_string ("Invalid pit number - ");
        }
      }
    } while (!validInput && !playerQuit);

    if (!playerQuit)
    {
      startIndex = PITS_PER_SIDE + 1;
      if (player == 2)
        startIndex = TOTAL_PITS;
        
      storeIndex = P1_STORE_INDEX;
      if (player == 2) 
        storeIndex = P2_STORE_INDEX;
        
      index = startIndex - move;

      stones = board[index].stones;
      board[index].stones = 0;

      while (stones > 0)
      {
        if (index == 0)
          index = TOTAL_PITS - 1;
        else
          index = index - 1;

        /* skip opponent's store */
        if (!(board[index].isStore == true && board[index].owner != player))
        {
          board[index].stones++;
          stones--;
        }
      }

      if (!board[index].isStore && board[index].owner == player && board[index].stones == 1)
      {
        opposite = TOTAL_PITS - index; /* calculate opposite pit index from the landing pit */
        opponentStones = board[opposite].stones;

        /* Capture any opponent stones across from the landing pit and put them */
        /* in the player's store along with the just-placed stone */
        if (opponentStones > 0)
        {
          board[storeIndex].stones += opponentStones;
          board[storeIndex].stones += 1; /* plus the just-placed stone */
          board[opposite].stones = 0;
          board[index].stones    = 0;    /* remove the just-placed stone */
        }
      }

      start = P1_STORE_INDEX;
      if (player == 2)
      {
        start = P2_STORE_INDEX;
      }

      isEmpty = true;
      /* check if the current player's pits are all empty */
      for (i = 1; i < PITS_PER_SIDE + 1 && isEmpty; i++)
      {
        if (board[start + i].stones != 0)
          isEmpty = false;
      }
      
      if (isEmpty)
        gameOver = true;
      else {
        if (player == 1)
          player = 2;
        else
          player = 1;
      }
    }
  }

  print_board (PITS_PER_SIDE, board);
  if (gameOver)
  {
    if (board[P1_STORE_INDEX].stones > board[P2_STORE_INDEX].stones)
      print_string ("Player 1 wins");
    else if (board[P2_STORE_INDEX].stones > board[P1_STORE_INDEX].stones)
      print_string ("Player 2 wins");
    else
      print_string ("The result is a tie");

    d0 = CR; /* go to a new line */
    write_char ();
    d0 = LF;
    write_char ();
  }
  else /* one player quit the game */
  {
    print_string ("Player ");
    print_number (player);
    print_string (" quit - game ends without a winner");
    d0 = CR; /* go to a new line */
    write_char ();
    d0 = LF;
    write_char ();
  }

  return 0;
}

