;
; STANDARD LIBRARY - MATH
; ASSEMBLY UTILITIES
; NOT NSTL COMPATIBLE
;
; Functions
;	u64 mulu32(u32 a, u32 b)		32x32 unsigned multiply
;	i64 muls32(i32 a, i32 b)		32x32 signed multiply
;	u32 to_hex_string(u16 num)		Converts a 16 bit value to a 4 byte ascii string of its hex
;

%libname mathutil

; u64 mulu32(u32 a, u32 b)
; Returns a * b in B:C:D:A. Unsigned.
mulu32:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	
	; alow	[BP + 8]
	; ahigh	[BP + 10]
	; blow	[BP + 12]
	; bhigh	[BP + 14]
	
	; old implemenation 16 instructions
	; new implementation 14 insturctions
	; by eliminating two MOVs
	
	MOV A, [BP + 8]		; A = alow
	MOV C, [BP + 10]	; C = ahigh
	MOV I, [BP + 12]	; I = blow
	MOV D, [BP + 14]	; D = bhigh
	
	; low/high pairs, sum into JI
	MULH D:A, D
	MULH J:I, C
	
	ADD I, A
	ADC J, D
	
	; low * low into D:A
	MOV A, [BP + 8]
	MULH D:A, [BP + 12]
	
	; high * high into B:C
	MULH B:C, D
	
	; add low/high sum into B:C:D:A
	ADD D, I
	ADC C, J
	ICC B
	
	; return
	POP J
	POP I
	POP BP
	RET



; i64 muls32(i32 a, i32 b)
; Returns a * b in B:C:D:A. Signed.
muls32:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	
	; alow	[BP + 8]
	; ahigh	[BP + 10]
	; blow	[BP + 12]
	; bhigh	[BP + 14]
	
	; make arguments positive, multiply, fix sign
	; check A
	MOV B, 0
	CMP byte [BP + 11], 0
	JGE .a_pos
	
	NOT word [BP + 10]
	NEG word [BP + 8]
	ICC word [BP + 10]
	MOV B, 1

.a_pos:
	CMP byte [BP + 15], 0
	JGE .b_pos
	
	NOT word [BP + 14]
	NEG word [BP + 12]
	ICC word [BP + 14]
	XOR BL, 1

.b_pos:
	PUSH B ; popped into I
	
	; copied from unsigned version
	MOV A, [BP + 8]		; A = alow
	MOV C, [BP + 10]	; C = ahigh
	MOV I, [BP + 12]	; I = blow
	MOV D, [BP + 14]	; D = bhigh
	
	; low/high pairs, sum into JI
	MULH D:A, D
	MULH J:I, C
	
	ADD I, A
	ADC J, D
	
	; low * low into D:A
	MOV A, [BP + 8]
	MULH D:A, [BP + 12]
	
	; high * high into B:C
	MULH B:C, D
	
	; add low/high sum into B:C:D:A
	ADD D, I
	ADC C, J
	ICC B
	
	; correct sign
	POP I
	CMP I, 0
	JZ .r_pos
	
	NOT B
	NOT C
	NOT D
	NEG A
	ICC D
	ICC C
	ICC B

	; return
.r_pos:
	POP J
	POP I
	POP BP
	RET
	
	
	
; u32 to_hex_string(u16 num)
; Converts the given number to a hex string
to_hex_string:
	PUSH BP
	MOV BP, SP
	
	MOV D, [BP + 8]
	MOV CL, DL
	AND CL, 0x0F
	CALL .sub_to_char
	MOV AL, BL
	
	MOV CL, DL
	SHR CL, 4
	CALL .sub_to_char
	MOV AH, BL
	
	MOV CL, DH
	AND CL, 0x0F
	CALL .sub_to_char
	MOV DL, BL
	
	MOV CL, DH
	SHR CL, 4
	CALL .sub_to_char
	MOV DH, BL
	
	POP BP
	RET
	
.sub_to_char:
	; converts CL to its character in BL
	MOV BL, 0x30
	CMP CL, 0x0A
	CMOVAE BL, 0x41 - 0x0A
	ADD BL, CL
	RET
