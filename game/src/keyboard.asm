
;
; keyboard stuff
;

%libname keys

%include "ivt.asm" as ivt

%define KEYBOARD_START 0xF000_0000

last_pressed:	db 0
last_released:	db 0

keydown_handler:
	MOV A, 3
	MOV [ivt.last_interrupt_source], A
	MOV A, [KEYBOARD_START]
	MOV [last_pressed], AL
	IRET

keyup_handler:
	MOV A, 2
	MOV [ivt.last_interrupt_source], AL
	MOV A, [KEYBOARD_START]
	MOV [last_released], AL
	IRET
