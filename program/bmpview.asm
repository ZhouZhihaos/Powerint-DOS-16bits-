; bmpview.asm
; Copyright (C) zhouzhihao 2021
db	'POWERBINHEAD'
photostart			equ	76h		; BMP图片开始地址
vramaddress			equ	0xa0000
; 颜色端口设定
PalettePort	equ	0x3c8
ColorPort	equ	0x3c9
colorpatseg	equ	36h
start:
	mov	ax,cs
	mov	ds,ax
	
	mov	ah,01h
	mov	si,openfileput
	int	36h
	
	mov	si,0
	jmp	usrinput
	
usrinput:	; 用户输入文件名
	mov	ah,0
	int	16h
	cmp	al,0dh
	je	.enter
	cmp	al,08h
	je	.backspace
	cmp	si,15
	je	usrinput
	mov	ah,0eh
	int	10h
	mov	[findfilename1+si],al
	inc	si
	jmp	usrinput
.backspace:
	dec	si
	mov	ah,0eh
	mov	al,08h
	int	10h
	mov	al,20h
	int	10h
	mov	al,08h
	int	10h
	mov	byte[findfilename1+si],0
	jmp	usrinput
.enter:
	mov	cx,8
	mov	si,0
.loop1:
	mov	al,[findfilename1+si]
	cmp	al,'.'
	je	.loop1ok
	and	al,11011111b
	mov	[findfilename2+si],al
	inc	si
	loop	.loop1
.loop1ok:
	inc	si	; 跳过'.'
	mov	cx,3
	mov	di,0
.loop2:
	mov	al,[findfilename1+si]
	and	al,11011111b
	mov	[findfilename2+8+di],al
	inc	si
	inc	di
	loop	.loop2
	
	mov	si,findfilename2
	mov	ah,[fileinfosegment]
	mov	al,[fileinfosegment+1]
	mov	es,ax
	mov	ah,06h	; 查找文件
	int	36h
	
	mov	ah,02h
	int	36h
	
	cmp	dx,0
	je	notfind
	
	mov	es,dx
	mov	cx,2
	mov	si,0
.format:	; 检查格式 开头2字节'BM'
	mov	al,[es:si]
	mov	ah,[bmpphotohead+si]
	cmp	ah,al
	jne	formaterror
	inc	si
	loop	.format
	
	mov	ah,0
	mov	al,13h	; 320*200*256
	int	10h
	
	mov	al,[es:0x12]	; 长
	mov	ah,[es:0x13]
	mov	word[photoxsize],ax
	mov	al,[es:0x16]	; 宽
	mov	ah,[es:0x17]
	mov	word[photoysize],ax
	mov	al,[es:2]
	mov	ah,[es:3]
	mov	[photolength],ax	; 长度
	mov	al,[es:0xa]
	mov	ah,[es:0xb]
	cmp	ax,76h	; 16色位图开始位置
	je	.c16
	cmp	ax,436h	; 256色位图开始位置
	je	.c256
	mov	ah,0
	mov	al,03h
	int	10h
	jmp	formaterror
.c16:
	mov	byte[phototype],0
	jmp	.cok
.c256:
	mov	byte[phototype],1
.cok:
	call	setcolor	; 设定颜色
	
	jmp	writecoloronscreen
	
writecoloronscreen:
	cmp	byte[phototype],0
	je	c16
	cmp	byte[phototype],1
	je	c256
	jmp	$

c16:
; 16色位图显示
	mov	di,[photolength]
	mov	cx,[photoysize]	; 大循环次数：photoysize
	mov	ax,vramaddress / 0x10
	mov	ds,ax
	mov	si,0
.bigloop:
	push	cx
	push	ds
	mov	ax,cs
	mov	ds,ax
	mov	ax,[photoxsize]	; 访问[photoxsize],需ds=cs
	pop	ds
	mov	bl,2
	div	bl
	cmp	ah,0	; 有余数
	jne	.inc
	jmp	.incok
.inc:
	mov	byte[photolastpixeldobb],1
	inc	al
	mov	ah,0
