CC = gcc
STD_CFLAGS = -Wall -std=gnu99 -c -g -O3

CFLAGS = $(STD_CFLAGS) # -DDEBUG

rds_msg: rds.o rds_msg.o
	$(CC) -o rds_msg rds_msg.o rds.o -lm

rds.o: rds.c rds.h
	$(CC) $(CFLAGS) rds.c

rds_msg.o: rds_msg.c
	$(CC) $(CFLAGS) rds_msg.c

clean:
	rm -f *.o *~

