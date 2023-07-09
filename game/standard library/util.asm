
;
; STANDARD LIBRARY - GENERAL
; UTILITIES
; Assembly Implementation
;

%libname util

; funciton_descriptor structure defines
%define FUNCTION_DESCRIPTOR_FUNC_PTR	0
%define FUNCTION_DESCRIPTOR_ARG_SIZE	4
%define FUNCTION_DESCRIPTOR_RET_SIZE	5

; none halt()
; halts
halt:
	HLT
	RET

; u16 mulh8(u8 a, u8 b)
; returns MULH A, B
mulh8:
	MOV AL, [SP + 4]
	MULH A, [SP + 5]
	RET

; i16 mulsh8(i8 a, i8 b)
; returns MULSH A, B
mulsh8:
	MOV AL, [SP + 4]
	MULSH A, [SP + 5]
	RET

; u32 mulh16(u16 a, u16 b)
; returns MULH A, B
mulh16:
	MOV A, [SP + 4]
	MULH D:A, [SP + 6]
	RET

; i32 mulsh16(i16 a, i16 b)
; returns MULSH A, B
mulsh16:
	MOV A, [SP + 4]
	MULH D:A, [SP + 6]
	RET

; u16 enable_interrupts()
; enables interrupts, returning the previous value of PF
enable_interrupts:
	MOV A, PF
	MOV B, A
	OR B, 1
	MOV PF, B
	RET

; u16 disable_interrupts()
; disables interrupts, returning the previous value of PF
disable_interrupts:
	MOV A, PF
	MOV B, A
	AND B, 0xFFFE
	MOV PF, B
.r:
	RET

; none set_pf(u16 pf)
; sets PF to the given value
set_pf:
	MOV A, [SP + 4]
	MOV PF, A
	RET

; u16 get_pf()
; returns PF
get_pf:
	MOV A, PF
	RET


; ptr atomic_call(function_descriptor* desc, u8* args)
; calls the described function with arguments in the args buffer, returning its return value.
; interrupts are disabled for the duration of the function.
atomic_call:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	
	; mask interrupts
	MOV A, PF
	PUSH A
	AND A, 0xFFFE
	MOV PF, A
	
	; push arguments
	MOVW B:C, [BP + 8]
	MOV D, [B:C + FUNCTION_DESCRIPTOR_ARG_SIZE]
	MOVW J:I, [BP + 12]
	JMP .arg_cmp

.arg_loop:
	PUSH byte [J:I]
	INC I
	ICC J

	DEC D
.arg_cmp:
	CMP D, 0
	JNE .arg_loop
	
	; make call
	MOVW J:I, B:C ; caller saved
	CALLA [B:C + FUNCTION_DESCRIPTOR_FUNC_PTR]
	
	; fix SP
	MOVZ C, [J:I + FUNCTION_DESCRIPTOR_ARG_SIZE]
	LEA SP, [SP + C]
	
	; unmask interrupts & return
	POP PF
	
	POP I
	POP BP
	RET
