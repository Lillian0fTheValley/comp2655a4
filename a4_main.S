;===============================================================
;  
; Your output must match the C version of Mancala exactly
;
;===============================================================

; external functions from the a4lib library
        xref    read_char,write_char,exit
	xref	print_string,print_number,print_board

;---------------------------------------------------------------
; Constants
;---------------------------------------------------------------
PITS_PER_SIDE   equ 4
TOTAL_PITS      equ (2*PITS_PER_SIDE+2)
START_STONES	equ	3

; Player constants
PLAYER1		equ	1
PLAYER2		equ	2
P1_STORE_INDEX	equ	0
P2_STORE_INDEX	equ	PITS_PER_SIDE+1
P1_START_INDEX	equ	PITS_PER_SIDE
P2_START_INDEX	equ	TOTAL_PITS-1

TRUE		equ	-1
FALSE		equ	0

CR		equ	13
LF		equ	10

PIT_STONES_NUM	equ	0
PIT_OWNER	equ	1
PIT_STORE_BOOL	equ	2
PIT_SZ		equ	4


;---------------------------------------------------------------
; Register Table
;
;
;
;
;
;
;d7 = 
;---------------------------------------------------------------


main:
; TODO - Place your code here
; Your output must match the C version of Mancala exactly
;
; The code here is some example code that does the following:
; 1. prints a null terminated string using print_string
; 2. prints out an unsigned integer that fits into a word using print_number
; 3. a newline is printed after both output items
;
; You MUST remove the following testing code in your final submission
; --- START of testing code ---
;	lea 	test_str,a0
;	jsr		print_string
;
;	move.b	#CR,d0			; move to new line
;	jsr		write_char
;	move.b	#LF,d0
;	jsr		write_char
;
;	move.w	#3579,d1
;
;	jsr		print_number
;
;	move.b	#CR,d0			; move to new line
;	jsr		write_char
;	move.b	#LF,d0
;	jsr		write_char
;	
; --- END of testing code ---

; --- BEGIN BOARD INITIALIZATION ---
	lea	BOARD,a0
	lea	QUIT,a6
	lea	GAMEOVER,a7
	move.w	#TOTAL_PITS-1,d7
init	move.w	#TOTAL_PITS-1,d6	;start of board initialization loop
	sub.w	d7,d6

	move.b	#START_STONES,PIT_STONES_NUM(a0)
	cmp.w	#P2_STORE_INDEX,d6	;branch if index > PITS_PER_SIDE + 1, sets pit to owner p2
	blt	p2Init	
	move.b	#PLAYER1,PIT_OWNER(a0)

isStore	cmp.w	#P1_STORE_INDEX,d6	;this block checks for index and initializes store if valid
	beq	store_init
	cmp.w	#P2_STORE_INDEX,d6
	beq	store_init
	move.b	#FALSE,PIT_STORE_BOOL(a0)

decr	adda.l	#PIT_SZ,a0	;this block updates the address and decrements and loops
	dbra	d7,init
	bra	game		;branches to game start when board is fully initialized

p2Init	move.b	#PLAYER2,PIT_OWNER(a0)	;this block sets pit owner to p2 and then branches to check if index is a store
	bra	isStore
	
	
store_init	move.b	#TRUE,PIT_STORE_BOOL(a0)	;this block initializes the store and then branches to decr unconditionally
		move.b	#0,PIT_STONES_NUM(a0)
		bra	decr

; --- BOARD INITIALIZATION DONE ---

game	cmp.w	#TRUE,(a6)	;this block checks for either end state
	;beq	end
	cmp.w	#TRUE,(a7)
	;beq	endQuit

	move.w	#PITS_PER_SIDE,d1
	jsr	print_board
	
	jsr     exit



;---------------------------------------------------------------
;        DATA 
;---------------------------------------------------------------
PIT		ds.b	PIT_SZ	;structure declaration

BOARD		ds.b	PIT_SZ*TOTAL_PITS	;array of PIT struct

QUIT		dc.b	FALSE

GAMEOVER	dc.b	FALSE

PLAYER		dc.b	PLAYER1
;---------------------------------------------------------------
; Strings constants
;
; Your output must match the C version of Mancala exactly
;---------------------------------------------------------------
test_str:	dc.b "This is a null-terminated string to test the print_string function",0;

