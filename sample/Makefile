#
# Simple Makefile to generate a compressed version of LuaSrcDiet
# This file is part of LuaSrcDiet.
#
# by Kein-Hong Man <khman@users.sf.net>, PUBLIC DOMAIN
#

# Lua 5.1 executables, please adjust name to suit
LUA 	= lua5.1
LUAC	= luac5.1

# LuaSrcDiet, to be in parent directory
LSD	= $(LUA) LuaSrcDiet.lua
LSD_MAX	= $(LSD) --maximum

all:
	@echo Sample Generator:
	@echo -------------------------------------------------------------
	@echo max - generate a basic set of max squeezed sources
	@echo test - run Lua on results from 'max'
	@echo strings - generate output for string samples
	@echo numbers - generate output for number samples
	@echo child - attempt to run second generation and diff the output
	@echo dump - generate token and parser dump samples
	@echo different - generate different llex.lua processed files
	@echo binchunks - needed for test_benchmark1.lua testing
	@echo html - sample for HTML plugin
	@echo -------------------------------------------------------------
	@echo clean - cleanup for 'child' and 'binchunks'
	@echo -------------------------------------------------------------

# basic test, run LuaSrcDiet files, to generate a compressed, hopefully working, version
max:
	cd .. && $(LSD_MAX) --details -o sample/LuaSrcDiet.lua LuaSrcDiet.lua > sample/statistics.txt
	cd .. && $(LSD_MAX) --details -o sample/llex.lua llex.lua >> sample/statistics.txt
	cd .. && $(LSD_MAX) --details -o sample/optlex.lua optlex.lua >> sample/statistics.txt
	cd .. && $(LSD_MAX) --details -o sample/lparser.lua lparser.lua >> sample/statistics.txt
	cd .. && $(LSD_MAX) --details -o sample/optparser.lua optparser.lua >> sample/statistics.txt

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
# note that you cannot enable entropy reduction if you wish to compare with diff
CHILD	= $(LUA) LuaSrcDiet.lua --maximum --noopt-entropy
child:
	cd .. && $(LSD_MAX) --noopt-entropy -o sample/LuaSrcDiet_1.lua LuaSrcDiet.lua > /dev/null
	cd .. && $(LSD_MAX) --noopt-entropy -o sample/llex_1.lua llex.lua > /dev/null
	cd .. && $(LSD_MAX) --noopt-entropy -o sample/optlex_1.lua optlex.lua > /dev/null
	cd .. && $(LSD_MAX) --noopt-entropy -o sample/lparser_1.lua lparser.lua > /dev/null
	cd .. && $(LSD_MAX) --noopt-entropy -o sample/optparser_1.lua optparser.lua > /dev/null
	@echo -------------------------------------------------------------
	$(CHILD) LuaSrcDiet_1.lua > child.txt
	$(CHILD) llex_1.lua >> child.txt
	$(CHILD) optlex_1.lua >> child.txt
	$(CHILD) lparser_1.lua >> child.txt
	$(CHILD) optparser_1.lua >> child.txt
	@echo -------------------------------------------------------------
	diff -s -urN LuaSrcDiet_1.lua LuaSrcDiet_1_.lua >> child.txt
	diff -s -urN llex_1.lua llex_1_.lua >> child.txt
	diff -s -urN optlex_1.lua optlex_1_.lua >> child.txt
	diff -s -urN lparser_1.lua lparser_1_.lua >> child.txt
	diff -s -urN optparser_1.lua optparser_1_.lua >> child.txt
	@echo -------------------------------------------------------------
	tail -n6 child.txt

binchunks:
	$(LUAC) -s -o LuaSrcDiet.out LuaSrcDiet.lua
	$(LUAC) -s -o llex.out llex.lua
	$(LUAC) -s -o optlex.out optlex.lua
	$(LUAC) -s -o lparser.out lparser.lua
	$(LUAC) -s -o optparser.out optparser.lua

html:
	cd .. && $(LSD) --plugin html plugin/html.lua -o sample/html_sample.html

# clean up "child" processing, for testing running of a compressed LuaSrcDiet
clean:
	rm -f LuaSrcDiet_1.lua llex_1.lua optlex_1.lua lparser_1.lua optparser_1.lua
	rm -f LuaSrcDiet_1_.lua llex_1_.lua optlex_1_.lua lparser_1_.lua optparser_1_.lua
	rm -f child.txt
	rm -f LuaSrcDiet.out llex.out optlex.out lparser.out optparser.out

.PHONY: all clean max test strings numbers child dump different binchunks html
