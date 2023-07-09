
;
; STANDARD LIBRARY - SPI
; INTERRUPT DRIVEN
; ASSEMBLY IMPLEMENTATION
;

%libname spi

%include "queue.asm" as queue

; spi interface
%define SPI_INTERRUPT_VECTOR	1
%define SPI_CONTROLLER_PTR		0x0000_0800

%define SPI_BASE		0x8000_0000
%define SPI_S0_OFFSET	0
%define SPI_C0_OFFSET	1
%define SPI_C1_OFFSET	2
%define SPI_D_OFFSET	3

%define SPI_S0_READ_FULL_MASK		0x02
%define SPI_S0_TRANSMIT_EMPTY_MASK	0x01

%define SPI_C0_DEVICE_SHIFT			5
%define SPI_C0_DEVICE_DEFAULT_MASK	0x10
%define SPI_C0_CD_MASK				0x01

%define SPI_C1_CLOCK_DIVIDER_SHIFT			4
%define SPI_C1_IDLE_CLOCK_MASK				0x08
%define SPI_C1_ENABLE_TE_INTERRUPTS_MASK	0x04
%define SPI_C1_ENABLE_RF_INTERRUPTS_MASK	0x02
%define SPI_C1_ENABLE_DEVICE_MASK			0x01

%define INTERRUPT_C0_CONFIG ((0x7 << SPI_C0_DEVICE_SHIFT) | SPI_C0_DEVICE_DEFAULT_MASK)
%define INTERRUPT_C1_CONFIG (SPI_C1_ENABLE_DEVICE_MASK | SPI_C1_ENABLE_TE_INTERRUPTS_MASK | SPI_C1_ENABLE_RF_INTERRUPTS_MASK)
%define INTERRUPT_CONFIG ((INTERRUPT_C1_CONFIG << 8) | INTERRUPT_C0_CONFIG)

; queue struct
%define QUEUE_IN_INDEX		0
%define QUEUE_OUT_INDEX		2
%define QUEUE_COUNT			4
%define QUEUE_BUFFER_SIZE	6
%define QUEUE_BUFFER		8

; spi control struct
%define SPI_CONTROLLER_TX_QUEUE		0
%define SPI_CONTROLLER_RX_QUEUE		4
%define SPI_CONTROLLER_DC_QUEUE		8
%define SPI_CONTROLLER_STATE		12
%define SPI_CONTROLLER_CONFIG		13
%define SPI_CONTROLLER_EXCEPTION	14

%define SPI_CONTROLLER_CFG_EXCEPT_MASK		0x01

%define SPI_CONTROL_RECIEVE_MASK		0x02
%define SPI_CONTROL_C0_OVERWRITE_MASK	0xE3

; init(spi_controller* p, queue* txp, queue* rxp, queue* dcp)
; initializes the spi_controller structure and configures the spi interface for interrupt driven
; operation. 
init:
	PUSH BP
	MOV BP, SP
	
	; configure SPI
	MOV A, INTERRUPT_CONFIG
	MOV [SPI_BASE + SPI_C0_OFFSET], A
	
	; place pointers n such
	MOVW B:C, [BP + 8]
	MOVW D:A, [BP + 12]
	MOVW [B:C + SPI_CONTROLLER_TX_QUEUE], D:A
	MOVW D:A, [BP + 16]
	MOVW [B:C + SPI_CONTROLLER_RX_QUEUE], D:A
	MOVW D:A, [BP + 20]
	MOVW [B:C + SPI_CONTROLLER_DC_QUEUE], D:A
	MOV A, 0
	MOV [B:C + SPI_CONTROLLER_STATE], A ; also sets config
	MOV [B:C + SPI_CONTROLLER_EXCEPTION], AL
	
	; place interrupt handler and its pointer
	MOVW D:A, isr
	MOVW [SPI_INTERRUPT_VECTOR * 4], D:A
	MOVW [SPI_CONTROLLER_PTR], B:C
	
	POP BP
	RET



; blocking_transmit(u8 data, u8 control)
; transmits a byte, waiting if no buffer space is available
; interrupts must be enabled during execution
blocking_transmit:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; get TX and DC queue pointers
	MOVW J:I, [SPI_CONTROLLER_PTR]
	MOVW L:K, [J:I + SPI_CONTROLLER_TX_QUEUE]
	MOVW J:I, [J:I + SPI_CONTROLLER_DC_QUEUE]
	
	; wait for space to be available
	PUSH L
	PUSH K
.poll_available:
	CALLA queue.space_available
	JNZ .space_available
	HLT ; wait patiently
	JMP .poll_available

