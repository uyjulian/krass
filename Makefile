#############################################
##                                         ##
##    Copyright (C) 2020-2021 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
##   See details of license at "LICENSE"   ##
##                                         ##
#############################################

DEPENDENCY_OUTPUT_DIRECTORY := $(shell realpath build-libraries)

SOURCES += main.cpp
SOURCES += $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libass.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a
INCFLAGS += -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include
PROJECT_BASENAME = krass

RC_FILEDESCRIPTION ?= Advanced Substation Alpha renderer for TVP(KIRIKIRI) (2/Z)
RC_LEGALCOPYRIGHT ?= Copyright (C) 2020-2021 Julian Uy; This product is licensed under the MIT license.
RC_PRODUCTNAME ?= Advanced Substation Alpha renderer for TVP(KIRIKIRI) (2/Z)

include external/ncbind/Rules.lib.make

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir -p $(DEPENDENCY_OUTPUT_DIRECTORY)

external/fribidi/configure:
	cd external/fribidi && \
	git reset --hard && \
	NOCONFIGURE=1 ./autogen.sh

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a: external/fribidi/configure $(DEPENDENCY_OUTPUT_DIRECTORY)
	cd external/fribidi && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	./configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=i686-w64-mingw32 \
		--enable-static \
		--disable-shared \
		--disable-dependency-tracking \
		--disable-debug \
	&& \
	$(MAKE) && \
	$(MAKE) install

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a: $(DEPENDENCY_OUTPUT_DIRECTORY)
	cd external/freetype2 && \
	git reset --hard && \
	NOCONFIGURE=1 ./autogen.sh && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	./configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=i686-w64-mingw32 \
		--enable-static \
		--disable-shared \
		\
		--without-brotli \
		--without-zlib \
		--without-bzip2 \
		--without-png \
		--without-harfbuzz \
	&& \
	$(MAKE) && \
	$(MAKE) install

external/libass/configure:
	cd external/libass && \
	git reset --hard && \
	NOCONFIGURE=1 ./autogen.sh

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libass.a: external/libass/configure $(DEPENDENCY_OUTPUT_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a
	cd external/libass && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	./configure \
		CFLAGS="-DFRIBIDI_LIB_STATIC -O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=i686-w64-mingw32 \
		--disable-shared \
		--enable-static \
		--disable-asm \
		\
		--disable-harfbuzz \
		--disable-fontconfig \
		--disable-require-system-font-provider \
		--disable-directwrite \
		--disable-fontconfig \
	&& \
	$(MAKE) && \
	$(MAKE) install

clean::
	$(MAKE) -C external/fribidi clean
	$(MAKE) -C external/freetype2 clean
	$(MAKE) -C external/libass clean
