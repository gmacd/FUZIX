CC = sdcc
ASM = sdasz80
AR = sdar
LINKER = sdcc
#CC_OPT = -mz80 -c --opt-code-size --std-c89 --max-allocs-per-node 2000000 -I../../Library/include
CC_OPT = -mz80 --std-c99 -c --opt-code-size --max-allocs-per-node 20000 -I../../Library/include
#--oldralloc
ASM_OPT = -l -o -s
LINKER_OPT = --code-loc 0 -mz80 --nostdlib --no-std-crt0

.SUFFIXES: .c .rel


SRCS  = basename.c \
	bd.c \
	cal.c \
	cat.c \
	chgrp.c \
	chmod.c \
	chown.c \
	cp.c \
	cut.c \
	date.c \
	dd.c \
	df.c \
	dirname.c \
	du.c \
	echo.c \
	ed.c \
	false.c \
	fsck.c \
	grep.c \
	id.c \
	init.c \
	kill.c \
	ll.c \
	ln.c \
	ls.c \
	mkdir.c \
	mkfs.c \
	mknod.c \
	more.c \
	mount.c \
	mv.c \
	od.c \
	passwd.c \
	patchcpm.c \
	printenv.c \
	prtroot.c \
	ps.c \
	pwd.c \
	rm.c \
	rmdir.c \
	sleep.c \
	ssh.c \
	su.c \
	sync.c \
	termcap.c \
	tget.c \
	touch.c \
	tr.c \
	true.c \
	umount.c \
	uniq.c \
	uud.c \
	uue.c \
	wc.c \
	which.c \
	whoami.c

OBJS = $(SRCS:.c=.rel)

LIBS = ../../Library/libs/syslib.lib

APPS = $(OBJS:.rel=)

all: $(APPS)

$(OBJS): $(SRCS)

.c.rel:
	$(CC) $(CC_OPT) $(@:.rel=.c)

%: %.rel
	$(LINKER) $(LINKER_OPT) ../../Library/libs/crt0.rel $< $(LIBS)

clean:
	rm -f $(OBJS) $(APPS) core *~ *.asm *.lst *.sym *.map *.noi *.lk

rmbak:
	rm -f *~ core

