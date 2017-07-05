/*
 * debug.inc
 * Простой Дебагер по UART
 * Скомпилированным занимает CREG (68 байт) и одну ячейку в SRAM
 *
 *  Created: 04.07.2017 22:26:54
 *   Author: kich
 */

;************************************
;******** Настройки передачи ********
;************************************
.equ	Debug_TxPort	= PORTB
.equ	Debug_TxDDR		= DDRB
.equ	Debug_TxD		= 2

;*****  Настройки передачи  *****
.equ	Debug_FREQ		= 1000000 ;частота кварца, если тини10, то можно вычислить программно
.equ	Debug_BAUD		= 9600
.equ	Debug_stop_bit	= 1

;********************************************************
;****** Рассчет скорости передачи (без делителя) ********
;********************************************************
;****** Ниже рассшифровка формулы ********
;	A = Debug_FREQ / Debug_BAUD
;	B = 12	; без задержек + 4 * nop
;	C = 9	; rjmp + ret + 2 * nop
;	D = (A - B - 2 * C) / 2		; Цикл задержки
;	DELAY_VALUE = D / 3
.equ	Debug_package	= ( ( (Debug_FREQ / Debug_BAUD) - 12 - 2 * 9) / 2 ) / 3

; Байт скорости в RAM
.dseg
DELAY_VALUE: .byte 1
.cseg

; Используемые РОН
.def	debug_buffer	= r16	; Byte message
.def	debug_temp		= r17
.def	debug_counter	= r18

;***************************
;********** Сахар **********
;***************************
.macro m_debug
	push debug_buffer
	push debug_temp
	push debug_counter
	mov debug_buffer, @0
	rcall Debug
	pop debug_counter
	pop debug_temp
	pop debug_buffer
.endm

;************************************
;******* Инициализайия метода *******
;************************************
Debug_init:
	;Установка переферии записи (TX)
	in		debug_temp, Debug_TxDDR		; Загрузить данные из порта в регистр (определить РВВ -> РОН)
	ori		debug_temp, (1<<Debug_TxD)	; Назначение регистра управления, (в общую переменную через логическое OR)
	out		Debug_TxDDR, debug_temp		; Записать данные из регистра в порт I/O
	sbi		Debug_TxPort, Debug_TxD		; Установить бит в регистр I/O

	; Установки скорости обмена засчет чистого цикла
	ldi		debug_temp, Debug_package	; Записываем в регистр настройки передачи
	sts		DELAY_VALUE, debug_temp		; Запись цикла непосредственно в СОЗУ (SRAM или точнее в RAM)
ret


;************************************
;******* Инициализайия метода *******
;************************************
Debug:
	ldi		debug_counter, 9 + Debug_stop_bit
	com		debug_buffer	; инверсия буффера (для соответствия стандарту передачи)
	sec						; Установить флаг переноса в SREG (самое начало)

	DebugNextBit: 
		brcc	DebugStart				; Если флаг переноса очищен, то перейти и передать старт-бит
		cbi		Debug_TxPort, Debug_TxD	; Логический ноль на I/O, старт передачи
		rjmp	DebugCyclesBit			; Цикл передачи одного бита данных
	DebugStart:
		sbi		Debug_TxPort, Debug_TxD	; Установить бит в регистр I/O
		nop								; Логический ноль
	DebugCyclesBit:
		rcall 	DebugDelay				; цикл задержки
		rcall 	DebugDelay				; цикл задержки

		nop	nop nop nop
		lsr		debug_buffer			; Логически сдвинуть вправо
		dec		debug_counter			; Уменьшаем счетчик пакета UART
		brne	DebugNextBit			; Если еще не все, то отправляем следующий бит
		sbi		Debug_TxPort, Debug_TxD	; Иначе, установить I/O в логическую единицу
	ret

	DebugDelay:
		lds		debug_temp, DELAY_VALUE
	DebugDelaySub:
		dec		debug_temp
		brne	DebugDelaySub
		nop
	ret
ret
