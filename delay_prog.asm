/*
 * delay_prog.asm
 *	
 *  Created: 05.07.2017 21:19:59
 *   Author: kich
 */
 
;******************************************
;*** Задержка с трехразрядным значением ***
; в данном случае в 1 сек.
;******************************************

.def Rz0 = r16
.def Rz1 = r17
.def Rz2 = r18

;************************************
;********** Сахарный метод **********
;************************************
.macro m_delay
	push Rz0
	push Rz1
	push Rz2
	rcall DelayProg
	pop Rz2
	pop Rz1
	pop Rz0
.endm

DelayProg:
	;Сек * Мгц / 5
	ldi Rz2, 0x03
	ldi Rz1, 0x0D
	ldi Rz0, 0x40
	DelayProgLoop:
		subi Rz0,1
		sbci Rz1,0
		sbci Rz2,0
	brcc DelayProgLoop
ret
;.exit