; hd.asm
; Copyright (C) zhouzhihao 2021
db	'BOOT    BIN '
dw	bootaddress
dw	bootlength

db	'LOADER  BIN '
dw	loaderaddress
dw	loaderlength

db	'COMMAND BIN '
dw	commandaddress
dw	commandlength

db	'SHELL   BIN '
dw	shelladdress
dw	shelllength

db	'CLOCK   BIN '
dw	clockaddress
dw	clocklength

db	'EDIT    BIN '
dw	editaddress
dw	editlength

db	'BITZ    BIN '
dw	bitzaddress
dw	bitzlength

db	'AUTOEXECBAT '
dw	autoexecaddress
dw	autoexeclength

db	'BMPVIEW BIN '
dw	bmpviewaddress
dw	bmpviewlength

db	'VIEW    BMP '
dw	viewaddress
dw	viewlength

bootaddress:
incbin "../outfile/boothd.bin"
bootlength		equ		$-bootaddress

loaderaddress:
incbin "../outfile/loader.bin"
loaderlength	equ		$-loaderaddress

commandaddress:
incbin "../outfile/command.bin"
commandlength	equ		$-commandaddress

shelladdress:
incbin "../outfile/shell.bin"
shelllength		equ		$-shelladdress

clockaddress:
incbin "../outfile/clock.bin"
clocklength		equ		$-clockaddress

editaddress:
incbin "../outfile/edit.bin"
editlength		equ		$-editaddress

bitzaddress:
incbin "../outfile/bitz.bin"
bitzlength		equ		$-bitzaddress

autoexecaddress:
db	'#AUTOEXEC.BAT',0dh,0ah
db	'echo Welcome to Powerint DOS 1.07c',0dh,0ah
db	'echo Copyright (C) zhouzhihao 2020-2021',0dh,0ah
db	'#Boot Program',0dh,0ah
db	'shell',0dh,0ah
autoexeclength	equ		$-autoexecaddress

bmpviewaddress:
incbin	"../outfile/bmpview.bin"
bmpviewlength	equ		$-bmpviewaddress

viewaddress:
incbin "../kernel/view.bmp"
viewlength		equ		$-viewaddress