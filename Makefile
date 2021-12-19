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

DEPENDENCY_SOURCE_DIRECTORY := $(abspath build-source)
DEPENDENCY_SOURCE_DIRECTORY_FRIBIDI := $(DEPENDENCY_SOURCE_DIRECTORY)/fribidi
DEPENDENCY_SOURCE_DIRECTORY_BROTLI := $(DEPENDENCY_SOURCE_DIRECTORY)/brotli
DEPENDENCY_SOURCE_DIRECTORY_FREETYPE2 := $(DEPENDENCY_SOURCE_DIRECTORY)/freetype2
DEPENDENCY_SOURCE_DIRECTORY_HARFBUZZ := $(DEPENDENCY_SOURCE_DIRECTORY)/harfbuzz
DEPENDENCY_SOURCE_DIRECTORY_LIBASS := $(DEPENDENCY_SOURCE_DIRECTORY)/libass

DEPENDENCY_SOURCE_FILE_FRIBIDI := $(DEPENDENCY_SOURCE_DIRECTORY)/fribidi.tar.xz
DEPENDENCY_SOURCE_FILE_BROTLI := $(DEPENDENCY_SOURCE_DIRECTORY)/brotli.tar.gz
DEPENDENCY_SOURCE_FILE_FREETYPE2 := $(DEPENDENCY_SOURCE_DIRECTORY)/freetype2.tar.xz
DEPENDENCY_SOURCE_FILE_HARFBUZZ := $(DEPENDENCY_SOURCE_DIRECTORY)/harfbuzz.tar.xz
DEPENDENCY_SOURCE_FILE_LIBASS := $(DEPENDENCY_SOURCE_DIRECTORY)/libass.tar.xz

DEPENDENCY_SOURCE_URL_FRIBIDI := https://github.com/fribidi/fribidi/releases/download/v1.0.11/fribidi-1.0.11.tar.xz
DEPENDENCY_SOURCE_URL_BROTLI := https://github.com/google/brotli/archive/refs/tags/v1.0.9.tar.gz
DEPENDENCY_SOURCE_URL_FREETYPE2 := https://download.savannah.gnu.org/releases/freetype/freetype-2.11.0.tar.xz
DEPENDENCY_SOURCE_URL_HARFBUZZ := https://github.com/harfbuzz/harfbuzz/releases/download/3.1.2/harfbuzz-3.1.2.tar.xz
DEPENDENCY_SOURCE_URL_LIBASS := https://github.com/libass/libass/releases/download/0.15.2/libass-0.15.2.tar.xz

$(DEPENDENCY_SOURCE_DIRECTORY):
	mkdir -p $@

$(DEPENDENCY_SOURCE_FILE_FRIBIDI): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_FRIBIDI)

$(DEPENDENCY_SOURCE_FILE_BROTLI): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_BROTLI)

$(DEPENDENCY_SOURCE_FILE_FREETYPE2): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_FREETYPE2)

$(DEPENDENCY_SOURCE_FILE_HARFBUZZ): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_HARFBUZZ)

$(DEPENDENCY_SOURCE_FILE_LIBASS): | $(DEPENDENCY_SOURCE_DIRECTORY)
	curl --location --output $@ $(DEPENDENCY_SOURCE_URL_LIBASS)

$(DEPENDENCY_SOURCE_DIRECTORY_FRIBIDI): $(DEPENDENCY_SOURCE_FILE_FRIBIDI)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

$(DEPENDENCY_SOURCE_DIRECTORY_BROTLI): $(DEPENDENCY_SOURCE_FILE_BROTLI)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

$(DEPENDENCY_SOURCE_DIRECTORY_FREETYPE2): $(DEPENDENCY_SOURCE_FILE_FREETYPE2)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

$(DEPENDENCY_SOURCE_DIRECTORY_HARFBUZZ): $(DEPENDENCY_SOURCE_FILE_HARFBUZZ)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

$(DEPENDENCY_SOURCE_DIRECTORY_LIBASS): $(DEPENDENCY_SOURCE_FILE_LIBASS)
	mkdir -p $@
	tar -x -f $< -C $@ --strip-components 1

