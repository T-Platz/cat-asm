CFLAGS=-g -nostdlib

.PHONY: all clean fresh

all: cat

cat: cat.S
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f cat

fresh: clean all