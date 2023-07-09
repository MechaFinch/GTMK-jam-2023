
;
; STANDARD LIBRARY - MEMORY
; QUEUE STRUCTURE
;

%libname queue

; structure offset definitions
%define QUEUE_IN_INDEX		0
%define QUEUE_OUT_INDEX		2
%define QUEUE_COUNT			4
%define QUEUE_BUFFER_SIZE	6
%define QUEUE_BUFFER		8

; create_queue(queue* struct_pointer, u16 size, u8* buffer)
; Initializes the given structure with the given information
create_queue:
	PUSH BP
	MOV BP, SP
	
	; in_index, out_index, and count all get zero
	MOVW B:C, [BP + 8]
	MOV D, 0
	MOV [B:C + QUEUE_IN_INDEX], D
	MOV [B:C + QUEUE_OUT_INDEX], D
	MOV [B:C + QUEUE_COUNT], D
	
	; buffer_size gets size, buffer gets buffer
	MOV D, [BP + 12]
	MOV [B:C + QUEUE_BUFFER_SIZE], D
	MOVW D:A, [BP + 14]
	MOVW [B:C + QUEUE_BUFFER], D:A
	
	POP BP
	RET



; u8 enqueue(queue* pointer, u8 data)
; Attempts to enqueue data
; returns 1 on success, 0 on failure
; sets the zero flag on failure
enqueue:
	PUSH BP
	MOV BP, SP
	
	MOVW B:C, [BP + 8]
	
	; check available space
	MOV D, [B:C + QUEUE_BUFFER_SIZE]
	CMP D, [B:C + QUEUE_COUNT]
	JE .queue_full
	
	; update info & place byte
	PUSH I
	PUSH J
	PUSH K
	
	; update count, retrieve index
	MOV K, [B:C + QUEUE_IN_INDEX]
	INC [B:C + QUEUE_COUNT]
	
	; place
	MOVW J:I, [B:C + QUEUE_BUFFER]
	MOV AL, [BP + 12]
	MOV [J:I + D], AL
	
	; update index
	INC K
	CMP K, D
	JL .ok
	MOV K, 0
.ok:
	MOV [B:C + QUEUE_IN_INDEX], K
	
	; clear zero flag & return
	MOV A, 1
	MOV F, 0
	POP K
	POP J
	POP I
	POP BP
	RET

.queue_full:
	; zero flag conveniently set
	MOV A, 0
	POP BP
	RET



; u8 dequeue(queue* pointer)
; Attempts to dequeue data
; returns data on success, zero on failure
; sets the zero flag on failure
dequeue:
	PUSH BP
	MOV BP, SP
	
	MOVW B:C, [BP + 8]
	
	; check for data
	MOV D, [B:C + QUEUE_COUNT]
	CMP D, 0
	JE .queue_empty
	
	PUSH I
	PUSH J
	
	; update count, get index
	MOV D, [B:C + QUEUE_OUT_INDEX]
	DEC [B:C + QUEUE_COUNT]
	
	; retrieve
	MOVW J:I, [B:C + QUEUE_BUFFER]
	MOV AL, [J:I + D]
	
	; update index
	INC D
	CMP D, [B:C + QUEUE_BUFFER_SIZE]
	JL .ok
	MOV D, 0
.ok:
	MOV [B:C + QUEUE_OUT_INDEX], D
	
	; clear zero flag and return
	MOV F, 0
	POP J
	POP I
	POP BP
	RET
	
.queue_empty:
	; zero flag already set
	MOV A, 0
	POP BP
	RET



; u8 data_available(queue* pointer)
; returns the number of bytes available to read
; the zero flag will be set accordingly
data_available:
	PUSH BP
	MOV BP, SP
	
	MOVW B:C, [BP + 8]
	MOV A, [B:C + QUEUE_COUNT]
	CMP A, 0
	
	POP BP
	RET



; u8 space_available(queue* pointer)
; returns the number of bytes available to write
; the zero flag will be set accordingly
space_available:
	PUSH BP
	MOV BP, SP
	
	MOVW B:C, [BP + 8]
	MOV A, [B:C + QUEUE_COUNT]
	SUB A, [B:C + QUEUE_BUFFER_SIZE]
	
	POP BP
	RET
