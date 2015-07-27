;
;	rds generator
;

; Copyright N.G.Hubbard June 2002
; nick@anotherurl.com

; Pin configuration
;
;	1	A2	OUT 	57kHz
;	2	A3	OUT 	Data manchester differential
;	3	A4 	open collector data clock
;	4	/MCLR
;	5	VSS	gnd
;	6	B0	OUT  	DTA 0	
;	7	B1	OUT	DTA 1
;	8	B2	OUT	DTA 2
;	9	B3	OUT	DTA 3
;	10	B4	OUT	DTA 4	
;	11	B5	OUT	DTA 5	
;	12	B6	OUT	DTA 6
;	13	B7	OUT	Unused - set when DTA data is unchanging
;	14	VDD	+5v
;	15	OSC
;	16	OSC
;	17	A0	OUT	19kHz
;	18	A1	OUT 	38kHz
;
; 
	LIST p=16f84
#include <p16f84.inc>	

	__CONFIG _XT_OSC & _WDT_OFF & _PWRTE_ON & _CP_OFF

	errorlevel      -302    ;Suppress bank warning

DCLK_BIT	equ 4	
DCLK_MASK	equ 16	

; RX_STATE bit mask

RX_PRES_BIT	equ 0
RX_PRES_MASK	equ 1

RX_DATA_BIT	equ 1
RX_DATA_MASK	equ 2

RX_B1_BIT	equ 2		; used when we're reading the ROM ID. This is 
RX_B1_MASK	equ 4		; the first bit read of the 3 cycle arbitration

;	note that general purpose registers begin at 0CH


databit		equ	0x0c
datasr		equ	0x0d
halfdata	equ	0x0e	; 19kHz counter for half data period
imagep4		equ	0x0f	; image of data port transferred on phase 4
bitcnt		equ	0x10	; bits in message byte
serialiser	equ	0x11	; shift reg
mdelta		equ	0x12	; manchester delta detector for DTA
; 		equ	0x13	
man_t		equ	0x14
man_tt		equ	0x15
man_ttt		equ	0x16
comp		equ	0x17

; a 32 entry cosine table is stored in RAM

cos0		equ	0x20
cos1		equ	0x21
cos2		equ	0x22
cos3		equ	0x23
cos4		equ	0x24
cos5		equ	0x25
cos6		equ	0x26
cos7		equ	0x27
cos8		equ	0x28
cos9		equ	0x29
cos10		equ	0x2a
cos11		equ	0x2b
cos12		equ	0x2c
cos13		equ	0x2d
cos14		equ	0x2e
cos15		equ	0x2f
cos16		equ	0x30
cos17		equ	0x31
cos18		equ	0x32
cos19		equ	0x33
cos20		equ	0x34
cos21		equ	0x35
cos22		equ	0x36
cos23		equ	0x37
cos24		equ	0x38
cos25		equ	0x39
cos26		equ	0x3a
cos27		equ	0x3b
cos28		equ	0x3c
cos29		equ	0x3d
cos30		equ	0x3e
cos31		equ	0x3f
cos32		equ	0x40
cos33		equ	0x41
cos34		equ	0x42
cos35		equ	0x43
cos36		equ	0x44
cos37		equ	0x45
cos38		equ	0x46
cos39		equ	0x47
cos40		equ	0x48
cos41		equ	0x49
cos42		equ	0x4a
cos43		equ	0x4b
cos44		equ	0x4c
cos45		equ	0x4d
cos46		equ	0x4e
cos47		equ	0x4f


; .. 4f (2f if C part)

	ORG 000H	; program code to start at 000H
;
;	Port initialisation
;
	BSF STATUS, RP0			; switch to bank 1 and
					; make all bits on Portb outputs

	movlw 0				;  
	movwf TRISA			; ... all outputs

	movlw 0				; 
	movwf TRISB			; all of PortB bits outputs

	BCF STATUS, RP0			; back to data bank 0

