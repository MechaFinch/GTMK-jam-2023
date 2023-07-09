
;
; STANDARD LIBRARY - SIMVIDEO
; SPRITES
; ASM IMPLEMENTATION
;

%libname sprites

%define VBUFFER_START 0xF002_0000
%define SCREEN_WIDTH 320
%define SCREEN_HEIGHT 240

%define SPRITE_WIDTH_OFFSET 0
%define SPRITE_HEIGHT_OFFSET 2
%define SPRITE_DATA_OFFSET 4



; none draw(sprite* sp, i16 x, i16 y)
; draws a sprite at x, y. no transparency
draw:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; compute screen address to LK
	MOV K, [BP + 14]
	MULH L:K, SCREEN_WIDTH
	ADD K, [BP + 12]
	ADC L, VBUFFER_START / 0x1_0000
	
	; get sprite & sprite params
	MOVW B:C, [BP + 8]
	MOVW J:I, [B:C] ; I = width, J = height
	PUSH I
	
	ADD C, 4
	ICC B

.y_loop:
	MOV I, [SP]
	CMP I, 16
	JB .x_final
	
.x_loop:
	MOVW D:A, [B:C + 0]
	MOVW [L:K + 0], D:A
	MOVW D:A, [B:C + 4]
	MOVW [L:K + 4], D:A
	MOVW D:A, [B:C + 8]
	MOVW [L:K + 8], D:A
	MOVW D:A, [B:C + 12]
	MOVW [L:K + 12], D:A
	
	ADD C, 16
	ICC B
	ADD K, 16
	ICC L
	
	SUB I, 16
	CMP I, 16
	JAE .x_loop
.x_final:
	JMP byte [IP + I]
	db @.x_final_0
	resb 3
	db @.x_final_4
	resb 3
	db @.x_final_8
	resb 3
	db @.x_final_12
	resb 3

.x_final_0:
	ADD K, SCREEN_WIDTH
	ICC L
	SUB K, [SP]
	DCC L
	JMP .x_end
	
.x_final_4:
	MOVW D:A, [B:C + 0]
	MOVW [L:K + 0], D:A
	
	ADD C, 4
	ICC B
	ADD K, SCREEN_WIDTH + 4
	ICC L
	SUB K, [SP]
	DCC L
	JMP .x_end
	
.x_final_8:
	MOVW D:A, [B:C + 0]
	MOVW [L:K + 0], D:A
	MOVW D:A, [B:C + 4]
	MOVW [L:K + 4], D:A
	
	ADD C, 8
	ICC B
	ADD K, SCREEN_WIDTH + 8
	ICC L
	SUB K, [SP]
	DCC L
	JMP .x_end
	
.x_final_12:
	MOVW D:A, [B:C + 0]
	MOVW [L:K + 0], D:A
	MOVW D:A, [B:C + 4]
	MOVW [L:K + 4], D:A
	MOVW D:A, [B:C + 8]
	MOVW [L:K + 8], D:A
	
	ADD C, 12
	ICC B
	ADD K, SCREEN_WIDTH + 12
	ICC L
	SUB K, [SP]
	DCC L

.x_end:
	DEC J
	JNZ .y_loop
	
	POP I
	POP L
	POP K
	POP J
	POP I
	
	POP BP
	RET



; none draw_transparent(sprite* sp, i16 x, i16 y)
; draws a sprite at x, y. has transparency
draw_transparent:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; compute screen address to LK
	MOV K, [BP + 14]
	MULH L:K, SCREEN_WIDTH
	ADD K, [BP + 12]
	ADC L, VBUFFER_START / 0x1_0000
	
	; get sprite & sprite params
	MOVW B:C, [BP + 8]
	MOVW J:I, [B:C] ; I = width, J = height
	PUSH I
	
	ADD C, 4
	ICC B

.y_loop:
	MOV I, [SP]
	
.x_loop:
	MOVW D:A, [B:C]
	CMP AL, 0
	CMOVNZ [L:K + 0], AL
	CMP AH, 0
	CMOVNZ [L:K + 1], AH
	CMP DL, 0
	CMOVNZ [L:K + 2], DL
	CMP DH, 0
	CMOVNZ [L:K + 3], DH
	
	ADD K, 4
	ICC L
	ADD C, 4
	ICC B
	
	SUB I, 4
	JNZ .x_loop
	
	ADD K, SCREEN_WIDTH
	ICC L
	SUB K, [SP]
	DCC L
	
	DEC J
	JNZ .y_loop
	
	POP I
	POP L
	POP K
	POP J
	POP I
	
	POP BP
	RET



; none draw_part(sprite* sp, i16 x, i16 y, i16 sx, i16 sy, i16 w, i16 h)
; draws part of a sprite without transparency
draw_part:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; compute screen address to LK
	MOV K, [BP + 14]
	ADD K, [BP + 18]
	MULH L:K, SCREEN_WIDTH
	ADD K, [BP + 12]
	ADC L, VBUFFER_START / 0x1_0000
	ADD K, [BP + 16]
	ICC L
	
	; get sprite & sprite params
	MOVW B:C, [BP + 8]
	
	MOV I, [B:C] ; width - w -> [SP]
	SUB I, [BP + 20]
	PUSH I
	
	MOV I, [BP + 18] ; (sy * sprite_w) + sx
	MULH J:I, [B:C]
	ADD I, [BP + 16]
	ICC J
	
	ADD C, I ; index into sprite
	ADC B, J
	ADD C, 4
	ICC B
	
	MOV J, [BP + 22] ; h

