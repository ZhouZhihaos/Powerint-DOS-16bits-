; syscall.asm
; Copyright (C) zhouzhihao 2021
; IVT在内存中的位置
; 0x0000 ~ 0x0400
; 系统调用36号中断
; AH=00H  得到DOS版本号
; AH=01H  打印字符串
; AH=02H  换行
; AH=03H  强制返回DOS系统
; AH=04H  获取当前时间
; AH=05H  获取当前日期
; AH=06H  在目录中寻找文件
; AH=07H  寻找目录中的空位
; AH=08H  调用系统命令
; AH=09H  获取系统当前读取的驱动器
ivtsegment			equ		0
filetypesegment		equ		0be0h	; 800h+3e0h=be0h
CMOS_Sent_Port		equ		0x70
CMOS_Read_Port		equ		0x71
CMOS_WEEK_DAY		equ		0x6
initsyscall:
; 初始化系统调用
; 无寄存器
	call	reginthandler36
	ret

reginthandler36:	; 注册36号中断
; 寻找对应中断向量公式：
; 中断号*4
	mov	ax,ivtsegment
	mov	es,ax
	mov	word[es:36h*4],inthandler36	; 偏移地址
	mov	ax,cs
	mov	word[es:36h*4+2],ax	; 段地址
	ret

inthandler36:	; 36号中断程序
; 系统调用36号中断
	cmp	ah,00h
	je	.versioncall
	cmp	ah,01h
	je	.putstrcall
	cmp	ah,02h
	je	.newlinecall
	cmp	ah,03h
	je	.returncall
	cmp	ah,04h
	je	.timecall
	cmp	ah,05h
	je	.datecall
	cmp	ah,06h
	je	.findfilecall
	cmp	ah,07h
	je	.findfreefilecall
	cmp	ah,08h
	je	.commandcall
	cmp	ah,09h
	je	.drivecall
	jmp	.end
.versioncall:
; INT36H AH=00H
; 得到DOS版本号
; OUT:
; AX --> 版本号
	mov	ax,107Ch	; 1.07c
	jmp	.end
.putstrcall:
; INT36H AH=01H
; 打印字符串
; IN:
; DS:SI --> 字符串地址
	push	ax
	push	si
.putstrcall.loop:
	mov	al,[ds:si]
	cmp	al,0	; 如果[SI]=0
	je	.putstrcall.end	; 就结束
	mov	ah,0eh
	int	10h
	inc	si
	jmp	.putstrcall.loop
.putstrcall.end:
	pop	si
	pop	ax
	jmp	.end
.newlinecall:
; INT36H AH=02H
; 换行
	push	ax
	mov	ah,0eh
	mov	al,0dh
	int	10h
	mov	al,0ah
	int	10h
	pop	ax
	jmp	.end
.returncall:
; INT36H AH=03H
; 强制返回DOS系统
	jmp	short	.returncall.codestart
	dw	0,systemaddress / 10h
.returncall.codestart:
	mov	ax,systemaddress / 10h
	mov	ds,ax
	mov	si,.returncall+2
	mov	edx,20201220h
	jmp	far	[si]
.timecall:
; INT36H AH=04H
; 获取当前时间
; IN:
; DS:SI --> 输出信息地址
; OUT:
; DS:SI+0 --> 时
; DS:SI+1 --> 分
; DS:SI+2 --> 秒
	push	ax
	push	cx
	push	dx
	mov	ah,02h
	int	1ah
	mov	byte[ds:si],ch
	mov	byte[ds:si+1],cl
	mov	byte[ds:si+2],dh
	pop	dx
	pop	cx
	pop	ax
	jmp	.end
.datecall:
; INT36H AH=05H
; 获取当前日期
; IN:
; DS:SI --> 输出信息地址
; OUT:
; DS:SI+0 --> 世纪
; DS:SI+1 --> 年份
; DS:SI+2 --> 月份
; DS:SI+3 --> 天数
	push	ax
	push	cx
	push	dx
	mov	ah,04h
	int	1ah
	mov	byte[ds:si],ch
	mov	byte[ds:si+1],cl
	mov	byte[ds:si+2],dh
	mov	byte[ds:si+3],dl
	pop	dx
	pop	cx
	pop	ax
	jmp	.end
.findfilecall:
; INT36H AH=06H
; 在目录中寻找文件
; IN:
; DS:SI --> 文件名字符串地址
; ES --> 目录区段地址
; OUT:
; BX --> 文件信息段地址
; DX --> 文件内容段地址
	push	es
	push	ax
	push	cx
	push	di
	push	si	; 这个PUSH SI是有特别作用的
	mov	cx,12
	mov	di,0
	mov	bx,0
	mov	dx,0
.findfilecall.loop:
	mov	al,[ds:si]
	mov	ah,[es:di]
	cmp	ah,al
	jne	.findfilecall.nextfile
	inc	si
	inc	di
	loop	.findfilecall.loop
	mov	bx,es	; 找到文件 将段地址放入BX
	mov	ax,es
	add	ax,1h
	mov	es,ax
	mov	cx,[es:10]	; 获取簇信息
	mov	ax,0
.findfilecall.mul:
	add	ax,20h
	loop	.findfilecall.mul
	add	ax,filetypesegment
	mov	dx,ax	; 计算完文件段地址 将其放入DX
.findfilecall.end:
	pop	si	; 这里如果没有POP SI程序会起飞
	pop	di
	pop	cx
	pop	ax
	pop	es
	jmp	.end
.findfilecall.nextfile:
	mov	ax,es
	add	ax,2h
	mov	es,ax
	mov	di,0
	pop	si	; 方便取出SI的原始值
	push	si	; 重新再存入
	mov	cx,12
	cmp	byte[es:di],0
	je	.findfilecall.end
	jmp	.findfilecall.loop
.findfreefilecall:
; INT36H AH=07H
; 寻找目录中的空位
; IN:
; ES --> 目录区段地址
; OUT:
; BX --> 目录中的空位段地址
	push	ax
	push	es
.findfreefilecall.loop:
	mov	al,[es:0]
	cmp	al,0
	je	.findfreefilecall.ok
	cmp	al,0xe5		; 文件被删除
	je	.findfreefilecall.ok
	mov	ax,es
	add	ax,2h
	mov	es,ax
	jmp	.findfreefilecall.loop
.findfreefilecall.ok:
	mov	bx,es
	pop	es
	pop	ax
	jmp	.end
.commandcall:
; INT36H AH=08H
; 调用系统命令
; IN:
; DS:SI --> 命令字符串
	pusha
	push	ds
	push	es
	mov	ax,systemaddress / 10h
	mov	es,ax
	mov	di,0
.commandcall.loop:
	mov	al,[ds:si]
	cmp	al,0
	je	.commandcall.ok
	mov	[es:cmdline+di],al
	inc	di
	inc	si
	jmp	.commandcall.loop
.commandcall.ok:
	mov	ax,systemaddress / 10h
	mov	ds,ax
	call	command
	pop	es
	pop	ds
	popa
	jmp	.end
.drivecall:
; INT36H AH=09H
; 获取系统当前读取的驱动器
; OUT:
; AL --> 驱动器号
	push	ds
	push	dx
	mov	dx,systemaddress / 10h
	mov	ds,dx
	mov	al,[drivetemp+1]
	pop	dx
	pop	ds
	jmp	.end
.end:
	iret	; pop cs pop ip popf

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