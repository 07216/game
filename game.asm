;***********************************************************
; Dots and Boxes
; EE 306 Fall 2004
; Lab 5
; Starter Code
;***********************************************************

                    .ORIG   x3000

;***********************************************************
; Main Program
;***********************************************************
                    JSR   DISPLAY_BOARD
PROMPT              JSR   DISPLAY_PROMPT
                    TRAP  x20                        ; get a character from keyboard into R0
                    TRAP  x21                        ; echo it to the screen
                    LD    R3, ASCII_Q_COMPLEMENT     ; load the 2's complement of ASCII 'Q'
                    ADD   R3, R0, R3                 ; compare the first character with 'Q'
                    BRz   EXIT                       ; if input was 'Q', exit
                    ADD   R1, R0, #0                 ; move R0 into R1, freeing R0 for another TRAP
                    TRAP  x20                        ; get another character into R0
                    TRAP  x21                        ; echo it to the screen
                    JSR   IS_INPUT_VALID      
                    JSR   TRANSLATE_MOVE             ; translate move into {0..6} coordinates
                    ADD   R3, R3, #0                 ; R3 will be zero if the move was valid
                    BRz   VALID_MOVE
                    LEA   R0, INVALID_MOVE_STRING    ; if the move was invalid, output corresponding
                    TRAP  x22                        ; message and go back to prompt
                    BR    PROMPT 
VALID_MOVE          JSR   IS_OCCUPIED         
                    ADD   R3, R3, #0                 ; R3 will be zero if the space was unoccupied
                    BRz   UNOCCUPIED
                    LEA   R0, OCCUPIED_STRING        ; if the place was occupied, output corresponding
                    TRAP  x22                        ; message and go back to prompt
                    BR    PROMPT
UNOCCUPIED          JSR   APPLY_MOVE                 ; apply the move 
                    JSR   BOXES_COMPLETED            ; returns the number of boxes completed by this move in R3
                    ADD   R0, R3, #0                 ; move the number of completed boxes to R0 where UPDATE_STATE expects it
                    JSR   UPDATE_STATE               ; change the score and the player as needed

                    JSR   DISPLAY_BOARD
                    JSR   IS_GAME_OVER      
                    ADD   R3, R3, #0                 ; R3 will be zero if there was a winner
                    BRnp  PROMPT                     ; otherwise, loop back
EXIT                LEA   R0, GOODBYE_STRING
                    TRAP  x22                        ; output a goodbye message
                    TRAP  x25                        ; halt

ASCII_Q_COMPLEMENT  .FILL  xFFAF                      ; two's complement of ASCII code for 'Q'
INVALID_MOVE_STRING .STRINGZ "\nInvalid move. Please try again.\n"
OCCUPIED_STRING     .STRINGZ "\nThis position is already occupied. Please try again.\n"
GOODBYE_STRING      .STRINGZ "\nThanks for playing! Goodbye!\n"

;***********************************************************
; DISPLAY_BOARD
;   Displays the game board and the score
;***********************************************************

DISPLAY_BOARD       ST    R0, DB_R0                  ; save registers
                    ST    R1, DB_R1
                    ST    R2, DB_R2
                    ST    R3, DB_R3
                    ST    R7, DB_R7

                    AND   R1, R1, #0                 ; R1 will be loop counter
                    ADD   R1, R1, #6
                    LEA   R2, ROW0                   ; R2 will be pointer to row
                    LEA   R3, ZERO                   ; R3 will be pointer to row number
                    LD    R0, ASCII_NEWLINE
                    OUT
                    OUT
                    LEA   R0, COL
                    PUTS
                    LD    R0, ASCII_NEWLINE
                    OUT
DB_ROWOUT           ADD   R0, R3, #0                 ; move address of row number to R0
                    PUTS
                    ADD   R0, R2, #0                 ; move address of row to R0
                    PUTS
                    LD    R0, ASCII_NEWLINE
                    OUT
                    ADD   R2, R2, #8                 ; increment R2 to point to next row
                    ADD   R3, R3, #3                 ; increment R3 to point to next row number
                    ADD   R1, R1, #-1
                    BRzp  DB_ROWOUT
                    JSR   DISPLAY_SCORE

                    LD    R0, DB_R0                  ; restore registers
                    LD    R1, DB_R1
                    LD    R2, DB_R2
                    LD    R3, DB_R3
                    LD    R7, DB_R7
                    RET

