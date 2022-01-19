; command.asm
; Copyright (C) zhouzhihao 2020-2022
jmp	near	start
; 内存分配表：
; 0x0000 ~ 0x0400      IVT            1KB
; 0x0400 ~ 0x0500      BIOS           256B
; 0x0500 ~ 0x7C00      Stack          29KB
; 0x7C00 ~ 0x7E00      Boot Sector    512B
; 0x7E00 ~ 0x8000      Boot Info      512B
; 0x8000 ~ 0x35000     Disk           180KB
; 0x35000 ~ 0x45000    System         64KB
; 0x45000 ~ 0x55000    Program        64KB
; 0x55000 ~ 0x65000    Copy Buffer    64KB
; 0x65000 ~ 0xA0000    Free           236KB
; 0xA0000 ~ 0x100000   BIOS           384KB
systemaddress	equ		0x35000
bootinfosegment	equ		7e0h
fileinfoseg		db		0ah,60h
; 字节	长度	描述
; 0,0	8		文件名
; 0,8	3		后缀名
; 0,11	1		文件属性
; 0,12	10		保留位
; 1,6	2		时间
; 1,8	2		日期
; 1,10	1		簇号
; 1,12	4		文件大小
filetypeseg		equ		0be0h	; 800h+3e0h=be0h
copybufferseg	equ		5500h
stackseg		equ		0
stacktop		equ		7c00h	; 堆栈范围0x1000 ~ 0x7C00
dataseg			equ		800h	; 10个柱面被读入的段地址
datatop			equ		3500h	; 10个柱面数据顶部段地址
region			db		0	; 起初第0区域：0~10柱面
sector			db		1
header			db		0
cyline			db		0
numsector		equ		18
numheader		equ		1
numcyline		equ		10
; 内存原因（1MB以内）每次只读写10个柱面
; 因此盘划分成n个区域 每个区域180KB

; 缓冲区 杂项
oldcmdline		times	128	db	0
cmdline			times	128	db	0
findfilename	db	'           ',0
timetemp		db	0,0,0
datetemp		db	0,0,0,0
colortemp		db	0
drivetemp		dw	0
addresssegtemp	dw	0
addressofftemp	dw	0
regeditnum		db	0
autoexecbat		db	'AUTOEXEC.BAT'
notautoexec		db	'Boot Waring: No AUTOEXEC.BAT in Drive A.',0
appfilehead		db	'POWERBINHEAD'
notappput		db	'Is Not Powerint DOS Execute File.',0
debugmodeput	db	'Debug:\>',0
lineput			db	'?:\>',0
badcom			db	'Bad Command.',0
clscom			db	'cls'
timecom			db	'time'
timemsg			db	'Nows time:  :  :  ',0dh,0ah,0
datecom			db	'date'
datemsg			db	'Nows date:    \  \  ',0dh,0ah,0
shutdowncom		db	'shutdown'
vercom			db	'ver'
verput			db	'Powerint DOS 1.07c',0
dircom			db	'dir'
dirput			db	'Directory of Drive ?:\ ',0
isdir			db	'<DIR>',0
echocom			db	'echo'
typecom			db	'type'
notfind			db	'File not find.',0
delcom			db	'del'
writeerror		db	'Write floppy error.',0
readerror		db	'Read floppy error.',0
mkfilecom		db	'mkfile'
editcom			db	'edit'
cdcom			db	'cd'
cdput			db	'Invalid directory.',0
colorcom		db	'color'
colorput:
	db	'0 = Black     8 = Gray',0dh,0ah
	db	'1 = Blue      9 = Light Blue',0dh,0ah
	db	'2 = Green     A = Light Green',0dh,0ah
	db	'3 = Aqua      B = Light Aqua',0dh,0ah
	db	'4 = Red       C = Light Red',0dh,0ah
	db	'5 = Purple    D = Light Purple',0dh,0ah
	db	'6 = Yellow    E = Light Yellow',0dh,0ah
	db	'7 = White     F = Light White',0
mkdircom		db	'mkdir'
mkdirwrite:
	db	'.          ',10h
	db	'..         ',10h
renamecom		db	'rename'
drivecom		db	'drive'
drivenotready	db	'Drive ? is not ready.',0
notthisdrive	db	'Not this drive.',0
pausecom		db	'pause'
pauseput		db	'Press any key to continue...',0
copycom			db	'copy'
copyfilelength	dw	0
pastecom		db	'paste'
cutcom			db	'cut'
; 调试命令 需要输入debug后才可使用
debugcom		db	'debug'
debugflags		db	0
exitcom			db	'exit'
pokecom			db	'poke'
pokeerror		db	'Poke usage Error.',0
visitcom		db	'visit'
visiterror		db	'Visit usage Error.',0
findcom			db	'find'
finderror		db	'Find usage Error.',0
findput			db	'Find data in address:&',0
findpauseput	db	'Press Enter to continue or ESC to exit...',0

start:
	mov	ax,cs
	mov	ds,ax
	mov	es,ax

	; 堆栈的初始化
	mov	ax,stackseg
	mov	ss,ax
	mov	sp,stacktop
	
	call	initsyscall		; 初始化系统调用中断

	; 读取Boot Info（0x7E00~0x8000）
	mov	ax,bootinfosegment
	mov	es,ax
	mov	al,[es:0]	; 驱动器字符
	mov	[drivetemp],al
	mov	al,[es:1]	; 驱动器号
	mov	[drivetemp+1],al
	
	cmp	edx,20201220h
	je	.noautoexec
	call	autoexec	; 加载AUTOEXEC.BAT 开机启动项
