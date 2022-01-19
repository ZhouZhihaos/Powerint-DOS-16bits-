TOOLPATH = ../../tools/
OUTPATH = ../outfile/

NASM	= $(TOOLPATH)nasm.exe
MAKE	= $(TOOLPATH)make.exe -r
EDIMG	= $(TOOLPATH)edimg.exe
COPY	= copy
DEL		= del

# 默认

default:
	$(MAKE) index.img

index.img : boot.bin loader.bin command.bin view.bmp Makefile
	$(EDIMG) imgin:../../tools/image.tek \
		wbinimg src:$(OUTPATH)boot.bin len:512 from:0 to:0 \
		copy from:$(OUTPATH)loader.bin to:@: \
		copy from:$(OUTPATH)command.bin to:@: \
		copy from:autoexec.bat to:@: \
		copy from:$(OUTPATH)setup.bin to:@: \
		copy from:$(OUTPATH)hd.pak to:@: \
		copy from:$(OUTPATH)gobang.bin to:@: \
		copy from:$(OUTPATH)mouse.bin to:@: \
		imgout:$(OUTPATH)index.img

# 生成规则

%.bin: %.asm Makefile
	$(NASM) $*.asm -o $(OUTPATH)$*.bin
