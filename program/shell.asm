; shell.asm
; Copyright (C) zhouzhihao 2021
db	'POWERBINHEAD'	; 表示是Powerint DOS子程序
%macro	paint	6
; “开窗填充”功能
	mov	ah,06h
	mov	al,%1	; 页
	mov	bh,%2	; 颜色
	mov	ch,%3	; 左上行
	mov	cl,%4	; 左上列
	mov	dh,%5	; 右下行
	mov	dl,%6	; 右下列
	int	10h
%endmacro
%macro	setcur	3
; 设定光标位置
	mov	ah,02h
	mov	bh,%1	; 页
	mov	dh,%2	; 行
	mov	dl,%3	; 列
	int	10h
%endmacro
filetypeseg		equ		0be0h
dataseg			equ		800h
numsector		equ		18
numheader		equ		1
numcyline		equ		10

FILE_INFO		equ		20h
DIR_INFO		equ		10h
start:
	mov	ax,cs
	mov	ds,ax
	
	mov	ah,09h
	int	36h	; 获取当前读取的驱动器
	mov	[drivetemp],al	; 将驱动器号存储到drivetemp里 
map:
	mov	al,[linenum]
	push	ax
	mov	al,[linenum+1]
	push	ax
	mov	al,[linenum+2]
	push	ax
	mov	al,[linenum+3]
	push	ax
	mov	al,[listnum]
	push	ax
	
	mov	dword[linenum],0x03030303		; 初始化行数
	mov	byte[filedelnum],0	; 初始化删除文件的数量
	
	; 画出布局
	paint	0,[bgcolor],0,0,24,79
	paint	0,[ftcolor],3,1,23,18
	paint	0,[ftcolor],3,20,23,38
	paint	0,[ftcolor],3,40,23,58
	paint	0,[ftcolor],3,60,23,78
	paint	0,[ftcolor],1,1,1,78
	paint	0,[bgcolor],2,1,2,78
	setcur	0,0,27
	mov	si,topput 
	mov	ah,01h
	int	36h
	setcur	0,2,1
	mov	si,topput2
	mov	ah,01h
	int	36h
	mov	ax,[fileinfoseg]
	mov	es,ax

	mov	byte[listnum],0
try:
	mov	al,[es:11]	; 判断属性
	cmp	al,FILE_INFO
	je	.filelist
	cmp	al,DIR_INFO
	je	.dirlist
.filelist:	; 如果是文件
	mov	bl,[listnum]
	mov	bh,0
	setcur	0,byte[linenum+bx],byte[listarrays+bx]
	jmp	.ok
.dirlist:	; 如果是目录
	setcur	0,byte[linenum+3],byte[listarrays+3]
	mov	si,dirput
	mov	ah,01h
	int	36h
	setcur	0,byte[linenum+3],byte[listarrays+3]
	mov	byte[listnum],3
.ok:
	mov	cx,11
	mov	si,0
.put:
	mov	al,[es:si]
	cmp	al,0	; 检测文件名是否打印完毕？
	je	.putok
	cmp	al,0xe5		; 检测文件是否被删除？
	je	.delete
.loopput:
	mov	ah,0eh
	int	10h
	inc	si
	loop	.put
	mov	bl,byte[listnum]
	mov	bh,0
	inc	byte[linenum+bx]
	cmp	byte[linenum+bx],25	; 打印满了一列
	je	.nextlist
	mov	ax,es	; 下一个文件的打印
	add	ax,2h
	mov	es,ax
	jmp	try
.nextlist:
	inc	byte[listnum]
	jmp	try
.delete:
	inc	byte[filedelnum]
	mov	al,[linenum]
	mov	byte[filedelline],al
	mov	ax,es
	add	ax,2h
	mov	es,ax
	jmp	try
.putok:
	setcur	0,1,[aboutput+6]
	mov	si,aboutput
	mov	ah,01h
	int	36h
	setcur	0,1,[newput+5]
	mov	si,newput
	mov	ah,01h
	int	36h
	setcur	0,1,[driveput+6]
	mov	si,driveput
	mov	ah,01h
	int	36h
	setcur	0,1,[exitput+5]
	mov	si,exitput
	mov	ah,01h
	int	36h
	pop	ax
	mov	[listnum],al
	pop	ax
	mov	[linenum+3],al
	pop	ax
	mov	[linenum+2],al
	pop	ax
	mov	[linenum+1],al
	pop	ax
	mov	[linenum],al
	mov	bl,[listnum]
	mov	bh,0
	setcur	0,[linenum],[listarrays+bx]

