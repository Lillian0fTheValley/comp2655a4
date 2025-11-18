;Assignment 4
;Student: Lillian Ma
;Class: COMP 2655-002
;Professor: Terrance Mok
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


;array offset declarations
PIT_STONES_NUM	equ	0	
PIT_OWNER	equ	2
PIT_STORE_BOOL	equ	4
PIT_SZ		equ	6

;---------------------------------------------------------------
; Register Table
;d0 = read_char, write_char
;d1 = print_num, print_board
;d2 = holds value stored at PIT_OWNER(a1,d7.l) for cmp
;d3 = opponentStones - # of stones in opponentIndex pit
;d4 = oppositeIndex - for use in steal
;d5 = word stones
;d6 = storeIndex - for calculating index
;d7 = startIndex - for calculating index
;(a0) = print_board, print_str 
;(a1) = PIT[] BOARD
;(a2) = bool ISEMPTY
;(a3) = bool GAMEOVER
;(a4) = word PLAYER
;(a5) = bool VALIDINPUT
;(a6) = bool QUIT
;---------------------------------------------------------------


main:		lea	BOARD,a1
		lea	ISEMPTY,a2
		lea	GAMEOVER,a3
		lea	PLAYER,a4
		lea	VALIDINPUT,a5
		lea	QUIT,a6
		clr.l   d0
		clr.l	d7

; --- BOARD INITIALIZATION ---
;TOP OF THE BOARD INITIALIZATION FOR LOOP
init:		cmp.w	#TOTAL_PITS,d7		
		beq	game			;break loop if d7 = TOTAL_PITS
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
		bra	init			
;BOTTOM OF THE BOARD INITIALIZATION FOR LOOP
	
; --- DRAWING BOARD AND PROMPT STRINGS ---
;TOP OF while(!gameOver && !playerQuit) LOOP
game:	cmp.b	#TRUE,(a6)			
	bne	printBoard
	jmp	score
	cmp.b	#TRUE,(a3)
	bne	printBoard
	jmp	score				;break loop if gameOver or playerQuit
	
printBoard:	move.w	#PITS_PER_SIDE,d1
	lea	BOARD,a0	
	jsr	print_board
	move.b	#FALSE,(a5)
	bra	input

invalid:	lea	strInvalid,a0
		jsr	print_string
		bra	input
emptyPit:	lea	strEmpty,a0
		jsr	print_string
	
input:	cmp.b	#TRUE,(a5)	;TOP OF DO/WHILE LOOP FOR RECEIVING INPUT
	beq	play
	cmp.b	#TRUE,(a6)
	beq	play
	lea	strPlayer,a0	;"Player"	
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
	move.b	d0,d1	
	move.b	#CR,d0		;CRLF after receiving input
	jsr	write_char
	move.b	#LF,d0
	jsr	write_char
	
; --- CALCULATING INDEX ---
	
	move.b	d1,d0		

	cmp.b	#'q',d0	;
	bne	convert
	move.b	#TRUE,(a6)
	bra	inputLoop
	
convert:sub.w	#'0',d0		;converting input to int

	cmp.w	#PLAYER2,(a4)
	beq	p2Ind
	move.w	#P2_STORE_INDEX,d7
	bra	indSet
p2Ind:	move.w	#TOTAL_PITS,d7

indSet	sub.w	d0,d7		;calculating index = startIndex - input
	mulu.w	#PIT_SZ,d7	
	move.w	PIT_STONES_NUM(a1,d7.l),d5
	
	cmp.b	#0,d0
	bls	invalid
	move.b	#PITS_PER_SIDE,d1
	cmp.b	d1,d0
	bhi	invalid
	cmp.w	#0,d5
	beq	emptyPit
	move.b	#TRUE,(a5)

inputLoop:	tst.b	(a6)	;break loop if validInput or playerQuit
		bne	play
		tst.b	(a5)
		bne	play
		bra	input	
		;BOTTOM OF DO/WHILE LOOP FOR REEIVING INPUT


; --- GAME LOGIC ---
play:	clr.l	d6		
	tst.b	(a6)		;if !playerQuit	
	bne	game
	cmp.w	#PLAYER2,(a4)
	beq	p2Turn
	move.w	#P2_STORE_INDEX,d7
	move.w	#P1_STORE_INDEX,d6
	bra	pickUp
