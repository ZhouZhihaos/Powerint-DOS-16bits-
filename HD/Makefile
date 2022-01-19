TOOLPATH = ../../tools/
OUTPATH = ../outfile/

NASM	= $(TOOLPATH)nasm.exe
MAKE	= $(TOOLPATH)make.exe -r
EDIMG	= $(TOOLPATH)edimg.exe
COPY	= copy
DEL		= del

# 默认

default:
	$(MAKE) hd.pak

hd.pak : boothd.bin hd.asm Makefile
	$(NASM) hd.asm -o $(OUTPATH)hd.pak

# 生成规则

%hd.bin: %.asm Makefile
	$(NASM) $*.asm -o $(OUTPATH)$*hd.bin