.space_available:
	ADD SP, 4
	
	; disable interrupts to ensure proper enqueue
	MOV A, PF
	AND A, 0xFFFE
	MOV PF, A
	PUSH A
	
	PUSH byte [BP + 8]
	PUSH L
	PUSH K
	CALLA queue.enqueue
	ADD SP, 5
	
	PUSH byte [BP + 9]
	PUSH J
	PUSH I
	CALLA queue.enqueue
	ADD SP, 5
	
	; make sure transmit empty interrupts are enabled
	MOV AL, [SPI_BASE + SPI_C1_OFFSET] ; putting this pointer in a reg is also 12 bytes
	OR AL, SPI_C1_ENABLE_TE_INTERRUPTS_MASK
	MOV [SPI_BASE + SPI_C1_OFFSET], AL
	
	; restore interrupts and return
	POP PF
	
	POP L
	POP K
	POP J
	POP I
	POP BP
	RET



; u8 nonblocking_transmit(u8 data, u8 control)
; transmits a byte, failing if no buffer space is available
; returns 1 on success, 0 on failure, with the zero flag set accordingly
nonblocking_transmit:
	PUSH BP
	MOV BP, SP
	
	PUSH I
	PUSH J
	PUSH K
	PUSH L
	
	; get queue pointers
	MOVW J:I, [SPI_CONTROLLER_PTR]
	MOVW L:K, [J:I + SPI_CONTROLLER_TX_QUEUE]
	MOVW J:I, [J:I + SPI_CONTROLLER_DC_QUEUE]
	
	; check space
	PUSH L
	PUSH K
	CALLA queue.space_available
	LEA SP, [SP + 4]
	JNZ .space_available
	
	; set A to zero, set zero flag
	MOV A, 0
	OR AL, 0
	POP L
	POP K
	POP J
	POP I
	POP BP
	RET
	
.space_available:
	; disable interrupts and enqueue
	MOV A, PF
	AND PF, 0xFFFE
	MOV PF, A
	PUSH A
	
	PUSH byte [BP + 8]
	PUSH L
	PUSH K
	CALLA queue.enqueue
	ADD SP, 5
	
	PUSH byte [BP + 9]
	PUSH J
	PUSH I
	CALLA queue.enqueue
	ADD SP, 5
	
	; make sure transmit empty interrupts are enabled
	MOV AL, [SPI_BASE + SPI_C1_OFFSET] ; putting this pointer in a reg is also 12 bytes
	OR AL, SPI_C1_ENABLE_TE_INTERRUPTS_MASK
	MOV [SPI_BASE + SPI_C1_OFFSET], AL
	
	; restore interrupts, set A and clear ZF, return
	MOV A, 0
	OR AL, 1
	POP PF
	POP BP
	RET



; u8 blocking_recieve()
; recieves a byte, waiting if no data is available
; interrupts must be enabled during execution
blocking_recieve:
	PUSH I
	PUSH J
	
	; get RX queue pointer
	MOVW J:I, [SPI_CONTROLLER_PTR]
	MOVW J:I, [J:I + SPI_CONTROLLER_RX_QUEUE]
	
	; wait for data to recieve
	PUSH J
	PUSH I
.poll_data:
	CALLA queue.data_available
	JNZ .data_available
	HLT
	JMP .poll_data

.data_available:
	ADD SP, 4
	
	; disable interrupts
	MOV A, PF
	AND A, 0xFFFE
	MOV PF, A
	PUSH A
	
	PUSH J
	PUSH I
	CALLA queue.dequeue
	ADD SP, 4
	
	; restore interrupts & return
	POP PF
	POP J
	POP I
	RET



; u8 nonblocking_recieve()
; recieves a byte, failing if no data is available
; returns zero if no data is available
; the zero flag will be clear on success and set on failure
nonblocking_recieve:
	PUSH I
	PUSH J
	
	; get RX queue
	MOVW J:I, [SPI_CONTROLLER_PTR]
	MOVW J:I, [J:I + SPI_CONTROLLER_RX_QUEUE]
	
	; check for data
	PUSH J
	PUSH I
	CALLA queue.data_available
	LEA SP, [SP + 4]
	JNZ .data_available
	
	; fail on no data
	MOV A, 0
	OR AL, 0
	POP J
	POP I
	POP BP
	RET
	
.data_available:
	; disable interrupts
	MOV A, PF
	AND A, 0xFFFE
	MOV PF, A
	PUSH A
	
	; get data
	PUSH J
	PUSH I
	CALLA queue.dequeue
	ADD SP, 4
	
	; enable interrupts, return 1 w/ zero clear
	MOV A, 0
	OR AL, 1
	POP PF
	RET



