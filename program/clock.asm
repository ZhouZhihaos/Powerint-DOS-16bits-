; clock.asm
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
start:
	mov	ax,cs
	mov	ds,ax
	
	; 初始化所有重要变量
	mov	cx,39
	xor	si,si
.fillloop:
	mov	byte[schedule2+si],' '
	inc	si
	loop	.fillloop
	mov	byte[todayy],2
	mov	byte[todayx1],0
	mov	byte[todayx2],0

	mov	cx,2607h	; 无形光标（2607H）
	mov	ah,01h
	int	10h	; 隐藏光标
	
	mov	si,timetemp
	mov	ah,04h	; 获取当前时间
	int	36h
	
	mov	si,datetemp
	mov	ah,05h	; 获取当前日期
	int	36h
	
	call	datetempcpy	; 在转换成16进制数前复制
	
	; datetemp中BCD码转16进制数
	mov	al,[datetemp]
	call	BCD2HEX
	mov	[datetemp],al
	mov	al,[datetemp+1]
	call	BCD2HEX
	mov	[datetemp+1],al
	mov	al,[datetemp+2]
	call	BCD2HEX
	mov	[datetemp+2],al
	mov	al,[datetemp+3]
	call	BCD2HEX
	mov	[datetemp+3],al
	
	; 初始化界面
	paint	0,70h,0,0,24,79
	paint	0,07h,1,1,10,42
	paint	0,07h,1,45,10,78
	paint	0,07h,12,1,23,78
	setcur	0,0,1
	mov	si,scheduleput
	mov	ah,01h
	int	36h
	setcur	0,0,45
	mov	si,clockput
	mov	ah,01h
	int	36h
	setcur	0,24,60
	mov	si,exitput
	mov	ah,01h
	int	36h
	
	; 打印星期日期（Schedule）
	setcur	0,1,1
	mov	si,schedule1
	mov	ah,01h
	int	36h
	setcur	0,2,1
	; 读CMOS得到1日的星期
	; 1.将日期修改为1日
	mov	al,7
	out	70h,al
	nop
	mov	al,1
	out	71h,al
	nop
	; 2.读CMOS6号单元得星期
	mov	al,6
	out	70h,al
	nop
	in	al,71h
	dec	al
	mov	bl,6
	mul	bl
	mov	bx,ax
	nop
	; 3.将日期修改回来
	mov	al,7
	out	70h,al
	nop
	mov	al,[datetemp+3]
	call	HEX2BCD
	out	71h,al
	nop
	; 判断是否为1,3,5,7,8,10,12月，2月
	; 是则打印31天 不是则打印30or29or28天
	mov	al,[datetemp+2]
	cmp	al,2	; 2月特殊情况
	je	.February
	mov	cx,7
	mov	si,0
.loop31days:
	mov	ah,[days31+si]
	cmp	al,ah
	je	.days31put
	inc	si
	loop	.loop31days
	mov	cx,30
	call	putmonthdays	; 4,6,9,11月情况
	jmp	.putsok
.days31put:
	mov	cx,31
	call	putmonthdays	; 1,3,5,7,8,10,12月的情况
	jmp	.putsok
.February:
	push	bx
	mov	al,[datetemp+1]
	mov	ah,0
	mov	bl,4
	div	bl
	pop	bx
	cmp	ah,0
	je	.days29put
	mov	cx,28
	call	putmonthdays	; 平年2月
	jmp	.putsok
.days29put:
	mov	cx,29
	call	putmonthdays	; 闰年2月
.putsok:
	setcur	0,9,18
	mov	al,[datetemp+2]
	dec	al	; 1月偏移为0
	mov	bl,4
	mul	bl
	mov	si,monthsname
	add	si,ax
	mov	ah,01h
	int	36h
	setcur	0,9,22
	mov	al,[datetemp+3]
	call	HEX2BCD
	mov	bh,al
	and	bh,0fh
	add	bh,30h
	shr	al,4
	add	al,30h
	mov	ah,0eh
	int	10h	; 十位
	mov	al,bh
	int	10h	; 个位
	
	; 打印星期日期（Schedule）部分到此结束
	; 接下来打印时间（Clock）
	setcur	0,2,45
;	call	datetempcpy
	mov	si,dateput
	mov	ah,01h
	int	36h
	setcur	0,5,45
	call	timetempcpy
	mov	si,timeput
	mov	ah,01h
	int	36h
.loop:
	; 更新时间
	call	timeputloop
	mov	ah,01h
	int	16h	; 键盘输入 但不等待
	cmp	al,1bh
	je	.loopend	; 输入ESC则结束
	jmp	.loop
.loopend:
	mov	ah,00h
	mov	al,03h
	int	10h
	setcur	0,1,0
	mov	ah,03h
	int	36h

timeputloop:
; 反复显示时间
	mov	si,timetemp
	mov	ah,04h	; 获取当前时间
	int	36h
	call	timetempcpy
	setcur	0,6,45
	mov	si,timeget
	mov	ah,01h
	int	36h
	ret

datetempcpy:
; 将datetemp中的内容转化ASCII码复制到dateput中
	mov	si,0
	mov	di,43
	mov	cx,4
