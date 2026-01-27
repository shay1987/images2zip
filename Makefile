PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man
DESTDIR ?=

.PHONY: install uninstall test clean

install:
	install -d $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(MANDIR)/man1
	install -m 755 bin/images2zip $(DESTDIR)$(BINDIR)/images2zip
	install -m 644 man/man1/images2zip.1 $(DESTDIR)$(MANDIR)/man1/images2zip.1

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/images2zip
	rm -f $(DESTDIR)$(MANDIR)/man1/images2zip.1

test:
	./test/run_tests.sh

clean:
	rm -rf test/tmp
