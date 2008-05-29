#
# Simple Makefile to generate a compressed version of LuaSrcDiet
# This file is part of LuaSrcDiet.
#
# by Kein-Hong Man <khman@users.sf.net>, PUBLIC DOMAIN
#

LUA 	= lua5.1
LUAC	= luac5.1
LSD	= $(LUA) LuaSrcDiet.lua
LSD_MAX	= $(LSD) --maximum

# basic test, run LuaSrcDiet files, to generate a compressed, hopefully working, version
all:
	cd .. && $(LSD_MAX) -o sample/LuaSrcDiet.lua LuaSrcDiet.lua > sample/statistics.txt
	cd .. && $(LSD_MAX) -o sample/llex.lua llex.lua >> sample/statistics.txt
	cd .. && $(LSD_MAX) -o sample/optlex.lua optlex.lua >> sample/statistics.txt
	cd .. && $(LSD_MAX) -o sample/lparser.lua lparser.lua >> sample/statistics.txt
	cd .. && $(LSD_MAX) -o sample/optparser.lua optparser.lua >> sample/statistics.txt

# test first generation, generated from above
test:
	$(LUA) LuaSrcDiet.lua -v
	$(LUA) llex.lua
	$(LUA) optlex.lua
	$(LUA) lparser.lua
	$(LUA) optparser.lua

# generate different samples
different:
	cd .. && $(LSD) llex.lua -o sample/llex_basic.lua --basic
	cd .. && $(LSD) llex.lua -o sample/llex_maximum.lua --maximum
	cd .. && $(LSD) llex.lua -o sample/llex_default.lua
	cd .. && $(LSD) llex.lua -o sample/llex_locals.lua --none --opt-locals
	cd .. && $(LSD) llex.lua -o sample/llex_whitespace.lua --none --opt-whitespace
	cd .. && $(LSD) llex.lua -o sample/llex_emptylines.lua --none --opt-emptylines

# disable aggressive optimizations so output can be studied for string optimization
strings:
	cd .. && $(LSD) --none --opt-strings \
	                -o sample/strings_on_diet.lua \
			sample/strings_original.lua

# disable aggressive optimizations so output can be studied for number optimization
numbers:
	cd .. && $(LSD) --none --opt-numbers \
	                -o sample/numbers_on_diet.lua \
			sample/numbers_original.lua

# dump samples
dump:
	cd .. && $(LSD) --dump-lexer llex.lua > sample/dump-lexer_llex.dat
	cd .. && $(LSD) --dump-parser llex.lua > sample/dump-parser_llex.dat

# run compressed version of LuaSrcDiet, compare first generation with second generation
CHILD	= $(LUA) LuaSrcDiet.lua --maximum
child:
	$(CHILD) LuaSrcDiet.lua > child.txt
	$(CHILD) llex.lua >> child.txt
	$(CHILD) optlex.lua >> child.txt
	$(CHILD) lparser.lua >> child.txt
	$(CHILD) optparser.lua >> child.txt
	diff -s -urN LuaSrcDiet.lua LuaSrcDiet_.lua >> child.txt
	diff -s -urN llex.lua llex_.lua >> child.txt
	diff -s -urN optlex.lua optlex_.lua >> child.txt
	diff -s -urN lparser.lua lparser_.lua >> child.txt
	diff -s -urN optparser.lua optparser_.lua >> child.txt

# clean up "child" processing, for testing running of a compressed LuaSrcDiet
clean:
	rm -f LuaSrcDiet_.lua llex_.lua optlex_.lua lparser_.lua optparser_.lua child.txt

.PHONY: all clean test strings numbers child dump different
