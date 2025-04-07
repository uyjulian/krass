# Copyright (c) third_party_cmake developers

cmake_minimum_required(VERSION 3.12)
project(third_party_cmake)

if((NOT DEFINED CMAKE_BUILD_TYPE) OR (NOT CMAKE_BUILD_TYPE) OR (CMAKE_BUILD_TYPE STREQUAL ""))
set(CMAKE_BUILD_TYPE RelWithDebInfo)
endif()

set(DEPENDENCY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/build-libraries)
file(MAKE_DIRECTORY ${DEPENDENCY_OUTPUT_DIRECTORY}/include)
set(DEPENDENCY_OUTPUT_DIRECTORY_NOHB ${CMAKE_CURRENT_BINARY_DIR}/build-libraries-nohb)
file(MAKE_DIRECTORY ${DEPENDENCY_OUTPUT_DIRECTORY_NOHB}/include)

if((NOT DEFINED MAKE_JOB_ARG) OR (NOT MAKE_JOB_ARG) OR (MAKE_JOB_ARG STREQUAL ""))
include(ProcessorCount)
ProcessorCount(MAKE_JOB_NUM)
set(MAKE_JOB_ARG -j1)
if(NOT MAKE_JOB_NUM EQUAL 0)
set(MAKE_JOB_ARG -j${MAKE_JOB_NUM})
endif()
endif()
if(NOT DEFINED TOOL_TRIPLET_PREFIX)
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL i686)
set(TOOL_TRIPLET_PREFIX i686-w64-mingw32-)
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL amd64)
set(TOOL_TRIPLET_PREFIX x86_64-w64-mingw32-)
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL arm)
set(TOOL_TRIPLET_PREFIX armv7-w64-mingw32-)
endif()
if(${CMAKE_SYSTEM_PROCESSOR} STREQUAL arm64)
set(TOOL_TRIPLET_PREFIX aarch64-w64-mingw32-)
endif()
if(NOT DEFINED TOOL_TRIPLET_PREFIX)
set(TOOL_TRIPLET_PREFIX i686-w64-mingw32-)
endif()
endif()
string(REGEX REPLACE "-$" "" TOOL_TRIPLET_PREFIX_NOTRAILINGDASH "${TOOL_TRIPLET_PREFIX}")

include(ExternalProject)
ExternalProject_Add(fribidi-build
    URL https://github.com/fribidi/fribidi/releases/download/v1.0.11/fribidi-1.0.11.tar.xz
    URL_HASH SHA256=30f93e9c63ee627d1a2cedcf59ac34d45bf30240982f99e44c6e015466b4e73d
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
		"PKG_CONFIG_PATH=${DEPENDENCY_OUTPUT_DIRECTORY}/lib/pkgconfig"
		<SOURCE_DIR>/configure
			CFLAGS=-O2
			"--prefix=${DEPENDENCY_OUTPUT_DIRECTORY}"
			--host=${TOOL_TRIPLET_PREFIX_NOTRAILINGDASH}
			--enable-static
			--disable-shared
			--disable-dependency-tracking
			--disable-debug
    BUILD_COMMAND make -C <BINARY_DIR> ${MAKE_JOB_ARG} && make -C <BINARY_DIR> ${MAKE_JOB_ARG} install
    BUILD_BYPRODUCTS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libfribidi.a
    INSTALL_COMMAND ""
)
list(APPEND THIRDPARTY_DEPENDS fribidi-build)

