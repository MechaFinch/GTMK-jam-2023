
; 
; STANDARD LIBRARY - SIM VIDEO
; SHAPES
; ASM IMPLEMENTATION
;

%libname shapes

%define VBUFFER_START 0xF002_0000

%define ROWS_PIXELS 240
%define COLS_PIXELS 320

; none freeline(i16 x1, i16 y1, i16 x2, i16 y2, u8 fgc)
; draws a freeform line from (x1, y1) to (x2, y2) in the fgc
freeline:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; A = y1
	; B = y2
	; C = x2
	; D = x1
	MOVW D:A, [BP + 8]
	MOVW B:C, [BP + 12]
	
	; determine what subroutine to call and how
	; absolute value
	; A = abs(y2 - y1)
	; B = y2 - y1
	; C = x2 - x1
	; D = abs(x2 - x1)
	SUB B, A
	MOV A, B
	NEG A
	CMOVS A, B
	
	SUB C, D
	MOV D, C
	NEG D
	CMOVS D, C
	
	CMP A, D
	JGE .quadhigh
	
	; low half. x1 > x2 if sign set
	; bresenham's: shallow slope
	; A = yi
	; B = dy
	; C = dx 2*(dy - dx)
	; D = D
	; J:I = pointer, tmp y
	; K = counter (abs(x2 - x1))
	; L = tmp x
	MOV K, D
	CMP C, 0 ; if sign set, x1 > x2 -> swap points
	JNS .low_no_rev
	
	NEG B ; -dy
	NEG C ; -dx
	MOV I, [BP + 14] ; y2
	MOV L, [BP + 12] ; x2
	JMP .draw_low

.low_no_rev:
	MOV I, [BP + 10] ; y1
	MOV L, [BP + 8]	 ; x1

.draw_low:
	; yi = 1 if dy pos else -1
	; dy = abs(dy)
	XCHG A, B
	SHR A, 15
	NEG A
	CMOVZ A, 1
	
	; D = 2dy - dx
	MOV D, B
	SHL D, 1
	SUB D, C
	
	; J:I = start pos
	MULH J:I, COLS_PIXELS
	ADD I, L
	ADC J, (VBUFFER_START / 0x1_0000)
	
	; AL = color
	; L = yi * COLS_PIXELS
	CMP A, 0
	CMOVS L, 0 - COLS_PIXELS
	CMOVNS L, COLS_PIXELS
	MOV AL, [BP + 16]
	
	; C = 2 * (dy - dx)
	NEG C
	ADD C, B
	SHL C, 1
	
	; B = 2 * dy
	SHL B, 1
	
	; loop by counter
.low_loop:
	; place pixel
	MOV [J:I], AL
	INC I
	ICC J
	
	CMP D, 0
	JLE .no_y_change
	
	CMP L, 0
	JS .yi_neg
	ADD I, L ; y += yi
	ICC J
	JMP .yi_pos
.yi_neg:
	ADD I, L
	DCC J
.yi_pos:
	ADD D, C ; D += 2 * (dy - dx)
	
	DEC K
	JNS .low_loop
	JMP .done
	
.no_y_change:
	ADD D, B ; D += 2 * dy

	DEC K
	JNS .low_loop
	JMP .done

	; high half, y1 > y2 if sign set
	; bresenhams: steep slope
	; A = xi
	; B = dy (dx - dy)
	; C = dx
	; D = D
	; J:I = pointer, tmp y
	; K = counter
	; L = tmp x
.quadhigh:
	MOV K, A ; counter = abs(y2 - y1)
	MOV A, D ; get abs(dx)
	CMP B, 0
	JNS .high_no_rev
	
	NEG B ; -dy
	NEG C ; -dx
	MOV I, [BP + 14] ; y2
	MOV L, [BP + 12] ; x2
	JMP .draw_high

.high_no_rev:
	MOV I, [BP + 10] ; y1
	MOV L, [BP + 8]  ; x1
	
.draw_high:
	; xi = 1 if dx pos else -1
	; dx = abs(dx)
	XCHG A, C
	SHR A, 15	; 1 if negative else 0
	NEG A		; -1 if negative else 0
	CMOVZ A, 1	; -1 if negative else 1
	
	; D = 2dx - dy
	MOV D, C
	SHL D, 1
	SUB D, B
	
	; J:I = start pos
	MULH J:I, COLS_PIXELS
	ADD I, L
	ADC J, (VBUFFER_START / 0x1_0000)
	
	; AL = color
	; L = xi
	MOV L, A
	MOV AL, [BP + 16]
	
	; B = 2 * (dx - dy)
	NEG B
	ADD B, C
	SHL B, 1
	
	; C = 2 * dx
	SHL C, 1
	
	; loop by counter
