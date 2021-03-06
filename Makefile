.SUFFIXES: .xml .html .1.html .1 .md .dot .svg

include Makefile.configure

VERSION 	 = 0.5.9
OBJS		 = compats.o \
		   main.o \
		   compile.o \
		   linkall.o \
		   grok.o \
		   util.o \
		   atom.o \
		   article.o \
		   json.o \
		   listtags.o
SRCS		 = compats.c \
		   main.c \
		   compile.c \
		   linkall.c \
		   grok.c \
		   util.c \
		   atom.c \
		   article.c \
		   json.c \
		   listtags.c \
		   tests.c
XMLS		 = versions.xml
ATOM 		 = atom.xml
HTMLS 		 = archive.html \
		   example1.html \
		   example2.html \
		   example3.html \
		   index.html \
		   sblg.1.html
CSSS 		 = index.css
DATADIR	 	 = $(SHAREDIR)/sblg
EXAMPLEDIR	 = $(DATADIR)/examples
WWWDIR		 = /var/www/vhosts/kristaps.bsd.lv/htdocs/sblg
DOTAR 		 = Makefile \
		   $(SRCS) \
		   sblg.in.1 \
		   sblg.h \
		   schema.json \
		   extern.h
BUILT		 = index1.svg \
		   index2.svg \
		   index3.svg
IMAGES		 = template1.jpg \
		   template2.jpg \
		   template3.jpg \
		   template4.jpg \
		   template5.jpg \
		   template6.jpg

LDADD_PKG	!= pkg-config --libs expat 2>/dev/null || echo "-lexpat"
CFLAGS_PKG 	!= pkg-config --cflags expat 2>/dev/null || echo ""
LDADD		+= $(LDADD_PKG)
CFLAGS		+= $(CFLAGS_PKG)

all: sblg sblg.a sblg.1

sblg: $(OBJS)
	$(CC) -o $@ $(OBJS) $(LDFLAGS) $(LDADD)

sblg.a: $(OBJS)
	$(AR) rs $@ $(OBJS)

www: $(HTMLS) $(BUILT) $(ATOM) sblg.tar.gz sblg.tar.gz.sha512 sblg
	( cd examples/simple && $(MAKE) SBLG=../../sblg )
	( cd examples/simple-frontpage && $(MAKE) SBLG=../../sblg )
	( cd examples/retro && $(MAKE) SBLG=../../sblg )
	( cd examples/brutalist && $(MAKE) SBLG=../../sblg )
	( cd examples/photos-column && $(MAKE) SBLG=../../sblg )
	( cd examples/photos-grid && $(MAKE) SBLG=../../sblg )

sblg.1: sblg.in.1
	sed "s!@SHAREDIR@!$(DATADIR)!g" sblg.in.1 >$@

installwww: www
	mkdir -p $(WWWDIR)
	mkdir -p $(WWWDIR)/snapshots
	install -m 0444 Makefile $(BUILT) $(IMAGES) $(ATOM) $(HTMLS) $(CSSS) $(WWWDIR)
	install -m 0444 sblg.tar.gz $(WWWDIR)/snapshots/sblg-$(VERSION).tar.gz
	install -m 0444 sblg.tar.gz.sha512 $(WWWDIR)/snapshots/sblg-$(VERSION).tar.gz.sha512
	install -m 0444 sblg.tar.gz $(WWWDIR)/snapshots
	install -m 0444 sblg.tar.gz.sha512 $(WWWDIR)/snapshots
	( cd examples/simple && $(MAKE) installwww SBLG=../../sblg WWWDIR=$(WWWDIR)/examples/simple )
	( cd examples/simple-frontpage && $(MAKE) installwww SBLG=../../sblg WWWDIR=$(WWWDIR)/examples/simple-frontpage )
	( cd examples/retro && $(MAKE) installwww SBLG=../../sblg WWWDIR=$(WWWDIR)/examples/retro )
	( cd examples/brutalist && $(MAKE) installwww SBLG=../../sblg WWWDIR=$(WWWDIR)/examples/brutalist )
	( cd examples/photos-column && $(MAKE) installwww SBLG=../../sblg WWWDIR=$(WWWDIR)/examples/photos-column )
	( cd examples/photos-grid && $(MAKE) installwww SBLG=../../sblg WWWDIR=$(WWWDIR)/examples/photos-grid )

install: all
	mkdir -p $(DESTDIR)$(BINDIR)
	mkdir -p $(DESTDIR)$(DATADIR)
	mkdir -p $(DESTDIR)$(EXAMPLEDIR)/simple
	mkdir -p $(DESTDIR)$(EXAMPLEDIR)/simple-frontpage
	mkdir -p $(DESTDIR)$(EXAMPLEDIR)/retro
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	$(INSTALL_PROGRAM) sblg $(DESTDIR)$(BINDIR)
	$(INSTALL_MAN) sblg.1 $(DESTDIR)$(MANDIR)/man1
	$(INSTALL_DATA) schema.json $(DESTDIR)$(DATADIR)
	( cd examples/simple && $(MAKE) install PREFIX=$(DESTDIR)$(EXAMPLEDIR)/simple )
	( cd examples/simple-frontpage && $(MAKE) install PREFIX=$(DESTDIR)$(EXAMPLEDIR)/simple-frontpage )
	( cd examples/retro && $(MAKE) install PREFIX=$(DESTDIR)$(EXAMPLEDIR)/retro )
	( cd examples/brutalist && $(MAKE) install PREFIX=$(DESTDIR)$(EXAMPLEDIR)/brutalist )
	( cd examples/photos-column && $(MAKE) install PREFIX=$(DESTDIR)$(EXAMPLEDIR)/photos-column )
	( cd examples/photos-grid && $(MAKE) install PREFIX=$(DESTDIR)$(EXAMPLEDIR)/photos-grid )

