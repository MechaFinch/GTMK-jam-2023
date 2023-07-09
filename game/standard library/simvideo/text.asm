
;
; STANDARD LIBRARY - SIM VIDEO
; TEXT
; ASSEMBLY IMPLEMENTATION
;

%libname text

%define VBUFFER_START 0xF002_0000
%define CHARSET_START 0xF003_4000

%define CHARSIZE 8

%define ROWS_PIXELS 240
%define ROWS_CHARS (ROWS_PIXELS / CHARSIZE)
%define COLS_PIXELS 320
%define COLS_CHARS (COLS_PIXELS / CHARSIZE)

; none a_char(u8 chr, u8 fgc, u8 bgc, u8 row, u8 col)
; draws a grid-aligned character to the given position
a_char:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; compute character pointer to A:B
	MOVZ B, [BP + 8]
	SHL B, 3
	LEA A:B, [CHARSET_START + B]
	
	; compute color data to C:D
	MOV C, [BP + 9]
	MOV DL, CH
	MOV DH, DL
	MOV CH, CL
	PSUB8 C, D
	
	; compute screen pointer to BP
	MOVZ I, [BP + 11] ; row
	MOVZ K, [BP + 12] ; col
	MULH J:I, COLS_PIXELS * CHARSIZE
	SHL K, 3
	LEA BP, [J:I + K + VBUFFER_START]
	
	; get character data
	MOVW J:I, [A:B + 0]
	MOVW L:K, [A:B + 4]
	
	; draw character
	CALL sub_char
	
	POP L
	POP K
	POP J
	POP I
	POP BP
	RET

; none a_string(u8* str, u16 len, u8 fgc, u8 bgc, u8 row, u8 col)
; draws a string to the gievn position
a_string:
	PUSH BP
	MOV BP, SP
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; compute color data to C:D
	MOV C, [BP + 14]
	MOV DL, CH
	MOV DH, DL
	MOV CH, CL
	PSUB8 C, D
	
	; put counter & pointer on the stack
	PUSH word [BP + 12]
	PUSH word [BP + 12]
	PUSH word [BP + 10]
	PUSH word [BP + 8]
	
	; compute screen pointer to BP
	MOVZ I, [BP + 16] ; row
	MOVZ K, [BP + 17] ; col
	MULH J:I, COLS_PIXELS * CHARSIZE
	SHL K, 3
	LEA BP, [J:I + K + VBUFFER_START]
	
.loop:
	; get character data
	MOVW A:B, [SP]
	LEA J:I, [A:B + 1]
	MOVW [SP], J:I
	
	MOVZ A, [A:B]
	
	; is it a newline
	CMP A, 0x0A
	JNE .not_newline
	
.newline:
	MOV A, [SP + 6] ; line length - remaining = printed
	SUB A, [SP + 4]
	SUB [SP + 6], A ; line length - printed = remaining
	SHL A, 3
	NEG A
	LEA BP, [BP + A + (COLS_PIXELS*CHARSIZE)]
	JMP .next
	
.not_newline:
	SHL A, 3
	MOVW J:I, [CHARSET_START + A + 0]
	MOVW L:K, [CHARSET_START + A + 4]
	
	; draw character
	CALL sub_char
	
	LEA BP, [BP + 8]
.next:
	DEC word [SP + 4]
	JNZ .loop
	
	ADD SP, 8
	
	POP L
	POP K
	POP J
	POP I
	POP BP
	RET

; subroutine char
; draws a char
; INPUT
; A		n/a (clobbered)
; B		n/a (clobbered)
; C		duplicated (foreground - background)
; D		duplicated background
; IJKL	character data (clobbered)
; BP	screen pointer
sub_char:
	MOV B, 0
	
.loop:
	MOV A, I
	SHR I, 1
	AND A, 0x0101
	PMUL8 A, C
	PADD8 A, D
	
	CMOVNZ [BP + (COLS_PIXELS * 0) + B], AL
	CMP AH, 0
	CMOVNZ [BP + (COLS_PIXELS * 1) + B], AH
	
	MOV A, J
	SHR J, 1
	AND A, 0x0101
	PMUL8 A, C
	PADD8 A, D
	CMOVNZ [BP + (COLS_PIXELS * 2) + B], AL
	CMP AH, 0
	CMOVNZ [BP + (COLS_PIXELS * 3) + B], AH
	
	MOV A, K
	SHR K, 1
	AND A, 0x0101
	PMUL8 A, C
	PADD8 A, D
	CMOVNZ [BP + (COLS_PIXELS * 4) + B], AL
	CMP AH, 0
	CMOVNZ [BP + (COLS_PIXELS * 5) + B], AH
	
	MOV A, L
	SHR L, 1
	AND A, 0x0101
	PMUL8 A, C
	PADD8 A, D
	CMOVNZ [BP + (COLS_PIXELS * 6) + B], AL
	CMP AH, 0
	CMOVNZ [BP + (COLS_PIXELS * 7) + B], AH
	
	INC B
	CMP B, 8
	JNE .loop
	RET
	
