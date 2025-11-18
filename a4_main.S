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

TRUE		equ	-1
FALSE		equ	0

CR		equ	13
LF		equ	10

PIT_STONES_NUM	equ	0
PIT_OWNER	equ	2
PIT_STORE_BOOL	equ	4
PIT_SZ		equ	6

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


; --- BOARD INITIALIZATION ---	
main:		lea	BOARD,a1
		lea	ISEMPTY,a2
		lea	GAMEOVER,a3
		lea	PLAYER,a4
		lea	VALIDINPUT,a5
		lea	QUIT,a6
		clr.l   d0
		clr.l	d7
init:		cmp.w	#TOTAL_PITS,d7		;beginning of the board initialization for loop
		beq	game	;break loop if d7 = TOTAL_PITS
		move.w	d7,d6
		mulu.w	#PIT_SZ,d6
		move.w	#START_STONES,PIT_STONES_NUM(a1,d6.l)
		move.b	#FALSE,PIT_STORE_BOOL(a1,d6.l)
		cmp.w	#PITS_PER_SIDE,d7
		bls	p1Init
		move.w	#PLAYER2,PIT_OWNER(a1,d6.l)
		bra	isStore
p1Init:		move.w	#PLAYER1,PIT_OWNER(a1,d6.l)

isStore:	divu.w	#PIT_SZ,d6	
		add.w	#1,d7			;post increment
		cmp.w	#P1_STORE_INDEX,d6	
		beq	storeInit
		cmp.w	#P2_STORE_INDEX,d6
		bne	init
storeInit:	mulu.w	#PIT_SZ,d6
		move.b	#TRUE,PIT_STORE_BOOL(a1,d6.l)
		move.w	#0,PIT_STONES_NUM(a1,d6.l)
		bra	init			;bottom of the board initialization for loop
	
; --- DRAWING BOARD AND PROMPT STRINGS ---

game:	cmp.b	#TRUE,(a6)			;beginning of the while(!gameOver && !playerQuit) loop
	bne	printBoard
	jmp	score
	cmp.b	#TRUE,(a3)
	bne	printBoard
	jmp	score		;break loop if gameOver or playerQuit
	
	
printBoard:	move.w	#PITS_PER_SIDE,d1
	lea	BOARD,a0	
	jsr	print_board
	bra	input

invalid:	move.b	#FALSE,(a5)
	lea	strInvalid,a0
	jsr	print_string
	bra	input
emptyPit:	lea	strEmpty,a0
		jsr	print_string
	
input:	cmp.b	#TRUE,(a5)	;break loop if validInput or playerQuit
	beq	play
	cmp.b	#TRUE,(a6)
	beq	play
	lea	strPlayer,a0	;"Player"	top of the loop for receiving input
	jsr	print_string
	
	move.w	(a4),d1		;"current player"
	jsr	print_number
	
	lea	strChoose,a0	;" - choose pit (1- "
	jsr	print_string
	move.w	#PITS_PER_SIDE,d1
	jsr	print_number	;"x"

	lea	strQuit,a0	;") or 'q' to quit: "
	jsr	print_string

	jsr	read_char
	and.l	#$00FF,d0	;bitmasking input
	move.b	d0,d1	;moving input to d1
	move.b	#CR,d0		;CRLF after receiving input
	jsr	write_char
	move.b	#LF,d0
	jsr	write_char
	;expected output: Player x - choose pit (1-PITS_PER_SIDE) or 'q' to quit: 
	
	
	move.b	d1,d0		;moving input back to d0 i guess

	cmp.b	#'q',d0	;
	bne	convert
	move.b	#TRUE,(a6)
	bra	inputLoop
	
convert:sub.w	#'0',d0		;converting input to int
	sub.w	d0,d7		;calculating index = startIndex - input
	mulu.w	#PIT_SZ,d7	;multiply index by struct size
	move.w	PIT_STONES_NUM(a1,d7.l),d5
	
	
	cmp.b	#0,d0
	bls	invalid
	move.b	#PITS_PER_SIDE,d1
	cmp.b	d1,d0
	bhi	invalid
	cmp.w	#0,d5
	beq	emptyPit
	move.b	#TRUE,(a5)	;set validInput = true
inputLoop:	tst.b	(a6)	;break loop if validInput or playerQuit
		bne	play
		tst.b	(a5)
		bne	play
		bra	input

play:	clr.l	d6
	tst.b	(a6)		;checks quit == true
	bne	game
	cmp.w	#PLAYER2,(a4)
	beq	p2Turn
	move.w	#P2_STORE_INDEX,d7
	move.w	#P1_STORE_INDEX,d6
	bra	pickUp
p2Turn:	move.w	#TOTAL_PITS,d7
	move.w	#P2_STORE_INDEX,d6
	
pickUp:	clr.l	d5
	sub.w	d0,d7
	mulu.w	#PIT_SZ,d7
	move.w	PIT_STONES_NUM(a1,d7.l),d5
	clr.w	PIT_STONES_NUM(a1,d7.l)

	;beginning of stone distribution loop	
