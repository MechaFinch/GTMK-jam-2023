
;
; interrupt vector table
;

%org 0

vector_reset:	resb 4	; set by simulator
vector_rtc:		null_vector
vector_keyup:	null_vector
vector_keydown:	null_vector
padding:		resb 1024 - (4 * 4)

; dummy vector
null_vector:
	IRET