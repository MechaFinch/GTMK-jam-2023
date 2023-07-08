
;
; interrupt vector table
;

%include "keyboard.asm" as keys
%include "periodic.asm" as pit

%org 0

vector_reset:	resp 1	; set by simulator
vector_pit:		dp pit.pit_handler
vector_keyup:	dp keys.keyup_handler
vector_keydown:	dp keys.keydown_handler
padding:		resb 1024 - (4 * 4)

; dummy vector
null_vector:
	IRET

; interrupt source tracker
last_interrupt_source: dw 1