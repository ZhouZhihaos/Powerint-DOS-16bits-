; bitz.asm
; Copyright (C) zhouzhihao 2021
db	'POWERBINHEAD'
start:
	mov	ax,cs
	mov	ds,ax
	
	mov	ah,01h
	mov	si,welcomemsg
	int	36h
	mov	ah,02h
	int	36h
	
	mov	ah,01h
	mov	si,fileinput
	int	36h
	mov	si,0
.usrinput:
	mov	ah,0
	int	16h
	cmp	al,0dh
	je	.enter
	cmp	al,08h
	je	.backspace
	cmp	si,15
	je	.usrinput
	mov	ah,0eh
	int	10h
	mov	[findfilename1+si],al
	inc	si
	jmp	.usrinput
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
	jmp	.usrinput
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
	
	mov	ah,01h
	mov	si,findfilename1
	int	36h
	mov	ah,0eh
	mov	al,':'
	int	10h
	mov	ah,02h
	int	36h
	
	mov	ah,01h
	mov	si,line
	int	36h
	mov	ah,02h
	int	36h

	add	bx,1h
	mov	es,bx
	mov	cl,[es:12]
	mov	ch,[es:13]
	mov	ah,0eh
	mov	es,dx
	mov	si,0
	mov	di,0
putbinloop:
	push	cx
	mov	cx,10h
.loop1:		; 循环1：打印二进制数据
	mov	ah,0eh
	mov	al,[es:si]
	shr	al,4
	call	numtoASCII
	int	10h
	mov	al,[es:si]
	and	al,0fh
	call	numtoASCII
	int	10h
	mov	al,' '
	int	10h
	inc	si
	loop	.loop1
	mov	al,' '
	int	10h
	int	10h
	mov	cx,10h
.loop2:		; 循环2：打印ASCII码数据
	mov	ah,0eh
	mov	al,[es:di]
	cmp	al,0dh
	je	.putz
	cmp	al,0ah
	je	.putz
	cmp	al,08h
	je	.putz
	int	10h
	jmp	.lop
.putz:
	mov	al,' '
	int	10h
.lop:
	inc	di
	loop	.loop2
	mov	ah,02h
	int	36h
	pop	cx
	cmp	cx,10h
	jb	.subcx
	sub	cx,10h
	jcxz	.ok
	inc	byte[temp]
	cmp	byte[temp],24	; 如果打印的行数满24行
	je	.pause
	jmp	putbinloop
.next:
	mov	ah,02h
	int	36h
	mov	byte[temp],0
	popa
	jmp	putbinloop
.subcx:
	sub	cx,cx
.ok:
	mov	ah,03h
	int	36h
.pause:
	pusha
	mov	ah,01h
	mov	si,pauseput
	int	36h
	mov	al,0
.loop3:
	mov	ah,0
	int	16h
	cmp	al,0
	jne	.next
	jmp	.loop3

numtoASCII:
	cmp	al,9
	jg	.letter
	add	al,30h
	ret
.letter:
	add	al,37h
	ret

notfind:
	mov	ah,01h
	mov	si,notfindfile
	int	36h
	
	mov	ah,02h
	int	36h
	
	mov	ah,03h
	int	36h

fileinfosegment		db	0ah,60h
welcomemsg		db	'Powerint Bitz Version 1.00',0
fileinput		db	'Input File name:',0
findfilename1	times	15	db	0
findfilename2	db	'        ','   ',20h
notfindfile		db	'File not find.'
line			db	'0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F  | 0123456789ABCDEF',0
pauseput		db	'Press any key to continue...',0
temp			db	0