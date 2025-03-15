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

DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE := $(DEPENDENCY_BUILD_DIRECTORY)/third_party_cmake

EXTLIBS += $(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE)/build-libraries/lib/libthird_party_cmake.a
SOURCES += $(EXTLIBS)
OBJECTS += $(EXTLIBS)
LDLIBS += $(EXTLIBS)

INCFLAGS += -I$(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE)/build-libraries/include

$(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE)/build-libraries/lib/libthird_party_cmake.a:
	cmake \
		-S third_party_cmake \
		-B $(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE) \
		-DCMAKE_SYSTEM_NAME=Windows \
		-DCMAKE_SYSTEM_PROCESSOR=$(TARGET_CMAKE_SYSTEM_PROCESSOR) \
		-DCMAKE_FIND_ROOT_PATH=/dev/null \
		-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
		-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
		-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY \
		-DCMAKE_DISABLE_FIND_PACKAGE_PkgConfig=TRUE \
		-DCMAKE_C_COMPILER=$(CC) \
		-DCMAKE_CXX_COMPILER=$(CXX) \
		-DCMAKE_RC_COMPILER=$(WINDRES) \
		-DCMAKE_BUILD_TYPE=Release \
		&& \
	cmake --build $(DEPENDENCY_BUILD_DIRECTORY_THIRD_PARTY_CMAKE)

$(BASESOURCES): $(EXTLIBS)
