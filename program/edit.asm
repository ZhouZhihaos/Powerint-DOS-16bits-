; edit.asm
; Copyright (C) zhouzhihao 2021
db	'POWERBINHEAD'
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
%macro	curchar	1
; 读取光标位置的字符
	mov	ah,08h
	mov	bh,%1
	int	10h
%endmacro
numsector		equ		18
numheader		equ		1
numcyline		equ		10
dataseg			equ		800h
start:
	mov	ax,cs
	mov	ds,ax
	
	mov	ah,09h
	int	36h	; 获取当前读取的驱动器
	mov	[drivetemp],al	; 将驱动器号存储到drivetemp里 

inputfilename:	; 输入文件名
	mov	ah,02h
	int	36h
	mov	ah,01h
	mov	si,createnterput
	int	36h
	paint	0,70h,10,31,12,47
	paint	0,07h,11,32,11,46
	setcur	0,10,32
	mov	si,inputfilenameput
	mov	ah,01h
	int	36h

	setcur	0,11,32
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
.enter:		; 转换文件名
	push	si
	paint	0,70h,0,0,24,79
	paint	0,07h,2,1,23,78
	setcur	0,0,27
	mov	si,versionput
	mov	ah,01h
	int	36h
	pop	si
	cmp	si,0
	je	untitled
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
	
	cmp	dx,0	; dx=0 or bx=0 都是没找到的标志
	je	notfind
	
	setcur	0,1,35	; 打印标题文件名
	mov	ah,01h
	mov	si,findfilename1
	int	36h
	
	mov	[filesegment],dx	; 这个赋值是关键
	mov	[fileinfosegment2],bx
	
	add	bx,1h
	mov	es,bx
	push	es	; 文件信息地址 保存方便更改完文件后写入新的文件长度
	mov	cx,[es:12]
	cmp	cx,0	; 长度大小为0 直接开始编辑
	je	editfile
	mov	es,dx
	mov	si,0

untitled:
	mov	si,mkuntitled
	mov	ah,08h
	int	36h	; 创建一个临时的untitled.txt
	setcur	0,1,35
	mov	ah,01h
	mov	si,untitledput
	int	36h
	
	mov	byte[untitledflags],1
	call	editfile
	
	paint	0,70h,10,31,12,47
	paint	0,07h,11,32,11,46
	
	setcur	0,10,32
	mov	ah,01h
	mov	si,saveuntitled
	int	36h
	
	setcur	0,11,32
	mov	si,20
.usrinput:
	mov	ah,0
	int	16h
	cmp	al,0dh
	je	.enter
	cmp	al,08h
	je	.backspace
	cmp	si,35
	je	.usrinput
	mov	ah,0eh
	int	10h
	mov	[mkfilename+si],al
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
	mov	byte[mkfilename+si],0
	jmp	.usrinput
.enter:		; 转换文件名
	mov	si,mkfilename
	mov	ah,08h
	int	36h
	
	jmp	exit

putfile:
	add	byte[col],1	; 因为版面问题 需要给[col]加1
	add	byte[line],2	; 同样的问题
	setcur	0,byte[line],byte[col]
	sub	byte[col],1
	sub	byte[line],2
	
	mov	al,[es:si]
	mov	ah,0eh
	int	10h
	cmp	al,0dh	; 回行的时候需要清空[col]
	je	.space
	cmp	al,0ah	; 换行的时候需要增加[line]
	je	.nextline
	inc	byte[col]	; 每打印一个字符[col]就给[col]加1
	cmp	byte[col],78
	je	.nextline
	jmp	.next
.space:
	mov	bl,[line]
	mov	bh,0
	mov	al,[col]
	mov	[colarrays+bx],al	; 记录这一行的col数放入[colarrays+[line]]中
	mov	byte[col],0
	jmp	.next
.nextline:
	inc	byte[line]
	jmp	.next
.next:
	inc	si
	loop	putfile
	mov	al,[line]
	mov	[maxline],al	; 修改[maxline]=[line]
	
	; 清空[line]和[col]
	mov	byte[line],0
	mov	byte[col],0

