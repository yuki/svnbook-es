XSLTPROC = xsltproc
INSTALL_DIR = $(DESTDIR)/usr/share/doc/subversion
INSTALL = install

## You shouldn't normally need to edit anything below here.
SHELL = /bin/sh
SVNVERSION = svnversion

BOOK_TOP = .
BOOK_HTML_CHUNK_DIR = $(BOOK_DIR)/html-chunk
BOOK_DIR = ${BOOK_TOP}/book
BOOK_HTML_TARGET = $(BOOK_DIR)/svn-book.html
BOOK_HTML_CHUNK_TARGET = $(BOOK_HTML_CHUNK_DIR)/index.html  # index.html is created last
BOOK_PDF_TARGET = $(BOOK_DIR)/svn-book.pdf
BOOK_PS_TARGET = $(BOOK_DIR)/svn-book.ps
BOOK_FO_TARGET = $(BOOK_DIR)/svn-book.fo
BOOK_XML_SOURCE = $(BOOK_DIR)/book.xml
BOOK_VERSION_SOURCE =  $(BOOK_DIR)/version.xml
BOOK_ALL_SOURCE = $(BOOK_DIR)/*.xml
BOOK_IMAGES = $(BOOK_DIR)/images/*.png
BOOK_INSTALL_DIR = $(INSTALL_DIR)/book
BOOK_ASPELL_FILES = book foreword ch00 ch01 ch04 ch08
OTHER_ASPELL_FILES = COORDINADOR glosario_traduccion LEAME TODO TRABAJO

MDOCS_DIR = ${BOOK_TOP}/misc-docs
MDOCS_HTML_TARGET = $(MDOCS_DIR)/misc-docs.html
MDOCS_PDF_TARGET = $(MDOCS_DIR)/misc-docs.pdf
MDOCS_PS_TARGET = $(MDOCS_DIR)/misc-docs.ps
MDOCS_FO_TARGET = $(MDOCS_DIR)/misc-docs.fo
MDOCS_XML_SOURCE = $(MDOCS_DIR)/misc-docs.xml
MDOCS_ALL_SOURCE = $(MDOCS_DIR)/*.xml
MDOCS_INSTALL_DIR = $(INSTALL_DIR)/misc-docs

XSL_FO = ${BOOK_TOP}/tools/fo-stylesheet.xsl
XSL_HTML = $(BOOK_TOP)/tools/html-stylesheet.xsl
XSL_HTML_CHUNK = $(BOOK_TOP)/tools/chunk-stylesheet.xsl

RUN_FOP = ${BOOK_TOP}/tools/bin/run-fop.sh

# Book xsltproc options for HTML output
# Note: --stringparam arguments no longer go here; 
# see tools/html-stylesheet.xsl and tools/chunk-stylesheet.xsl
BOOK_HTML_XSLTPROC_OPTS = 

# Book xsltproc options for PDF and PostScript output
# BOOK_PDF_XSLTPROC_OPTS = --stringparam page.height 9in --stringparam page.width 6.4in
# BOOK_PS_XSLTPROC_OPTS = --stringparam page.height 9in --stringparam page.width 6.4in

# Uncomment the following line if you'd like to print on A4 paper
# BOOK_PDF_XSLTPROC_OPTS = --stringparam paper.type A4

all: all-html #all-pdf all-ps

aspell_add_words:
	@for file in $(BOOK_ASPELL_FILES); do \
		cat book/$$file.xml |aspell list -H --lang=es |sort|uniq> tmp.txt;\
		cat book/$$file.xml.aspell_ignore >> tmp.txt;\
		sort tmp.txt|uniq> book/$$file.xml.aspell_ignore;\
		rm tmp.txt;\
		svn diff book/$$file.xml.aspell_ignore;\
	done
	@for file in $(OTHER_ASPELL_FILES); do \
		cat $$file | aspell list --mode=url --lang=es |sort|uniq> tmp.txt;\
		cat .aspell_ignore >> tmp.txt;\
		sort tmp.txt|uniq> .aspell_ignore;\
		rm tmp.txt;\
		svn diff $$file;\
	done

aspell_check:
	@for file in $(BOOK_ASPELL_FILES); do \
		touch book/$$file.xml.aspell_ignore;\
		aspell -H --lang=es create master ./book/.aspell.$$file < book/$$file.xml.aspell_ignore;\
		aspell check book/$$file.xml -H --lang=es --add-extra-dicts ./book/.aspell.$$file;\
	done
	touch .aspell_ignore
	aspell --mode=url --lang=es create master ./.aspell.master < .aspell_ignore
	@for file in $(OTHER_ASPELL_FILES); do \
		aspell check $$file --mode=url --lang=es --add-extra-dicts ./.aspell.master;\
	done



install: install-book install-misc-docs

all-html: book-html book-html-chunk #misc-docs-html

all-pdf: book-pdf misc-docs-pdf

all-ps: book-ps misc-docs-ps

all-book: book-html book-html-chunk book-pdf book-ps

install-book: install-book-html install-book-html-chunk install-book-pdf install-book-ps

all-misc-docs: misc-docs-html misc-docs-pdf book-ps

install-misc-docs: install-misc-html install-misc-pdf \
                   install-misc-ps

clean: book-clean misc-docs-clean

$(BOOK_VERSION_SOURCE): book-version

book-version:
	@if $(SVNVERSION) . > /dev/null; then \
	echo '<!ENTITY svn.version "Revision '`$(SVNVERSION) .`'">' > $(BOOK_VERSION_SOURCE).tmp; \
	else \
	echo '<!ENTITY svn.version "">' > $(BOOK_VERSION_SOURCE).tmp; \
	fi
	@if cmp -s $(BOOK_VERSION_SOURCE) $(BOOK_VERSION_SOURCE).tmp; then \
	rm $(BOOK_VERSION_SOURCE).tmp; \
	else \
	mv $(BOOK_VERSION_SOURCE).tmp $(BOOK_VERSION_SOURCE); \
	fi

book-html: $(BOOK_HTML_TARGET)

$(BOOK_HTML_TARGET): $(BOOK_ALL_SOURCE) $(BOOK_VERSION_SOURCE)
	$(XSLTPROC) $(BOOK_HTML_XSLTPROC_OPTS) \
           --output $(BOOK_HTML_TARGET) $(XSL_HTML) $(BOOK_XML_SOURCE)

book-html-chunk: $(BOOK_HTML_CHUNK_TARGET)

## This trailing slash is essential that xsltproc will output pages to the dir
$(BOOK_HTML_CHUNK_TARGET): $(BOOK_ALL_SOURCE) $(BOOK_VERSION_SOURCE) \
                           $(BOOK_DIR)/styles.css $(BOOK_IMAGES)
	mkdir -p $(BOOK_HTML_CHUNK_DIR)
	mkdir -p $(BOOK_HTML_CHUNK_DIR)/images
	$(XSLTPROC) $(BOOK_HTML_XSLTPROC_OPTS) \
           --output $(BOOK_HTML_CHUNK_DIR)/ \
	   $(XSL_HTML_CHUNK) $(BOOK_XML_SOURCE)
	cp $(BOOK_DIR)/styles.css $(BOOK_HTML_CHUNK_DIR)
	cp $(BOOK_IMAGES) $(BOOK_HTML_CHUNK_DIR)/images

book-pdf: $(BOOK_PDF_TARGET)

book-ps: $(BOOK_PS_TARGET)

$(BOOK_PDF_TARGET): $(BOOK_ALL_SOURCE) $(BOOK_VERSION_SOURCE) $(BOOK_IMAGES)
	$(XSLTPROC) $(BOOK_PDF_XSLTPROC_OPTS) \
	   --output $(BOOK_FO_TARGET) $(XSL_FO) $(BOOK_XML_SOURCE)
	$(RUN_FOP) $(BOOK_TOP) -fo $(BOOK_FO_TARGET) -pdf $(BOOK_PDF_TARGET)

$(BOOK_PS_TARGET): $(BOOK_ALL_SOURCE) $(BOOK_VERSION_SOURCE) $(BOOK_IMAGES)
	$(XSLTPROC) $(BOOK_PS_XSLTPROC_OPTS) \
	   --output $(BOOK_FO_TARGET) $(XSL_FO) $(BOOK_XML_SOURCE)
	$(RUN_FOP) $(BOOK_TOP) -fo $(BOOK_FO_TARGET) -ps $(BOOK_PS_TARGET)

$(BOOK_INSTALL_DIR):
	$(INSTALL) -d $(BOOK_INSTALL_DIR)

install-book-html: $(BOOK_HTML_TARGET)
	$(INSTALL) -d $(BOOK_INSTALL_DIR)/images
	$(INSTALL) $(BOOK_HTML_TARGET) $(BOOK_INSTALL_DIR)
	$(INSTALL) $(BOOK_DIR)/styles.css $(BOOK_INSTALL_DIR)
	$(INSTALL) $(BOOK_IMAGES) $(BOOK_INSTALL_DIR)/images

install-book-html-chunk: $(BOOK_HTML_CHUNK_TARGET)
	$(INSTALL) -d $(BOOK_INSTALL_DIR)/images
	$(INSTALL) $(BOOK_HTML_CHUNK_DIR)/*.html $(BOOK_INSTALL_DIR)
	$(INSTALL) $(BOOK_DIR)/styles.css $(BOOK_INSTALL_DIR)
	$(INSTALL) $(BOOK_IMAGES) $(BOOK_INSTALL_DIR)/images

install-book-pdf: $(BOOK_PDF_TARGET) $(BOOK_INSTALL_DIR)
	$(INSTALL) $(BOOK_PDF_TARGET) $(BOOK_INSTALL_DIR)

install-book-ps: $(BOOK_PS_TARGET) $(BOOK_INSTALL_DIR)
	$(INSTALL) $(BOOK_PS_TARGET) $(BOOK_INSTALL_DIR)

book-clean:
	rm -f $(BOOK_VERSION_SOURCE)
	rm -f $(BOOK_HTML_TARGET) $(BOOK_FO_TARGET)
	rm -rf $(BOOK_HTML_CHUNK_DIR)
	rm -f $(BOOK_PDF_TARGET) $(BOOK_PS_TARGET) 

misc-docs-html: $(MDOCS_HTML_TARGET)

$(MDOCS_HTML_TARGET): $(MDOCS_ALL_SOURCE)
	$(XSLTPROC) $(XSL_HTML) $(MDOCS_XML_SOURCE) > $(MDOCS_HTML_TARGET)

misc-docs-pdf: $(MDOCS_PDF_TARGET)

misc-docs-ps: $(MDOCS_PS_TARGET)

$(MDOCS_PDF_TARGET): $(MDOCS_ALL_SOURCE)
	$(XSLTPROC) $(XSL_FO) $(MDOCS_XML_SOURCE) > $(MDOCS_FO_TARGET)
	$(RUN_FOP) $(BOOK_TOP) -fo $(MDOCS_FO_TARGET) -pdf $(MDOCS_PDF_TARGET)

$(MDOCS_PS_TARGET): $(MDOCS_ALL_SOURCE)
	$(XSLTPROC) $(XSL_FO) $(MDOCS_XML_SOURCE) > $(MDOCS_FO_TARGET)
	$(RUN_FOP) $(BOOK_TOP) -fo $(MDOCS_FO_TARGET) -ps $(MDOCS_PS_TARGET)

misc-docs-clean:
	rm -f $(MDOCS_HTML_TARGET) $(MDOCS_FO_TARGET)
	rm -f $(MDOCS_PDF_TARGET) $(MDOCS_PS_TARGET)

$(MDOCS_INSTALL_DIR):
	$(INSTALL) -d $(MDOCS_INSTALL_DIR)

install-misc-html: $(MDOCS_HTML_TARGET) $(MDOCS_INSTALL_DIR)
	$(INSTALL) $(MDOCS_HTML_TARGET) $(MDOCS_INSTALL_DIR)

install-misc-pdf: $(MDOCS_PDF_TARGET) $(MDOCS_INSTALL_DIR)
	$(INSTALL) $(MDOCS_PDF_TARGET) $(MDOCS_INSTALL_DIR)

install-misc-ps: $(MDOCS_PS_TARGET) $(MDOCS_INSTALL_DIR)
	$(INSTALL) $(MDOCS_PS_TARGET) $(MDOCS_INSTALL_DIR)