.loop:
	mov	dh,[datetemp+si]
	mov	dl,[datetemp+si]
	shr	dh,4
	and	dl,0fh
	add	dh,30h
	add	dl,30h
	mov	[dateput+di],dh
	inc	di
	mov	[dateput+di],dl
	inc	si
	cmp	cx,4
	je	.inc1
	inc	di
.inc1:
	inc	di
	loop	.loop
	ret

timetempcpy:
; 将timetemp中的内容转化ASCII码复制到timeput中
	mov	si,0
	mov	di,43
	mov	cx,3
.loop:
	mov	dh,[timetemp+si]
	mov	dl,[timetemp+si]
	shr	dh,4
	and	dl,0fh
	add	dh,30h
	add	dl,30h
	mov	[timeput+di],dh
	inc	di
	mov	[timeput+di],dl
	inc	si
	add	di,2
	loop	.loop
	ret

putmonthdays:
; 按BX依次打印出31or30or29or28天（标记今天）
; IN:BX
	mov	al,[datetemp+3]	; 得到天数
	call	HEX2BCD
	mov	dl,al
	mov	dh,dl
	and	dl,0fh
	add	dl,30h	; 化成ASCII码
	shr	dh,4
	add	dh,30h
	mov	al,'1'
	mov	ah,'0'
.loop:
	cmp	cx,0
	je	.out
	mov	[schedule2+bx],ah
	mov	[schedule2+bx+1],al
	cmp	dx,ax	; 是否为今天？
	je	.today
	add	bx,6
	jmp	.next
.today:
	inc	bl
	mov	[todayx1],bl	; 给今天的X1赋值
	mov	[todayx2],bl
	dec	bl
	add	byte[todayx2],2	; 给今天的X2赋值
	push	ax
	push	bx
	push	cx
	push	dx
	; paint更改AX,BX,CX,DX 只能存起来
	paint	0,70h,byte[todayy],byte[todayx1],byte[todayy],byte[todayx2]
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	add	bx,6
	jmp	.next
.addah1:
	inc	ah	; 十位进一
	mov	al,'0'-1	; 个位置-1（因为next有inc）
	jmp	.next
.byzero:	; 当填写完一个周期后 会来到这
	push	ax
	mov	si,schedule2
	mov	ah,01h	; 打印出这个周期
	int	36h
	mov	ah,02h
	int	36h
	push	cx
	mov	cx,39
	xor	si,si
.fillloop:	; 重新将schedule2填充' '
	mov	byte[schedule2+si],' '
	inc	si
	loop	.fillloop
	pop	cx
	mov	ah,0eh
	mov	al,' '
	int	10h
	pop	ax
	inc	byte[todayy]	; 给今天的Y+1
	xor	bx,bx	; 开始下一个周期 BX置0
.next:
	cmp	al,'9'	; 判断是否要进位
	je	.addah1
	cmp	bx,36	; 判断是否填写了1个周期
	ja	.byzero
	inc	al
	dec	cx
	jmp	.loop	; 由于代码超过256字节 无法使用loop
.out:
	mov	si,schedule2
	mov	ah,01h
	int	36h
	ret

BCD2HEX:
; BCD码转换成16进制数
; IN:AL
; OUT:AL
	cmp	al,10h
	jae	.bcd
	ret
.bcd:
	push	bx
	push	ax
	mov	bl,0
.loop:
	sub	al,10h
	inc	bl
	cmp	al,10h
	jb	.ok
	jmp	.loop
.ok:
	mov	al,6
	mul	bl
	mov	bl,al
	pop	ax
	sub	al,bl
	pop	bx
	ret

HEX2BCD:
; 16进制数转换成BCD码
; IN:AL
; OUT:AL
	cmp	al,10
	jae	.bcd
	ret
.bcd:
	push	bx
	push	ax
	mov	bl,0
.loop:
	sub	al,10
	inc	bl
	cmp	al,10
	jb	.ok
	jmp	.loop
.ok:
	mov	al,6
	mul	bl
	mov	bl,al
	pop	ax
	add	al,bl
	pop	bx
	ret

datetemp		times	4	db	0	; 存放日期的临时地点
timetemp		times	3	db	0	; 存放时间的临时地点
schedule1		db	'Sun   Mon   Tue   Wed   Thu   Fri   Sat',0
schedule2		db	'                                       ',0
days31			db	1,3,5,7,8,10,12	; 为31天的月份
; 1~12月英文缩写
monthsname		db	'Jan',0,'Feb',0,'Mar',0,'Apr',0,'May',0,'Jun',0,'Jul',0,'Aug',0,'Sep',0,'Oct',0,'Nov',0,'Dec',0
dateput:
	db	'The current date is: ',0ah
	times 21 db 08h
	db	'    \  \  ',0
timeput:
	db	'The current time is: ',0ah
	times 21 db 08h
timeget:	db	'  :  :  ',0
scheduleput		db	'Schedule',0
clockput		db	'Clock',0
exitput			db	'ESC = Exit Clock',0
todayy			db	2	; 从第2行开始算起
todayx1			db	0
todayx2			db	0