.noautoexec:
	mov	al,[drivetemp]
	mov	[lineput],al
	mov	si,lineput
	mov	ah,01h
	int	36h
	mov	si,0
	jmp	usrinput
	
autoexec:
	sub	si,si
	mov	cx,12
.loop:
	mov	al,[autoexecbat+si]
	mov	byte[cmdline+si],al
	inc	si
	loop	.loop
	call	batsearch	
	mov	si,notautoexec
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	int	36h
	ret
usrinput:
; 将键盘输入字符打印出来
; 无寄存器
	call	oldcleancopy
	call	cleaninput
.ready:
	mov	ah,0
	int	16h
	cmp	si,128
	jae	.long
	cmp	si,0
	jne	.in
	cmp	al,08h
	jne	.in
	jmp	.ready
.long:
; 进入这个分段SI已经超过了128
; 所以分段只提供打印 而不提供记录
	mov	ah,0eh
	int	10h
	cmp	al,0dh
	je	.enter
	cmp	al,08h
	je	.backspace
	jmp	.ready
.in:
	cmp	ah,48h	; 上键退回上一行
	je	.oldcmdput
	mov	ah,0eh
	int	10h
	; 如果是回车
	cmp	al,0dh
	je	.enter
	; 如果是退格
	cmp	al,08h
	je	.backspace
	; 保存字符到cmdline中
	; （最多32字节）
	mov	[cmdline+si],al
	inc	si
	jmp	.ready
.oldcmdput:
	push	di
	push	si
	mov	si,oldcmdline
	mov	ah,01h
	int	36h
	pop	si
	mov	di,0
.cpyloop:
	mov	al,[oldcmdline+di]
	cmp	al,0
	je	.ready
	mov	[cmdline+si],al
	inc	si
	inc	di
	jmp	.cpyloop
.backspace:
	; 对退格键的特殊处理
	dec	si
	mov	ah,0eh
	; 空格
	mov	al,20h
	int	10h
	; 退格
	mov	al,08h
	int	10h
	mov	byte[cmdline+si],0
	jmp	.ready
.enter:
	; 对回车键的特殊处理
	mov	ah,02h
	int	36h
	cmp	byte[cmdline],0	; 有输入
	jne	.haveinput
	mov	al,[drivetemp]	; 没输入
	mov	[lineput],al
	mov	si,lineput
	mov	ah,01h
	int	36h
	mov	si,0
	jmp	.ready
.haveinput:
	call	appsearch
	call	batsearch
	call	command
	mov	ah,02h
	int	36h
	cmp	byte[debugflags],1
	je	.debugmode
	mov	al,[drivetemp]
	mov	[lineput],al
	mov	si,lineput
	mov	ah,01h
	int	36h
	jmp	.putok
.debugmode:
	mov	si,debugmodeput
	mov	ah,01h
	int	36h
.putok:
	mov	si,0
	jmp usrinput

command:
; 命令识别与执行
; 无寄存器
.lop1r:
	; 清空缓冲区
	mov	si,0
	mov	cx,3