DB_R0               .BLKW #1
DB_R1               .BLKW #1
DB_R2               .BLKW #1
DB_R3               .BLKW #1
DB_R7               .BLKW #1

;***********************************************************
; DISPLAY_SCORE
;***********************************************************

DISPLAY_SCORE       ST    R0, DS_R0                   ; save registers
                    ST    R7, DS_R7

                    LEA   R0, DS_BEGIN_STRING
                    TRAP  x22                         ; print out the first part of the score string
                    LD    R0, SCORE_PLAYER_ONE
                    LD    R7, ASCII_OFFSET
                    ADD   R0, R0, R7                  ; create the ASCII for first player's score
                    TRAP  x21                         ; output it
                    LEA   R0, DS_OTHER_STRING
                    TRAP  x22                         ; print out the second part of the score string
                    LD    R0, SCORE_PLAYER_TWO
                    LD    R7, ASCII_OFFSET
                    ADD   R0, R0, R7                  ; create the ASCII for second player's score
                    TRAP  x21                         ; output it
                    LD    R0, ASCII_NEWLINE
                    TRAP  x21

                    LD    R0, DS_R0                   ; restore registers
                    LD    R7, DS_R7
                    RET

DS_R0              .BLKW   #1
DS_R7              .BLKW   #1
DS_BEGIN_STRING    .STRINGZ "SCORE Player 1: "
DS_OTHER_STRING    .STRINGZ " Player 2: "




;***********************************************************
; IS_BOX_COMPLETE
; Input      R1   the column number of the square center (0-6)
;      R0   the row number of the square center (0-6)
; Returns   R3   zero if the square is complete; -1 if not complete
;***********************************************************

IS_BOX_COMPLETE     ST    R0, IBC_R0                  ; save registers
                    ST    R1, IBC_R1         
                    ST    R2, IBC_R2         
                    ST    R4, IBC_R4         
                    ST    R7, IBC_R7

                    ADD   R0, R0, #-1                 ; check the top pipe
                    JSR   BOUNDS_CHECK
                    ADD   R3, R3, #0
                    BRnp  IBC_NON_COMPLETE
                    JSR   IS_OCCUPIED
                    ADD   R3, R3, #0
                    BRz   IBC_NON_COMPLETE

                    ADD   R0, R0, #2                  ; check the bottom pipe
                    JSR   BOUNDS_CHECK
                    ADD   R3, R3, #0
                    BRnp  IBC_NON_COMPLETE
                    JSR   IS_OCCUPIED
                    ADD   R3, R3, #0
                    BRz   IBC_NON_COMPLETE

                    ADD   R0, R0, #-1                 ; check the left pipe
                    ADD   R1, R1, #-1
                    JSR   BOUNDS_CHECK
                    ADD   R3, R3, #0
                    BRnp  IBC_NON_COMPLETE
                    JSR   IS_OCCUPIED
                    ADD   R3, R3, #0
                    BRz   IBC_NON_COMPLETE

                    ADD   R1, R1, #2                  ; check the right pipe
                    JSR   BOUNDS_CHECK
                    ADD   R3, R3, #0
                    BRnp  IBC_NON_COMPLETE
                    JSR   IS_OCCUPIED
                    ADD   R3, R3, #0
                    BRz   IBC_NON_COMPLETE

                    ADD   R1, R1, #-1                 ; back to original square

                    AND   R3, R3, #0
                    BR    IBC_EXIT

IBC_NON_COMPLETE    AND   R3, R3, #0
                    ADD   R3, R3, #-1   

IBC_EXIT            LD    R0, IBC_R0                  ; restore registers
                    LD    R1, IBC_R1         
                    LD    R2, IBC_R2         
                    LD    R4, IBC_R4         
                    LD    R7, IBC_R7
                    RET

IBC_R0             .BLKW  #1
IBC_R1             .BLKW  #1
IBC_R2             .BLKW  #1
IBC_R4             .BLKW  #1
IBC_R7             .BLKW  #1


