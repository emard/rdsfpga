			; PI c000
			; PS Radio4
			; RT HELLO
			; PTY 0 -
loop_1
			; Group 0B segment 0
			; c000 26c 080c 29f c000 1c0 5261 2a9
			; c0 00 9b 02 03 29 fc 00 07 01 49 86 a9 
	movlw	0xc0	; 00
	call	sendita	; compensate for the extra goto
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x02	; 03
	call	sendit
	movlw	0x03	; 04
	call	sendit
	movlw	0x29	; 05
	call	sendit
	movlw	0xfc	; 06
	call	sendit
	movlw	0x00	; 07
	call	sendit
	movlw	0x07	; 08
	call	sendit
	movlw	0x01	; 09
	call	sendit
	movlw	0x49	; 10
	call	sendit
	movlw	0x86	; 11
	call	sendit
	movlw	0xa9	; 12
	call	sendit
			; Group 0B segment 1
			; c000 26c 0809 07b c000 1c0 6469 3c6
			; c0 00 9b 02 02 47 bc 00 07 01 91 a7 c6 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x02	; 03
	call	sendit
	movlw	0x02	; 04
	call	sendit
	movlw	0x47	; 05
	call	sendit
	movlw	0xbc	; 06
	call	sendit
	movlw	0x00	; 07
	call	sendit
	movlw	0x07	; 08
	call	sendit
	movlw	0x01	; 09
	call	sendit
	movlw	0x91	; 10
	call	sendit
	movlw	0xa7	; 11
	call	sendit
	movlw	0xc6	; 12
	call	sendit
			; Group 0B segment 2
			; c000 26c 080a 2b0 c000 1c0 6f34 394
			; c0 00 9b 02 02 ab 0c 00 07 01 bc d3 94 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x02	; 03
	call	sendit
	movlw	0x02	; 04
	call	sendit
	movlw	0xab	; 05
	call	sendit
	movlw	0x0c	; 06
	call	sendit
	movlw	0x00	; 07
	call	sendit
	movlw	0x07	; 08
	call	sendit
	movlw	0x01	; 09
	call	sendit
	movlw	0xbc	; 10
	call	sendit
	movlw	0xd3	; 11
	call	sendit
	movlw	0x94	; 12
	call	sendit
			; Group 0B segment 3
			; c000 26c 080b 309 c000 1c0 2020 0dc
			; c0 00 9b 02 02 f0 9c 00 07 00 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x02	; 03
	call	sendit
	movlw	0x02	; 04
	call	sendit
	movlw	0xf0	; 05
	call	sendit
	movlw	0x9c	; 06
	call	sendit
	movlw	0x00	; 07
	call	sendit
	movlw	0x07	; 08
	call	sendit
	movlw	0x00	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 0
			; c000 26c 2000 237 4845 03d 4c4c 313
			; c0 00 9b 08 00 23 74 84 50 f5 31 33 13 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x00	; 04
	call	sendit
	movlw	0x23	; 05
	call	sendit
	movlw	0x74	; 06
	call	sendit
	movlw	0x84	; 07
	call	sendit
	movlw	0x50	; 08
	call	sendit
	movlw	0xf5	; 09
	call	sendit
	movlw	0x31	; 10
	call	sendit
	movlw	0x33	; 11
	call	sendit
	movlw	0x13	; 12
	call	sendit
			; Group 2A segment 1
			; c000 26c 2001 38e 4f20 23d 2020 0dc
			; c0 00 9b 08 00 78 e4 f2 08 f4 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x00	; 04
	call	sendit
	movlw	0x78	; 05
	call	sendit
	movlw	0xe4	; 06
	call	sendit
	movlw	0xf2	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xf4	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 2
			; c000 26c 2002 145 2020 238 2020 0dc
			; c0 00 9b 08 00 94 52 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x00	; 04
	call	sendit
	movlw	0x94	; 05
	call	sendit
	movlw	0x52	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 3
			; c000 26c 2003 0fc 2020 238 2020 0dc
			; c0 00 9b 08 00 cf c2 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x00	; 04
	call	sendit
	movlw	0xcf	; 05
	call	sendit
	movlw	0xc2	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 4
			; c000 26c 2004 16a 2020 238 2020 0dc
			; c0 00 9b 08 01 16 a2 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x01	; 04
	call	sendit
	movlw	0x16	; 05
	call	sendit
	movlw	0xa2	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 5
			; c000 26c 2005 0d3 2020 238 2020 0dc
			; c0 00 9b 08 01 4d 32 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x01	; 04
	call	sendit
	movlw	0x4d	; 05
	call	sendit
	movlw	0x32	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 6
			; c000 26c 2006 218 2020 238 2020 0dc
			; c0 00 9b 08 01 a1 82 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x01	; 04
	call	sendit
	movlw	0xa1	; 05
	call	sendit
	movlw	0x82	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 7
			; c000 26c 2007 3a1 2020 238 2020 0dc
			; c0 00 9b 08 01 fa 12 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x01	; 04
	call	sendit
	movlw	0xfa	; 05
	call	sendit
	movlw	0x12	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 8
			; c000 26c 2008 134 2020 238 2020 0dc
			; c0 00 9b 08 02 13 42 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x02	; 04
	call	sendit
	movlw	0x13	; 05
	call	sendit
	movlw	0x42	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 9
			; c000 26c 2009 08d 2020 238 2020 0dc
			; c0 00 9b 08 02 48 d2 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x02	; 04
	call	sendit
	movlw	0x48	; 05
	call	sendit
	movlw	0xd2	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 10
			; c000 26c 200a 246 2020 238 2020 0dc
			; c0 00 9b 08 02 a4 62 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x02	; 04
	call	sendit
	movlw	0xa4	; 05
	call	sendit
	movlw	0x62	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 11
			; c000 26c 200b 3ff 2020 238 2020 0dc
			; c0 00 9b 08 02 ff f2 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x02	; 04
	call	sendit
	movlw	0xff	; 05
	call	sendit
	movlw	0xf2	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 12
			; c000 26c 200c 269 2020 238 2020 0dc
			; c0 00 9b 08 03 26 92 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x03	; 04
	call	sendit
	movlw	0x26	; 05
	call	sendit
	movlw	0x92	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 13
			; c000 26c 200d 3d0 2020 238 2020 0dc
			; c0 00 9b 08 03 7d 02 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x03	; 04
	call	sendit
	movlw	0x7d	; 05
	call	sendit
	movlw	0x02	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 14
			; c000 26c 200e 11b 2020 238 2020 0dc
			; c0 00 9b 08 03 91 b2 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x03	; 04
	call	sendit
	movlw	0x91	; 05
	call	sendit
	movlw	0xb2	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
			; Group 2A segment 15
			; c000 26c 200f 0a2 2020 238 2020 0dc
			; c0 00 9b 08 03 ca 22 02 08 e0 80 80 dc 
	movlw	0xc0	; 00
	call	sendit
	movlw	0x00	; 01
	call	sendit
	movlw	0x9b	; 02
	call	sendit
	movlw	0x08	; 03
	call	sendit
	movlw	0x03	; 04
	call	sendit
	movlw	0xca	; 05
	call	sendit
	movlw	0x22	; 06
	call	sendit
	movlw	0x02	; 07
	call	sendit
	movlw	0x08	; 08
	call	sendit
	movlw	0xe0	; 09
	call	sendit
	movlw	0x80	; 10
	call	sendit
	movlw	0x80	; 11
	call	sendit
	movlw	0xdc	; 12
	call	sendit
	goto	loop_1
