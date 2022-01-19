; setup.asm
; Copyright (C) zhouzhihao 2021
db	'POWERBINHEAD'
%macro	setcur	3
; 设定光标位置
	mov	ah,02h
	mov	bh,%1	; 页
	mov	dh,%2	; 行
	mov	dl,%3	; 列
	int	10h
%endmacro
fileinfoseg		equ		0a60h	; 根目录地址
datatempseg		equ		5500h	; 数据缓存地址
loaderdataseg	equ		4200h
commanddataseg	equ		4400h
shelldataseg	equ		5800h
clockdataseg	equ		6400h
editdataseg		equ		6A00h
bitzdataseg		equ		7200h
autoexecdataseg	equ		7600h
bmpviewdataseg	equ		7800h
viewdataseg		equ		7C00h
numsector		equ		18
numheader		equ		1
numcyline		equ		10	; 安装包最大11KB 不会超过5个柱面
; HD.PAK 内容：
; 1.BOOT.BIN
; 2.LOADER.BIN
; 3.COMMAND.BIN
; 4.SHELL.BIN
; 5.CLOCK.BIN
; 6.EDIT.BIN
; 7.BITZ.BIN
; 8.AUTOEXEC.BAT
; 9.BMPVIEW.BIN
; 10.VIEW.BMP
; PAK 文件结构：
; 0x00 ~ 0x0B 文件名
; 0x0C ~ 0x0D 文件地址
; 0x0E ~ 0x0F 文件长度
start:
	mov	ax,cs
	mov	ds,ax
	
	mov	ah,0
	mov	al,03h
	int	10h
	mov	ah,02h
	int	36h
	
	mov	ah,01h
	mov	si,welcomeput
	int	36h
inputloop:
	mov	ah,0
	int	16h
	cmp	al,'1'
	je	installall	; 用户选1 安装所有组件
	cmp	al,'2'
	je	custinstall	; 用户选2 自定义安装
	cmp	al,0dh
	je	installall	; 用户没选 默认安装所有组件
	cmp	al,1bh
	je	breakdos	; 用户按ESC	退出安装
	jmp	inputloop