; u16 data_available()
; returns the number of bytes available to read
; the zero flag will be set accordingly
data_available:
	MOVW B:C, [SPI_CONTROLLER_PTR]
	PUSH word [B:C + SPI_CONTROLLER_RX_QUEUE + 2]
	PUSH word [B:C + SPI_CONTROLLER_RX_QUEUE + 0]
	CALLA queue.data_available
	LEA SP, [SP + 4] ; avoid affecting flags
	RET



; u16 space_available()
; returns the number of bytes available to write
; the zero flag will be set accordingly
space_available:
	MOVW B:C, [SPI_CONTROLLER_PTR]
	PUSH word [B:C + SPI_CONTROLLER_TX_QUEUE + 2]
	PUSH word [B:C + SPI_CONTROLLER_RX_QUEUE + 0]
	CALLA queue.space_available
	LEA SP, [SP + 4]
	RET



; Interrupt Service Routine
; Handles intterupts raised by the SPI controller
; Reads data into the RX queue and transmits data from the TX queue controlled by the DC queue
; If the RX queue is full, the data is discarded if exceptions are disabled. If exceptions are
; enabled, the data is held in the AL register when the exception is raised.
isr:
	PUSHA
	; disable interrupts, restored by IRET
	MOV A, PF
	AND A, 0xFFFE
	MOV PF, A
	
	; get spi device & controller
	MOVW J:I, SPI_BASE
	MOVW L:K, [SPI_ISR_CONTROLLER_PTR]
	
	; do we have data to recieve
	MOV DL, [J:I + SPI_S0_OFFSET]
	MOV DH, DL
	AND DL, SPI_S0_READ_FULL_MASK
	JZ .no_read
	
	; read data
	MOV AL, [J:I + SPI_D_OFFSET]
	
	; should we be saving read data
	MOV AH, [L:K + SPI_CONTROLLER_STATE]
	AND AH, SPI_CONTROL_RECIEVE_MASK
	JZ .no_read
	
	MOVW B:C, [L:K + SPI_CONTROLLER_RX_QUEUE]
	
	; is there space
	PUSH A
	PUSH D
	PUSH B
	PUSH C
	CALLA queue.space_available
	POP C
	POP B
	POP D
	POP A
	
	JNZ .has_space
	
	; no space - interrupt/discard
	MOV AH, [L:K + SPI_CONTROLLER_CONFIG]
	AND AH, SPI_CONTROLLER_CFG_EXCEPT_MASK
	JZ .no_exception
	INT [L:K + SPI_CONTROLLER_EXCEPTION]

.has_space:
	; enqueue
	PUSH D
	PUSH AL
	PUSH B
	PUSH C
	CALLA queue.enqueue
	ADD SP, 5
	POP D

.no_exception:	
.no_read:
	AND DH, SPI_S0_TRANSMIT_EMPTY_MASK
	JZ .no_transmit
	
	; is there data to transmit
	MOVW B:C, [L:K + SPI_CONTROLLER_TX_QUEUE]
	
	PUSH B
	PUSH C
	CALLA queue.data_available
	JZ .no_data
	
	; send off the data
	; handle C0 first
	MOVW B:C, [L:K + SPI_CONTROLLER_DC_QUEUE]
	
	PUSH B
	PUSH C
	CALLA queue.dequeue
	ADD SP, 4
	
	MOV [L:K + SPI_CONTROLLER_STATE], AL
	MOV DL, [J:I + SPI_C0_OFFSET]			; current C0
	AND DL, ~SPI_CONTROL_C0_OVERWRITE_MASK	; keep parts we don't overwrite
	AND AL, SPI_CONTROL_C0_OVERWRITE_MASK	; remove stuff needed in state that doesn't overwrite
	OR DL, AL								; overwrite & set
	MOV [J:I + SPI_C0_OFFSET], DL
	
	; transmit
	; TX was pushed earlier
	CALLA queue.dequeue
	ADD SP, 4
	
	MOV [J:I + SPI_D_OFFSET], AL
	
	; done
	POPA
	IRET
	
.no_data:
	ADD SP, 4
	
	; if there's nothing to transmit, disable transmit empty interrupts
	MOV AL, [J:I + SPI_C1_OFFSET]
	AND AL, ~SPI_C1_ENABLE_TE_INTERRUPTS_MASK
	MOV [J:I + SPI_C1_OFFSET], AL

.no_transmit:	
	POPA
	IRET