;	Global variable initialisation

	movlw 	0x00			; 
	movwf 	PORTB

	movlw 	0x00			; 
	movwf 	databit			;
	movwf 	imagep4			;
	movwf	serialiser	
	movwf	mdelta
	movwf	comp	

	movlw 	0x01
	movwf 	halfdata
	movwf	bitcnt

;	build the cosine table

	movlw 	.71
	movwf 	cos0
	movlw	.83
	movwf 	cos1
	movlw	.94
	movwf 	cos2
	movlw	.103
	movwf 	cos3
	movlw	.110
	movwf 	cos4
	movlw	.115
	movwf 	cos5
	movlw	.117
	movwf 	cos6
	movlw	.117
	movwf 	cos7
	movlw	.115
	movwf 	cos8
	movlw	.111
	movwf 	cos9
	movlw	.106
	movwf 	cos10
	movlw	.102
	movwf 	cos11
	movlw	.97
	movwf 	cos12
	movlw	.94
	movwf 	cos13
	movlw	.92
	movwf 	cos14
	movlw	.92
	movwf 	cos15

	movlw	.94
	movwf 	cos16
	movlw	.98
	movwf 	cos17
	movlw	.103
	movwf 	cos18
	movlw	.109
	movwf 	cos19
	movlw	.115
	movwf 	cos20
	movlw	.121
	movwf 	cos21
	movlw	.125
	movwf 	cos22
	movlw	.127
	movwf 	cos23
	movlw	.127			; start of cosine and last quad of transition
	movwf 	cos24
	movlw	.125
	movwf 	cos25
	movlw	.120
	movwf 	cos26
	movlw	.113
	movwf 	cos27
	movlw	.104
	movwf 	cos28
	movlw	.94
	movwf 	cos29
	movlw	.82
	movwf 	cos30
	movlw	.70
	movwf 	cos31

	movlw	.58			; cosine second quadrant
	movwf 	cos32
	movlw	.46
	movwf 	cos33
	movlw	.34
	movwf 	cos34
	movlw	.24
	movwf 	cos35
	movlw	.15
	movwf 	cos36
	movlw	.8
	movwf 	cos37
	movlw	.3
	movwf 	cos38
	movlw	.1
	movwf 	cos39
	movlw	.1
	movwf 	cos40
	movlw	.3
	movwf 	cos41
	movlw	.8
	movwf 	cos42
	movlw	.15
	movwf 	cos43

	movlw	cos0			; set DTA pointer
	movwf	FSR
;
;
;	un-comment this to generate the NAB test waveform
;
;loop42	movlw	0xad			; 8
;	call	sendita			; 9, 10
;	movlw	0x3f			; 6
;	call	sendit			; 7, 8
;	movlw	0xad			; 6
;	call	sendit			; 7, 8
;	movlw	0x3f			; 6
;	call	sendit			; 7, 8
;	goto	loop42			; 6, 7

#include "message.asm"

sendit	nop				; 9
	nop				; 10
sendita movwf	serialiser		; 11			76543210
	call	serial			; 12, 13	0
	call	del_6			; 3..8		
	call	slong			; 9, 10		1
	rlf	serialiser, 1		; 8			6543210x
	call	slong			; 9, 10		2
	nop				; 8
	call	slong			; 9, 10		3
	rlf	serialiser, 1		; 8			543210xx
	call	slong			; 9, 10		4
	nop				; 8
	call	slong			; 9, 10		5
	rlf	serialiser, 1		; 8			43210xxx
	call	slong			; 9, 10		6
	nop				; 8
	call	slong			; 9, 10		7
	rlf	serialiser, 1		; 8			3210xxxx
	call	slong			; 9, 10		8
	nop				; 8		
	call	slong			; 9, 10		9
	rlf	serialiser, 1		; 8			210xxxxx
	call	slong			; 9, 10		10
	nop				; 8
	call	slong			; 9, 10		11
	rlf	serialiser, 1		; 8			10xxxxxx
	call	slong			; 9, 10		12	
	nop				; 8
	call	slong			; 9, 10		13
	rlf	serialiser, 1		; 8			0xxxxxxx
	call	slong			; 9, 10		14
	call	del_4			; 8..11
	call	serial			; 12, 13	15
	nop				; 3
	return				; 4, 5

