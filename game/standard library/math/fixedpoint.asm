
;
; STANDARD LIBRARY - MATH
; FIXED POINT
; ASSEMBLY IMPLEMENTATION
;
; Multiplication and division for 16 and 32 bit fixed point
;
; TODO: fast 32 bit implementations
;

%libname fxp

%include mathutil.asm as util

; u16 mulu88(u16 a, u16 b)
; returns a * b for 8.8 usigned fixed point
mulu88:
	MOV A, [SP + 4]
	MULH D:A, [SP + 6]
	MOV AL, AH
	MOV AH, DL
	RET

; i16 muls88(i16 a, i16 b)
; returns a * b for 8.8 signed fixed point
muls88:
	MOV A, [SP + 4]
	MULSH D:A, [SP + 6]
	MOV AL, AH
	MOV AH, DL
	RET

; u16 divu88(u16 a, u16 b)
; returns a / b for 8.8 unsigned fixed point
divu88:
	MOV A, 0			; D:A = A << 8
	MOV AH, [SP + 4]
	MOVS D, [SP + 5]
	DIVM D:A, [SP + 6]	; divide -> everything in the right place
	RET

; i16 divs88(i16 a, i16 b)
; returns a / b for 8.8 signed fixed point
divs88:
	MOV A, 0
	MOV AH, [SP + 4]
	MOVS D, [SP + 5]
	DIVMS D:A, [SP + 6]
	RET



; u32 mulu824(u32 a, u32 b)
; returns a * b for 8.24 unsigned fixed point
mulu824:
	; call existing 32 bit multiply
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	CALL util.mulu32
	ADD SP, 8
	
	; swizz bytes
	; BL:C:DH -> D:A
	MOV AL, DH
	MOV AH, CL
	MOV DL, CH
	MOV DH, BL
	RET

; i32 muls824(i32 a, i32 b)
; returns a * b for 8.24 signed fixed point
muls824:
	; call signed 32 bit mul
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	CALL util.muls32
	ADD SP, 8
	
	; swizz
	MOV DH, BL
	MOV DL, CH
	MOV AH, CL
	MOV AL, DH
	RET


	
; u32 mulu1616(u32 a, u32 b)
; returns a * b for 16.16 unsigned fixed point
mulu1616:
	; call unsigned 32 bit mul
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	CALL util.mulu32
	ADD SP, 8
	
	MOVW D:A, C:D
	RET

; i32 muls1616(i32 a, i32 b)
; returns a * b for 16.16 signed fixed point
muls1616:
	; call signed 32 bit mul
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	CALL util.muls32
	ADD SP, 8
	
	MOVW D:A, C:D
	RET
	


; u32 mulu248(u32 a, u32 b)
; returns a * b for 24.8 unsigned fixed point
mulu248:
	; call unsigned 32 bit mul
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	CALL util.mulu32
	ADD SP, 8
	
	; swizzzzzz
	; CL:D:AH -> D:A
	MOV AL, AH
	MOV AH, DL
	MOV DL, DH
	MOV DH, CL
	RET

; i32 muli248(i32 a, i32 b)
; returns a * b for 24.8 signed fixed point
muls248:
	; call signed 32 bit mul
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	PUSH word [SP + 8]
	CALL util.muls32
	ADD SP, 8
	
	; swizzzzzz
	; CL:D:AH -> D:A
	MOV AL, AH
	MOV AH, DL
	MOV DL, DH
	MOV DH, CL
	RET
