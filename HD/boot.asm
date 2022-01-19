; boot.asm
; Copyright (C) zhouzhihao 2021-2022
; Hard Disk Drive
numsector	equ		18	; 最大扇区
numheader	equ		1	; 最大磁头
numcylind	equ		10	; 最大柱面
bootseg		equ		7c0h
dataseg		equ		800h	; 软盘10扇区读入的地址
bootinfoseg	equ		7e0h	; 启动信息

jmp	short	start
; FAT16文件系统定义
	db	0x90
	db	"POWERINT"
	dw	512
	db	1
	dw	1
	db	2
	dw	224
	dw	2880
	db	0xf0
	dw	9
	dw	18
	dw	2
	dd	0
	dd	2880
	db	0,0,0x29
	dd	0xffffffff
	db	"POWERINTDOS"
	db	"FAT16   "

start:
; main
	mov	ax,bootseg
	mov	ds,ax
	mov	ax,dataseg
	mov	es,ax

	mov	si,startput
	call	putstr

	call	harddiskload	; 读硬盘
	call	findloader	; 巡查文件
	
	mov	ax,bootinfoseg
	mov	es,ax
	mov	byte[es:0],'C'	; C盘启动
	mov	byte[es:1],0x80	; 驱动器号0x80

	call	newline
	call	newline

	jmp	far	[loaderseg]
	; 将控制权交给jmpseg处（LOADER.BIN）

harddiskload:
; 读硬盘
; 无寄存器
	call	read1sector
	mov	ax,es
	add	ax,20h
	mov	es,ax
	; 读扇区
	inc	byte[sector];+11]
	cmp	byte[sector],numsector+1;+11],numsector+1
	jne	harddiskload
	mov	byte[sector],1;+11],1
	; 读磁头
	inc	byte[header];+11]
	cmp	byte[header],numheader+1;+11],numheader+1
	jne	harddiskload
	mov	byte[header],0;+11],0
	; 读柱面
	inc byte[cylind];+11]
	cmp	byte[cylind],numcylind;+11],numcylind
	jne	harddiskload
	
	ret

;numtoascii:
; 将2位数的10进制数分解成ASCII码
; 寄存器：in:CL out:AL/AH
;	mov	ax,0
;	mov	al,cl
;	mov	bl,10
;	div	bl
;	add	ax,3030h
;	ret

;readinfo:
; 输出所读出的信息
; 无寄存器
;	mov	si,cylind
;	call	putstr
;	mov	si,header
;	call	putstr
;	mov	si,sector
;	call	putstr
;	ret

read1sector:
; 读取1个扇区的通用程序
; 寄存器：in:ES
	; 扇区
;	mov	cl,[sector+11]
;	call	numtoascii
;	mov	[sector+7],al
;	mov	[sector+8],ah
	
	; 磁头
;	mov	cl,[header+11]
;	call	numtoascii
;	mov	[header+7],al
;	mov	[header+8],ah
	
	; 柱面
;	mov	cl,[cylind+11]
;	call	numtoascii
;	mov	[cylind+7],al
;	mov	[cylind+8],ah
	
	mov	ch,[cylind]
	mov	dh,[header]
	mov	cl,[sector]
	
;	call	readinfo
	mov	di,0
.retry:
	mov	ah,02h
	mov	al,1
	mov	bx,0
	mov	dl,80h
	int	13h
	jnc	.readok
	inc	di
	mov	ah,00h
	mov	dl,80h
	int	13h
	cmp	di,5
	jne	.retry
	
;	mov	si,floppyerror
;	call	putstr
;	call	newline
;	jmp		.exitread
.readok:
;	mov	si,floppyok
;	call	putstr
;	call	newline
;.exitread:
	ret

findloader:
; 巡查是否有LOADER.BIN
; 无寄存器
	mov	ax,0a60h
	mov	es,ax
	mov	si,0
	mov	cx,11
.cmp:
	mov	al,[es:si]
	mov	ah,[loaderbin+si]
	cmp	al,ah
	jne	.nextfile
	inc	si
	loop	.cmp
	mov	ax,es
	add	ax,1h
	mov	es,ax
	mov	cx,[es:10]
	sub	ax,ax
.mul:
	add	ax,20h
	loop	.mul
	add	ax,0be0h
	mov	[loaderseg+2],al
	mov	[loaderseg+3],ah
	ret
.nextfile:
	mov	ax,es
	add	ax,2h
	mov	es,ax
	sub	si,si
	mov	al,[es:si]
	cmp	al,0
	je	.end
	mov	cx,11
	jmp	.cmp
.end:
	call	newline
	mov	si,errormsg
	call	putstr
	jmp	$	; 如果没有就死循环

putstr:
; 打印字符串
; 寄存器：in:SI
	mov	al,[si]
	cmp	al,'$'	; 如果[SI]='$'
	je	.end	; 就结束
	mov	ah,0eh
	int	10h
	inc	si
	jmp	putstr
.end:
	ret

newline:
; 换行
; 无寄存器
	mov	ah,0eh
	mov	al,0dh
	int	10h
	mov	al,0ah
	int	10h
	ret

; 字符串定义（char）
startput	db	'Starting Powerint DOS...','$'
loaderbin	db	'LOADER  BIN'
cylind		db	0;'Cylind:   $',0
header		db	0;'Header:   $',0
sector		db	1;'Sector:   $',1
;floppyerror	db	'Read Error.','$'
;floppyok	db	'Read OK.','$'
errormsg	db	'Boot Error: No LOADER.BIN in Drive C.','$'
loaderseg	db	0,0,0,0

times	510-($-$$)	db	0
db	0x55,0xaa

; boot.asm 结束