sblg.tar.gz:
	mkdir -p .dist/sblg-$(VERSION)/
	install -m 0644 $(DOTAR) .dist/sblg-$(VERSION)
	install -m 0755 configure .dist/sblg-$(VERSION)
	mkdir -p .dist/sblg-$(VERSION)/examples/retro
	mkdir -p .dist/sblg-$(VERSION)/examples/brutalist
	mkdir -p .dist/sblg-$(VERSION)/examples/photos-column
	mkdir -p .dist/sblg-$(VERSION)/examples/photos-grid
	mkdir -p .dist/sblg-$(VERSION)/examples/simple-frontpage
	( cd examples/simple && $(MAKE) install PREFIX=../../.dist/sblg-$(VERSION)/examples/simple )
	( cd examples/simple-frontpage && $(MAKE) install PREFIX=../../.dist/sblg-$(VERSION)/examples/simple-frontpage )
	( cd examples/retro && $(MAKE) install PREFIX=../../.dist/sblg-$(VERSION)/examples/retro )
	( cd examples/brutalist && $(MAKE) install PREFIX=../../.dist/sblg-$(VERSION)/examples/brutalist )
	( cd examples/photos-column && $(MAKE) install PREFIX=../../.dist/sblg-$(VERSION)/examples/photos-column )
	( cd examples/photos-grid && $(MAKE) install PREFIX=../../.dist/sblg-$(VERSION)/examples/photos-grid )
	( cd .dist/ && tar zcf ../$@ ./ )
	rm -rf .dist/

sblg.tar.gz.sha512: sblg.tar.gz
	openssl dgst -sha512 -hex sblg.tar.gz >$@

distcheck: sblg.tar.gz.sha512
	mandoc -Tlint -Werror sblg.in.1
	newest=`grep "<h1>" versions.xml | tail -1 | sed 's![ 	]*!!g'` ; \
	       [ "$$newest" = "<h1>$(VERSION)</h1>" ] || \
		{ echo "Version $(VERSION) not newest in versions.xml" 1>&2 ; exit 1 ; }
	rm -rf .distcheck
	[ "`openssl dgst -sha512 -hex sblg.tar.gz`" = "`cat sblg.tar.gz.sha512`" ] || \
 		{ echo "Checksum does not match." 1>&2 ; exit 1 ; }
	mkdir -p .distcheck
	( cd .distcheck && tar -zvxpf ../sblg.tar.gz )
	( cd .distcheck/sblg-$(VERSION) && ./configure PREFIX=prefix )
	( cd .distcheck/sblg-$(VERSION) && $(MAKE) )
	( cd .distcheck/sblg-$(VERSION) && $(MAKE) regress )
	( cd .distcheck/sblg-$(VERSION) && $(MAKE) install )
	rm -rf .distcheck

$(OBJS): sblg.h extern.h config.h version.h

atom.xml $(HTMLS): sblg

atom.xml: atom-template.xml

version.h: Makefile
	echo "#define VERSION \"$(VERSION)\"" >$@

index.html: index.xml versions.xml
	./sblg -o- -t index.xml versions.xml >$@

archive.html: archive.xml versions.xml
	./sblg -o- -t archive.xml versions.xml >$@

example1.html: example1-template.xml example1-article.xml
	./sblg -t example1-template.xml -o $@ -c example1-article.xml

example2.html: example2-template.xml example2-article1.xml example2-article2.xml
	./sblg -t example2-template.xml -o $@ example2-article1.xml example2-article2.xml

example3.html: example3-template.xml example2-article1.xml example2-article2.xml
	./sblg -t example3-template.xml -o $@ -C example2-article1.xml example2-article1.xml example2-article2.xml

atom.xml: versions.xml
	./sblg -s date -o $@ -a versions.xml

.1.1.html:
	mandoc -Ostyle=https://bsd.lv/css/mandoc.css -Thtml $< >$@

.dot.svg:
	dot -Tsvg $< | xsltproc --novalid notugly.xsl - >$@

clean:
	rm -f sblg $(ATOM) $(OBJS) $(HTMLS) $(BUILT) sblg.tar.gz sblg.tar.gz.sha512 sblg.1
	rm -f version.h
	( cd examples/simple && $(MAKE) clean )
	( cd examples/simple-frontpage && $(MAKE) clean )
	( cd examples/retro && $(MAKE) clean )
	( cd examples/brutalist && $(MAKE) clean )
	( cd examples/photos-column && $(MAKE) clean )
	( cd examples/photos-grid && $(MAKE) clean )

regress:
	# Do nothing.

distclean: clean
	rm -f Makefile.configure config.h config.log