.lop1:
	; cls命令的判断
	mov	ah,[clscom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop2r
	inc	si
	loop	.lop1
	jmp	cls
.lop2r:
	; 清空缓冲区
	mov	si,0
	mov	cx,4
.lop2:
	; time命令的判断
	mov	ah,[timecom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop3r
	inc	si
	loop	.lop2
	jmp	time
.lop3r:
	; 清空缓冲区
	mov	si,0
	mov	cx,4
.lop3:
	; date命令的判断
	mov	ah,[datecom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop4r
	inc	si
	loop	.lop3
	jmp	date
.lop4r:
	; 清空缓冲区
	mov	si,0
	mov	cx,8
.lop4:
	; shutdown命令的判断
	mov	ah,[shutdowncom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop5r
	inc	si
	loop	.lop4
	jmp	shutdown
.lop5r:
	; 清空缓冲区
	mov	si,0
	mov	cx,3
.lop5:
	; ver命令的判断
	mov	ah,[vercom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop6r
	inc	si
	loop	.lop5
	jmp	ver
.lop6r:
	; 清空缓冲区
	mov	si,0
	mov	cx,3
.lop6:
	; dir命令的判断
	mov	ah,[dircom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop7r
	inc	si
	loop	.lop6
	jmp	dir
.lop7r:
	; 清空缓冲区
	mov	si,0
	mov	cx,4
.lop7:
	; echo命令的判断
	mov	ah,[echocom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop8r
	inc	si
	loop	.lop7
	jmp	echo
.lop8r:
	; 清空缓冲区
	mov	si,0
	mov	cx,4
.lop8:
	; type命令的判断
	mov	ah,[typecom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop9r
	inc	si
	loop	.lop8
	jmp	type
.lop9r:
	; 清空缓冲区
	mov	si,0
	mov	cx,3
.lop9:
	; del命令的判断
	mov	ah,[delcom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop10r
	inc	si
	loop	.lop9
	jmp	del
.lop10r:
	; 清空缓冲区
	mov	si,0
	mov	cx,6
.lop10:
	; mkfile命令的判断
	mov	ah,[mkfilecom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop11r
	inc	si
	loop	.lop10
	jmp	mkfile
.lop11r:
	; 清空缓冲区
	mov	si,0
	mov	cx,4
.lop11:
	; edit命令的判断
	mov	ah,[editcom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop12r
	inc	si
	loop	.lop11
	jmp	edit
.lop12r:
	; 清空缓冲区
	mov	si,0
	mov	cx,2
.lop12:
	; cd命令的判断
	mov	ah,[cdcom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop13r
	inc	si
	loop	.lop12
	jmp	cd
.lop13r:
	; 清空缓冲区
	mov	si,0
	mov	cx,5
.lop13:
	; color命令的判断
	mov	ah,[colorcom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop14r
	inc	si
	loop	.lop13
	jmp	color
.lop14r:
	mov	si,0
	mov	cx,5
.lop14:
	; mkdir命令的判断
	mov	ah,[mkdircom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop15r
	inc	si
	loop	.lop14
	jmp	mkdir
.lop15r:
	mov	si,0
	mov	cx,5
.lop15:
	; debug命令的判断
	mov	ah,[debugcom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop16r
	inc	si
	loop	.lop15
	mov	byte[debugflags],1
	ret
.lop16r:
	mov	si,0
	mov	cx,6
.lop16:
	; rename命令的判断
	mov	ah,[renamecom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop17r
	inc	si
	loop	.lop16
	jmp	rename
.lop17r:
	mov	si,0
	mov	cx,5
.lop17:
	; drive命令的判断
	mov	ah,[drivecom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop18r
	inc	si
	loop	.lop17
	jmp	drive
.lop18r:
	mov	si,0
	mov	cx,5
.lop18:
	; pause命令的判断
	mov	ah,[pausecom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop19r
	inc	si
	loop	.lop18
	jmp	cpause
.lop19r:
	mov	si,0
	mov	cx,4
.lop19:
	; copy命令的判断
	mov	ah,[copycom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.lop20r
	inc	si
	loop	.lop19
	jmp	copy
.lop20r:
	mov	si,0
	mov	cx,5
.lop20:
	; paste命令的判断
	mov	ah,[pastecom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.end
	inc	si
	loop	.lop20
	jmp	paste
.de1r:
	mov	si,0
	mov	cx,4
.de1:
	; exit命令的判断
	mov	ah,[exitcom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.de2r
	inc	si
	loop	.de1
	mov	byte[debugflags],0
	ret
.de2r:
	mov	si,0
	mov	cx,4
.de2:
	; poke命令的判断
	mov	ah,[pokecom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.de3r
	inc	si
	loop	.de2
	jmp	poke
.de3r:
	mov	si,0
	mov	cx,5
.de3:
	; visit命令的判断
	mov	ah,[visitcom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.de4r
	inc	si
	loop	.de3
	jmp	visit
.de4r:
	mov	si,0
	mov	cx,4
.de4:
	; find命令的判断
	mov	ah,[findcom+si]
	mov	al,[cmdline+si]
	cmp	ah,al
	jne	.nocom
	inc	si
	loop	.de4
	jmp	find
.end:
	cmp	byte[debugflags],1	; 如果进入了调试模式
	je	.de1r
.nocom:
	; 无命令执行
	mov	si,badcom
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

cls:
	; cls命令执行
	mov	ah,00h
	mov	al,03h
	int	10h
	ret

time:
	; time命令执行
	mov	si,timetemp
	mov	ah,04h
	int	36h
	mov	si,0
	mov	di,10
	mov	cx,3
.loop:
	mov	dh,[timetemp+si]
	mov	dl,[timetemp+si]
	shr	dh,4
	and	dl,0fh
	add	dh,30h
	add	dl,30h
	mov	[timemsg+di],dh
	inc	di
	mov	[timemsg+di],dl
	inc	si
	add	di,2
	loop	.loop
	
	; 输出结果到屏幕上
	mov	si,timemsg
	mov	ah,01h
	int	36h
	ret

date:
	; data命令执行
	mov	si,datetemp
	mov	ah,05h
	int	36h
	mov	si,0
	mov	di,10
	mov	cx,4
.loop:
	mov	dh,[datetemp+si]
	mov	dl,[datetemp+si]
	shr	dh,4
	and	dl,0fh
	add	dh,30h
	add	dl,30h
	mov	[datemsg+di],dh
	inc	di
	mov	[datemsg+di],dl
	inc	si
	cmp	cx,4
	je	.inc1
	inc	di
.inc1:
	inc	di
	loop	.loop
	
	; 输出结果到屏幕上
	mov	si,datemsg
	mov	ah,01h
	int	36h
	ret

shutdown:
	; shutdown命令执行
	; 利用BIOS中断关机
	mov	ax,5301h
	xor	bx,bx
	int	15h
	mov	ax,530eh
	mov	cx,0102h
	int	15h
	mov	ax,5307h
	mov	bl,01h
	mov	cx,0003h
	int	15h
	ret

ver:
	; ver命令执行
	mov	ah,02h
	int	36h
	mov	si,verput
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

dir:
	; dir命令执行
	; 规律：每2h循环文件名
	; 文件属性：20h为文件 10h为目录
	mov	al,[drivetemp]
	mov	[dirput+19],al
	mov	si,dirput
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	mov	ah,[fileinfoseg]	; 文件信息段地址
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	si,0
.try:
	mov	cx,12
	mov	ah,02h
	int	36h
.put:
	mov	al,[es:si]
	cmp	al,10h		; 文件属性是目录
	je	.dir
	mov	ah,0eh
	int	10h
	inc	si
	loop	.put
.lop:
	mov	ax,es
	add	ax,2h	; 给ES加上2h
	mov	es,ax
	mov	si,0
	mov	al,[es:si]
	cmp	al,0	; 如果[ES:SI]处为0
	je	.ret	; 就结束
	cmp	al,0xe5	; 如果文件被删除（开头为0xe5）
	je	.lop	; 判断下1个文件是否存在
	jmp	.try
.dir:
	mov	si,isdir
	mov	ah,01h
	int	36h
	jmp	.lop
.ret:
	mov	ah,02h
	int	36h
	ret

echo:
	; echo命令的执行 
	mov	di,5
.try:
	mov	al,[cmdline+di]
	cmp	al,0
	je	.ret
	mov	ah,0eh
	int	10h
	inc	di
	jmp .try
.ret:
	mov	ah,02h
	int	36h
	ret

type:
	; type命令的执行
	mov	si,5	; 'type '占5字节 文件名是从6字节开始的
	mov	dh,20h
	call	filenamecpy
	
	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	si,findfilename
	mov	ah,06h
	int	36h	; 寻找文件
	
	cmp	bx,0
	je	.ret
	cmp	dx,0
	je	.ret
	add	bx,1h
	mov	es,bx	; 将文件信息段地址赋值给ES
	mov	cx,[es:12]
	cmp	cx,0
	je	.lengthzero
	mov	es,dx	; 将文件内容段地址赋值给ES
	mov	si,0
.put:
	mov	al,[es:si]
	mov	ah,0eh
	int	10h
	inc	si
	loop	.put
.lengthzero:
	ret
.ret:
	mov	si,notfind
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

del:
	; del命令执行
	; 利用int13h读写删除文件
	mov	si,4
	mov	dh,20h
	call	filenamecpy
	
	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	si,findfilename
	mov	ah,06h
	int	36h
	
	cmp	bx,0
	je	.ret
	mov	es,bx
.deling:
	mov	byte[es:0],0xe5	; 把文件的第1字节写成0xe5 造成“删除”（内存）
	call	diskrest
	ret
.ret:
	mov	si,notfind
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

mkfile:
	; mkfile命令执行
	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	ah,07h
	int	36h	; 先寻找空位
	mov	es,bx
	
	mov	si,7
	mov	dh,20h
	call	filenamecpy

	mov	cx,12
	mov	si,0
.loop:
	mov	al,[findfilename+si]
	mov	[es:si],al
	inc	si
	loop	.loop
	
	push	es
	mov	ax,es
	sub	ax,1h
	mov	es,ax	; 寻找上个文件的簇和长度
	
	mov	ax,[es:12]
	mov	cx,1
.div:
	cmp	ax,200h
	jb	.next
	sub	ax,200h
	inc	cx
	jmp	.div
.next:
	mov	ax,[es:10]
	add	cx,ax
	pop	es
	mov	[es:0x10+10],cx
	call	diskrest
	ret

edit:
	; edit命令执行
	mov	si,5
	mov	dh,20h
	call	filenamecpy
	
	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	si,findfilename
	mov	ah,06h
	int	36h
	
	cmp	bx,0
	je	.ret
	cmp	dx,0
	je	.ret
	mov	es,dx
	push	bx
	mov	si,0
.input:
	mov	ah,0
	int	16h
	cmp	al,1bh
	je	.inputend
	cmp	al,0dh
	je	.enter	; 如果输入的是换行
	mov	ah,0eh
	int	10h
	cmp	al,08h
	je	.backspace
	mov	byte[es:si],al
	inc	si
	jmp	.input
.enter:
	mov	ah,02h
	int	36h
	mov	word[es:si],0a0dh	; 将0dh,0ah（换行）写入[es:si]处
	add	si,2	; 一个word占2字节
	jmp	.input
.backspace:
	dec	si
	mov	ah,0eh
	mov	al,20h
	int	10h
	mov	al,08h
	int	10h
	mov	byte[es:si],0
	jmp	.input
.inputend:
	mov	ah,02h
	int	36h
	pop	bx
	add	bx,1h
	mov	es,bx
	mov	word[es:12],si	; 将文件长度赋值
	call	diskrest
	ret
.ret:
	mov	si,notfind
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

cd:
	; cd命令执行
	mov	si,3
	mov	dh,10h
	call	filenamecpy
	
	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	si,findfilename
	mov	ah,06h
	int	36h
	
	cmp	bx,0
	je	.ret
	cmp	dx,0
	je	.ret
	
	add	bx,1h
	mov	es,bx
	cmp	word[es:10],0
	je	.father
	
	mov	[fileinfoseg],dh	; 更改文件目录地址
	mov	[fileinfoseg+1],dl
	ret
.father:	; 根目录
	mov	byte[fileinfoseg],0ah
	mov	byte[fileinfoseg+1],60h
	ret
.ret:
	mov	si,cdput
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

color:
	; color命令执行
	mov	al,[cmdline+6]
	cmp	al,0
	je	.error
	and	al,11011111b
	cmp	al,'F'
	jg	.error
	cmp	al,'9'
	jg	.letter
	sub	al,30h	; 1~9 ASCII码 转化数字
	jmp	.next
.letter:
	sub	al,37h	; A~F ASCII码 转化数字
.next:
	mov	cl,4
	shl	al,cl
	mov	[colortemp],al
	mov	al,[cmdline+7]
	cmp	al,0
	je	.zero
	and	al,11011111b
	cmp	al,'F'
	jg	.error
	cmp	al,'9'
	jg	.letter2
	sub	al,30h
	jmp	.next2
.letter2:
	sub	al,37h
.next2:
	mov	ah,[colortemp]
	add	ah,al
	mov	[colortemp],ah
	jmp	.paintscreen
.zero:
	mov	al,[colortemp]
	mov	cl,4
	shr	al,cl
	mov	[colortemp],al
.paintscreen:
	mov	ax,0b800h	; 显存地址
	mov	es,ax
	mov	si,1
	mov	ah,[colortemp]
	mov	cx,25*80
.paintloop:
	mov	[es:si],ah
	add	si,2
	loop	.paintloop
	ret
.error:
	mov	si,colorput
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

mkdir:
	; mkdir命令执行
	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	ah,07h
	int	36h
.findend:
	mov	si,6
	mov	di,0
	mov	cx,11
	mov	es,bx
.writeloop1:	
	mov	byte[es:di],' '	; 先全部填充空格
	inc	di
	loop	.writeloop1
	mov	di,0
.writeloop2:
	mov	al,[cmdline+si]
	cmp	al,0
	je	.writeend
	and	al,11011111b
	mov	[es:di],al
	inc	si
	inc	di
	cmp	di,11
	je	.writeend
	jmp	.writeloop2
.writeend:
	mov	byte[es:11],10h	; 属性：文件夹
	mov	ax,es
	sub	ax,1h
	mov	es,ax
	mov	cl,[es:10]	; 得到上一个文件簇号
	mov	al,[es:12]
	mov	ah,[es:13]	; 得到上一个文件长度
.div:
	inc	cl
	cmp	ax,200h
	jb	.divok
	sub	ax,200h
	jmp	.div
.divok:
	mov	ax,es
	add	ax,2h
	mov	es,ax
	mov	[es:10],cl	; 将簇号写入
	push	cx
	mov	ax,0
.mul:
	add	ax,20h
	loop	.mul
	add	ax,filetypeseg
	mov	es,ax
	mov	di,0
	mov	si,0
	mov	cx,12
.writeloop3:
	mov	al,[mkdirwrite+si]
	mov	[es:di],al
	inc	si
	inc	di
	loop	.writeloop3
	mov	ax,es
	add	ax,1h
	mov	es,ax
	pop	cx
	mov	[es:10],cl
	mov	ax,es
	add	ax,1h
	mov	es,ax
	mov	di,0
	mov	cx,12
.writeloop4:
	mov	al,[mkdirwrite+si]
	mov	[es:di],al
	inc	si
	inc	di
	loop	.writeloop4
	call	diskrest
	ret

rename:
	; rename命令执行
	mov	si,7	; 第一个文件名 用来查找文件信息地址
	mov	dh,20h
	call	filenamecpy

	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	si,findfilename
	mov	ah,06h
	int	36h
	
	cmp	bx,0
	je	.ret
	cmp	dx,0
	je	.ret
	mov	es,bx
	mov	si,7
.lenloop:	; 这里用来确认第二个文件在cmdline中的位置
	cmp	byte[cmdline+si],' '
	je	.ok
	inc	si
	jmp	.lenloop
.ok:
	inc	si	; 跳过' '
	mov	dh,20h
	call	filenamecpy
	
	mov	si,0
	mov	cx,11
.reloop:	; 替换文件名
	mov	al,[findfilename+si]
	mov	[es:si],al
	inc	si
	loop	.reloop
	call	diskrest
	ret
.ret:
	mov	ah,01h
	mov	si,notfind
	int	36h
	mov	ah,02h
	int	36h
	ret

drive:
	; drive命令的执行
	mov	al,[cmdline+6]
	cmp	al,'C'
	jae	.hard
	cmp	al,'A'
	jae	.floppy
	mov	ah,01h
	mov	si,notthisdrive
	int	36h
	mov	ah,02h
	int	36h
	ret
.floppy:	; A,B盘 软盘
	push	ax
	sub	al,'A'	; 'A'-'A'=0（=驱动A的编码）
	mov	dl,al
	mov	ah,01h
	int	13h	; 检测磁盘状态
	cmp	al,0	; 如果不是无错状态（代码=0） 那就是有错
	jne	.notready
	pop	ax
	mov	[drivetemp],al
	sub	al,'A'
	mov	[drivetemp+1],al
	mov	word[fileinfoseg],0x600A	; 根目录
	call	restread	; 重新读盘
	ret
.hard:	; C~Z盘 硬盘
	push	ax
	sub	al,'C'	; 'C'-'C'+0x80=0x80（=驱动C的编码）
	add	al,80h
	mov	dl,al
	mov	ah,01h
	int	13h	; 检测磁盘状态
	cmp	al,0	; 如果不是无错状态（代码=0） 那就是有错
	jne	.notready
	pop	ax
	mov	[drivetemp],al
	sub	al,'C'
	add	al,80h
	mov	[drivetemp+1],al
	mov	word[fileinfoseg],0x600A	; 根目录
	call	restread	; 重新读盘
	ret
.notready:	; 磁盘有错或没准备好
	pop	ax
	mov	[drivenotready+6],al
	mov	ah,01h
	mov	si,drivenotready
	int	36h
	mov	ah,02h
	int	36h
	ret

cpause:
	; pause命令的执行
	mov	si,pauseput
	mov	ah,01h
	int	36h
.loop:
	mov	ah,0
	int	16h
	mov	ah,02h
	int	36h
	ret

copy:
	; copy命令执行
	mov	si,5
	mov	dh,20h
	call	filenamecpy

	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	si,findfilename
	mov	ah,06h
	int	36h
	
	cmp	bx,0
	je	.notfind
	cmp	dx,0
	je	.notfind
	; 将文件内容复制到0x55000~0x65000中（copybuffer）
	mov	es,bx
	mov	cx,[es:28]	; 得到文件长度
	mov	[copyfilelength],cx	; 保存到copyfilelength中
	push	ds
	mov	ds,dx
	mov	si,0
	mov	ax,copybufferseg
	mov	es,ax
	mov	di,0
	call	memcpy
	pop	ds
	ret
.notfind:
	mov	ah,01h
	mov	si,notfind
	int	36h
	mov	ah,02h
	int	36h
	ret

paste:
	; paste命令执行
	; 寻找目录中的空位
	mov	ah,[fileinfoseg]
	mov	al,[fileinfoseg+1]
	mov	es,ax
	mov	ah,07h
	int	36h
	mov	es,bx

	mov	si,6
	mov	dh,20h
	call	filenamecpy

	mov	cx,12
	mov	si,0
.loop:	; 复制文件名
	mov	al,[findfilename+si]
	mov	[es:si],al
	inc	si
	loop	.loop
	; 得到上个文件的簇和长度
	push	es
	mov	ax,es
	sub	ax,1h
	mov	es,ax
	mov	cx,[es:12]	; 长度
	mov	al,[es:10]	; 簇
	; 计算这个文件的簇
.sub:
	inc	al
	cmp	cx,200h
	jb	.ok
	sub	cx,200h
	jmp	.sub
.ok:
	; 写入簇
	pop	es
	mov	[es:26],al
	; 写入长度
	mov	cx,[copyfilelength]
	mov	[es:28],cx
	; 写入内容
	mov	di,0
	mov	si,0
	; 计算文件段地址
	mov	bx,filetypeseg
.mul:
	add	bx,20h
	dec	al
	cmp	al,0
	je	.ok2
	jmp	.mul
.ok2:
	mov	es,bx
	mov	ax,copybufferseg
	push	ds
	mov	ds,ax
	call	memcpy
	pop	ds
	
	; 写盘
	call	diskrest
	ret

poke:
	; poke命令执行
	mov	al,[cmdline+5]
	cmp	al,'&'	; 地址符号标识
	jne	.error
	mov	si,6
.loop:	; 得到段地址
	mov	al,[cmdline+si]	; 每次转化1个数字 直到下1个字符是' '
	cmp	byte[cmdline+si+1],' '
	je	.ok
	call	ASCIItonum
	mov	bx,[addresssegtemp]
	shl	bx,4	; 现在=原来*0x10+新添加
	mov	ah,0
	add	bx,ax
	mov	[addresssegtemp],bx
	inc	si
	jmp	.loop
.ok:	; 得到偏移地址
	call	ASCIItonum
	mov	ah,0
	mov	[addressofftemp],ax
.findaddress:
	mov	ax,[addresssegtemp]
	mov	es,ax
	mov	al,[cmdline+si+2]
	call	ASCIItonum
	mov	ah,al
	mov	al,[cmdline+si+3]
	call	ASCIItonum
	shl	ah,4
	add	ah,al
	mov	si,[addressofftemp]
	mov	[es:si],ah	; 写数据
	; 清空Addressofftemp和Addresssegtemp
	mov	word[addresssegtemp],0
	mov	word[addressofftemp],0
	ret
.error:
	mov	si,pokeerror
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

visit:
	; visit命令执行
	mov	al,[cmdline+6]
	cmp	al,'&'	; 地址符号标识
	jne	.error
	mov	si,7
.loop:	; 得到段地址
	mov	al,[cmdline+si]	; 每次转化1个数字 直到下1个字符是' '或者0
	cmp	byte[cmdline+si+1],' '
	je	.ok
	cmp	byte[cmdline+si+1],0
	je	.ok
	call	ASCIItonum
	mov	bx,[addresssegtemp]
	shl	bx,4	; 现在=原来*0x10+新添加
	mov	ah,0
	add	bx,ax
	mov	[addresssegtemp],bx
	inc	si
	jmp	.loop
.ok:	; 得到偏移地址
	call	ASCIItonum
	mov	ah,0
	mov	[addressofftemp],ax
.findaddress:
	mov	ax,[addresssegtemp]
	mov	es,ax
	mov	si,[addressofftemp]
	mov	al,[es:si]	; 读数据
	shr	al,4
	call	numtoASCII
	mov	ah,0eh
	int	10h
	mov	al,[es:si]
	and	al,0fh
	call	numtoASCII
	int	10h
	; 清空Addressofftemp和Addresssegtemp
	mov	word[addresssegtemp],0
	mov	word[addressofftemp],0
	ret
.error:
	mov	si,visiterror
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

find:
	; find命令的执行
	mov	al,[cmdline+5]
	cmp	al,'&'	; 地址符号标识
	jne	.error
	mov	si,6
	; 1.起始地址（保存到堆栈
.loop:	; 得到段地址
	mov	al,[cmdline+si]	; 每次转化1个数字 直到下1个字符是' '
	cmp	byte[cmdline+si+1],' '
	je	.ok
	call	ASCIItonum
	mov	bx,[addresssegtemp]
	shl	bx,4	; 现在=原来*0x10+新添加
	mov	ah,0
	add	bx,ax
	mov	[addresssegtemp],bx
	inc	si
	jmp	.loop
.ok:	; 得到偏移地址
	call	ASCIItonum
	mov	ah,0
	mov	[addressofftemp],ax
	; 保存起始地址到堆栈
	mov	ax,[addresssegtemp]
	push	ax
	mov	ax,[addressofftemp]
	push	ax
	add	si,2	; 跳过' '
	cmp	byte[cmdline+si],'&'	; 地址符标识
	jne	.error
	inc	si	; 跳过'&'
	; 2.目标地址（保存到temp中
.loop2:	; 得到段地址
	mov	al,[cmdline+si]	; 每次转化1个数字 直到下1个字符是' '
	cmp	byte[cmdline+si+1],' '
	je	.ok2
	call	ASCIItonum
	mov	bx,[addresssegtemp]
	shl	bx,4	; 现在=原来*0x10+新添加
	mov	ah,0
	add	bx,ax
	mov	[addresssegtemp],bx
	inc	si
	jmp	.loop2
.ok2:	; 得到偏移地址
	call	ASCIItonum
	mov	ah,0
	mov	[addressofftemp],ax
	; 3.数据
	mov	al,[cmdline+si+2]
	call	ASCIItonum
	mov	ah,al
	mov	al,[cmdline+si+3]
	call	ASCIItonum
	shl	ah,4
	add	ah,al
	; 取出起始地址
	pop	si
	pop	es
	; 长度=目标地址-起始地址
	mov	cx,[addresssegtemp]
	shl	ecx,4	; cx=cx*0x10=cx<<4
	add	cx,[addressofftemp]
	mov	bx,es
	shl	ebx,4	; bx=bx*0x10=bx<<4
	add	bx,si
	sub	ecx,ebx
.loop3:
	cmp	si,16
	jne	.next
	mov	si,es
	inc	si
	mov	es,si
	mov	si,0
.next:
	mov	al,[es:si]
	cmp	ah,al
	je	.pc
	inc	si
	dec	ecx
	jecxz	.end
	jmp	.loop3
.put	db	0
.pc:
	push	ax
	push	si
	mov	ah,01h
	mov	si,findput
	int	36h
	mov	dx,es
	mov	al,dh
	shr	al,4
	call	numtoASCII
	mov	ah,0eh
	int	10h
	mov	al,dh
	and	al,0fh
	call	numtoASCII
	int	10h
	mov	al,dl
	shr	al,4
	call	numtoASCII
	int	10h
	mov	al,dl
	and	al,0fh
	call	numtoASCII
	int	10h
	pop	si
	push	si
	mov	dx,si
	mov	al,dl
	and	al,0fh
	call	numtoASCII
	int	10h
	mov	ah,02h
	int	36h
	inc	byte[.put]	; 记数
	cmp	byte[.put],25
	jne	.next2
	mov	ah,01h
	mov	si,findpauseput
	int	36h
.pause:
	mov	ah,0
	int	16h
	cmp	al,0dh
	je	.newline
	cmp	al,1bh
	je	.popend
	jmp	.pause
.newline:
	mov	ah,02h
	int	36h
.next2:
	pop	si
	pop	ax
	inc	si
	dec	ecx
	jecxz	.end
	jmp	.loop3
.popend:
	pop	si
	pop	ax
.end:
	ret
.error:
	mov	si,finderror
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	ret

filenamecpy:
; 1.将cmdline中"*.*"类文件名转化成"*       *  "类文件名（"a.txt"->"A       TXT"）
; 2.将转化后的文件名写入FindFileName中
; 寄存器：in:SI/DH
	mov	di,0
	mov	cx,11
.strcpy:	; 循环一：将FindFileName全部归' '
	mov	byte[findfilename+di],' '
	inc	di
	loop	.strcpy
	mov	byte[findfilename+11],dh	; 文件属性
	mov	di,0
	mov	cx,8
.strcpy2:	; 循环二：将文件名复制到FindFileName前8位中
	mov	ah,[cmdline+si]
	cmp	ah,'.'
	je	.spot
	cmp	ah,0
	je	.zero
	cmp	ah,' '
	je	.zero
	and	ah,11011111b	; 防止小写错误
	mov	[findfilename+di],ah
	inc	si
	inc	di
	loop	.strcpy2
.strcpy3r:	; 循环三：跳过'.' 将后缀名复制到FindFileName后3位中
	mov	cx,3
	mov	di,8
	inc	si	; 跳过'.'
.strcpy3:
	mov	ah,[cmdline+si]
	cmp	ah,0
	je	.strcpyend
	and	ah,11011111b
	mov	[findfilename+di],ah
	inc	si
	inc	di
	loop	.strcpy3
.strcpyend:
	ret
.spot:	; 从循环二跳来 如果后缀点
	cmp	dh,10h
	je	.spota
	jmp	.strcpy3r
.spota:		; 'cd .?'的情况
	mov	byte[findfilename+0],'.'
	inc	si
	cmp	byte[cmdline+si],'.'
	jne	.strcpyend	; 'cd .'
	mov	byte[findfilename+1],'.'	; 'cd ..'
	jmp	.strcpyend
.zero:	; 从循环二跳来 如果没有后缀点
	mov	cx,8
	sub	cx,di
.zeroloop:
	mov	byte[findfilename+di],' '
	inc	di
	loop	.zeroloop
;	jmp	.strcpy3r
	ret

cleaninput:
; 清空输入（cmdline）的内容
; 无寄存器
	push	si	; SI入堆栈
	mov	si,0
.loop:
	cmp	si,128	; [max]len
	je	.end
	mov	byte[cmdline+si],0
	inc	si
	jmp	.loop
.end:
	pop	si	; SI出堆栈
	ret

oldcleancopy:
; 将上上次输入（oldcmdline）清空 将上一次输入复制到这里
; 无寄存器
	push	si
.loop:
	cmp	si,128	; [max]len
	je	.end
	mov	byte[oldcmdline+si],0
	inc	si
	jmp	.loop
.end:
	mov	si,0
.loop2:
	mov	al,[cmdline+si]
	cmp	al,0
	je	.end2
	mov	[oldcmdline+si],al
	inc	si
	jmp	.loop2
.end2:
	pop	si
	ret

ASCIItonum:
; 将ASCII码转化成16进制数
; 寄存器：in:AL out:AL
	cmp	al,'A'
	jge	.letter
	sub	al,30h
	ret
.letter:
	sub	al,37h
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

diskrest:
; 重新写读盘
; 无寄存器
	mov	ax,dataseg	; 启动时读入的数据地址
	mov	es,ax
.write:
	mov	cl,[sector]
	mov	dh,[header]
	mov	ch,[cyline]
	call	write1sector	; 将ES:BX（地址）的内存数据写入软盘
	call	read1sector		; 再读入ES:BX（地址）
	
	mov	ax,es
	add	ax,20h	; 512B=200H
	mov	es,ax	; ES=ES+20H
	; 扇区
	inc	byte[sector]
	cmp	byte[sector],numsector+1
	jne	.write
	mov	byte[sector],1
	; 磁头
	inc	byte[header]
	cmp	byte[header],numheader+1
	jne	.write
	mov	byte[header],0
	; 柱面
	inc	byte[cyline]
	cmp	byte[cyline],numcyline
	jne	.write
	
	mov	byte[sector],1	; 写读完后全部还原（必须）
	mov	byte[header],0
	mov	byte[cyline],0
	ret

restread:
; 重新读盘
; 无寄存器
	mov	ax,dataseg	; 启动时读入的数据地址
	mov	es,ax
	mov	byte[sector],1	; 写读完后全部还原（必须）
	mov	byte[header],0
	mov	byte[cyline],0
.read:
	mov	cl,[sector]
	mov	dh,[header]
	mov	ch,[cyline]
	call	read1sector		; 读入ES:BX（地址）
	
	mov	ax,es
	add	ax,20h	; 512B=200H
	mov	es,ax	; ES=ES+20H
	; 扇区
	inc	byte[sector]
	cmp	byte[sector],numsector+1
	jne	.read
	mov	byte[sector],1
	; 磁头
	inc	byte[header]
	cmp	byte[header],numheader+1
	jne	.read
	mov	byte[header],0
	; 柱面
	inc	byte[cyline]
	cmp	byte[cyline],numcyline
	jne	.read
	
	mov	byte[sector],1	; 写读完后全部还原（必须）
	mov	byte[header],0
	mov	byte[cyline],0
	ret

write1sector:
; 写1个扇区的通用程序
; 寄存器：in:CL/DH/CH/ES
	mov	di,0
.retry:
	mov	ah,03h
	mov	al,1
	mov	bx,0	; ES:BX = ????:0
	mov	dl,[drivetemp+1]
	int	13h
	jnc	.ok		; 未出错就跳转
	inc	di
	
	mov	ah,00h
	mov	dl,[drivetemp+1]
	int	13h
	cmp	di,5	; 写5次依然出错就放弃
	jne	.retry

	mov	ah,01h
	mov	si,writeerror	; 打印错误
	int	36h
	mov	ah,02h
	int	36h
.ok:
	ret

read1sector:
; 读取1个扇区的通用程序
; 寄存器：in:CL/DH/CH/ES
	mov	di,0
.retry:
	mov	ah,02h
	mov	al,1
	mov	bx,0	; ES:BX = ????:0
	mov	dl,[drivetemp+1]
	int	13h
	jnc	.ok		; 未出错就跳转
	inc	di
	
	mov	ah,00h
	mov	dl,[drivetemp+1]
	int	13h
	cmp	di,5	; 读5次依然出错就放弃
	jne	.retry

	mov	ah,01h
	mov	si,readerror	; 打印错误
	int	36h
	mov	ah,02h
	int	36h
.ok:
	ret

%include "execbatch.asm"	; 可执行文件 批处理文件
%include "syscall.asm"		; 系统调用