
;
; STANDARD LIBRARY - SPI DRIVER
; POLLING DRIVEN SPI
;
; SPI driver with polling
; 

%libname spi

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

%define POLLING_CONFIG ((SPI_C1_ENABLE_DEVICE_MASK << 8) | ((0x7 << SPI_C0_DEVICE_SHIFT) | SPI_C0_DEVICE_DEFAULT_MASK))

; polling_init()
; configures the SPI interface for polling
polling_init:
	; thats it lmao xd
	MOV A, POLLING_CONFIG
	MOV [SPI_BASE + SPI_C0_OFFSET], A
	RET



; u8 polling_rxtx(u8 d, u8 c)
; transmits and returns the recieved byte
polling_rxtx:
	PUSH BP
	MOV BP, SP
	
	MOV AL, [BP + 8]
	MOVW B:C, SPI_BASE
	
	MOV DL, [BP + 9]
	AND DL, 0xE1
	
	; wait for the device to be available
.poll_ready:
	CMP byte [B:C + SPI_S0_OFFSET], 0
	JNZ .poll_ready
	
	; update C0 for CD & device
	MOV DH, [B:C + SPI_C0_OFFSET]
	AND DH, 0x17
	OR DL, DH
	MOV [B:C + SPI_C0_OFFSET], DL
	
	; send byte
	MOV [B:C + SPI_D_OFFSET], AL
	
	; wait for transmit/recieve
.poll_recieve:
	CMP byte [B:C + SPI_S0_OFFSET], 0
	JZ .poll_recieve
	
	MOV AL, [B:C + SPI_D_OFFSET]
	
	POP BP
	RET
