#
# Auto-generate thingies
# This file is part of LuaSrcDiet.
#
# by Kein-Hong Man <keinhong@gmail.com>, PUBLIC DOMAIN
#

LUA = LUA_PATH=../?.lua lua
LUAC = luac

LUASRCDIET = ../bin/luasrcdiet

SOURCE = LuaSrcDiet.lua

APPSAMPLES = app_default.lua \
	     app_basic.lua \
	     app_maximum.lua \
	     app_experimental.lua \
	     opt_comments.lua \
	     opt_whitespace.lua \
	     opt_emptylines.lua \
	     opt_locals.lua

APPREPORTS = app_default.lua.txt \
	     app_basic.lua.txt \
	     app_maximum.lua.txt \
	     app_experimental.lua.txt

GENSAMPLES = numbers_on_diet.lua \
	     strings_on_diet.lua \
	     dump-llex-lexer.dat \
	     dump-llex-parser.dat \
	     llex-plugin-output.html \
	     experimental1_output.lua

all: $(APPSAMPLES) $(GENSAMPLES)

# samples for major processing options

app_default.lua: $(SOURCE)
	$(LUA) $(LUASRCDIET) $(<F) -o $(@F) --details > $(@F).txt

app_basic.lua: $(SOURCE)
	$(LUA) $(LUASRCDIET) $(<F) -o $(@F) --basic --details > $(@F).txt

app_maximum.lua: $(SOURCE)
	$(LUA) $(LUASRCDIET) $(<F) -o $(@F) --maximum --details > $(@F).txt

app_experimental.lua: $(SOURCE)
	$(LUA) $(LUASRCDIET) $(<F) -o $(@F) --maximum --opt-experimental --noopt-srcequiv --details > $(@F).txt

# samples for individual options

opt_comments.lua: $(SOURCE)
	$(LUA) $(LUASRCDIET) $(<F) -o $(@F) --none --quiet --opt-comments

opt_whitespace.lua: $(SOURCE)
	$(LUA) $(LUASRCDIET) $(<F) -o $(@F) --none --quiet --opt-whitespace

opt_emptylines.lua: $(SOURCE)
	$(LUA) $(LUASRCDIET) $(<F) -o $(@F) --none --quiet --opt-emptylines

opt_locals.lua: $(SOURCE)
	$(LUA) $(LUASRCDIET) $(<F) -o $(@F) --none --quiet --opt-locals

# other samples

numbers_on_diet.lua: numbers_original.lua
	$(LUA) $(LUASRCDIET) $< -o $@ --none --opt-numbers --quiet

strings_on_diet.lua: strings_original.lua
	$(LUA) $(LUASRCDIET) $< -o $@ --none --opt-strings --quiet

dump-llex-lexer.dat: ../luasrcdiet/llex.lua
	$(LUA) $(LUASRCDIET) $< --dump-lexer > $@

dump-llex-parser.dat: ../luasrcdiet/llex.lua
	$(LUA) $(LUASRCDIET) $< --dump-parser > $@

llex-plugin-output.html: ../luasrcdiet/llex.lua
	$(LUA) $(LUASRCDIET) $< -o $@ --plugin html --quiet

experimental1_output.lua: experimental1.lua
	$(LUA) $(LUASRCDIET) $< -o $@ --none --opt-experimental --noopt-srcequiv --quiet

# housekeeping

clean:
	rm -f $(APPSAMPLES) $(APPREPORTS) $(GENSAMPLES)

.PHONY: all clean
