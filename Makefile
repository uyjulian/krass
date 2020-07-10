#############################################
##                                         ##
##    Copyright (C) 2020-2020 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
##   See details of license at "LICENSE"   ##
##                                         ##
#############################################

DEPENDENCY_OUTPUT_DIRECTORY := $(realpath build-libraries)
CC = i686-w64-mingw32-gcc
CXX = i686-w64-mingw32-g++
WINDRES := i686-w64-mingw32-windres
GIT_TAG := $(shell git describe --abbrev=0 --tags)
INCFLAGS += -I. -I.. -I../ncbind -I$(DEPENDENCY_OUTPUT_DIRECTORY)/include
ALLSRCFLAGS += $(INCFLAGS) -DGIT_TAG=\"$(GIT_TAG)\"
CFLAGS += -O2 -flto
CFLAGS += $(ALLSRCFLAGS) -Wall -Wno-unused-value -Wno-format -DNDEBUG -DWIN32 -D_WIN32 -D_WINDOWS 
CFLAGS += -D_USRDLL -DMINGW_HAS_SECURE_API -DUNICODE -D_UNICODE -DNO_STRICT
CXXFLAGS += $(CFLAGS) -fpermissive
WINDRESFLAGS += $(ALLSRCFLAGS) --codepage=65001
LDFLAGS += -static -static-libstdc++ -static-libgcc -shared -Wl,--kill-at
LDLIBS +=

%.o: %.c
	@printf '\t%s %s\n' CC $<
	$(CC) -c $(CFLAGS) -o $@ $<

%.o: %.cpp
	@printf '\t%s %s\n' CXX $<
	$(CXX) -c $(CXXFLAGS) -o $@ $<

%.o: %.rc
	@printf '\t%s %s\n' WINDRES $<
	$(WINDRES) $(WINDRESFLAGS) $< $@

SOURCES := ../tp_stub.cpp ../ncbind/ncbind.cpp main.cpp krass.rc
OBJECTS := $(SOURCES:.c=.o)
OBJECTS := $(OBJECTS:.cpp=.o)
OBJECTS := $(OBJECTS:.rc=.o)
OBJECTS += $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libass.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfribidi.a $(DEPENDENCY_OUTPUT_DIRECTORY)/lib/libfreetype.a

BINARY ?= krass.dll
ARCHIVE ?= krass.$(GIT_TAG).7z

all: $(BINARY)

archive: $(ARCHIVE)

clean:
	rm -f $(OBJECTS) $(BINARY) $(ARCHIVE)
	$(MAKE) -C external/fribidi clean
	$(MAKE) -C external/freetype2 clean
	$(MAKE) -C external/libass clean

$(DEPENDENCY_OUTPUT_DIRECTORY):
	mkdir $(DEPENDENCY_OUTPUT_DIRECTORY)

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

$(ARCHIVE): $(BINARY)
	rm -f $(ARCHIVE)
	7z a $@ $^

$(BINARY): $(OBJECTS) 
	@printf '\t%s %s\n' LNK $@
	$(CXX) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

