; gobang.asm
; Copyright (C) zhouzhihao 2022
; 五子棋游戏
db	'POWERBINHEAD'
%macro	setcur	3
; 设定光标位置
	mov	ah,02h
	mov	bh,%1	; 页
	mov	dh,%2	; 行
	mov	dl,%3	; 列
	int	10h
%endmacro
vramsegment		equ	0a000h
start:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	
	mov	ah,0
	mov	al,13h
	int	10h
	
	mov	bl,0fh
	mov	si,gobangboard
	mov	ah,01h
	int	36h

red:
	setcur	0,17,0
	mov	ah,02h
	int	36h
	mov	bl,0fh
	mov	si,askputred
	mov	ah,01h
	int	36h
.inputx:
	; 输入x
	mov	ah,0
	int	16h
	mov	ah,0eh
	mov	bl,0fh
	int	10h
	call	ascii2num
	mov	[redin],al
	mov	al,20h
	int	10h
.inputy:
	; 输入y
	mov	ah,0
	int	16h
	mov	ah,0eh
	int	10h
	call	ascii2num
	mov	[redin+1],al
.count:
	; 计算坐标对应点：(y+1)*18+x
	mov	al,[redin+1]
	inc	al
	mov	bl,18
	mul	bl
	add	al,byte[redin]
	mov	bx,ax
	cmp	byte[gobangboard+bx],'.'
	jne	.again
	mov	byte[gobangboard+bx],'R'
	setcur	0,19,0	; 覆盖Sorry...
	mov	si,noneput
	mov	bl,0fh
	mov	ah,01h
	int	36h
	setcur	0,byte[redin+1],byte[redin]
	mov	ah,0eh
	mov	bl,0ch
	mov	al,'O'
	int	10h
	jmp	white
.again:
	call	again
	jmp	red
white:
	setcur	0,17,0
	mov	ah,02h
	int	36h
	mov	bl,0fh
	mov	si,askputwhite
	mov	ah,01h
	int	36h
.inputx:
	; 输入x
	mov	ah,0
	int	16h
	mov	ah,0eh
	mov	bl,0fh
	int	10h
	call	ascii2num
	mov	[whitein],al
	mov	al,20h
	int	10h
.inputy:
	; 输入y
	mov	ah,0
	int	16h
	mov	ah,0eh
	int	10h
	call	ascii2num
	mov	[whitein+1],al
.count:
	; 计算坐标对应点：y*18+x
	mov	al,[whitein+1]
	mov	bl,18
	mul	bl
	add	al,byte[whitein]
	mov	bx,ax
	cmp	byte[gobangboard+bx],'.'
	jne	.again
	mov	byte[gobangboard+bx],'W'
	setcur	0,19,0	; 覆盖Sorry...
	mov	si,noneput
	mov	bl,0fh
	mov	ah,01h
	int	36h
	setcur	0,byte[whitein+1],byte[whitein]
	mov	ah,0eh
	mov	bl,0fh
	mov	al,'O'
	int	10h
	jmp	red
.again:
	call	again
	jmp	white

again:
	setcur	0,19,0
	mov	ah,01h
	mov	bl,0fh
	mov	si,cantinput
	int	36h
	ret

ascii2num:
; 将ASCII码化成十六进制数
	cmp	al,'9'
	ja	.letter
	sub	al,30h
	ret
.letter:
	sub	al,37h
	ret
	
gobangboard:
	db	' 123456789ABCDEF',0ah,0dh
	db	'1...............',0ah,0dh
	db	'2...............',0ah,0dh
	db	'3...............',0ah,0dh
	db	'4...............',0ah,0dh
	db	'5...............',0ah,0dh
	db	'6...............',0ah,0dh
	db	'7...............',0ah,0dh
	db	'8...............',0ah,0dh
	db	'9...............',0ah,0dh
	db	'A...............',0ah,0dh
	db	'B...............',0ah,0dh
	db	'C...............',0ah,0dh
	db	'D...............',0ah,0dh
	db	'E...............',0ah,0dh
	db	'F...............',0
askputwhite		db	'(White)Please input coordinate:',0
askputred		db	'(Red)Please input coordinate:  ',0
cantinput		db	'Sorry,you cant input here!',0
noneput			db	'                          ',0
redwin			db	'RED WIN!',0
whitewin		db	'WHITE WIN!',0
redin			db	2
whitein			db	2