#
# Auto-generate thingies
# This file is part of LuaSrcDiet.
#
# by Kein-Hong Man <keinhong@gmail.com>, PUBLIC DOMAIN
#

LUA = lua
LUAC = luac

FILES = ../src/llex.lua \
	../src/lparser.lua \
        ../src/optlex.lua \
	../src/optparser.lua \
	../src/equiv.lua \
	../src/LuaSrcDiet.lua \
	../src/plugin/html.lua \
	../src/plugin/sloc.lua

ONEAPP = LuaSrcDiet.lua

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

all: $(ONEAPP) $(APPSAMPLES) $(GENSAMPLES)

# all-in-one application script

$(ONEAPP): ../util/onefile.lua $(FILES)
	cd ../util && $(LUA) $(<F)

# samples for major processing options

app_default.lua: $(ONEAPP)
	$(LUA) $(<F) $(<F) -o $(@F) --details > $(@F).txt

app_basic.lua: $(ONEAPP)
	$(LUA) $(<F) $(<F) -o $(@F) --basic --details > $(@F).txt

app_maximum.lua: $(ONEAPP)
	$(LUA) $(<F) $(<F) -o $(@F) --maximum --details > $(@F).txt

app_experimental.lua: $(ONEAPP)
	$(LUA) $(<F) $(<F) -o $(@F) --maximum --opt-experimental --noopt-srcequiv --details > $(@F).txt

# samples for individual options

opt_comments.lua: $(ONEAPP)
	$(LUA) $(<F) $(<F) -o $(@F) --none --quiet --opt-comments

opt_whitespace.lua: $(ONEAPP)
	$(LUA) $(<F) $(<F) -o $(@F) --none --quiet --opt-whitespace

opt_emptylines.lua: $(ONEAPP)
	$(LUA) $(<F) $(<F) -o $(@F) --none --quiet --opt-emptylines

opt_locals.lua: $(ONEAPP)
	$(LUA) $(<F) $(<F) -o $(@F) --none --quiet --opt-locals

# other samples

numbers_on_diet.lua: numbers_original.lua $(ONEAPP)
	$(LUA) $(ONEAPP) $< -o $@ --none --opt-numbers --quiet

strings_on_diet.lua: strings_original.lua $(ONEAPP)
	$(LUA) $(ONEAPP) $< -o $@ --none --opt-strings --quiet

dump-llex-lexer.dat: ../src/llex.lua $(ONEAPP)
	$(LUA) $(ONEAPP) $< --dump-lexer > $@

dump-llex-parser.dat: ../src/llex.lua $(ONEAPP)
	$(LUA) $(ONEAPP) $< --dump-parser > $@

llex-plugin-output.html: ../src/llex.lua $(ONEAPP)
	$(LUA) $(ONEAPP) $< -o $@ --plugin html --quiet

experimental1_output.lua: experimental1.lua $(ONEAPP)
	$(LUA) $(ONEAPP) $< -o $@ --none --opt-experimental --noopt-srcequiv --quiet

# housekeeping

clean:
	rm -f $(ONEAPP) $(APPSAMPLES) $(APPREPORTS) $(GENSAMPLES)

.PHONY: all clean
