
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

; u16 to88(u8 a)
; returns a as 8.8 fixed point
to88:
	MOV AH, [SP + 4]
	MOV AL, 0
	RET

; u8 from88(u16 a)
; returns a as an int
from88:
	MOV AL, AH
	RET

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



; u32 to824(u8 a)
; returns a as 8.24 fixed point
to824:
	MOVZ D:A, 0
	MOV DH, [SP + 4]
	RET

from824:
	MOV AL, DH
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


	
; u32 to1616(u16 a)
; returns a as 16.16 fixed point
to1616:
	MOV D, [SP + 4]
	MOV A, 0
	RET

from1616:
	MOV A, D
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

divu1616:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; 64/32 bit divide
	; 1. shift dividend into remainder
	; 2. if the divisor can be subtracted from the remainder, do it
	; 3. if the divisor was subtracted, shift a 1 into to quotient, 0 otherwise
	; 4. continue until all bits processed
	
	; D:A = quot
	; B:C = rem
	; I = count
	; J = divisor high
	; L:K = dividend
	; [BP + 12] = divisor low
	MOVZ D:A, 0
	MOVZ B:C, 0
	MOV J, [BP + 14]
	MOVW L:K, [BP + 8]
	
	MOV I, 49 ; bits + 1, defines point position
.fast_start:
	DEC I
	SHL K, 1
	RCL L, 1
	JNC .fast_start
	JMP .loop_entry

.loop:
	; shift quotient
	SHL A, 1
	RCL D, 1
	
	; shift dividend
	SHL K, 1
	RCL L, 1
	
.loop_entry:
	; into remainder
	RCL C, 1
	RCL B, 1
	
	; sub?
	CMP B, J
	JB .no_sub
	CMP C, [BP + 12]
	JB .no_sub
	
	; sub.
	SUB C, [BP + 12]
	SBB B, J
	
	; shift 1
	OR AL, 1

.no_sub:
	DEC I
	JNZ .loop
	
	POP L
	POP K
	POP J
	POP I
	
	POP BP
	RET

divs1616:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; make unsigned
	MOV B, 0
	CMP byte [BP + 11], 0
	JGE .a_positive
	
	NOT word [BP + 10]
	NEG word [BP + 8]
	ICC word [BP + 10]
	MOV B, 1

.a_positive:
	CMP byte [BP + 15], 0
	JGE .b_positive
	
	NOT word [BP + 14]
	NEG word [BP + 12]
	ICC word [BP + 14]
	XOR B, 1

.b_positive:
	PUSH B
	; lolw
	PUSH word [BP + 14]
	PUSH word [BP + 12]
	PUSH word [BP + 10]
	PUSH word [BP + 8]
	CALL divu1616
	ADD SP, 8
	
	; correct sign
	POP F
	JNC .r_positive
	
	NOT D
	NEG A
	ICC D

.r_positive:
	POP L
	POP K
	POP J
	POP I
	POP BP
	RET


; u32 to248(u32 a)
; returns a as 24.8 fixed point
to248:
	MOV D, [SP + 5]
	MOV AH, [SP + 4]
	MOV AL, 0
	RET

fromu248:
	MOV AL, AH
	MOV AH, DL
	MOVZ D, DH
	RET

froms248:
	MOV AL, AH
	MOV AH, DL
	MOVS D, DH
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