;***********************************************************
; BOXES_COMPLETED 
; Input   R1   the column number (0-6)
;      R0   the row number (0-6)
; Returns
;       R3  the number of boxes this move completed
;***********************************************************

BOXES_COMPLETED    ST    R7, BC1_R7                 ; save registers
                   ST    R4, BC1_R4

                   JSR   GET_ADDRESS                ; get address in game board structure where line will be drawn
                   AND   R4,R1,#1
                   BRz   BC1_VERTICAL               ; true if the line drawn was vertical   

                   AND   R4, R4, #0                 ; R4 will hold the number of boxes completed
                   ADD   R0, R0, #-1                ; is the top square complete?
                   JSR   IS_BOX_COMPLETE
                   ADD   R3, R3, #0                 ; R3 will be zero if square is complete
                   BRnp  BC1_SKIP1
                   ADD   R4, R4, #1                 ; we have one complete
                   JSR   FILL_BOX
BC1_SKIP1          ADD   R0, R0, #2                 ; is the bottom square complete?
                   JSR   IS_BOX_COMPLETE
                   ADD   R3, R3, #0                 ; R3 will be zero if square is complete
                   BRnp  BC1_SKIP2
                   ADD   R4, R4, #1
                   JSR   FILL_BOX
BC1_SKIP2          ADD   R0, R0, #-1                ; restore R0
                   BRnzp BC1_EXIT

BC1_VERTICAL       AND   R4, R4, #0
                   ADD   R1, R1, #-1                ; is left square complete?
                   JSR   IS_BOX_COMPLETE
                   ADD   R3, R3, #0                 ; R3 will be zero if square is complete
                   BRnp  BC1_SKIP3
                   ADD   R4, R4, #1
                   JSR   FILL_BOX
BC1_SKIP3          ADD   R1, R1, #2                 ; is right square complete?
                   JSR   IS_BOX_COMPLETE
                   ADD   R3, R3, #0                 ; R3 will be zero if square is complete
                   BRnp  BC1_SKIP4
                   ADD   R4, R4, #1
                   JSR   FILL_BOX
BC1_SKIP4          ADD   R1, R1, #-1                ; restore R1

BC1_EXIT           ADD   R3, R4, #0                 ; move the number of completed squares to R3
                   LD    R7,BC1_R7                  ; restore registers
                   LD    R4,BC1_R4
                   RET

BC1_R7             .BLKW #1
BC1_R4             .BLKW #1

;***********************************************************
; BOUNDS_CHECK
; Input       R1    numeric column
;      R0    numeric row (either may be invalid)
; Returns   R3   zero if valid; -1 if invalid
;***********************************************************
 
BOUNDS_CHECK       ADD   R1, R1, #0                 ; Column Check
                   BRn   BC_HUGE_ERROR    
                   ADD   R3, R1, #-6
                   BRp   BC_HUGE_ERROR 
  
                   ADD   R0, R0, #0                 ; Row check
                   BRn   BC_HUGE_ERROR 
                   ADD   R3, R0, #-6
                   BRp   BC_HUGE_ERROR 

                   AND   R3, R3, #0                 ; valid move, return 0
                   BR    BC_DONE
BC_HUGE_ERROR      AND   R3, R3, #0
                   ADD   R3, R3, #-1                ; invalid move, return -1   

BC_DONE            RET

BC_NEGA            .FILL #-65
BC_NEGZERO         .FILL #-48

;***********************************************************
; Global constants used in program
;***********************************************************

COL                .STRINGZ "  ABCDEFG"
ZERO               .STRINGZ "0 "
ONE                .STRINGZ "1 "
TWO                .STRINGZ "2 "
THREE              .STRINGZ "3 "
FOUR               .STRINGZ "4 "
FIVE               .STRINGZ "5 "
SIX                .STRINGZ "6 "
ASCII_OFFSET       .FILL   x0030
ASCII_NEWLINE      .FILL   x000A

;***********************************************************
; This is the data structure for the game board
;***********************************************************
ROW0               .STRINGZ "* * * *"
ROW1               .STRINGZ "       "
ROW2               .STRINGZ "* * * *"
ROW3               .STRINGZ "       "
ROW4               .STRINGZ "* * * *"
ROW5               .STRINGZ "       "
ROW6               .STRINGZ "* * * *"
  
