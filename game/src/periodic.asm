
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
%include "spriteanim" as spra
%include "music.obj" as music

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

%define CONV_WHEEL_ANIM_PERIOD 200
%define CONV_WHEEL_ANIM_TIME 100
%define CONV_WHEEL_COL1_IDX 19
%define CONV_WHEEL_COL2_IDX 20
%define CONV_WHEEL_COLOR1 0x60_5D_5B
%define CONV_WHEEL_COLOR2 0x7E_76_75

%define RUNLATER_SIZE_INC 16
%define RUNLATER_SIZE_DEC 32

%define MIDI_START 0xF001_0000

millis_counter: 	dp 0

runlater_array_ptr:	dp 0
runlater_array_len: dw RUNLATER_SIZE_INC

conveyor_anim_enabled:	db 1

music_pointer: 		resp 1;
music_start:		resp 1;
music_start_time:	resp 1;
dummy_music:		dp 0;


; initializes the system
init:
	PUSH BP
	MOVW BP, SP
	
	PUSH ptr RUNLATER_SIZE_INC
	call dma.calloc
	ADD SP, 4
	
	MOVW [runlater_array_ptr], D:A
	
	MOVW D:A, dummy_music
	MOVW [music_pointer], D:A
	MOVW [music_start], D:A
	MOVZ D:A, 0
	MOVW [music_start_time], D:A
	
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

	MOVW B:C, J:I
	DIVM B:C, CONV_WHEEL_ANIM_PERIOD
	CMP B, 0
	JNZ .task4
	CALL start_conv_wheel_anim
.task4:

	CALL spra.animate_conveyor
.task5:

	; music
.midi_loop:
	MOVW D:A, [music_pointer]
	MOVW B:C, [D:A]
	CMP B, 0
	MOV K, F
	CMP C, 0
	AND F, K
	JZ .restart_track
	
	MOVW L:K, [music_start_time]
	ADD C, K
	ADC B, L
	
	CMP J, B
	JA .midi_yes
	JB .no_music
	CMP I, C
	JB .no_music
.midi_yes:
	MOVW B:C, [D:A + 4]
	MOVW [MIDI_START], B:C
	ADD A, 8
	ICC D
	MOVW [music_pointer], D:A
	JMP .midi_loop

.restart_track:
	MOVW D:A, [music_start]
	MOVW [music_start_time], J:I
	MOVW [music_pointer], D:A

.no_music:
	
	; handle runlater tasks
.runlater_tasks:
	; for each entry in the runlater array, check if the time is up.
	; if so, run the function
	MOVW J:I, [runlater_array_ptr]
	MOV K, [runlater_array_len]
	MOV L, 0
.runlater_loop:
	MOVW D:A, [J:I]
	CMP D, 0
	MOV C, F
	CMP A, 0
	AND F, C
	JZ .runlater_loop_next_zero
	
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
	MOV L, 0
	JMP .runlater_loop

.runlater_loop_next_zero:
	INC L
.runlater_loop_next:
	ADD I, 8
	ICC J
	SUB K, 8
	JNZ .runlater_loop
	
	; if 8+ runlater entries are empty, downsize the list
	CMP word [runlater_array_len], RUNLATER_SIZE_DEC
	JBE .done
	CMP L, (RUNLATER_SIZE_DEC / 8)
	JB .done
	
	MOVZ J:I, [runlater_array_len]
	SUB I, RUNLATER_SIZE_DEC
	MOV [runlater_array_len], I
	PUSH J
	PUSH I
	
	MOVW J:I, [runlater_array_ptr]
	PUSH J
	PUSH I
	CALL dma.rcalloc
	ADD SP, 8
	
	MOVW [runlater_array_ptr], D:A
	
.done:
	POPA
	IRET



; calls a function after n ms
runlater:
	PUSH BP
	MOV BP, SP
	PUSH I
	PUSH J
	PUSH K
	
	; make sure the pointer is valid
	MOVW D:A, [BP + 8]
	CMP D, 0
	MOV D, F
	CMP A, 0
	JNZ .ok
	
	; error
	CALLA 0

.ok:
	
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
.realloc:
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
	CALL dma.rcalloc
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



start_conv_wheel_anim:
	MOVW B:C, PALETTE_START
	MOVW D:A, CONV_WHEEL_COLOR1
	MOV [B:C + (3 * CONV_WHEEL_COL1_IDX) + 0], A
	MOV [B:C + (3 * CONV_WHEEL_COL1_IDX) + 2], DL
	
	MOVW D:A, CONV_WHEEL_COLOR2
	MOV [B:C + (3 * CONV_WHEEL_COL2_IDX) + 0], A
	MOV [B:C + (3 * CONV_WHEEL_COL2_IDX) + 2], DL
	
	PUSH word CONV_WHEEL_ANIM_TIME
	PUSH ptr end_conv_wheel_anim
	CALL runlater
	ADD SP, 6
	RET

end_conv_wheel_anim:
	MOVW B:C, PALETTE_START
	MOVW D:A, CONV_WHEEL_COLOR1
	MOV [B:C + (3 * CONV_WHEEL_COL2_IDX) + 0], A
	MOV [B:C + (3 * CONV_WHEEL_COL2_IDX) + 2], DL
	
	MOVW D:A, CONV_WHEEL_COLOR2
	MOV [B:C + (3 * CONV_WHEEL_COL1_IDX) + 0], A
	MOV [B:C + (3 * CONV_WHEEL_COL1_IDX) + 2], DL
	RET

enable_conveyor_anim:
	MOV A, 1
	MOV [conveyor_anim_enabled], AL
	RET
	
disable_conveyor_anim:
	MOV A, 0
	MOV [conveyor_anim_enabled], AL
	RET



set_song:
	MOVW D:A, [SP + 4]
	MOVW [music_start], D:A
	MOVW [music_pointer], D:A
	MOVW D:A, [millis_counter]
	MOVW [music_start_time], D:A
	
	MOVW D:A, MIDI_START
	MOV [D:A + 4], AL ; all off
	RET