ExternalProject_Add(brotli-build
    URL https://github.com/google/brotli/archive/refs/tags/v1.0.9.tar.gz
    URL_HASH SHA256=f9e8d81d0405ba66d181529af42a3354f838c939095ff99930da6aa9cdf6fe46
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND 
    	bash -c "cd <SOURCE_DIR> && NOCONFIGURE=1 ./bootstrap" &&
    	${CMAKE_COMMAND} -E env
		"PKG_CONFIG_PATH=${DEPENDENCY_OUTPUT_DIRECTORY}/lib/pkgconfig"
		<SOURCE_DIR>/configure
			CFLAGS=-O2
			CXXFLAGS=-O2
			"--prefix=${DEPENDENCY_OUTPUT_DIRECTORY}"
			--host=${TOOL_TRIPLET_PREFIX_NOTRAILINGDASH}
			--enable-static
			--disable-shared
			--disable-dependency-tracking
    BUILD_COMMAND make -C <BINARY_DIR> ${MAKE_JOB_ARG} && make -C <BINARY_DIR> ${MAKE_JOB_ARG} install
    BUILD_BYPRODUCTS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libbrotlidec.a ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libbrotlicommon.a
    INSTALL_COMMAND ""
)
list(APPEND THIRDPARTY_DEPENDS brotli-build)

ExternalProject_Add(freetype-build-nohb
    URL https://download.savannah.gnu.org/releases/freetype/freetype-2.11.0.tar.xz
    URL_HASH SHA256=8bee39bd3968c4804b70614a0a3ad597299ad0e824bc8aad5ce8aaf48067bde7
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND 
    	${CMAKE_COMMAND} -E env
		"PKG_CONFIG_PATH=${DEPENDENCY_OUTPUT_DIRECTORY_NOHB}/lib/pkgconfig"
		<SOURCE_DIR>/configure
			CFLAGS=-O2
			"--prefix=${DEPENDENCY_OUTPUT_DIRECTORY_NOHB}"
			--host=${TOOL_TRIPLET_PREFIX_NOTRAILINGDASH}
            --enable-static
            --disable-shared

            --without-brotli
            --without-zlib
            --without-bzip2
            --without-png
            --without-harfbuzz
    BUILD_COMMAND make -C <BINARY_DIR> ${MAKE_JOB_ARG} && make -C <BINARY_DIR> ${MAKE_JOB_ARG} install
    BUILD_BYPRODUCTS ${DEPENDENCY_OUTPUT_DIRECTORY_NOHB}/lib/libfreetype.a
    INSTALL_COMMAND ""
)
# Dependency on freetype-build-nohb not added to list

ExternalProject_Add(harfbuzz-build
	DEPENDS freetype-build-nohb
    URL https://github.com/harfbuzz/harfbuzz/releases/download/3.1.2/harfbuzz-3.1.2.tar.xz
    URL_HASH SHA256=4056b1541dd8bbd8ec29207fe30e568805c0705515632d7fec53a94399bc7945
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND 
        ${CMAKE_COMMAND} -E env
        "PKG_CONFIG_PATH=${DEPENDENCY_OUTPUT_DIRECTORY_NOHB}/lib/pkgconfig"
        <SOURCE_DIR>/configure
            "CFLAGS=-O2 -DHB_NO_MT -DHB_NO_PRAGMA_GCC_DIAGNOSTIC_ERROR"
            "CXXFLAGS=-O2 -DHB_NO_MT -DHB_NO_PRAGMA_GCC_DIAGNOSTIC_ERROR"
            "--prefix=${DEPENDENCY_OUTPUT_DIRECTORY}"
            --host=${TOOL_TRIPLET_PREFIX_NOTRAILINGDASH}
            --enable-static
            --disable-shared
            --disable-dependency-tracking

            --without-cairo
            --without-fontconfig
            --without-icu
            --with-freetype
            --without-glib
    BUILD_COMMAND make -C <BINARY_DIR> ${MAKE_JOB_ARG} && make -C <BINARY_DIR> ${MAKE_JOB_ARG} install
    BUILD_BYPRODUCTS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libharfbuzz.a
    INSTALL_COMMAND ""
)
list(APPEND THIRDPARTY_DEPENDS harfbuzz-build)