;***********************************************************
; this data stores the state for who's turn it is and what the score is
;***********************************************************
CURRENT_PLAYER     .FILL   #1 ; initially player 1 goes
SCORE_PLAYER_ONE   .FILL   #0
SCORE_PLAYER_TWO   .FILL   #0

;***********************************************************
;***********************************************************
;***********************************************************
;***********************************************************
;***********************************************************
;***********************************************************
; The code above is provided for you. 
; DO NOT MODIFY THE CODE ABOVE THIS LINE.
;***********************************************************
;***********************************************************
;***********************************************************
;***********************************************************
;***********************************************************
;***********************************************************


;***********************************************************
; IS_GAME_OVER
; Checks to see if there is a winner. If so, outputs winner
; Returns   R3   zero if there was a winner; -1 if no winner yet
;***********************************************************

IS_GAME_OVER      

            ; Your code goes here
		 ST 	R0,ISR_R0
		 ST 	R1,ISR_R1
		 ST		R7,ISR_R7
		 AND	R3,R3,#0
		 ADD 	R3,R3,#-1
		 LD 	R0,SCORE_PLAYER_ONE
		 LD 	R1,SCORE_PLAYER_TWO		;通过两个玩家的分数总和是否为9来判断游戏是否结束,R0、R1分别存两玩家分数
		 ADD 	R0,R0,R1
		 ADD	R0,R0,#-9
		 BRnp	ENDISR
		 ADD	R3,R3,#1
		 LEA	R0,PROMPT_ISR_ONE
		 PUTS
		 LD		R0,SCORE_PLAYER_ONE
		 NOT	R1,R1
		 ADD	R1,R1,#1
		 ADD	R0,R0,R1				;比较两玩家分数大小
		 BRn	WINTWO
		 LD		R0,PROMPT_ONE
		 OUT
		 LEA 	R0,PROMPT_ISR_TWO
		 PUTS
		 BR 	ENDISR
WINTWO	 LD		R0,PROMPT_TWO
		 OUT
		 LEA	R0,PROMPT_ISR_TWO
		 PUTS
ENDISR	 LD 	R0,ISR_R0
		 LD 	R1,ISR_R1
		 LD		R7,ISR_R7
         RET 
            ; .FILLS and other data for IS_GAME_OVER goes here

PROMPT_ISR_ONE	.STRINGZ	"Game over.Play "
PROMPT_WINNER	.BLKW		#1
PROMPT_ISR_TWO	.STRINGZ	" is the winner!\n"
PROMPT_ONE		.FILL		#49
PROMPT_TWO		.FILL		#50
ISR_R0			.BLKW 		#1
ISR_R1			.BLKW		#1
ISR_R7			.BLKW		#1

;***********************************************************
; DISPLAY_PROMPT
; Prompts the player, specified by location CURRENT_PLAYER, to input a move
;***********************************************************

DISPLAY_PROMPT      

            ; Your code goes here
		ST 	R0,DP_R0
		ST	R1,DP_R1
		ST	R7,DP_R7
		LEA R0,DP_PR_ONE
		PUTS
		LD	R0,CURRENT_PLAYER				;从内存中读出CURRENT_PLAYER再结合STRING输出,R0储存当前玩家编号
		LD	R1,DP_ZERO
		ADD R0,R0,R1
		OUT
		LEA R0,DP_PR_TWO
		PUTS
		LD	R0,DP_R0
		LD	R1,DP_R1
		LD	R7,DP_R7
		RET
            ; .FILLS and other data for DISPLAY_PROMPT goes here

DP_PR_ONE	.STRINGZ "Player "
DP_PR_TWO	.STRINGZ ", input a move (or 'Q' to quit):"
DP_ZERO		.FILL	#48
DP_R0		.BLKW	#1
DP_R1		.BLKW	#1
DP_R7		.BLKW	#1
            