slong	nop				; 11
	call	serial			; 12, 13
	nop				; 3
	nop				; 4
	nop				; 5
	return				; 6, 7

ploop
	nop				; 21
	call	del_8 			; 22 .. 29
	movlw  	0x0			; 30
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32

					;   INDF will be ... 1, 3, 5, 7, 9, 11, 13, not 15, 17,  in this phase.
					; for cosine: 33 35 37 39
					;	 if we are at 39 change the direction of the index so we wrap
					; really we would do this at 39 but 39 is in the other bit...
					; so do it at 41 


	movlw	cos41			; 1	end point
	subwf	FSR, 0			; 2
	BTFSS	STATUS, Z		; 3
	goto	pha1			; 4, 5
	movlw	cos25			; 5
	movwf	FSR			; 6
	movlw	.1			; 7 invert
	xorwf	comp, 1			; 8
	goto	pha2			; 9, 10

pha1	call	del_5			; 6..10 
pha2	call	del_19			; 11 .. 29
	movlw  	0x04			; 30  was 07
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32

	call	del_16			; 1  .. 16
	call	del_13 			; 17 .. 29
	movlw  	0x0			; 30 was 03
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32

	movfw	INDF			; 1 
	btfsc	comp, 0			; 2
	comf	INDF, 0			; 3
	addwf	comp, 0			; 4
	movwf	PORTB			; 5 
	movlw	.1			; 6		get index direction
	addwf	FSR,1			; 7		and bump index -- or ++ 22, 26
	call	del_16			; 8 ..23
	call	del_6			; 24..29
	movlw  	0x04			; 30
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32

	call	del_16 			; 1  .. 16
	call	del_13 			; 17 .. 29
	movlw  	0x0			; 30 was 02
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32

ph4a	bcf	databit, 5		; 1 		7 of 8 
	btfsc	halfdata, 2		; 2 		bit 2 of the 3 bit counter toggles at 2 * data rate 
	bsf	databit, 5		; 3 
	call	del_10			; 4  .. 13
	call	del_16 			; 14 .. 29
	movlw  	0x04			; 30 was 06
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32

	movfw	INDF			; 1 
	btfsc	comp, 0			; 2
	comf	INDF, 0			; 3
	addwf	comp, 0			; 4
	movwf	PORTB			; 5 
	movlw	.1			; 6		get index direction
	addwf	FSR,1			; 7		and bump index -- or ++ 21, 27
	call	del_9			; 8 .. 16
	decf	halfdata, 1		; 17
	BTFSS	STATUS, Z		; 18
	goto	ploop			; 19, 20 		7 out of 8 times we do nothing

; the half data period sequence

	call	del_10			; 20 .. 29
	movlw  	0x0			; 30
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32
	return				; 1, 2		// return to the co-routine

serial
	call	del_16			; 14..29
	movlw  	0x04			; 30  was 07 was ff for test
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32
ph2	btfsc	imagep4, 4		; 1 		serialise and differntial encode. If data rate clock toggle is 0,
	goto 	ph2b			; 2, 3		serialise and encode. If 1, do nothing 

ph2a
	movfw	imagep4			; 3
	andlw	0x3f			; 4	clear message and diff bits
	nop				; 5
	BTFSC	serialiser, 7		; 6
	IORLW	0x80			; 7
	movwf	imagep4			; 8	message bit now presented. on to the differential encoder
	rrf	imagep4, 0		; 9	dxxx xxxx -> (w)xdxx xxxx
	xorwf	databit, 0		; 10			^D^^ ^^^^
	andlw	0x40			; 11			0D00 0000
	BTFSS	STATUS, Z		; 12
	bsf	imagep4, 6		; 13		set the diff bit
	goto	phbd			; 14, 15