usrinput:
	mov	ah,00h
	int	16h
	cmp	ah,48h	; 上
	je	.up
	cmp	ah,50h	; 下
	je	.down
	cmp	ah,4bh
	je	.left3
	cmp	ah,4dh
	je	.right3
	cmp	al,1bh
	je	.esc	; ESC键
	cmp	al,0dh
	je	.enter
	jmp	usrinput
.up:
	cmp	byte[linenum],3
	je	usrinput
	dec	byte[linenum]
	mov	bl,[listnum]
	mov	bh,0
	setcur	0,[linenum],[listarrays+bx]
	jmp	usrinput
.down:
	cmp	byte[linenum],23
	je	usrinput
	inc	byte[linenum]
	mov	bl,[listnum]
	mov	bh,0
	setcur	0,[linenum],[listarrays+bx]
	jmp	usrinput
.left3:
	cmp	byte[listnum],0
	je	usrinput
	dec	byte[listnum]
	mov	bl,[listnum]
	mov	bh,0
	setcur	0,[linenum],[listarrays+bx]
	jmp	usrinput
.right3:
	cmp	byte[listnum],3
	je	usrinput
	inc	byte[listnum]
	mov	bl,[listnum]
	mov	bh,0
	setcur	0,[linenum],[listarrays+bx]
	jmp	usrinput
.esc:
	setcur	0,1,[meunnum]
.in3:
	mov	ah,00h
	int	16h
	cmp	ah,4bh
	je	.left2
	cmp	ah,4dh
	je	.right2
	cmp	al,1bh
	je	map
	cmp	al,0dh
	je	.enter3
	jmp	.in3
.left2:
	mov	ah,[aboutput+6]
	cmp	byte[meunnum],ah
	je	.in3
	sub	byte[meunnum],7
	jmp	.putcmp2
.right2:
	mov	ah,[exitput+5]
	cmp	byte[meunnum],ah
	je	.in3
	add	byte[meunnum],7
	jmp	.putcmp2
.putcmp2:
	paint	0,70h,24,0,24,79
	setcur	0,24,1
	 
	mov	ah,[aboutput+6]
	cmp	byte[meunnum],ah
	je	.putaboutmore
	mov	ah,[newput+5]
	cmp	byte[meunnum],ah
	je	.putnewmore
	mov	ah,[driveput+6]
	cmp	byte[meunnum],ah
	je	.putdrivemore
	mov	ah,[exitput+5]
	cmp	byte[meunnum],ah
	je	.putexitmore
	jmp	.esc
.putaboutmore:
	mov	si,aboutmore
	mov	ah,01h
	int	36h
	jmp	.esc
.putnewmore:
	mov	si,newmore
	mov	ah,01h
	int	36h
	jmp	.esc
.putdrivemore:
	mov	si,drivemore
	mov	ah,01h
	int	36h
	jmp	.esc
.putexitmore:
	mov	si,exitmore
	mov	ah,01h
	int	36h
	jmp	.esc
.enter3:
	mov	ah,[aboutput+6]
	mov	al,[meunnum]
	cmp	ah,al
	je	about
	mov	ah,[newput+5]
	cmp	ah,al
	je	newfile
	mov	ah,[driveput+6]
	cmp	ah,al
	je	drive
	mov	ah,[exitput+5]
	cmp	ah,al
	je	.retf
.enter:
	mov	bx,[fileinfoseg]
	mov	al,[linenum]
	mov	ah,[filedelnum]
	mov	cl,[filedelline]	; 删除文件的行
	cmp	al,cl	; 如果浏览文件的行小于被删除文件的行
	jb	.none	; 就不做任何动作
	add	al,ah	; 不然就还要加上被删除的文件数量
