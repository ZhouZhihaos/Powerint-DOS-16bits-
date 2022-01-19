; execbatch.asm
; Copyright (C) zhouzhihao 2021
programsegment	equ	4500h
; Powerint DOS可执行文件（.BIN）
; 开头12字节：POWERBINHEAD
; 需利用INT36H AH=03H返回系统
appsearch:
; 应用程序识别与执行
; 无寄存器
	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	si,0
	mov	di,0
.bin:	; 判断文件后缀是否为.BIN
	mov	al,[es:8]
	cmp	al,'B'
	jne	.next
	mov	al,[es:9]
	cmp	al,'I'
	jne	.next
	mov	al,[es:10]
	cmp	al,'N'
	jne	.next
	mov	al,[es:11]
	cmp	al,' '
	jne	.next
.loop:
	mov	cx,8
.cmp:
	mov	ah,[cmdline+di]
	and	ah,11011111b	; 将小写字母转化成大写
	mov	al,[es:si]
	cmp	al,' '
	je	.suffix
	cmp	al,ah
	jne	.next
	inc	si
	inc	di
	loop	.cmp
.suffix:	; 判断输入的后缀是否为.bin
	cmp	byte[cmdline+di],0	; 没有输后缀也可以
	je	.ok
	cmp	byte[cmdline+di],' '
	je	.ok
	cmp	byte[cmdline+di],'.'
	jne	.end
	inc	di
	mov	ah,[cmdline+di]
	and	ah,11011111b
	cmp	ah,'B'
	jne	.end
	inc	di
	mov	ah,[cmdline+di]
	and	ah,11011111b
	cmp	ah,'I'
	jne	.end
	inc	di
	mov	ah,[cmdline+di]
	and	ah,11011111b
	cmp	ah,'N'
	jne	.end
	jmp	.ok
.next:
	mov	ax,es
	add	ax,2h	; 指向下一个文件
	mov	es,ax
	mov	si,0
	mov	al,[es:si]
	cmp	al,0
	je	.end
	mov	di,0
	jmp	.bin
.ok:	; 计算文件段地址
	mov	ax,es
	add	ax,1h
	mov	es,ax
	mov	si,10
	mov	cx,[es:si]
	mov	ax,0
.mul:
	add	ax,20h	; 一个扇区
	loop	.mul
	add	ax,filetypeseg
	mov	es,ax
	mov	si,0
	mov	cx,12
.sawloop:
	mov	al,[es:si]
	mov	ah,[appfilehead+si]	; 应用程序格式：开头'POWERBINHEAD' 好处：隔离文件 坏处：淘汰旧版本
	cmp	ah,al
	jne	.notapp
	inc	si
	loop	.sawloop
	
	mov	ax,es	; 将程序复制到0x45000处再执行
	mov	ds,ax
	mov	si,0
	mov	ax,programsegment
	mov	es,ax
	mov	di,0
	mov	cx,0xffff
	call	memcpy
	
	push	ds
;	call	far	[si]	; CALL FAR 段间转移
	; 有了强制返回DOS系统的中断 就可以直接使用JMP FAR了
;	jmp	far	[si]
	jmp	dword programsegment:12	; 规定了程序地址 只需跳转到规定地址即可
								; 忽略开头12字节'POWERBINHEAD'
	pop	ds
.jmp:
	mov	ah,02h
	int	36h
	mov	si,lineput
	mov	ah,01h
	int	36h
	mov	si,0
	jmp usrinput
.notapp:
	mov	si,notappput
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	int	36h
	mov	si,lineput
	mov	ah,01h
	int	36h
	jmp	usrinput
.end:
	ret

; Powerint DOS批处理文件（.BAT）
; '#'符号后的文字为注释 只能注释一行
; 批处理文件中必须都为标准的DOS命令 或可执行文件
batsearch:
; 批处理文件识别与执行
; 无寄存器
	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	si,0
	mov	di,0
.bat:	; 判断文件后缀是否为.BAT
	mov	al,[es:8]
	cmp	al,'B'
	jne	.next
	mov	al,[es:9]
	cmp	al,'A'
	jne	.next
	mov	al,[es:10]
	cmp	al,'T'
	jne	.next
	mov	al,[es:11]
	cmp	al,' '
	jne	.next
.loop:
	mov	cx,8
.cmp:
	mov	ah,[cmdline+di]
	and	ah,11011111b	; 将小写字母转化成大写
	mov	al,[es:si]
	cmp	al,' '
	je	.suffix
	cmp	al,ah
	jne	.next
	inc	si
	inc	di
	loop	.cmp
.suffix:	; 判断输入的后缀是否为.bat
	cmp	byte[cmdline+di],0	; 没有输后缀也可以
	je	.ok
	cmp	byte[cmdline+di],' '
	je	.ok
	cmp	byte[cmdline+di],'.'
	jne	.end
	inc	di
	mov	ah,[cmdline+di]
	and	ah,11011111b
	cmp	ah,'B'
	jne	.end
	inc	di
	mov	ah,[cmdline+di]
	and	ah,11011111b
	cmp	ah,'A'
	jne	.end
	inc	di
	mov	ah,[cmdline+di]
	and	ah,11011111b
	cmp	ah,'T'
	jne	.end
	jmp	.ok
.next:
	mov	ax,es
	add	ax,2h	; 指向下一个文件
	mov	es,ax
	mov	si,0
	mov	al,[es:si]
	cmp	al,0
	je	.end
	mov	di,0
	jmp	.bat
.ok:	; 计算文件段地址
	mov	ax,es
	add	ax,1h
	mov	es,ax
	mov	si,10
	mov	cx,[es:si]
	mov	ax,0
.mul:
	add	ax,20h	; 一个扇区
	loop	.mul
	add	ax,filetypeseg
	mov	es,ax
	mov	si,0
	mov	di,0
.line:
	mov	ah,[es:si]	; 获取当前字符
	cmp	ah,0
	je	.ret
	cmp	ah,'#'	; 定义'#'字为注释
	je	.nextline
	cmp	ah,0dh		; 以换行为结束标志
	je	.lineok
	mov	[cmdline+di],ah
	inc	si
	inc	di
	jmp	.line
.nextline:
	mov	ah,[es:si]
	inc	si
	cmp	ah,0dh
	jne	.nextline
	inc	si
	jmp	.line
.lineok:
	add	si,2	; 0dh,0ah +2
	push	es	; appsearch调用更改ES 存起来
	push	si	; 调用需要更改SI 只好存起来
	call	appsearch
	call	command
	call	cleaninput
	pop	si		; 取出SI
	pop	es		; 取出ES
	mov	di,0
	jmp	.line
.ret:
	mov	ah,02h
	int	36h
	cmp	byte[debugflags],1
	je	.debugmode
	mov	si,lineput
	mov	ah,01h
	int	36h
	mov	si,0
	jmp usrinput
.debugmode:
	mov	si,debugmodeput
	mov	ah,01h
	int	36h
	mov	si,0
	jmp	usrinput
.end:
	ret