ExternalProject_Add(freetype-build
	DEPENDS harfbuzz-build brotli-build
    URL https://download.savannah.gnu.org/releases/freetype/freetype-2.11.0.tar.xz
    URL_HASH SHA256=8bee39bd3968c4804b70614a0a3ad597299ad0e824bc8aad5ce8aaf48067bde7
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND 
        ${CMAKE_COMMAND} -E env
        "PKG_CONFIG_PATH=${DEPENDENCY_OUTPUT_DIRECTORY}/lib/pkgconfig:${DEPENDENCY_OUTPUT_DIRECTORY_NOHB}/lib/pkgconfig"
        <SOURCE_DIR>/configure
            CFLAGS=-O2
            "--prefix=${DEPENDENCY_OUTPUT_DIRECTORY}"
            --host=${TOOL_TRIPLET_PREFIX_NOTRAILINGDASH}
            --enable-static
            --disable-shared

            --with-brotli
            --without-zlib
            --without-bzip2
            --without-png
            --with-harfbuzz
    BUILD_COMMAND make -C <BINARY_DIR> ${MAKE_JOB_ARG} && make -C <BINARY_DIR> ${MAKE_JOB_ARG} install
    BUILD_BYPRODUCTS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libfreetype.a
    INSTALL_COMMAND ""
)
list(APPEND THIRDPARTY_DEPENDS freetype-build)

ExternalProject_Add(libass-build
	DEPENDS fribidi-build freetype-build harfbuzz-build
    URL https://github.com/libass/libass/releases/download/0.15.2/libass-0.15.2.tar.xz
    URL_HASH SHA256=1be2df9c4485a57d78bb18c0a8ed157bc87a5a8dd48c661961c625cb112832fd
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    CONFIGURE_COMMAND 
        ${CMAKE_COMMAND} -E env
        "PKG_CONFIG_PATH=${DEPENDENCY_OUTPUT_DIRECTORY}/lib/pkgconfig"
        <SOURCE_DIR>/configure
            "CFLAGS=-DFRIBIDI_LIB_STATIC -O2"
            "--prefix=${DEPENDENCY_OUTPUT_DIRECTORY}"
            --host=${TOOL_TRIPLET_PREFIX_NOTRAILINGDASH}
            --disable-shared
            --enable-static
            --disable-asm

            --disable-require-system-font-provider
            --disable-directwrite
            --disable-fontconfig
    BUILD_COMMAND make -C <BINARY_DIR> ${MAKE_JOB_ARG} && make -C <BINARY_DIR> ${MAKE_JOB_ARG} install
    BUILD_BYPRODUCTS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libass.a
    INSTALL_COMMAND ""
)
list(APPEND THIRDPARTY_DEPENDS libass-build)

foreach(CUR_DEPEND IN LISTS THIRDPARTY_DEPENDS)
ExternalProject_Get_Property(${CUR_DEPEND} BUILD_BYPRODUCTS)
list(APPEND THIRDPARTY_LIBRARIES ${BUILD_BYPRODUCTS})
endforeach()

add_custom_command(
    OUTPUT ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libthird_party_cmake.a
    COMMAND 
    	printf 'create %s\\n' ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libthird_party_cmake.a > ${DEPENDENCY_OUTPUT_DIRECTORY}/build.mri &&
    	printf 'addlib %s\\n' ${THIRDPARTY_LIBRARIES} >> ${DEPENDENCY_OUTPUT_DIRECTORY}/build.mri &&
    	printf 'save\\nend\\n' >> ${DEPENDENCY_OUTPUT_DIRECTORY}/build.mri &&
    	cat ${DEPENDENCY_OUTPUT_DIRECTORY}/build.mri | ${CMAKE_AR} -M
    DEPENDS ${THIRDPARTY_DEPENDS}
)

add_custom_command(
	OUTPUT ${DEPENDENCY_OUTPUT_DIRECTORY}/include/third_party_cmake.h
	COMMAND touch ${DEPENDENCY_OUTPUT_DIRECTORY}/include/third_party_cmake.h
	DEPENDS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libthird_party_cmake.a
)

add_custom_target(main_output_target
	ALL
	DEPENDS ${DEPENDENCY_OUTPUT_DIRECTORY}/lib/libthird_party_cmake.a ${DEPENDENCY_OUTPUT_DIRECTORY}/include/third_party_cmake.h
)