editfile:
	call	putlinecol
	add	byte[col],1
	add	byte[line],2
	setcur	0,byte[line],byte[col]
	sub	byte[col],1
	sub	byte[line],2
	cmp	byte[col],78	; col最大限度
	je	.nextline
	mov	ah,0
	int	16h
	cmp	ah,48h
	je	.decline	; 上
	cmp	ah,4bh
	je	.left		; 左
	cmp	ah,4dh
	je	.right		; 右
	cmp	ah,50h
	je	.down		; 下
	cmp	al,1bh	; ESC退出编辑
	je	.ok
	cmp	byte[line],20	; line最大限度
	je	editfile
	mov	ah,0eh
	int	10h
	cmp	al,0dh	; 回车换行
	je	.nextline
	cmp	al,08h	; 退格
	je	.backspace
	inc	byte[col]
	jmp	editfile
.left:	; 处理左键
	cmp	byte[col],0
	je	editfile
	dec	byte[col]
	jmp	editfile
.right:	; 处理右键
	mov	bl,[line]
	mov	bh,0
	mov	al,[col]
	cmp	al,byte[colarrays+bx]
	je	editfile
	inc	byte[col]
	jmp	editfile
.down:	; 处理下键
	mov	al,[line]
	cmp	al,byte[maxline]
	je	editfile
	inc	byte[line]
	mov	bl,[line]
	mov	bh,0
	mov	al,[col]
	cmp	al,byte[colarrays+bx]
	ja	.downtoend
	jmp	editfile
.downtoend:
	mov	al,[colarrays+bx]
	mov	[col],al
	jmp	editfile
.nextline:	; 处理回车换行
	mov	bl,[line]
	mov	bh,0
	mov	al,[col]
	cmp	al,byte[colarrays+bx]
	ja	.colarraysal
.contiune:
	inc	byte[line]
	mov	byte[col],0
	mov	al,[line]
	cmp	al,byte[maxline]	; line比maxline大 将maxline替换为line
	ja	.maxlineal
	jmp	editfile
.colarraysal:
	mov	[colarrays+bx],al
	jmp	.contiune
.maxlineal:
	mov	[maxline],al
	jmp	editfile
.backspace:	; 处理退格
	cmp	byte[col],0
	je	.decline
	jmp	.deccol
.decline:
	cmp	byte[line],0
	je	editfile
	dec	byte[line]
	jmp	editfile
.deccol:
	dec	byte[col]
	mov	ah,0eh
	mov	al,20h
	int	10h
	mov	al,08h
	int	10h
	jmp	editfile
.ok:	; 结束编辑
	mov	cl,[maxline]
	mov	ch,0
	mov	bx,0
	mov	byte[line],0
	
	cmp	byte[untitledflags],1
	jne	.next
	push	cx
	push	bx
	mov	ah,[fileinfosegment]
	mov	al,[fileinfosegment+1]
	mov	es,ax
	mov	si,untitledname
	mov	ah,06h	; 寻找UNTITLE.TXT
	int	36h
	mov	es,dx
	mov	[fileinfosegment2],bx
	mov	si,0
	pop	bx
	pop	cx
	jmp	loopcurchar
.next:
	mov	ah,[filesegment+1]
	mov	al,[filesegment]
	mov	es,ax
	mov	si,0

loopcurchar:	; 将屏幕上的内容记录到文件里
	push	cx
	mov	cl,[colarrays+bx]
	mov	ch,0
	add	[filelength],cx	; 计算文件长度
	add	word[filelength],2	; 回车也得算进去 2字节大小
	mov	byte[col],0
.loopcurchar2:
	add	byte[line],2
	add	byte[col],1
	setcur	0,byte[line],byte[col]
	sub	byte[line],2
	sub	byte[col],1
	curchar	0
	mov	[es:si],al
	inc	si
	inc	byte[col]
	loop	.loopcurchar2
	pop	cx
	mov	byte[es:si],0dh
	mov	byte[es:si+1],0ah
	add	si,2
	inc	bx
	inc	byte[line]
	loop	loopcurchar
	
	mov	ax,[fileinfosegment2]
	mov	es,ax	; 取出文件信息地址 写入新长度
	mov	ax,[filelength]
	mov	[es:12],ax
		
	cmp	byte[untitledflags],1
	jne	exit
	ret

