TOOLPATH = ../../tools/
OUTPATH = ../outfile/

NASM	= $(TOOLPATH)nasm.exe
MAKE	= $(TOOLPATH)make.exe -r
EDIMG	= $(TOOLPATH)edimg.exe
COPY	= copy
DEL		= del

# 默认

default:
	$(MAKE) shell.bin
	$(MAKE) clock.bin
	$(MAKE) edit.bin
	$(MAKE) bitz.bin
	$(MAKE) bmpview.bin
	$(MAKE) setup.bin
	$(MAKE) gobang.bin
	$(MAKE) mouse.bin

# 生成规则

%.bin: %.asm Makefile
	$(NASM) $*.asm -o $(OUTPATH)$*.bin