.high_loop:
	; place pixel
	MOV [J:I], AL
	INC I
	ICC J
	
	CMP D, 0
	JLE .no_x_change
	
	CMP L, 0
	JS .xi_neg
	INC I
	ICC J
	JMP .xi_pos
.xi_neg:
	DEC I
	DCC J
.xi_pos:
	ADD D, B
	DEC K
	JNS .low_loop
	JMP .done

.no_x_change:
	ADD D, C
	
	DEC K
	JNS .high_loop
	
.done:
	POP L
	POP K
	POP J
	POP I
	POP BP
	RET

; none hlineus(i16 x1, i16 y1, i16 x2, u8 fgc)
; draws a horizontal line from (x1, y1) to (x2, y1) in the fgc without bounds checks
hlineus:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	
	MOVW D:A, [BP + 8]
	MOV B, [BP + 12]
	JMP hline.ready

; none hline(i16 x1, i16 y1, i16 x2, u8 fgc)
; draws a horizontal line from (x1, y1) to (x2, y1) in the fgc
hline:
	; check/clip such that things are on screen
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	
	; D = y1
	; A = x1
	MOVW D:A, [BP + 8] 
	CMP D, ROWS_PIXELS
	JGE .done
	CMP D, 0
	JL .done

	; B = x2
	MOV B, [BP + 12]
	CMP A, COLS_PIXELS
	JGE .x1_oob
	CMP A, 0
	JL .x1_oob
	
	; x1 in bounds. if x2 oob, clip
	CMP B, COLS_PIXELS
	JGE .x2_oob
	CMP B, 0
	JL .x2_oob
	
	; both in bounds
	JMP .none_oob
	
	; x1 oob. if x2 oob, draw nothing, otherwise clip x1
.x1_oob:
	CMP B, COLS_PIXELS
	JGE .done
	CMP B, 0
	JL .done
	
	; clip - x1 is either right (> COLS_PIXELS) or left (< zero) of the screen
	CMP A, 0
	CMOVG A, COLS_PIXELS - 1
	CMOVL A, 0
	JMP .none_oob
	
.x2_oob:
	CMP B, 0
	CMOVG B, COLS_PIXELS - 1
	CMOVL B, 0
	
	; make sure x1<x2
.none_oob:
	CMP A, B
	JL .ready
	XCHG A, B

	; good to go
	; D = y1
	; A = x1
	; B = x2
.ready:
	; B = x2 - x1
	SUB B, A
	
	; D:A = start address
	MOV C, A
	MOV A, COLS_PIXELS
	MULH D:A, D
	ADD A, C
	ADC D, (VBUFFER_START / 0x1_0000)
	
	; CL = fgc
	MOV CL, [BP + 14]
	MOV CH, CL
	MOV I, C
	MOV J, C
	
	MOV K, B
	INC K
	CMP K, 16
	JL .last

.fast_loop:
	MOVW [D:A], J:I
	MOVW [D:A + 4], J:I
	MOVW [D:A + 8], J:I
	MOVW [D:A + 12], J:I
	
	ADD A, 16
	ICC D
	SUB K, 16
	CMP K, 16
	JGE .fast_loop

.last:
	SHL K, 1
	JMP word [IP + K]
	dw @.d0
	dw @.d1
	dw @.d2
	dw @.d3
	dw @.d4
	dw @.d5
	dw @.d6
	dw @.d7
	dw @.d8
	dw @.d9
	dw @.dA
	dw @.dB
	dw @.dC
	dw @.dD
	dw @.dE
	dw @.dF
	
.d1:
	MOV [D:A], CL
	JMP .done
	
.d2:
	MOV [D:A], C
	JMP .done

.d3:
	MOV [D:A + 0], C
	MOV [D:A + 2], CL
	JMP .done

.d4:
	MOVW [D:A], J:I
	JMP .done

.d5:
	MOVW [D:A], J:I
	MOV [D:A + 4], CL
	JMP .done
	
.d6:
	MOVW [D:A], J:I
	MOV [D:A + 4], C
	JMP .done
	
.d7:
	MOVW [D:A], J:I
	MOV [D:A + 4], C
	MOV [D:A + 6], CL
	JMP .done
	
.d8:
	MOVW [D:A], J:I
	MOVW [D:A + 4], J:I
	JMP .done
	
.d9:
	MOVW [D:A], J:I
	MOVW [D:A + 4], J:I
	MOV [D:A + 8], CL
	JMP .done
	
.dA:
	MOVW [D:A], J:I
	MOVW [D:A + 4], J:I
	MOV [D:A + 8], C
	JMP .done
	
