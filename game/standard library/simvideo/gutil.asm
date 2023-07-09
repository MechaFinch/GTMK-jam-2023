
;
; STANDARD LIBRARY - SIMVIDEO
; GRAPHICS UTILITIES
; ASM IMPLEMENTATION
;

%libname gutil

%define VBUFFER_START 0xF002_0000
%define PALETTE_START (VBUFFER_START + (320 * 240))

; none set_palette(u8* palette)
; copies the palette
set_palette:
	PUSH BP
	MOVW BP, SP
	
	PUSH I
	PUSH L
	PUSH K
	
	MOVW L:K, PALETTE_START
	MOVW B:C, [BP + 8]
	MOV I, (256 * 3) / 16
	
.loop:
	MOVW D:A, [B:C + 0]
	MOVW [L:K + 0], D:A
	MOVW D:A, [B:C + 4]
	MOVW [L:K + 4], D:A
	MOVW D:A, [B:C + 8]
	MOVW [L:K + 8], D:A
	MOVW D:A, [B:C + 12]
	MOVW [L:K + 12], D:A
	
	ADD K, 16
	ICC L
	ADD C, 16
	ICC B
	DEC I
	JNZ .loop

	POP K
	POP L
	POP I
	POP BP
	RET

; none set_color(u8 index, color24 color)
; sets a single color
set_color:
	PUSH BP
	MOVW BP, SP
	
	MOVW D:A, [BP + 9]
	MOVZ B, [BP + 8]
	MUL B, 3
	MOV [PALETTE_START + B + 0], A
	MOV [PALETTE_START + B + 2], DL
	
	POP BP
	RET