.none:
	sub	al,3	; 根据行数确定文件位置
	mov	cl,2h
	mul	cl
	add	ax,bx
	push	ax
	mov	al,[listnum]
	mov	cl,21	; 1列21个文件
	mul	cl
	mov	bx,ax
	pop	ax
	add	ax,bx
	mov	es,ax
	mov	al,[es:0]
	cmp	al,0		; 检测此位置是否无文件
	je	usrinput
	paint	0,[bgcolor],8,20,16,59	; 对话框[=]
	paint	0,[ftcolor],9,21,15,58
	setcur	0,10,22
	mov	si,fileoptions
	mov	ah,01h
	int	36h
	mov	si,0
	mov	cx,12
	setcur	0,8,34
.put2:
	mov	al,[es:si]
	mov	ah,0eh
	int	10h
	inc	si
	loop	.put2
	setcur	0,13,[fileedit+5]
	mov	si,fileedit
	mov	ah,01h
	int	36h
	setcur	0,13,[filedel+4]
	mov	si,filedel
	mov	ah,01h
	int	36h
	setcur	0,13,[filecancel+7]
	mov	si,filecancel
	mov	ah,01h
	int	36h
.cmpokjmp:
	setcur	0,13,[options]
.in2:
	mov	ah,00h
	int	16h
	cmp	ah,4bh	; 左
	je	.left
	cmp	ah,4dh	; 右
	je	.right
	cmp	al,0dh
	je	.enter2
	jmp	.in2
.right:
	mov	ah,[filecancel+7]
	cmp	byte[options],ah
	je	.in2
	add	byte[options],10
	jmp	.putcmp
.left:
	mov	ah,[fileedit+5]
	cmp	byte[options],ah
	je	.in2
	sub	byte[options],10
	jmp	.putcmp
.putcmp:
	paint	0,[bgcolor],24,0,24,79
	setcur	0,24,1
	mov	ah,[fileedit+5]
	cmp	byte[options],ah
	je	.puteditmore
	mov	ah,[filedel+4]
	cmp	byte[options],ah
	je	.putdelmore
	mov	ah,[filecancel+7]
	cmp	byte[options],ah
	je	.putcancelmore
.puteditmore:
	mov	si,editmore
	mov	ah,01h
	int	36h
	jmp	.cmpokjmp
.putdelmore:
	mov	si,delmore
	mov	ah,01h
	int	36h
	jmp	.cmpokjmp
.putcancelmore:
	mov	si,cancelmore
	mov	ah,01h
	int	36h
	jmp	.cmpokjmp
.enter2:
	mov	ah,[fileedit+5]
	cmp	byte[options],ah
	je	edit
	mov	ah,[filedel+4]
	cmp	byte[options],ah
	je	del
	mov	ah,[filecancel+7]
	cmp	byte[options],ah
	je	map
.retf:
	call	diskrest
	mov	ah,00h
	mov	al,03h
	int	10h
	mov	ah,02h
	int	36h
	mov	ah,03h	; 返回DOS系统
	int	36h

edit:
	mov	ax,es
	add	ax,1h
	mov	es,ax
	push	es
	mov	cl,[es:12]	; 文件的长度
	mov	ch,[es:13]
	push	cx		; （长度）存起来
	mov	cx,[es:10]	; 簇信息
	mov	ax,0
.mul:
	add	ax,20h		; 20h = 1簇 = 1扇区
	loop	.mul
	add	ax,filetypeseg
	mov	es,ax
	mov	si,0
	paint	0,[bgcolor],0,0,24,79
	paint	0,[ftcolor],1,1,23,78
	setcur	0,1,1
	pop	cx	; 取出（长度）
	cmp	cx,0
	je	.zero
.put:
	mov	al,[es:si]
	cmp	al,0dh
	je	.nextline
	 
	mov	ah,0eh
	int	10h
	inc	si
	loop	.put
	;push	si
.zero:
	push	si	; 在上面写会导致程序起飞
	mov	si,0	; SI记录输入的信息长度
	setcur	0,1,1
.in:
	mov	ah,00h
	int	16h
	cmp	al,0dh	; 换行需要特殊处理
	je	.enter
	cmp	al,1bh	; ESC键代表结束标志
	je	.ret
	mov	ah,0eh
	int	10h
	cmp	al,08h
	je	.backspace
	mov	byte[es:si],al
	inc	si
	jmp	.in
.enter:
	mov	ah,0eh
	mov	al,0dh
	int	10h
	mov	al,0ah
	int	10h
	mov	al,20h
	int	10h
	mov	word[es:si],0a0dh	; 0dh,0ah 代表换行
	add	si,2
	jmp	.in