.incok:
	mov	cx,ax	; 小循环次数：photoxsize / 2
	sub	di,ax
.loop:
	cmp	byte[photolastpixeldobb],1
	jne	.do
	mov	al,[es:di]
	and	al,0fh
	mov	[si],al
	inc	si
	inc	di
	mov	byte[photolastpixeldobb],0
	loop	.loop
.do:
	mov	al,[es:di]
	shr	al,4
	mov	[si],al
	inc	si
	mov	al,[es:di]
	and	al,0fh
	mov	[si],al
	inc	si
	inc	di
	loop	.loop
	pop	cx
	push	ds
	mov	ax,cs
	mov	ds,ax
	mov	ax,[photoxsize]
	mov	bl,2
	div	bl
	cmp	ah,0	; 有余数
	jne	.inc2
	jmp	.incok2
.inc2:
	inc	al
	mov	ah,0
.incok2:
	sub	di,ax
	sub	si,[photoxsize]
	pop	ds
	add	si,320
	loop	.bigloop
	jmp	exitloop

c256:
; 256色位图显示
	mov	di,[photolength]
	mov	cx,[photoysize]	; 大循环次数：photoysize
	mov	ax,vramaddress / 0x10
	mov	ds,ax
	mov	si,0
.bigloop:
	push	cx
	push	ds
	mov	ax,cs
	mov	ds,ax
	mov	ax,[photoxsize]	; 访问[photoxsize],需ds=cs
	pop	ds
	mov	cx,ax	; 小循环次数：photoxsize / 2
	sub	di,ax
.loop:
	mov	al,[es:di]
	mov	[si],al
	inc	di
	inc	si
	loop	.loop
	pop	cx
	push	ds
	mov	ax,cs
	mov	ds,ax
	mov	ax,[photoxsize]
	sub	di,ax
	sub	si,[photoxsize]
	pop	ds
	add	si,320
	loop	.bigloop

exitloop:	; 等待用户输入ESC退出bmpview
	mov	ah,0
	int	16h
	cmp	al,1bh
	jne	exitloop
	mov	ah,0
	mov	al,03h
	int	10h
	mov	ah,02h
	int	36h
	mov	ah,03h
	int	36h

setcolor:
; 初始化调色板
; 无寄存器
	cmp	byte[phototype],0
	je	.cx16
	cmp	byte[phototype],1
	je	.cx256
	jmp	$
.cx16:
	mov	cx,16
	jmp	.cxok
.cx256:
	mov	cx,256
.cxok:
	mov	al,0
	mov	dx,PalettePort
	out	dx,al
	mov	si,colorpatseg
	call	.OutOfPort
	ret
.OutOfPort:
	mov	dx,ColorPort
	mov	bl,4
	mov	ah,0
	mov	al,[es:si+2]
	div	bl
	out	dx,al
	mov	ah,0
	mov	al,[es:si+1]
	div	bl
	out	dx,al
	mov	ah,0
	mov	al,[es:si]
	div	bl
	out	dx,al
	add	si,4
	loop	.OutOfPort
	ret

notfind:
; 没找到文件
	mov	ah,01h
	mov	si,filenotfind
	int	36h
	mov	si,findfilename1
	int	36h
	mov	ah,02h
	int	36h
	int	36h
	mov	ah,03h
	int	36h

formaterror:
; BMP文件格式错误
	mov	ah,01h
	mov	si,isnotbmpphoto
	int	36h
	mov	ah,02h
	int	36h
	int	36h
	mov	ah,03h
	int	36h

openfileput			db	'Open a BMP photo file:',0
findfilename1		times	15	db	0
findfilename2		db	'        ','   ',20h
fileinfosegment		db	0ah,60h
filenotfind			db	'Can',27h,'t find file ',0
bmpphotohead		db	'BM'
isnotbmpphoto		db	'Isn',27h,'t BMP photo,format error.',0
phototype			db	0	; 0=16色位图 1=256色位图
photoxsize			dw	0
photoysize			dw	0
photolength			dw	0	; 最大支持64K Bmp图片
photolastpixeldobb	db	0	; 最后一个像素的奇偶性
