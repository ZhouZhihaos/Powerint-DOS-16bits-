; mouse.asm
; Copyright (C) zhouzhihao 2022
; 测试鼠标程序
db	'POWERBINHEAD'
; PIC相关设定
PIC0_ICW1	equ	0x20
PIC0_ICW2	equ	0x21
PIC0_ICW3	equ	0x21
PIC0_ICW4	equ	0x21
PIC1_ICW1	equ	0xa0
PIC1_ICW2	equ	0xa1
PIC1_ICW3	equ	0xa1
PIC1_ICW4	equ	0xa1
PIC0_OCW1	equ	0x21
PIC0_OCW2	equ	0x20
PIC1_OCW1	equ	0xa1
PIC1_OCW2	equ	0xa0
; 主PIC（PIC0）：
; IRQ0   -->   计时器
; IRQ1   -->   键盘
; IRQ2   -->   连接从PIC（PIC1）
; IRQ3   -->   串口设备
; IRQ4   -->   串口设备
; IRQ5   -->   声卡
; IRQ6   -->   软驱
; IRQ7   -->   打印机

; 从PIC（PIC1）：
; IRQ8   -->   时钟
; IRQ9   -->   连接主PIC（PIC0）
; IRQ10  -->   网卡
; IRQ11  -->   显卡
; IRQ12  -->   鼠标
; IRQ13  -->   协处理器
; IRQ14  -->   主硬盘
; IRQ15  -->   从硬盘

; 键盘电路相关设置
KEYBOARD_DATA_PORT		equ	0x60
KEYBOARD_STATE_PORT		equ	0x64
KEYBOARD_CMD_PORT		equ	0x64
MOUSE_ENCODE			equ	0xd4
MOUSE_ENABLED_ENCODE	equ	0xfa
start:
	mov	ax,cs
	mov	ds,ax

	; 初始化PIC
	call	initPIC
	; 激活键盘电路
	call	enabled_keyboardCMD
	; 激活鼠标电路
	call	enabled_mouseCMD
	
getmousedata:
	in	al,KEYBOARD_DATA_PORT
	push	ax
	shr	al,4
	call	numtoASCII
	mov	ah,0eh
	int	10h
	pop	ax
	and	al,0fh
	call	numtoASCII
	mov	ah,0eh
	int	10h
	mov	al,' '
	mov	ah,0eh
	int	10h
	jmp	getmousedata
	
	mov	ah,03h
	int	36h

initPIC:
; 初始化PIC
; 无寄存器
	in	al,PIC0_OCW1
	and	al,11111011b	; 开启IRQ2（连接从PIC），其他不变
	out	PIC0_OCW1,al
	in	al,PIC1_OCW1
	and	al,11101101b	; 开启IRQ9（连接主PIC）和IRQ12（鼠标），其他不变
	out	PIC1_OCW1,al
	
	ret

enabled_keyboardCMD:
; 激活键盘电路
	call	waitkeyboardready
	mov	al,0x60
	out	KEYBOARD_CMD_PORT,al
	call	waitkeyboardready
	mov	al,0x47
	out	KEYBOARD_DATA_PORT,al	; 鼠标电路
	ret

waitkeyboardready:
; 等待键盘电路准备完毕
	in	al,KEYBOARD_STATE_PORT
	and	al,0x02	; 如果键盘电路没准备好 会送0x02过来
	jz	.ret
	jmp	waitkeyboardready
.ret:
	ret

enabled_mouseCMD:
; 激活鼠标电路
	call	waitkeyboardready
	mov	al,MOUSE_ENCODE
	out	KEYBOARD_CMD_PORT,al
	call	waitkeyboardready
	mov	al,MOUSE_ENABLED_ENCODE
	out	KEYBOARD_DATA_PORT,al
	ret

numtoASCII:
; 将16进制数转化成ASCII码
; 寄存器：in:AL out:AL
	cmp	al,9
	jg	.letter
	add	al,30h
	ret
.letter:
	add	al,37h
	ret

cant:
	mov	si,cantenabled
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	
	mov	ah,03h
	int	36h

cantenabled		db	'Your PC can not enabled mouse.',0