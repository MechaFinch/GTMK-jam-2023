
;
; periodic interrupt timer
; handles periodic interrupts
;

; NSTL function headers
; library _pit;
; external function _pit.init of none returns none;
; external function _pit.runlater of ptr func, u16 time returns none;

%libname pit

%include "ivt.asm" as ivt
%include "util" as util
%include "memory/dma" as dma

%define PALETTE_START 0xF003_2C00

%define RANDOM 0xF004_0000

; there is a 1 in n chance to flicker the 'window' every period ms
%define WINDOW_FLICKER_PERIOD 2000
%define WINDOW_FLICKER_CHANCE 4
%define WINDOW_FLICKER_TIME 150
%define WINDOW_FLICKER_COL1_IDX 12
%define WINDOW_FLICKER_COL2_IDX 13
%define WINDOW_FLICKER_SOURCE1_IDX 3
%define WINDOW_FLICKER_SOURCE2_IDX 2
%define WINDOW_FLICKER_COLOR 0x3F_42_43

%define SERVER_FLICKER1_PERIOD 1000
%define SERVER_FLICKER1_TIME 500
%define SERVER_FLICKER1_CHANCE 4
%define SERVER_FLICKER1_COL_IDX 14
%define SERVER_FLICKER2_PERIOD 202
%define SERVER_FLICKER2_TIME 101
%define SERVER_FLICKER2_CHANCE 5
%define SERVER_FLICKER2_COL_IDX 16
%define SERVER_FLICKER3_PERIOD 500
%define SERVER_FLICKER3_TIME 400
%define SERVER_FLICKER3_CHANCE 10
%define SERVER_FLICKER3_COL_IDX 15
%define SERVER_FLICKER_COLOR_D 0x00_FF_00
%define SERVER_FLICKER_COLOR_F 0x30_36_40

%define DEFAULT_RUNLATER_SIZE 16

millis_counter: 	dp 0

runlater_array_ptr:	dp 0
runlater_array_len: dw DEFAULT_RUNLATER_SIZE



; initializes the system
init:
	PUSH BP
	MOVW BP, SP
	
	PUSH ptr DEFAULT_RUNLATER_SIZE
	call dma.calloc
	ADD SP, 4
	
	MOVW [runlater_array_ptr], D:A
	
	POP BP
	RET



; handles the PIT interrupt
pit_handler:
	PUSHA
	
	MOV A, 1
	MOV [ivt.last_interrupt_source], A
	
	MOVW J:I, [millis_counter]
	INC I
	ICC J
	MOVW [millis_counter], J:I
	
	; handle periodic tasks
	; window flicker
	MOVW B:C, J:I
	DIVM B:C, WINDOW_FLICKER_PERIOD
	CMP B, 0
	JNZ .task0
	MOV B, [RANDOM]
	MOVW B:C, [RANDOM]
	DIVM B:C, WINDOW_FLICKER_CHANCE
	CMP B, 0
	JNZ .task0
	CALL start_window_flicker
.task0:
	
	; server flickers
	MOVW B:C, J:I
	DIVM B:C, SERVER_FLICKER1_PERIOD
	CMP B, 0
	JNZ .task1
	MOVW B:C, [RANDOM]
	DIVM B:C, SERVER_FLICKER1_CHANCE
	CMP B, 0
	JNZ .task1
	CALL start_server_flicker1
.task1:

	MOVW B:C, J:I
	DIVM B:C, SERVER_FLICKER2_PERIOD
	CMP B, 0
	JNZ .task2
	MOVW B:C, [RANDOM]
	DIVM B:C, SERVER_FLICKER2_CHANCE
	CMP B, 0
	JNZ .task2
	CALL start_server_flicker2
.task2:

	MOVW B:C, J:I
	DIVM B:C, SERVER_FLICKER3_PERIOD
	CMP B, 0
	JNZ .task3
	MOVW B:C, [RANDOM]
	DIVM B:C, SERVER_FLICKER3_CHANCE
	CMP B, 0
	JNZ .task3
	CALL start_server_flicker3
.task3:
	
	; handle runlater tasks
.runlater_tasks:
	; for each entry in the runlater array, check if the time is up.
	; if so, run the function
	MOVW J:I, [runlater_array_ptr]
	MOV K, [runlater_array_len]
.runlater_loop:
	MOVW D:A, [J:I]
	CMP D, 0
	MOV C, F
	CMP A, 0
	AND F, C
	JZ .runlater_loop_next
	
	; there is a time. is it reached?
	MOVW B:C, [millis_counter]
	CMP B, D
	JA .runlater_loop_reached
	JB .runlater_loop_next
	CMP C, A
	JB .runlater_loop_next
	
	; yes. end the timer and call the function
.runlater_loop_reached:
	MOVW D:A, 0
	MOVW [J:I], D:A
	CALLA [J:I + 4]
	
	; re-load runlater array in case it got reallocated
	MOVW J:I, [runlater_array_ptr]
	MOV K, [runlater_array_len]

.runlater_loop_next:
	ADD I, 8
	ICC J
	SUB K, 8
	JNZ .runlater_loop

	POPA
	IRET