p2Turn:	move.w	#TOTAL_PITS,d7
	move.w	#P2_STORE_INDEX,d6
	
pickUp:	clr.l	d5		;this code block removes stones from array location and places in d5 for distribution
	sub.w	d0,d7
	mulu.w	#PIT_SZ,d7
	move.w	PIT_STONES_NUM(a1,d7.l),d5
	clr.w	PIT_STONES_NUM(a1,d7.l)

;BEGINNING OF STONE DISTRIBUTION LOOP
distribute:	tst.w	d5
		beq	steal	;break loop if stones = 0
		cmp.l	#P1_STORE_INDEX,d7
		bne	shift
		clr.l	d7
		move.w	#TOTAL_PITS,d7
		mulu.w	#PIT_SZ,d7
		
shift:	sub.l	#PIT_SZ,d7	;this code block shifts d7 to the next array
	move.w	PIT_OWNER(a1,d7.l),d2
	cmp.b	#FALSE,PIT_STORE_BOOL(a1,d7.l)
	beq	place
	cmp.w	(a4),d2
	beq	place
	bra	distribute	;skip if pit isStore and pitOwner!=PLAYER
	
place:	add.w	#1,PIT_STONES_NUM(a1,d7.l)
	dbra	d5,distribute
;BOTTOM OF STONE DISTRIBUTION LOOP

steal:	cmp.b	#FALSE,PIT_STORE_BOOL(a1,d7.l)	;steal moves opposite pit's stones and placed stone into currentPlayer's store
	bne	pCheck
	cmp.w	(a4),d2
	bne	pCheck
	cmp.w	#1,PIT_STONES_NUM(a1,d7.l)
	bne	pCheck
	
	move.w	#TOTAL_PITS,d4		;this block adds index pit and opposite pit's stones to current player's store
	mulu.w	#PIT_SZ,d4
	sub.l	d7,d4	;opposite = TOTAL_PITS - index
	tst.w	PIT_STONES_NUM(a1,d4.l)		
	beq	pCheck
	move.w	PIT_STONES_NUM(a1,d4.l),d3
	add.w	#1,d3
	clr.w	PIT_STONES_NUM(a1,d4.l)
	clr.w	PIT_STONES_NUM(a1,d7.l)	
	mulu.w	#PIT_SZ,d6
	add.w	d3,PIT_STONES_NUM(a1,d6.l)
	

pCheck:		clr.l	d7			;pCheck block sets d7=STORE_INDEX according to current player
		clr.l	d6
		move.w	#P1_STORE_INDEX,d7	
		move.b	#TRUE,(a2)
		move.w	#1,d6
		cmp.w	#PLAYER2,(a4)
		bne	emptyCheckLoop
		move.w	#P2_STORE_INDEX,d7
		mulu.w	#PIT_SZ,d7

emptyCheckLoop:	tst.b	(a2)		;emptyCheckLoop is a for loop that loops through current player's pits to check if all are empty	
		beq	turnChange	;break loop if !isEmpty
		cmp.w	#PITS_PER_SIDE+1,d6
		beq	gameOver	;break loop if d6 == P2_STORE_INDEX
		clr.l	d4
		move.w	#PIT_SZ,d4
		mulu.w	d6,d4
		add.l	d7,d4
		add.w	#1,d6		;post increment d6
		cmp.w	#0,PIT_STONES_NUM(a1,d4.l)
		beq	emptyCheckLoop	;set isEmpty to false if stones != 0
		move.b	#FALSE,(a2)
		bra	emptyCheckLoop	;loop

gameOver:	move.b	#TRUE,(a3)	;gameOver is only set by emptyCheckLoop	
		bra	score	

turnChange:	cmp.w	#PLAYER1,(a4)	;turnChange changes current player for next turn 
		bne	setP1
		move.w	#PLAYER2,(a4)
		jmp	game
setP1:		move.w	#PLAYER1,(a4)
		jmp	game
;BOTTOM OF if(!playerQuit)
;BOTTOM OF while(!gameOver && !playerQuit) LOOP

;--- OUTPUT GAME RESULT ---
score:		clr.l	d7		;score prints final board and outputs relevant end message	
		clr.l	d6
		move.w	#PITS_PER_SIDE,d1
		lea	BOARD,a0
		jsr	print_board
		tst.b	(a6)
		bne	quit		;check quit first	
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

quit:		lea	strPlayer,a0
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


