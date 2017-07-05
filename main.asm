;
; main.asm
; Пример использования 
; Created: 04.07.2017 20:23:01
; Author : kich
;
; @todo Добавить директивы или макрос для определи контроллера

.device ATtiny10
.include "tn10def.inc"

;*****    Регистры    *****
.def	temp	= r16
.equ	_test	= 0xf1

.cseg
.org 0
	rjmp start

.include "debug.asm"
.include "delay_prog.asm"
.listmac
start:
    ldi temp, LOW(RAMEND)
    out SPL, temp
    ldi temp, HIGH(RAMEND)
    out SPH, temp

	rcall Debug_init	; инициализация дебага
	ldi temp, _test		; байт-сообщение в регистр
	m_debug temp		; отправка сообщения через макрос

	m_delay

	dec temp
	rcall Debug			; Вызов напрямую, без макроса
rjmp start

.exit