installall:
; 全部安装
	mov	ah,0eh
	int	10h
	mov	ah,02h
	int	36h
	mov	ah,02h
	int	36h
	mov	si,pastkeyput
	mov	ah,01h
	int	36h
	
	call	pastkeyinput	; 输入密钥
	call	cmppastkey		; 判断输入密钥是否正确？
	
	mov	si,pakfilename
	mov	ax,fileinfoseg
	mov	es,ax
	mov	ah,06h
	int	36h
	cmp	dx,0
	je	lostpakfile
	
	mov	ah,02h
	int	36h
	mov	ah,02h
	int	36h
	dec	ah
	mov	si,setupingput
	int	36h
	
	; 全部安装
	; Step1:安装引导扇区
	mov	ds,dx
	mov	ax,datatempseg
	mov	es,ax
	mov	si,[0x0c]
	mov	cx,[0x0e]
	mov	di,0
	call	memcpy	; 复制引导扇区到数据缓存区
	
	; Step2:安装系统核心文件
	; (1).Loader.bin
	mov	si,[0x1c]
	mov	cx,[0x1e]
	mov	di,loaderdataseg
	call	memcpy
	; (2).Command.bin
	mov	si,[0x2c]
	mov	cx,[0x2e]
	mov	di,commanddataseg
	call	memcpy
	; (3).文件信息
	; 文件名
	mov	si,0x10
	mov	cx,12
	mov	di,0x2600
	call	memcpy
	mov	si,0x20
	mov	cx,12
	mov	di,0x2600+0x20
	call	memcpy
	; 簇和长度
	mov	cx,[0x1e]
	mov	word[es:0x2600+26],(loaderdataseg-0x3e00)/0x200
	mov	[es:0x2600+28],cx
	mov	cx,[0x2e]
	mov	word[es:0x2600+0x20+26],(commanddataseg-0x3e00)/0x200
	mov	[es:0x2600+0x20+28],cx
	
	; Step3:安装程序
	; (1).Shell.bin
	mov	si,[0x3c]
	mov	cx,[0x3e]
	mov	di,shelldataseg
	call	memcpy
	; (2).Clock.bin
	mov	si,[0x4c]
	mov	cx,[0x4e]
	mov	di,clockdataseg
	call	memcpy
	; (3).Edit.bin
	mov	si,[0x5c]
	mov	cx,[0x5e]
	mov	di,editdataseg
	call	memcpy
	; (4).Bitz.bin
	mov	si,[0x6c]
	mov	cx,[0x6e]
	mov	di,bitzdataseg
	call	memcpy
	; (5).Bmpview.bin
	mov	si,[0x8c]
	mov	cx,[0x8e]
	mov	di,bmpviewdataseg
	call	memcpy
	; (6).View.bmp
	mov	si,[0x9c]
	mov	cx,[0x9e]
	mov	di,viewdataseg
	call	memcpy
	; (7).文件信息
	; 文件名
	mov	si,0x30
	mov	cx,12
	mov	di,0x2600+0x40
	call	memcpy
	mov	si,0x40
	mov	cx,12
	mov	di,0x2600+0x60
	call	memcpy
	mov	si,0x50
	mov	cx,12
	mov	di,0x2600+0x80
	call	memcpy
	mov	si,0x60
	mov	cx,12
	mov	di,0x2600+0xa0
	call	memcpy
	mov	si,0x80
	mov	cx,12
	mov	di,0x2600+0xe0
	call	memcpy
	mov	si,0x90
	mov	cx,12
	mov	di,0x2600+0x100
	call	memcpy
	; 簇和长度
	mov	cx,[0x3e]
	mov	word[es:0x2600+0x40+26],(shelldataseg-0x3e00)/0x200
	mov	[es:0x2600+0x40+28],cx
	mov	cx,[0x4e]
	mov	word[es:0x2600+0x60+26],(clockdataseg-0x3e00)/0x200
	mov	[es:0x2600+0x60+28],cx
	mov	cx,[0x5e]
	mov	word[es:0x2600+0x80+26],(editdataseg-0x3e00)/0x200
	mov	[es:0x2600+0x80+28],cx
	mov	cx,[0x6e]
	mov	word[es:0x2600+0xa0+26],(bitzdataseg-0x3e00)/0x200
	mov	[es:0x2600+0xa0+28],cx
	mov	cx,[0x8e]
	mov	word[es:0x2600+0xe0+26],(bmpviewdataseg-0x3e00)/0x200
	mov	[es:0x2600+0xe0+28],cx
	mov	cx,[0x9e]
	mov	word[es:0x2600+0x100+26],(viewdataseg-0x3e00)/0x200
	mov	[es:0x2600+0x100+28],cx
	
	; Step4:安装Autoexec.bat
	mov	si,[0x7c]
	mov	cx,[0x7e]
	mov	di,autoexecdataseg
	call	memcpy
	
	mov	si,0x70
	mov	cx,12
	mov	di,0x2600+0xc0
	call	memcpy
	mov	cx,[0x7e]
	mov	word[es:0x2600+0xc0+26],(autoexecdataseg-0x3e00)/0x200
	mov	[es:0x2600+0xc0+28],cx
	
	; Step5:写入到硬盘中
	mov	ax,cs
	mov	ds,ax
	call	harddiskrest
	
	mov	ah,01h
	mov	si,doneput
	int	36h
	
	jmp	breakdos

pastkeyinput:
; 输入密钥（临时函数）
	mov	ah,0eh
	mov	al,0dh	; 光标置顶
	int	10h
	mov	si,0
	mov	di,0
.input:
	cmp	si,25
	je	.next
	mov	ah,0
	int	16h
	mov	ah,0eh
	int	10h
	cmp	al,08h
	je	.backspace
	push	si
	add	si,di
	mov	byte[pastkeyput.key+si],al
	pop	si
	inc	si
.sublop:
	cmp	si,5
	je	.putspace
	cmp	si,10
	je	.putspace
	cmp	si,15
	je	.putspace
	cmp	si,20
	je	.putspace
	jmp	.input
.putspace:
	mov	ah,0eh
	mov	al,'-'
	int	10h
	inc	di
	jmp	.input
.backspace:
	cmp	si,0
	je	.input
	dec	si
	jmp	.input
.next:
	ret

cmppastkey:
; 判断输入密钥是否正确？（临时函数）
	mov	cx,29
	mov	si,0
.loop:
	cmp	di,15	; 只需输对60%
	je	.true
	mov	al,[pastkeyput.key+si]
	mov	ah,[pastkey+si]
	cmp	ah,al
	jne	.not
	inc	si
	inc	di
	jmp	.next
.not:
	inc	si