DEPENDENCY_BUILD_DIRECTORY := $(abspath build-$(TARGET_ARCH))
DEPENDENCY_BUILD_DIRECTORY_FRIBIDI := $(DEPENDENCY_BUILD_DIRECTORY)/fribidi
DEPENDENCY_BUILD_DIRECTORY_BROTLI := $(DEPENDENCY_BUILD_DIRECTORY)/brotli
DEPENDENCY_BUILD_DIRECTORY_FREETYPE2_NOHB := $(DEPENDENCY_BUILD_DIRECTORY)/freetype2_nohb
DEPENDENCY_BUILD_DIRECTORY_FREETYPE2 := $(DEPENDENCY_BUILD_DIRECTORY)/freetype2
DEPENDENCY_BUILD_DIRECTORY_HARFBUZZ := $(DEPENDENCY_BUILD_DIRECTORY)/harfbuzz
DEPENDENCY_BUILD_DIRECTORY_LIBASS := $(DEPENDENCY_BUILD_DIRECTORY)/libass

DEPENDENCY_OUTPUT_DIRECTORY := $(abspath build-libraries)-$(TARGET_ARCH)
DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB := $(abspath $(DEPENDENCY_BUILD_DIRECTORY))/freetype2_nohb_output

EXTLIBS += $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libass.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libharfbuzz.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlidec.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlicommon.a
SOURCES += $(EXTLIBS)
OBJECTS += $(EXTLIBS)
LDLIBS += $(EXTLIBS)

INCFLAGS += -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include

$(BASESOURCES): $(EXTLIBS)

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir -p $@

$(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB):
	mkdir -p $@

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a: | $(DEPENDENCY_SOURCE_DIRECTORY_FRIBIDI) $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_FRIBIDI) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_FRIBIDI) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(DEPENDENCY_SOURCE_DIRECTORY_FRIBIDI)/configure \
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

$(DEPENDENCY_SOURCE_DIRECTORY_BROTLI)/aclocal.m4: | $(DEPENDENCY_SOURCE_DIRECTORY_BROTLI)
	cd $(DEPENDENCY_SOURCE_DIRECTORY_BROTLI) && \
	NOCONFIGURE=1 ./bootstrap

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlicommon.la: | $(DEPENDENCY_SOURCE_DIRECTORY_BROTLI)/aclocal.m4 $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_BROTLI) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_BROTLI) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(DEPENDENCY_SOURCE_DIRECTORY_BROTLI)/configure \
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

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlidec.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlicommon.a: $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlicommon.la

$(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)/lib/libfreetype.a: | $(DEPENDENCY_SOURCE_DIRECTORY_FREETYPE2) $(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_FREETYPE2) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_FREETYPE2) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)/lib/pkgconfig \
	$(DEPENDENCY_SOURCE_DIRECTORY_FREETYPE2)/configure \
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

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libharfbuzz.a: $(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)/lib/libfreetype.a | $(DEPENDENCY_SOURCE_DIRECTORY_HARFBUZZ) $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_HARFBUZZ) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_HARFBUZZ) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY_FREETYPE2_NOHB)/lib/pkgconfig \
	$(DEPENDENCY_SOURCE_DIRECTORY_HARFBUZZ)/configure \
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

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a: $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libharfbuzz.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlidec.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libbrotlicommon.a | $(DEPENDENCY_SOURCE_DIRECTORY_FREETYPE2) $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_FREETYPE2) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_FREETYPE2) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(DEPENDENCY_SOURCE_DIRECTORY_FREETYPE2)/configure \
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

$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libass.a: $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libharfbuzz.a | $(DEPENDENCY_SOURCE_DIRECTORY_LIBASS) $(DEPENDENCY_OUTPUT_DIRECTORY)
	mkdir -p $(DEPENDENCY_BUILD_DIRECTORY_LIBASS) && \
	cd $(DEPENDENCY_BUILD_DIRECTORY_LIBASS) && \
	PKG_CONFIG_PATH=$(DEPENDENCY_OUTPUT_DIRECTORY)/lib/pkgconfig \
	$(DEPENDENCY_SOURCE_DIRECTORY_LIBASS)/configure \
		CFLAGS="-DFRIBIDI_LIB_STATIC -O2" \
		--prefix="$(DEPENDENCY_OUTPUT_DIRECTORY)" \
		--host=$(patsubst %-,%,$(TOOL_TRIPLET_PREFIX)) \
		--disable-shared \
		--enable-static \
		--disable-asm \
		\
		--disable-require-system-font-provider \
		--disable-directwrite \
		--disable-fontconfig \
	&& \
	$(MAKE) && \
	$(MAKE) install

clean::
	rm -rf $(DEPENDENCY_SOURCE_DIRECTORY) $(DEPENDENCY_BUILD_DIRECTORY) $(DEPENDENCY_OUTPUT_DIRECTORY)