distribute:	tst.w	d5
	beq	steal	;break loop if stones = 0
	cmp.l	#P1_STORE_INDEX,d7
	bne	shift
	clr.l	d7
	move.w	TOTAL_PITS,d7
	mulu.w	#PIT_SZ,d7
shift:	sub.l	#PIT_SZ,d7
	move.w	PIT_OWNER(a1,d7.l),d2
	cmp.b	#FALSE,PIT_STORE_BOOL(a1,d7.l)
	beq	place
	cmp.w	(a4),d2
	beq	place
	bra	distribute	;skip if isStore and pitOwner!=PLAYER
place:	add.w	#1,PIT_STONES_NUM(a1,d7.l)
	dbra	d5,distribute

steal:	cmp.b	#FALSE,PIT_STORE_BOOL(a1,d7.l)
	bne	pCheck
	cmp.w	(a4),d2
	bne	pCheck
	cmp.w	#1,PIT_STONES_NUM(a1,d7.l)
	bne	pCheck
	
	move.w	#TOTAL_PITS,d4
	mulu.w	#PIT_SZ,d4
	sub.l	d7,d4	;opposite = TOTAL_PITS - index
	tst.w	PIT_STONES_NUM(a1,d4.l)		;this block adds index pit and opposite pit's stones to your store if opposite pit 
	beq	pCheck
	move.w	PIT_STONES_NUM(a1,d4.l),d3
	add.w	#1,d3
	clr.w	PIT_STONES_NUM(a1,d4.l)
	clr.w	PIT_STONES_NUM(a1,d7.l)	
	mulu.w	#PIT_SZ,d6
	add.w	d3,PIT_STONES_NUM(a1,d6.l)
	

pCheck:		clr.l	d7	
		move.w	#P1_STORE_INDEX,d7	
		move.b	#TRUE,(a2)
		move.w	#1,d6
		cmp.w	#PLAYER2,(a4)
		bne	emptyCheckLoop
		move.w	#P2_STORE_INDEX,d7
		mulu.w	#PIT_SZ,d7

emptyCheckLoop:	cmp.w	#PITS_PER_SIDE+1,d6
		bge	turnChange	;break loop if d6 > P2_STORE_INDEX
		tst.b	(a2)
		beq	turnChange	;break loop if !isEmpty
		clr.l	d4
		move.w	#PIT_SZ,d4
		mulu.w	d6,d4
		add.l	d7,d4
		add.w	#1,d6		;post increment d6
		cmp.w	#0,PIT_STONES_NUM(a1,d4.l)
		beq	emptyCheckLoop	;set isEmpty to false if stones != 0
		move.b	#FALSE,(a2)
		bra	emptyCheckLoop	;loop


turnChange:	cmp.w	#PLAYER1,(a4)
		bne	setP1
		move.w	#PLAYER2,(a4)
		jmp	game
setP1:		move.w	#PLAYER1,(a4)
		jmp	game

score:		clr.l	d7
		clr.l	d6
		move.w	#PITS_PER_SIDE,d1
		lea	BOARD,a0
		jsr	print_board
		tst.b	(a6)
		bne	endQuit
		move.w	#P1_STORE_INDEX,d6
		mulu.w	#PIT_SZ,d6
		move.w	#P2_STORE_INDEX,d7
		mulu.w	#PIT_SZ,d7
		move.w	PIT_STONES_NUM(a1,d7.l),d2	
		cmp.w	PIT_STONES_NUM(a1,d6.l),d2
		beq	tie
		bhi	p2Win
		lea	strP1win,a0
		jsr	print_string
		bra	exit
p2Win:		lea	strP2win,a0
		jsr	print_string
		bra	exit
		
tie:		lea	strTie,a0
		jsr	print_string
		bra	end

endQuit:	lea	strPlayer,a0
		jsr	print_string
		move.w	(a4),d1
		jsr	print_number
		lea	strQuitEnd,a0
		jsr	print_string
		
end:		move.b	#CR,d0
		jsr	write_char
		move.b	#LF,d0
		jsr	write_char
		jsr exit

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


;---------------------------------------------------------------
;        DATA 
;---------------------------------------------------------------
PIT		ds.b	PIT_SZ	;structure declaration

BOARD		ds.b	PIT_SZ*TOTAL_PITS	;array of PIT struct

QUIT		dc.b	FALSE

GAMEOVER	dc.b	FALSE

VALIDINPUT	dc.b	FALSE

PLAYER		dc.w	PLAYER1

ISEMPTY		dc.b	TRUE
;---------------------------------------------------------------
; Strings constants
;
; Your output must match the C version of Mancala exactly
;---------------------------------------------------------------
test_str:	dc.b	"This is a null-terminated string to test the print_string function",0;

strPlayer	dc.b	"Player ",0;

strChoose	dc.b	" - choose pit (1-",0

strQuit		dc.b	") or 'q' to quit: ",0

strEmpty	dc.b	"Empty pit selected - ",0

strInvalid	dc.b	"Invalid pit number - ",0

strP1win	dc.b	"Player 1 wins",0

strP2win	dc.b	"Player 2 wins",0

strTie		dc.b	"The result is a tie",0

strQuitEnd	dc.b	" quit - game ends without a winner",0