.next:
	loop	.loop
	jmp	.false
.true:
	mov	ah,02h
	int	36h
	mov	si,truepastkeyput
	mov	ah,01h
	int	36h
	ret
.false:
	mov	ah,02h
	int	36h
	mov	si,falsepastkeyput
	mov	ah,01h
	int	36h
	mov	ah,02h
	int	36h
	inc	ah
	int	36h
	ret

custinstall:
; 自定义安装
	mov	ah,0eh
	int	10h
	mov	ah,02h
	int	36h
	mov	ah,02h
	int	36h
	mov	si,custinstallopt
	mov	ah,01h
	int	36h
.try:
	setcur	0,byte[opttmp],21
.in1:
	mov	ah,0
	int	16h
	cmp	al,20h
	je	.yes
	cmp	al,0dh
	je	.next
	jmp	.in1
.yes:
	mov	ah,0eh
	mov	al,'*'
	int	10h
.next:
	cmp	byte[opttmp],14
	je	.pastkey
	inc	byte[opttmp]
	jmp	.try
.pastkey:
	mov	ah,02h
	int	36h
	mov	ah,02h
	int	36h
	mov	si,pastkeyput
	mov	ah,01h
	int	36h
	
	call	pastkeyinput	; 输入密钥
	call	cmppastkey		; 判断输入密钥是否正确？
	
	mov	si,pakfilename
	mov	ax,fileinfoseg
	mov	es,ax
	mov	ah,06h
	int	36h
	cmp	dx,0
	je	lostpakfile
	
	jmp	$

lostpakfile:
; 丢失HD.PAK
	mov	ah,02h
	int	36h
	mov	ah,02h
	int	36h
	mov	ah,01h
	mov	si,lostpakfileput
	int	36h

breakdos:
	mov	ah,02h
	int	36h
	mov	ah,02h
	int	36h
	mov	ah,03h
	int	36h

harddiskrest:
; 重新写硬盘
; 无寄存器
	mov	ax,datatempseg	; 启动时读入的数据地址
	mov	es,ax
.write:
	mov	cl,[sector]
	mov	dh,[header]
	mov	ch,[cyline]
	call	write1sector	; 将ES:BX（地址）的内存数据写入软盘
	
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
	cmp	byte[cyline],numcyline+1
	jne	.write
	
	mov	byte[sector],1	; 写读完后全部还原（必须）
	mov	byte[header],0
	mov	byte[cyline],0
	ret


write1sector:
; 写1个扇区的通用程序
; 寄存器：in:CL/DH/CH/ES
; CL --> 扇区
; DH --> 磁头
; CH --> 柱面
; ES --> 内存地址
	mov	di,0
.retry:
	mov	ah,03h
	mov	al,1
	mov	bx,0	; ES:BX = ????:0
	mov	dl,80h
	int	13h
	jnc	.ok		; 未出错就跳转
	inc	di
	mov	ah,00h
	mov	dl,80h
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

welcomeput:
	db	'Welcome install Powerint DOS.',0dh,0ah
	db	'Install options:',0dh,0ah
	db	'1.Install All(default)',0dh,0ah
	db	'2.Customize Install',0dh,0ah
	db	'ESC.Exit setup',0dh,0ah
	db	'Press Input number of options:',0
custinstallopt:
	db	'Install choose:',0dh,0ah
	db	'Space:yes | Enter:no',0dh,0ah
	db	'1.Command parser    [*]',0dh,0ah
	db	'2.Filemanager shell [ ]',0dh,0ah
	db	'3.Suchdule & Clock  [ ]',0dh,0ah
	db	'4.File edit         [ ]',0dh,0ah
	db	'5.Byte edit         [ ]',0dh,0ah,0
opttmp	db	11
pastkeyput:
	db	'Please input your pastkey:',0dh,0ah
.key:db	'_____-_____-_____-_____-_____',0
pastkey	db	'OEMXX-K08v5-e4C2h-jbCBa-SETUP'		; pastkey范本 只需输对60%
truepastkeyput	db	'True Pastkey.',0
falsepastkeyput	db	'False Pastkey.',0
pakfilename		db	'HD      PAK',20h	; 安装文件pak
lostpakfileput	db	'Setup Error:No HD.PAK in drive A.',0
setupingput		db	'Setup is writing harddisk,please wait...',0
writeerror		db	'Write harddisk error.',0
doneput			db	'done.',0
sector			db	1
header			db	0
cyline			db	0