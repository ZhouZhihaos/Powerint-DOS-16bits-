; birthday.asm
; 生日快乐 Powerint DOS 发布1周年
; Copyright (C) zhouzhihao 2020-2021
db	'POWERBINHEAD'
start:
	mov	ax,0b800h
	mov	es,ax
	mov	ax,cs
	mov	ds,ax
	
	mov	byte[es:0],'H'
	mov	byte[es:1],0ch
	call	waitsec
	mov	byte[es:2],'A'
	mov	byte[es:3],0ch
	call	waitsec
	mov	byte[es:4],'P'
	mov	byte[es:5],0ch
	call	waitsec
	mov	byte[es:6],'P'
	mov	byte[es:7],0ch
	call	waitsec
	mov	byte[es:8],'Y'
	mov	byte[es:9],0ch
	call	waitsec
	mov	byte[es:10],' '
	mov	byte[es:11],0ch
	call	waitsec
	mov	byte[es:12],'B'
	mov	byte[es:13],0ch
	call	waitsec
	mov	byte[es:14],'I'
	mov	byte[es:15],0ch
	call	waitsec
	mov	byte[es:16],'R'
	mov	byte[es:17],0ch
	call	waitsec
	mov	byte[es:18],'T'
	mov	byte[es:19],0ch
	call	waitsec
	mov	byte[es:20],'H'
	mov	byte[es:21],0ch
	call	waitsec
	mov	byte[es:22],'D'
	mov	byte[es:23],0ch
	call	waitsec
	mov	byte[es:24],'A'
	mov	byte[es:25],0ch
	call	waitsec
	mov	byte[es:26],'Y'
	mov	byte[es:27],0ch
	call	waitsec
	
	mov	ah,01h
	mov	si,put
	int	36h
	call	waitsec
	call	waitsec
	
	mov	ah,03h
	int	36h

waitsec:
; 等待
	mov	cx,20000
.loop:
	push	cx
	nop
	mov	cx,20000
.loop2:
	nop
	loop	.loop2
	pop	cx
	loop	.loop
	ret

put		db		0ah,0dh,'To Powerint DOS 1st anniversary. ',0ah,0dh,0ah,0dh,0