exit:
	call	diskrest
	
	mov	ah,0
	mov	al,03h
	int	10h
	mov	ah,02h
	int	36h
	
	mov	ah,03h
	int	36h

putlinecol:
	mov	al,[pagex]
	shr	al,4
	call	numtoASCII
	mov	[linecolput+5],al
	
	mov	al,[pagex]
	and	al,0fh
	call	numtoASCII
	mov	[linecolput+6],al
	
	mov	al,[line]
	shr	al,4
	call	numtoASCII
	mov	[linecolput+16],al
	
	mov	al,[line]
	and	al,0fh
	call	numtoASCII
	mov	[linecolput+17],al
	
	mov	al,[col]
	shr	al,4
	call	numtoASCII
	mov	[linecolput+26],al

	mov	al,[col]
	and	al,0fh
	call	numtoASCII
	mov	[linecolput+27],al
	
	setcur	0,24,47
	mov	si,linecolput
	mov	ah,01h
	int	36h
	ret

numtoASCII:
; 16进制数字转化成ASCII码
; 寄存器：in:AL out:AL
	cmp	al,9
	jg	.letter
	add	al,30h
	ret
.letter:
	add	al,37h
	ret

notfind:	; 没找到文件的情况
	paint	0,70h,9,26,14,52
	setcur	0,9,34
	mov	si,errortopput
	mov	ah,01h
	int	36h
	
	setcur	0,11,30
	mov	si,notfindfile
	mov	ah,01h
	int	36h
	
	setcur	0,13,33
	paint	0,07h,13,32,13,35
	mov	si,OKoption
	mov	ah,01h
	int	36h

	setcur	0,13,40
	paint	0,07h,13,39,13,46
	mov	si,CANCELoption
	mov	ah,01h
	int	36h
.try:
	jmp	short .codestart
	db	33
.codestart:		; 给用户的选择
	setcur	0,13,byte[.try+2]
	mov	ah,0
	int	16h
	cmp	al,0dh
	je	.enter
	cmp	ah,4dh
	je	.right
	cmp	ah,4bh
	je	.left
	jmp	.try
.right:
	mov	byte[.try+2],40
	jmp	.codestart
.left:
	mov	byte[.try+2],33
	jmp	.codestart
.enter:
	cmp	byte[.try+2],33
	je	inputfilename	; 用户选择重新输入 那么跳回inputfilename
	mov	ah,0
	mov	al,03h
	int	10h
	mov	ah,02h
	int	36h
	mov	ah,03h
	int	36h

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
	cmp	byte[cyline],numcyline+1
	jne	.write
	
	mov	byte[sector],1	; 写读完后全部还原（必须）
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

drivetemp			db	0
fileinfosegment		db	0ah,60h
createnterput		db	'Enter to creat a new file',0
inputfilenameput	db	'Input File name',0
findfilename1		times	15	db	0
findfilename2		db	'        ','   ',20h
filesegment			dw	0
fileinfosegment2	dw	0
untitledput			db	'UNTITLED',0
versionput			db	'Powerint Edit Version 1.01',0
errortopput			db	'   ERROR   ',0
notfindfile			db	'Could',27h,'nt Find File.',0
OKoption			db	'OK',0
CANCELoption		db	'CANCEL',0
line				db	0
col					db	0
pagex				db	0
linecolput			db	'Page:      Line:      Col:      ',0
maxline				db	0
colarrays			times	255	db	0
filelength			dw	0
escexitput			db	'ESC = Save & Exit',0
saveuntitled		db	'Save File name',0
mkuntitled			db	'mkfile untitled.txt',0
untitledname		db	'UNTITLEDTXT',20h
mkfilename:
	db	'rename untitled.txt '
	times	15	db	0
untitledflags		db	0
sector				db	1
header				db	0
cyline				db	0