# Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2

all: scanner

scanner: parser.tab.c lex.yy.c main.o
	$(CC) $(CFLAGS) -o scanner parser.tab.c lex.yy.c main.o -lfl

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

lex.yy.c: scanner.l parser.tab.h
	flex scanner.l

main.o: main.c parser.tab.h
	$(CC) $(CFLAGS) -c main.c

clean:
	rm -f scanner parser.tab.c parser.tab.h lex.yy.c main.o