.backspace:
	dec	si
	mov	ah,0eh
	mov	al,20h
	int	10h
	mov	al,08h
	int	10h
	mov	byte[es:si],0
	jmp	.in
.ret:
	mov	di,si
	pop	si
	pop	es
	cmp	si,0
	je	.di
	cmp	di,si
	jbe	.si
.di:
	mov	[es:12],di	; 文件新长度
	jmp	map
.si:
	mov	[es:12],si	; 文件旧长度
	jmp	map
.nextline:
	mov	al,0dh
	int	10h
	mov	al,0ah
	int	10h
	mov	al,20h
	int	10h
	add	si,2
	jmp	.put

del:
	mov	byte[es:0],0xe5	; 0xe5 代表删除
	inc	byte[filedelnum]	; 往文件删除数量里+1
	mov	ah,[linenum]
	mov	al,[filedelline]
	cmp	al,0
	je	.move
	cmp	al,ah
	jb	.move
	jmp	map
.move:
	mov	[filedelline],ah
	jmp	map

newfile:
	paint	0,[bgcolor],11,26,13,53	; 对话框 [=]
	paint	0,[ftcolor],12,27,12,52
	setcur	0,11,33
	mov	si,filenews
	mov	ah,01h
	int	36h
	setcur	0,12,27
	mov	si,0
.inloop:
	mov	ah,00h
	int	16h
	mov	ah,0eh
	int	10h
	cmp	al,08h
	je	.backspace
	cmp	al,0dh
	je	.enter
	and	al,11011111b	; 小写化大写
	mov	byte[filename+si],al
	inc	si
	jmp	.inloop
.backspace:		; 对退格键的特殊处理
	dec	si
	mov	ah,0eh
	mov	al,20h
	int	10h
	mov	al,08h
	int	10h
	mov	byte[filename+si],' '
	jmp	.inloop
.enter:
	; 这里和DOS的mkfile特别像
	mov	ax,[fileinfoseg]
	mov	es,ax
.find:
	mov	al,[es:0]
	cmp	al,0
	je	.create
	cmp	al,0xe5
	je	.create
	mov	ax,es
	add	ax,2h
	mov	es,ax
	jmp	.find
.create:
	mov	cx,8	; 文件名长度
	mov	si,0
.putloop:
	mov	al,[filename+si]
	mov	byte[es:si],al
	inc	si
	loop	.putloop
	mov	byte[es:8],' '
	mov	byte[es:9],' '
	mov	byte[es:10],' '
	mov	byte[es:11],' '
	mov	ax,es
	add	ax,1h
	mov	es,ax
	push	es
	sub	ax,2h
	mov	es,ax
	mov	ah,[es:10]	; 得到上一个文件的簇信息
	mov	cl,[es:12]
	mov	ch,[es:13]
	mov	al,1
.div:
	cmp	cx,200h
	jb	.divok
	sub	cx,200h
	inc	al
	jmp	.div
.divok:
	add	ah,al
	pop	es
	mov	byte[es:10],ah
	jmp	map

about:
	paint	0,[bgcolor],11,20,14,59
	paint	0,[ftcolor],12,21,13,58
	setcur	0,11,28
	mov	si,abouttop
	mov	ah,01h
	int	36h
	setcur	0,12,21
	mov	si,topput
	mov	ah,01h
	int	36h
	setcur	0,13,21
	mov	si,copyright
	mov	ah,01h
	int	36h
.loop:
	mov	ah,00h
	int	16h
	cmp	al,0dh
	je	map
	jmp	.loop

drive:
	paint	0,[bgcolor],11,26,13,52	; 对话框 [=]
	paint	0,[ftcolor],12,27,12,51
	setcur	0,11,30
	mov	ah,01h
	mov	si,drivemsg
	int	36h
	setcur	0,12,27
	mov	ah,01h
	mov	si,drivechoose
	int	36h
.choose:
	setcur	0,12,[drivechoose+26]
	mov	ah,0
	int	16h
	cmp	ah,4bh
	je	.left
	cmp	ah,4dh
	je	.right
	cmp	al,0dh
	je	.enter
	jmp	.choose
