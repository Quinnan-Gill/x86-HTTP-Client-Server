FILENAME=http_server

all: clean
		nasm -f elf $(FILENAME).asm
		ld -m elf_i386 $(FILENAME).o -o $(FILENAME)
		rm -f $(FILENAME).o

clean:
	rm -f $(FILENAME)