ph2b	call	del_12			; 4..15
phbd	call	del_14			; 16..29
	movlw  	0x0			; 30  
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32

	movfw	INDF			; 1 
	btfsc	comp, 0			; 2
	comf	INDF, 0			; 3
	addwf	comp, 0			; 4
	movwf	PORTB			; 5 
	movlw	.1			; 6		get index direction
	addwf	FSR,1			; 7		and bump index -- or ++ 20, 28
	call	del_16			; 8  .. 23
	call	del_6			; 24 .. 29
	movlw  	0x04			; 30    was 05
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32

ph3
	call	del_8			; 1..8
	movfw	imagep4			; 9		manchester encode. If data rate clock toggle is 0, take 
	btfss	imagep4, 4		; 10 		data from the diff encode. If 1, negate the last data.
	goto 	ph3a			; 11, 12			
	xorlw	0x08			; 12 		toggle
	nop				; 13
	goto 	ph3b			; 14, 15

ph3a	andlw	0xf7			; 13		take data from diff encode. Assume a zero
	btfsc	imagep4, 6		; 14
	iorlw	0x08			; 15		.. OK it was a 1
ph3b	movwf	imagep4			; 16
	movwf	databit			; 17		 make data change on o/p before clock. (setup time)
	call	del_12			; 18 .. 29
	movlw  	0x0			; 30		was 02
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32
ph4
	movfw	man_tt			; 1	// set up a pipeline
	movwf	man_ttt			; 2
	movwf	mdelta			; 3
	movfw	man_t			; 4
	movwf	man_tt			; 5
	xorwf	mdelta, 1		; 6		set the delta	
	movfw	databit			; 7
	movwf	man_t			; 8
	movfw	imagep4			; 9 		all clock outputs change at this time
	xorlw	0x10			; 10 		data rate clock toggle
	andlw	0xdf			; 11 		2 times clock will be zero	
	movwf	imagep4			; 12
	movwf	databit			; 13  	 	
	btfsc	mdelta, 3		; 14 		transition?
	goto	ph4d			; 15, 16 	jump if a transition
	movlw	cos0			; 16
	movwf	FSR			; 17 		do double hump
	movlw	.0			; 18
	movwf	comp			; 19
	movlw	.1			; 20 set DTA pointer 	1 -> 0
	btfss	man_tt, 3		; 21
	movwf	comp			; 22 set DTA pointer	0 -> 1
	goto	ph4e			; 23, 24
ph4d	call	del_8			; 17 .. 24
ph4e	call	del_5			; 25 .. 29
	movlw  	0x04			; 30  was 06
	iorwf   databit,0		; 31
	movwf 	PORTA			; 32

	movfw	INDF			; 1 
	btfsc	comp, 0			; 2
	comf	INDF, 0			; 3
	addwf	comp, 0			; 4
	movwf	PORTB			; 5 
	movlw	.1			; 6		get index direction
	addwf	FSR,1			; 7		and bump index -- or ++ 23, 25
	call	del_8			; 8..15
	movlw 	0x07			; 16	reset half data rate counter
	movwf 	halfdata		; 17
	nop				; 18
	goto	ploop			; 19, 20	ploop

del_19	nop
	nop
	nop
del_16					; call 1, 2
	nop				; 3
	nop				; 4
del_14	nop				; 5
del_13	nop				; 6
del_12	nop				; 7
	nop				; 8
del_10	nop				; 9
del_9	nop				; 10	
del_8	nop				; 11		for 8: 	call 1, 2 3
del_7	nop				; 12			4
del_6	nop				; 13			5
del_5	nop				; 14			6
del_4	return				; 15, 16		7, 8

;***************************************************************************



	END