.y_loop:
	MOV I, [BP + 20] ; w
	CMP I, 4
	JB .x_final
	
.x_loop:
	MOVW D:A, [B:C]
	MOVW [L:K], D:A
	
	ADD K, 4
	ICC L
	ADD C, 4
	ICC B
	
	SUB I, 4
	CMP I, 4
	JAE .x_loop

.x_final:
	JMP byte [IP + I]
	db @.x_final_0
	db @.x_final_1
	db @.x_final_2
	db @.x_final_3
	
.x_final_0:
	ADD K, SCREEN_WIDTH
	ICC L
	JMP .x_end

.x_final_1:
	MOV AL, [B:C]
	MOV [L:K], AL
	
	INC C
	ICC B
	ADD K, SCREEN_WIDTH + 1
	ICC L
	JMP .x_end
	
.x_final_2:
	MOV A, [B:C]
	MOV [L:K], A
	
	ADD C, 2
	ICC B
	ADD K, SCREEN_WIDTH + 2
	ICC L
	JMP .x_end

.x_final_3:
	MOVW D:A, [B:C]
	MOV [L:K + 0], A
	MOV [L:K + 2], DL
	
	ADD C, 3
	ICC B
	ADD K, SCREEN_WIDTH + 3
	ICC L
	JMP .x_end
	
.x_end:
	SUB K, [BP + 20] ; w
	DCC L
	ADD C, [SP] ; sprite_w - w
	ICC B
	
	DEC J
	JNZ .y_loop
	
	POP I
	POP L
	POP K
	POP J
	POP I
	
	POP BP
	RET



; none draw_part_transparent(sprite* sp, i16 x, i16 y, i16 sx, i16 sy, i16 w, i16 h)
; draws part of a sprite without transparency
draw_part_transparent:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; compute screen address to LK
	MOV K, [BP + 14]
	ADD K, [BP + 18]
	MULH L:K, SCREEN_WIDTH
	ADD K, [BP + 12]
	ADC L, VBUFFER_START / 0x1_0000
	ADD K, [BP + 16]
	ICC L
	
	; get sprite & sprite params
	MOVW B:C, [BP + 8]
	
	MOV I, [B:C]
	SUB I, [BP + 20]
	PUSH I
	PUSH word [BP + 20]
	PUSH word [BP + 22]
	
	MOV I, [BP + 18]
	MULH J:I, [B:C]
	ADD I, [BP + 16]
	ICC J
	
	ADD C, I
	ADC B, J
	ADD C, 4
	ICC B
	
	MOV J, [SP]

.y_loop:
	MOV I, [SP + 2]
	CMP I, 4
	JB .x_final
	
.x_loop:
	MOVW D:A, [B:C]
	CMP AL, 0
	CMOVNZ [L:K + 0], AL
	CMP AH, 0
	CMOVNZ [L:K + 1], AH
	CMP DL, 0
	CMOVNZ [L:K + 2], DL
	CMP DH, 0
	CMOVNZ [L:K + 3], DH
	
	ADD K, 4
	ICC L
	ADD C, 4
	ICC B
	
	SUB I, 4
	CMP I, 4
	JAE .x_loop

.x_final:
	JMP byte [IP + I]
	db @.x_final_0
	db @.x_final_1
	db @.x_final_2
	db @.x_final_3
	
.x_final_0:
	ADD K, SCREEN_WIDTH
	ICC L
	JMP .x_end

.x_final_1:
	MOV AL, [B:C]
	CMP AL, 0
	CMOVNZ [L:K], AL
	
	INC C
	ICC B
	ADD K, SCREEN_WIDTH + 1
	ICC L
	JMP .x_end
	
.x_final_2:
	MOV A, [B:C]
	CMP AL, 0
	CMOVNZ [L:K + 0], AL
	CMP AH, 0
	CMOVNZ [L:K + 1], AH
	
	ADD C, 2
	ICC B
	ADD K, SCREEN_WIDTH + 2
	ICC L
	JMP .x_end

.x_final_3:
	MOVW D:A, [B:C]
	CMP AL, 0
	CMOVNZ [L:K + 0], AL
	CMP AH, 0
	CMOVNZ [L:K + 1], AH
	CMP DL, 0
	CMOVNZ [L:K + 2], DL
	
	ADD C, 3
	ICC B
	ADD K, SCREEN_WIDTH + 3
	ICC L
	JMP .x_end
	
.x_end:
	SUB K, [SP]
	DCC L
	ADD C, [SP + 4]
	ICC B
	
	DEC J
	JNZ .y_loop
	
	ADD SP, 6
	POP L
	POP K
	POP J
	POP I
	
	POP BP
	RET



; u16 get_width(sprite* sp)
; gets the width
get_width:
	MOVW D:A, [SP + 4]
	MOV A, [D:A]
	RET

; u16 get_height(sprite* sp)
; gets the height
get_height:
	MOVW D:A, [SP + 4]
	MOV A, [D:A + 2]
	RET