.dB:
	MOVW [D:A], J:I
	MOVW [D:A + 4], J:I
	MOV [D:A + 8], C
	MOV [D:A + 10], CL
	JMP .done
	
.dC:
	MOVW [D:A], J:I
	MOVW [D:A + 4], J:I
	MOVW [D:A + 8], J:I
	JMP .done
	
.dD:
	MOVW [D:A], J:I
	MOVW [D:A + 4], J:I
	MOVW [D:A + 8], J:I
	MOV [D:A + 12], CL
	JMP .done
	
.dE:
	MOVW [D:A], J:I
	MOVW [D:A + 4], J:I
	MOVW [D:A + 8], J:I
	MOV [D:A + 12], C
	JMP .done
	
.dF:
	MOVW [D:A], J:I
	MOVW [D:A + 4], J:I
	MOVW [D:A + 8], J:I
	MOV [D:A + 12], C
	MOV [D:A + 14], CL
	
.d0:
.done:
	POP K
	POP J
	POP I
	POP BP
	RET

; none vlineus((i16 x1, i16 y1, i16 y2, u8 fgc)
; draws a vertical line from (x1, y1) to (x1, y2) in the fgc without bounds checks
vlineus:
	PUSH BP
	MOV BP, SP
	
	PUSH K
	
	MOVW D:A, [BP + 8]
	MOV B, [BP + 12]
	JMP vline.ready

; none vline(i16 x1, i16 y1, i16 y2, u8 fgc)
; draws a vertical line from (x1, y1) to (x1, y2) in the fgc
vline:
	PUSH BP
	MOV BP, SP
	
	PUSH K
	
	; check/clip such that things are on screen
	; D = y1
	; A = x1
	; B = y2
	MOVW D:A, [BP + 8]
	CMP A, COLS_PIXELS
	JGE .done
	CMP A, 0
	JL .done
	
	MOV B, [BP + 12]
	CMP D, ROWS_PIXELS
	JGE .y1_oob
	CMP D, 0
	JL .y1_oob
	
	; y1 in bounds. if y2 oob, clip
	CMP B, ROWS_PIXELS
	JGE .y2_oob
	CMP B, 0
	JL .y2_oob
	
	; both in bounds
	JMP .none_oob

	; y1 oob. if y2 oob, draw nothing, otherwise clip y1
.y1_oob:
	CMP B, ROWS_PIXELS
	JGE .done
	CMP B, 0
	JL .done
	
	; clip y1
	CMP D, 0
	CMOVG D, ROWS_PIXELS - 1
	CMOVL D, 0
	JMP .none_oob

.y2_oob:
	CMP B, 0
	CMOVG B, ROWS_PIXELS - 1
	CMOVL B, 0

	; ensure y1 < y2
.none_oob:
	CMP D, B
	JL .ready
	XCHG D, B

	; good to go
.ready:
	; B = y2 - y1
	; D:A = start address
	; CL = fgc
	SUB B, D
	
	MOV C, A
	MOV A, COLS_PIXELS
	MULH D:A, D
	ADD A, C
	ADC D, (VBUFFER_START / 0x1_0000)
	
	MOV CL, [BP + 14]
	
	MOV K, B
	INC K
	CMP K, 8
	JL .last
	
.fast_loop:
	MOV [D:A + 0 * COLS_PIXELS], CL
	MOV [D:A + 1 * COLS_PIXELS], CL
	MOV [D:A + 2 * COLS_PIXELS], CL
	MOV [D:A + 3 * COLS_PIXELS], CL
	MOV [D:A + 4 * COLS_PIXELS], CL
	MOV [D:A + 5 * COLS_PIXELS], CL
	MOV [D:A + 6 * COLS_PIXELS], CL
	MOV [D:A + 7 * COLS_PIXELS], CL
	
	ADD A, 8 * COLS_PIXELS
	ICC D
	SUB K, 8
	CMP K, 8
	JGE .fast_loop

.last:
	SHL K, 1
	JMP word [IP + K]
	dw @.d0
	dw @.d1
	dw @.d2
	dw @.d3
	dw @.d4
	dw @.d5
	dw @.d6
	dw @.d7

.d1:
	MOV [D:A + 0 * COLS_PIXELS], CL
	JMP .done
	
.d2:
	MOV [D:A + 0 * COLS_PIXELS], CL
	MOV [D:A + 1 * COLS_PIXELS], CL
	JMP .done
	
.d3:
	MOV [D:A + 0 * COLS_PIXELS], CL
	MOV [D:A + 1 * COLS_PIXELS], CL
	MOV [D:A + 2 * COLS_PIXELS], CL
	JMP .done
	
.d4:
	MOV [D:A + 0 * COLS_PIXELS], CL
	MOV [D:A + 1 * COLS_PIXELS], CL
	MOV [D:A + 2 * COLS_PIXELS], CL
	MOV [D:A + 3 * COLS_PIXELS], CL
	JMP .done
	
.d5:
	MOV [D:A + 0 * COLS_PIXELS], CL
	MOV [D:A + 1 * COLS_PIXELS], CL
	MOV [D:A + 2 * COLS_PIXELS], CL
	MOV [D:A + 3 * COLS_PIXELS], CL
	MOV [D:A + 4 * COLS_PIXELS], CL
	JMP .done
	
.d6:
	MOV [D:A + 0 * COLS_PIXELS], CL
	MOV [D:A + 1 * COLS_PIXELS], CL
	MOV [D:A + 2 * COLS_PIXELS], CL
	MOV [D:A + 3 * COLS_PIXELS], CL
	MOV [D:A + 4 * COLS_PIXELS], CL
	MOV [D:A + 5 * COLS_PIXELS], CL
	JMP .done
	
.d7:
	MOV [D:A + 0 * COLS_PIXELS], CL
	MOV [D:A + 1 * COLS_PIXELS], CL
	MOV [D:A + 2 * COLS_PIXELS], CL
	MOV [D:A + 3 * COLS_PIXELS], CL
	MOV [D:A + 4 * COLS_PIXELS], CL
	MOV [D:A + 5 * COLS_PIXELS], CL
	MOV [D:A + 6 * COLS_PIXELS], CL

.d0:
.done:
	POP K
	POP BP
	RET

; none outline_rect(i16 x1, i16 y1, i16 w, i16 h, u8 fgc)
; draws the outline of a rectangle in the fgc
; top left at (x1, y1)
outline_rect:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; check and clip bounds
	; I = x1
	; J = y1
	; K = w, x2
	; L = h, y2
	MOVW J:I, [BP + 8]
	MOVW L:K, [BP + 12]
	
	ADD K, I
	ADD L, J
	DEC K
	DEC L
	
	; if x2 < 0 or x1 > width, definitely off screen
	CMP K, 0
	JL .done
	CMP I, COLS_PIXELS
	JGE .done
	
	; same with y and height
	CMP L, 0
	JL .done
	CMP J, ROWS_PIXELS
	JGE .done
	
	; clip to bounds
	CMP I, 0
	CMOVL I, 0
	
	CMP J, 0
	CMOVL J, 0
	
	CMP K, COLS_PIXELS - 1
	CMOVG K, COLS_PIXELS - 1
	
	CMP L, ROWS_PIXELS - 1
	CMOVG L, ROWS_PIXELS - 1
	
	; hline top
	PUSH byte [BP + 16]
	PUSH K
	PUSH J
	PUSH I
	CALL hlineus
	
	; hline bottom
	PUSH byte [BP + 16]
	PUSH K
	PUSH L
	PUSH I
	CALL hlineus
	
	; vline left
	PUSH byte [BP + 16]
	PUSH L
	PUSH J
	PUSH I
	CALL vlineus
	
	; vline right
	PUSH byte [BP + 16]
	PUSH L
	PUSH J
	PUSH K
	CALL vlineus
	
	ADD SP, 28
	
.done:
	POP L
	POP K
	POP J
	POP I
	POP BP
	RET

; none fill_rect(i16 x1, i16 y1, i16 w, i16 h, u8 fgc)
; fills a rectangle in the fgc
; top left at (x1, y1)
fill_rect:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; check and clip bounds
	; I = x1
	; J = y1
	; K = w, x2
	; L = h, y2
	MOVW J:I, [BP + 8]
	MOVW L:K, [BP + 12]
	
	ADD K, I
	ADD L, J
	DEC K
	DEC L
	
	; if x2 < 0 or x1 > width, definitely off screen
	CMP K, 0
	JL .done
	CMP I, COLS_PIXELS
	JGE .done
	
	; same with y and height
	CMP L, 0
	JL .done
	CMP J, ROWS_PIXELS
	JGE .done
	
	; clip to bounds
	CMP I, 0
	CMOVL I, 0
	
	CMP J, 0
	CMOVL J, 0
	
	CMP K, COLS_PIXELS - 1
	CMOVG K, COLS_PIXELS - 1
	
	CMP L, ROWS_PIXELS - 1
	CMOVG L, ROWS_PIXELS - 1
	
	; for each y, hline
	SUB L, J
.loop:
	PUSH byte [BP + 16]
	PUSH K
	PUSH J
	PUSH I
	CALL hlineus
	ADD SP, 7
	
	INC J
	DEC L
	JNS .loop
	
.done:
	POP L
	POP K
	POP J
	POP I
	POP BP
	RET
	