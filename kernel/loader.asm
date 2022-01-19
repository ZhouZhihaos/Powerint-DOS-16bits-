; loader.asm
; Copyright (C) zhouzhihao 2021-2022
jmp	near	start
commandbin		db	'COMMAND BIN'
errormsg		db	'Load Error: No COMMAND.BIN in Drive.',0
commandsegment	equ	0x3500

start:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
	
	mov	si,commandbin
	call	findfile
	cmp	ah,0	; 返回值=0 没找到文件
	jne	next
	
	call	newline
	mov	si,errormsg
	call	putstr
	jmp	$
next:
	jmp	jmpfile

findfile:
; 巡查是否有指定的文件
; 寄存器：in:SI out:ES/AH
; AH=1找到 AH=0未找到
	mov	ax,0a60h
	mov	es,ax
	sub	di,di
	mov	cx,11
.loop:
	mov	ah,[si]
	mov	al,[es:di]
	cmp	ah,al
	jne	.next
	inc	si
	inc	di
	loop	.loop
	mov	ah,1	; 找到！
	ret
.next:
	mov	ax,es
	add	ax,2h
	mov	es,ax
	sub	di,di
	mov	al,[es:di]
	cmp	al,0
	je	.end
	mov	cx,11
	jmp	.loop
.end:
	mov	ah,0	; 未找到！
	ret

jmpfile:
; 跳转到指定的文件地址
; 寄存器：in:ES
	mov	ax,es
	add	ax,1h
	mov	es,ax
	mov	cx,[es:10]
	mov	ax,0
.mul:
	add	ax,20h
	loop	.mul
	add	ax,0be0h
	
	mov	ds,ax
	mov	si,0
	mov	ax,commandsegment
	mov	es,ax
	mov	di,0
	mov	cx,0xffff
	call	memcpy
	jmp	dword commandsegment:0

putstr:
; 打印字符串
; 寄存器：in:SI
	mov	al,[si]
	cmp	al,0
	je	.end
	mov	ah,0eh
	int	10h
	inc	si
	jmp	putstr
.end:
	ret

newline:
; 换行
; 无寄存器
	mov	al,0dh
	mov	ah,0eh
	int	10h
	mov	al,0ah
	int	10h
	ret

memcpy:
; 拷贝内存到某处
; 寄存器：in:DS:SI/ES:DI/CX
	mov	al,[ds:si]
	mov	[es:di],al
	inc	si
	inc	di
	loop	memcpy
.cpyend:
	ret