;***********************************************************
; UPDATE_STATE
; Input      R0  number of boxes completed this turn
;   this function updates the score, and decides which player should go next 
;***********************************************************
UPDATE_STATE

            ; Your code goes here
		 ST		R1,US_R1
		 LD		R1,CURRENT_PLAYER
		 ADD	R0,R0,#0					;R0是要改变的分数值
		 BRnp	CAL							;如果R0为0，换一个玩家
		 NOT	R1,R1
		 ADD	R1,R1,#4					;R1存储玩家编号,R1=3-R1
		 ST		R1,CURRENT_PLAYER
		 BR		US_END
CAL		 ADD 	R1,R1,#-1
		 BRp	CALTWO
		 LD		R1,SCORE_PLAYER_ONE
		 ADD	R1,R0,R1
		 ST		R1,SCORE_PLAYER_ONE			;玩家1加分并继续游戏
		 BR		US_END
CALTWO	 LD		R1,SCORE_PLAYER_TWO			;玩家2加分并继续游戏
		 ADD	R1,R0,R1
		 ST		R1,SCORE_PLAYER_TWO
US_END	 LD		R1,US_R1
         RET
            ; .FILLS and other data for UPDATE_STATE goes here

US_R1	 .BLKW	#1


;***********************************************************
; GET_ADDRESS
; Input      R1   the column number (0-6)
;      R0   the row number (0-6)
; Returns   R3   the corresponding address in the data structure
;***********************************************************

GET_ADDRESS      

            ; Your code goes here
		 ST R0,GA_R0
		 LEA R3,ROW0
		 ADD R0,R0,#0
GA_LOOP	 BRz GA_ELOOP					;R3=ROW0的起始地址+8*R0+R1,得到内存中的具体存储位置
		 ADD R3,R3,#8
		 ADD R0,R0,#-1
		 BR GA_LOOP
GA_ELOOP ADD R3,R3,R1
		 LD R0,GA_R0
         RET 
            ; .FILLS and other data for GET_ADDRESS goes here

GA_R0	.BLKW #1
GA_R4	.BLKW #1
            


;***********************************************************
; FILL_BOX
; Input      R1   the column number of the square center (0-6)
;      R0   the row number of the square center (0-6)
;   fills in the box with the current player's number
;***********************************************************
FILL_BOX
            ; Your code goes here
		 ST R3,FB_R3
		 ST R4,FB_R4
		 ST R5,FB_R5
		 ST R7,FB_R7
		 LD R4,CURRENT_PLAYER			;R4存储当前玩家
		 LD R5,FB_ZERO
		 JSR GET_ADDRESS				;读出具体地址后，直接把对应玩家ASCII码存入该地址
		 ADD R4,R4,R5
		 STR R4,R3,#0
		 LD R3,FB_R3
		 LD R4,FB_R4
		 LD R5,FB_R5
		 LD R7,FB_R7
		 RET
            ; .FILLS and other data for FILL_BOX goes here

FB_ZERO	 .FILL #48
FB_R3	 .BLKW #1
FB_R4	 .BLKW #1
FB_R5	 .BLKW #1
FB_R7	 .BLKW #1
            
;***********************************************************
; APPLY_MOVE (write - or | in appropriate place)
; Input      R1   the column number (0-6)
;      R0   the row number (0-6)
;***********************************************************

APPLY_MOVE   

            ; Your code goes here
		 ST R2,AM_R2
		 ST R3,AM_R3
		 ST R7,AM_R7
		 ADD R2,R1,#-1
		 BRz HYP
		 ADD R2,R1,#-3
		 BRz HYP
		 ADD R2,R1,#-5					;首先判断列数是不是奇数，奇数的话画横线，否则画竖线，R2在这作临时变量 
		 BRz HYP
		 LD R2,pipe
		 JSR GET_ADDRESS
		 STR R2,R3,#0
		 BR ENDAM
HYP 	 LD R2,hyphen
		 JSR GET_ADDRESS
		 STR R2,R3,#0
ENDAM	 LD R2,AM_R2
		 LD R3,AM_R3
		 LD R7,AM_R7
		 RET
            ; .FILLS and other data for APPLY_MOVE goes here

pipe	.FILL x7C
hyphen	.FILL x2D
AM_R2 	.BLKW #1
AM_R3 	.BLKW #1
AM_R7	.BLKW #1
            

;***********************************************************
; IS_OCCUPIED
; Input      R1   the column number (0-6)
;      R0   the row number (0-6)
; Returns   R3   zero if the place is unoccupied; -1 if occupied
;***********************************************************

