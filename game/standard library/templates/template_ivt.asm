
;
; ASSEMBLY TEMPLATES
;
; Interrupt Vector Table
;

%libname ivt
%org 0x0000_0000

reset:	dp RESET_VECTOR
isr_1:	dp SERVICE_ROUTINE_1
isr_2:	dp SERVICE_ROUTINE_2
isr_3:	dp SERVICE_ROUTINE_3
isr_4:	dp SERVICE_ROUTINE_4
isr_5:	dp SERVICE_ROUTINE_5
isr_6:	dp SERVICE_ROUTINE_6
isr_7:	dp SERVICE_ROUTINE_7
isr_8:	dp SERVICE_ROUTINE_8

; etc

; point NULL_HANDLER to an IRET
padding:	repeat ((1024 + (reset - padding)) / 4) dp NULL_HANDLER