.left:
	cmp	byte[drivechoose+26],27
	je	.choose
	sub	byte[drivechoose+26],2
	jmp	.choose
.right:
	cmp	byte[drivechoose+26],51
	je	.choose
	add	byte[drivechoose+26],2
	jmp	.choose
.enter:
	mov	al,[drivechoose+26]
	sub	al,27
	mov	ah,0
	mov	bl,2
	div	bl
	add	al,41h	; 选择的驱动器号=(drivechoose-27)/2+0x41(字符A)
	cmp	al,'C'	; C盘D盘等
	jae	.hard
	cmp	al,'A'	; A盘或B盘
	jae	.floppy
.floppy:
	sub	al,'A'
	jmp	.ok
.hard:
	sub	al,'C'
	add	al,80h
.ok:
	push	ax
	mov	dl,al
	mov	ah,01h
	int	13h	; 检测磁盘状态 确保无错
	cmp	al,0
	jne	.error
	pop	ax
	mov	[drivetemp],al
	call	restread
.over:
	jmp	map
.error:	; 驱动器有错或不存在
	setcur	0,12,27
	mov	ah,01h
	mov	si,drivenot
	int	36h
.in:	; 输入enter结束
	mov	ah,0
	int	16h
	cmp	al,0dh
	je	.over
	jmp	.in

diskrest:
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
	mov	ax,dataseg	; 启动时读入的数据地址
	mov	es,ax
.write:
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
	
	mov	byte[sector],1	; 读完后全部还原（必须）
	mov	byte[header],0
	mov	byte[cyline],0
	ret

write1sector:
	mov	di,0
.retry:
	mov	ah,03h
	mov	al,1
	mov	bx,0	; ES:BX = ????:0
	mov	dl,[drivetemp]
	int	13h
	jnc	.ok		; 未出错就跳转
	inc	di
	mov	ah,00h
	mov	dl,[drivetemp]
	int	13h
	cmp	di,5	; 写5次依然出错就放弃
	jne	.retry

	jmp	$
.ok:
	ret

read1sector:
	mov	di,0
.retry:
	mov	ah,02h
	mov	al,1
	mov	bx,0	; ES:BX = ????:0
	mov	dl,[drivetemp]
	int	13h
	jnc	.ok		; 未出错就跳转
	inc	di
	mov	ah,00h
	mov	dl,[drivetemp]
	int	13h
	cmp	di,5	; 读5次依然出错就放弃
	jne	.retry

	jmp	$
.ok:
	ret

fileinfoseg	dw	0a60h
topput		db	'Powerint Shell Version 1.06',0
topput2		db	'File List 1        File List 2         File List 3         <DIR> List',0
listarrays	db	1,20,40,60
dirput		db	'           <DIR>',0
exitput		db	'EXIT',0,22
exitmore	db	'Return to DOS mode.',0
newput		db	'NEWS',0,15
newmore		db	'Create a new file or a new dir.',0
driveput	db	'DRIVE',0,8
drivemore	db	'Switch the drive management file.',0
drivemsg	db	'Choose drive letter',0
drivenot	db	'Drive is not ready.',0
drivechoose	db	'A B C D E F G H I J K L M',0,27
aboutput	db	'ABOUT',0,1
aboutmore	db	'About this shell',27h,'s infomations.',0
filenews	db	'Input New Name',0
filename	db	'        '	; 文件名最多8字节
abouttop	db	'About Powerint Shell',0
copyright	db	'Copyright (C) 2021 zhouzhihao.',0
drivetemp	db	0
fileoptions	db	'File Options:',0
fileedit	db	'EDIT',0,26
editmore	db	'Open and edit this file from scratch.',0
filedel		db	'DEL',0,36
delmore		db	'Delete this file form this disk.',0
filecancel	db	'CANCEL',0,46
cancelmore	db	'Don',27h,'t do any things for this file.',0
filedelnum	db	0			; 文件被删除的数量
filedelline	db	0			; 删除文件的行
linenum		db	3,3,3,3		; 光标指向文件的行
listnum		db	0			; 光标指向文件的列
options		db	26			; 光标指向选项的列
meunnum		db	1			; 光标指向菜单的列
bgcolor		db	0x70
ftcolor		db	0x07
sector		db	1
header		db	0
cyline		db	0