IS_OCCUPIED      

            ; Your code goes here
		 ST R4,IO_R4
		 ST R5,IO_R5
		 ST R7,IO_R7
		 JSR GET_ADDRESS
		 LDR R4,R3,#0
		 LD R5,IO_NEG				;读出具体地址，再把地址中存储的值读到R5中，再把R5与" "的ASCII码比较来判断是否被占
		 ADD R4,R4,R5
		 BRz SKIPIO
		 AND R3,R3,#0
		 ADD R3,R3,#-1
		 BR	 ENDIO
SKIPIO	 AND R3,R3,#0
ENDIO	 LD R4,IO_R4
		 LD R5,IO_R5
		 LD R7,IO_R7
         RET 
            ; .FILLS and other data for IS_OCCUPIED goes here

IO_NEG	 .FILL	x-20            
IO_R4	 .BLKW  #1
IO_R5	 .BLKW  #1
IO_R7	 .BLKW  #1
;***********************************************************
; TRANSLATE_MOVE
; Input      R1   the ASCII code for the column ('A'-'G')
;      R0   the ASCII code for the row ('0'-'6')
; Returns   R1   the column number (0-6)
;      R0   the row number (0-6)
;***********************************************************

TRANSLATE_MOVE      

            ; Your code goes here
		 ST		R2,TM_R2
		 LD 	R2,TM_NEG0
		 ADD	R0,R0,R2
		 LD 	R2,TM_NEGA				;R0=R0-ASCII('0') R1=R1-ASCII('A')
		 ADD 	R1,R1,R2
		 LD 	R2,TM_R2
		 RET
            ; .FILLS and other data for TRANSLATE_MOVE goes here


TM_R2	.BLKW 	#1
TM_NEG0	.FILL	#-48
TM_NEGA .FILL	#-65
            
;***********************************************************
; IS_INPUT_VALID
; Input      R1  ASCII character for column
;       R0  ASCII character for row 
; Returns   R3  zero if valid; -1 if invalid
;***********************************************************

IS_INPUT_VALID

            ; Your code goes here
		 ST R0,IIV_R0
		 ST R1,IIV_R1
		 ST R2,IIV_R2
		 ST R7,IIV_R7
		 LD R2,IIV_NEG0
		 ADD R2,R2,R0
		 BRn FAIL
		 LD R2,IIV_NEG6				;判断R0是否在'0'到'6'内
		 ADD R2,R2,R0
		 BRp FAIL
		 LD R2,IIV_NEGA
		 ADD R2,R2,R1				;判断R1是否在'A'到'G'内
		 BRn FAIL 
		 LD R2,IIV_NEGG
		 ADD R2,R2,R1
		 BRp FAIL
		 JSR TRANSLATE_MOVE
		 JSR GET_ADDRESS
		 LDR R2,R3,#0				;接着读取(R0,R1)处的元素，判断是否是'*'
		 LD  R3,IIV_NEGX
		 ADD R2,R2,R3
		 BRz FAIL
L1		 ADD R0,R0,#-2
		 BRzp L1
L2		 ADD R1,R1,#-2
		 BRzp L2
		 ADD R0,R0,#1
		 BRn SUC
		 ADD R1,R1,#1
		 BRn SUC					;再判断行列是否同时是奇数，若同时是奇数，说明该处为填数字处，输入无效
		 BR	 FAIL
SUC		 AND R3,R3,#0
		 BR  ENDIIV
FAIL	 AND R3,R3,#0
		 ADD R3,R3,#-1
ENDIIV	 LD R0,IIV_R0
		 LD R1,IIV_R1
		 LD R2,IIV_R2
		 LD R7,IIV_R7
         RET 
            ; .FILLS and other data for IS_INPUT_VALID goes here

IIV_R0	 .BLKW  #1
IIV_R1	 .BLKW  #1
IIV_R2	 .BLKW	#1
IIV_R7	 .BLKW 	#1
IIV_NEG0 .FILL 	#-48
IIV_NEG6 .FILL 	#-54
IIV_NEGA .FILL  #-65
IIV_NEGG .FILL  #-71
IIV_NEGX .FILL  #-42
.END


