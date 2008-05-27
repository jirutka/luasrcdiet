#
# Simple Makefile to generate a compressed version of LuaSrcDiet
# This file is part of LuaSrcDiet.
#
# by Kein-Hong Man <khman@users.sf.net>, PUBLIC DOMAIN
#

LUA 	= lua5.1
LUAC	= luac5.1
LSD	= $(LUA) LuaSrcDiet.lua --maximum

all:
	cd .. && $(LSD) -o sample/LuaSrcDiet.lua LuaSrcDiet.lua > sample/statistics.txt
	cd .. && $(LSD) -o sample/llex.lua llex.lua >> sample/statistics.txt
	cd .. && $(LSD) -o sample/optlex.lua optlex.lua >> sample/statistics.txt

# disable aggressive optimizations so output can be studied for string optimization
strings:
	cd .. && $(LSD) --noopt-comments --noopt-eols \
	                -o sample/strings_on_diet.lua \
			sample/strings_original.lua

# disable aggressive optimizations so output can be studied for number optimization
numbers:
	cd .. && $(LSD) --noopt-comments --noopt-eols \
	                -o sample/numbers_on_diet.lua \
			sample/numbers_original.lua

test:
	$(LUA) LuaSrcDiet.lua -v
	$(LUA) llex.lua
	$(LUA) optlex.lua

clean:
	rm -f *.lua

.PHONY: all clean test strings numbers


