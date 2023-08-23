
all: output
output: main.o numbers.o add.o
	gcc -m32 -g -Wall -o output main.o numbers.o add.o

main.o: main.c 
	gcc -m32 -g -Wall -c -o main.o main.c

numbers.o: numbers.c
	gcc -m32 -g -Wall -c -o numbers.o numbers.c

add.o: add.s
	nasm -g -f elf -w+all -o add.o add.s

.PHONY: clean
clean: 
	rm -f *.o *.exe

# -o output - the file created after compilation
# -O - optimize. The higher the number, the more optimized the file is
# -c - compiles the file without linking
# -f format - specifies the format of the file
# -g - adds debug information to the compiled file
# -W+all - turns on all warnings
# -Wall - turns on all warnings
# -m32 - specifies the output file format to be 32 bit