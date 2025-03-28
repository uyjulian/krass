#############################################
##                                         ##
##    Copyright (C) 2020-2021 Julian Uy    ##
##  https://sites.google.com/site/awertyb  ##
##                                         ##
##   See details of license at "LICENSE"   ##
##                                         ##
#############################################

SOURCES += main.cpp
PROJECT_BASENAME = krass

RC_FILEDESCRIPTION ?= Advanced Substation Alpha renderer for TVP(KIRIKIRI) (2/Z)
RC_LEGALCOPYRIGHT ?= Copyright (C) 2020-2021 Julian Uy; This product is licensed under the MIT license.
RC_PRODUCTNAME ?= Advanced Substation Alpha renderer for TVP(KIRIKIRI) (2/Z)

include external/ncbind/Rules.lib.make