; calls a function after n ms
runlater:
	PUSH BP
	MOV BP, SP
	PUSH I
	PUSH J
	PUSH K
	
	; find the next available runlater slot
	MOVW J:I, [runlater_array_ptr]
	MOV K, [runlater_array_len]
.find_loop:
	MOVW D:A, [J:I]
	CMP D, 0
	JNZ .find_loop_next
	CMP A, 0
	JNZ .find_loop_next
	
	; found a slot
	JMP .slot_found

.find_loop_next:
	ADD I, 8
	ICC J
	SUB K, 8
	JNZ .find_loop
	
	; no slot found. reallocate one
	CALL util.disable_interrupts
	PUSH A
	
	MOVZ D:A, [runlater_array_len]
	MOV K, A
	ADD A, 16
	MOV [runlater_array_len], A
	PUSH D
	PUSH A
	
	MOVW D:A, [runlater_array_ptr]
	PUSH D
	PUSH A
	CALL dma.realloc
	ADD SP, 8
	
	MOVW [runlater_array_ptr], D:A
	LEA J:I, [D:A + K]
	
	; previous pf is on the stack
	CALLA util.set_pf
	POP A

.slot_found:
	MOVW D:A, [millis_counter]
	ADD A, [BP + 12]
	ICC D
	MOVW [J:I], D:A

	MOVW D:A, [BP + 8]
	MOVW [J:I + 4], D:A
	
	POP K
	POP J
	POP I
	POP BP
	RET
	


;
; PERIODIC STUFF
;
start_window_flicker:
	MOVW B:C, PALETTE_START
	
	MOVW D:A, WINDOW_FLICKER_COLOR
	MOV [B:C + (3 * WINDOW_FLICKER_COL1_IDX) + 0], A
	MOV [B:C + (3 * WINDOW_FLICKER_COL1_IDX) + 2], DL
	MOV [B:C + (3 * WINDOW_FLICKER_COL2_IDX) + 0], A
	MOV [B:C + (3 * WINDOW_FLICKER_COL2_IDX) + 2], DL
	
	PUSH word WINDOW_FLICKER_TIME
	PUSH ptr end_window_flicker
	CALL runlater
	ADD SP, 6
	RET

end_window_flicker:
	MOVW B:C, PALETTE_START
	MOVW D:A, [B:C + (3 * WINDOW_FLICKER_SOURCE1_IDX)]
	MOV [B:C + (3 * WINDOW_FLICKER_COL1_IDX) + 0], A
	MOV [B:C + (3 * WINDOW_FLICKER_COL1_IDX) + 2], DL
	
	MOVW D:A, [B:C + (3 * WINDOW_FLICKER_SOURCE2_IDX)]
	MOV [B:C + (3 * WINDOW_FLICKER_COL2_IDX) + 0], A
	MOV [B:C + (3 * WINDOW_FLICKER_COL2_IDX) + 2], DL
	RET



start_server_flicker1:
	MOVW B:C, PALETTE_START
	MOVW D:A, SERVER_FLICKER_COLOR_F
	MOV [B:C + (3 * SERVER_FLICKER1_COL_IDX) + 0], A
	MOV [B:C + (3 * SERVER_FLICKER1_COL_IDX) + 2], DL
	
	PUSH word SERVER_FLICKER1_TIME
	PUSH ptr end_server_flicker1
	CALL runlater
	ADD SP, 6
	RET

end_server_flicker1:
	MOVW B:C, PALETTE_START
	MOVW D:A, SERVER_FLICKER_COLOR_D
	MOV [B:C + (3 * SERVER_FLICKER1_COL_IDX) + 0], A
	MOV [B:C + (3 * SERVER_FLICKER1_COL_IDX) + 2], DL
	RET



start_server_flicker2:
	MOVW B:C, PALETTE_START
	MOVW D:A, SERVER_FLICKER_COLOR_F
	MOV [B:C + (3 * SERVER_FLICKER2_COL_IDX) + 0], A
	MOV [B:C + (3 * SERVER_FLICKER2_COL_IDX) + 2], DL
	
	PUSH word SERVER_FLICKER2_TIME
	PUSH ptr end_server_flicker2
	CALL runlater
	ADD SP, 6
	RET

end_server_flicker2:
	MOVW B:C, PALETTE_START
	MOVW D:A, SERVER_FLICKER_COLOR_D
	MOV [B:C + (3 * SERVER_FLICKER2_COL_IDX) + 0], A
	MOV [B:C + (3 * SERVER_FLICKER2_COL_IDX) + 2], DL
	RET



start_server_flicker3:
	MOVW B:C, PALETTE_START
	MOVW D:A, SERVER_FLICKER_COLOR_F
	MOV [B:C + (3 * SERVER_FLICKER3_COL_IDX) + 0], A
	MOV [B:C + (3 * SERVER_FLICKER3_COL_IDX) + 2], DL
	
	PUSH word SERVER_FLICKER3_TIME
	PUSH ptr end_server_flicker3
	CALL runlater
	ADD SP, 6
	RET

end_server_flicker3:
	MOVW B:C, PALETTE_START
	MOVW D:A, SERVER_FLICKER_COLOR_D
	MOV [B:C + (3 * SERVER_FLICKER3_COL_IDX) + 0], A
	MOV [B:C + (3 * SERVER_FLICKER3_COL_IDX) + 2], DL
	RET
