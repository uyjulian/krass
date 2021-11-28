#############################################
##                                         ##
##    Copyright (C) 2020-2021 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
##   See details of license at "LICENSE"   ##
##                                         ##
#############################################

BASESOURCES += main.cpp
SOURCES += $(BASESOURCES)
PROJECT_BASENAME = krass

RC_FILEDESCRIPTION ?= Advanced Substation Alpha renderer for TVP(KIRIKIRI) (2/Z)
RC_LEGALCOPYRIGHT ?= Copyright (C) 2020-2021 Julian Uy; This product is licensed under the MIT license.
RC_PRODUCTNAME ?= Advanced Substation Alpha renderer for TVP(KIRIKIRI) (2/Z)

include external/ncbind/Rules.lib.make

DEPENDENCY_BUILD_DIRECTORY := build-$(TARGET_ARCH)
DEPENDENCY_BUILD_DIRECTORY_FRIBIDI := $(DEPENDENCY_BUILD_DIRECTORY)/fribidi
DEPENDENCY_BUILD_DIRECTORY_BROTLI := $(DEPENDENCY_BUILD_DIRECTORY)/brotli
DEPENDENCY_BUILD_DIRECTORY_FREETYPE2_NOHB := $(DEPENDENCY_BUILD_DIRECTORY)/freetype2_nohb
DEPENDENCY_BUILD_DIRECTORY_FREETYPE2 := $(DEPENDENCY_BUILD_DIRECTORY)/freetype2
DEPENDENCY_BUILD_DIRECTORY_HARFBUZZ := $(DEPENDENCY_BUILD_DIRECTORY)/harfbuzz
DEPENDENCY_BUILD_DIRECTORY_LIBASS := $(DEPENDENCY_BUILD_DIRECTORY)/libass

FRIBIDI_PATH := $(realpath external/fribidi)
BROTLI_PATH := $(realpath external/brotli)
FREETYPE2_PATH := $(realpath external/freetype2)
HARFBUZZ_PATH := $(realpath external/harfbuzz)
LIBASS_PATH := $(realpath external/libass)

DEPENDENCY_OUTPUT_DIRECTORY := $(shell realpath build-libraries)-$(TARGET_ARCH)
DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB := $(shell realpath $(DEPENDENCY_BUILD_DIRECTORY))/freetype2_nohb_output

EXTLIBS += $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libass.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libharfbuzz.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlidec.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlicommon.a
SOURCES += $(EXTLIBS)
OBJECTS += $(EXTLIBS)
LDLIBS += $(EXTLIBS)

INCFLAGS += -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include

$(BASESOURCES): $(EXTLIBS)

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir -p $(DEPENDENCY_OUTPUT_DIRECTORY)

$(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB):
	mkdir -p $(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)

$(FRIBIDI_PATH)/configure:
	cd $(FRIBIDI_PATH) && \
	NOCONFIGURE=1 ./autogen.sh

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a: $(FRIBIDI_PATH)/configure $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_FRIBIDI) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_FRIBIDI) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(FRIBIDI_PATH)/configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
		--enable-static \
		--disable-shared \
		--disable-dependency-tracking \
		--disable-debug \
	&& \
	$(MAKE) && \
	$(MAKE) install

$(BROTLI_PATH)/config.guess:
	cd $(BROTLI_PATH) && \
	NOCONFIGURE=1 ./bootstrap

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlidec.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlicommon.a: $(BROTLI_PATH)/config.guess $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_BROTLI) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_BROTLI) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(BROTLI_PATH)/configure \
		CFLAGS="-O2" \
		CXXFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
		--enable-static \
		--disable-shared \
		--disable-dependency-tracking \
	&& \
	$(MAKE) && \
	$(MAKE) install

$(FREETYPE2_PATH)/configure:
	cd $(FREETYPE2_PATH) && \
	NOCONFIGURE=1 ./autogen.sh

$(HARFBUZZ_PATH)/configure:
	cd $(HARFBUZZ_PATH) && \
	NOCONFIGURE=1 ./autogen.sh

$(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)/lib/libfreetype.a: $(FREETYPE2_PATH)/configure $(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_FREETYPE2) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_FREETYPE2) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)/lib/pkgconfig \
	$(FREETYPE2_PATH)/configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)" \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
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

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libharfbuzz.a: $(HARFBUZZ_PATH)/configure $(DEPENDENCY_OUTPUT_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)/lib/libfreetype.a
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_HARFBUZZ) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_HARFBUZZ) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)/lib/pkgconfig \
	$(HARFBUZZ_PATH)/configure \
		CFLAGS="-O2 -DHB_NO_MT" \
		CXXFLAGS="-O2 -DHB_NO_MT" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
		--enable-static \
		--disable-shared \
		--disable-dependency-tracking \
		\
		--without-cairo \
		--without-fontconfig \
		--without-icu \
		--with-freetype \
		--without-glib \
	&& \
	$(MAKE) && \
	$(MAKE) install

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a: $(FREETYPE2_PATH)/configure $(DEPENDENCY_OUTPUT_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libharfbuzz.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlidec.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlicommon.a
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_FREETYPE2) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_FREETYPE2) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(FREETYPE2_PATH)/configure \
		CFLAGS="-O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
		--enable-static \
		--disable-shared \
		\
		--with-brotli \
		--without-zlib \
		--without-bzip2 \
		--without-png \
		--with-harfbuzz \
	&& \
	$(MAKE) && \
	$(MAKE) install

$(LIBASS_PATH)/configure:
	cd $(LIBASS_PATH) && \
	NOCONFIGURE=1 ./autogen.sh

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libass.a: $(LIBASS_PATH)/configure $(DEPENDENCY_OUTPUT_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libharfbuzz.a
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_LIBASS) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_LIBASS) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(LIBASS_PATH)/configure \
		CFLAGS="-DFRIBIDI_LIB_STATIC -O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
		--disable-shared \
		--enable-static \
		--disable-asm \
		\
		--enable-harfbuzz \
		--disable-require-system-font-provider \
		--disable-directwrite \
		--disable-fontconfig \
	&& \
	$(MAKE) && \
	$(MAKE) install

clean::
	rm -rf $(DEPENDENCY_BUILD_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)
