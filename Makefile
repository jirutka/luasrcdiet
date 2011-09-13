#
# Auto-generate thingies
# This file is part of LuaSrcDiet.
#
# by Kein-Hong Man <keinhong@gmail.com>, PUBLIC DOMAIN
#

LUA = lua
LUAC = luac

FILES = src/llex.lua \
	src/lparser.lua \
        src/optlex.lua \
	src/optparser.lua \
	src/equiv.lua \
	src/LuaSrcDiet.lua \
	src/plugin/html.lua \
	src/plugin/sloc.lua

ONEAPP = LuaSrcDiet.lua

APPSAMPLES = bin/app_default.lua \
	     bin/app_basic.lua \
	     bin/app_maximum.lua \
	     bin/app_experimental.lua \
	     bin/opt_comments.lua \
	     bin/opt_whitespace.lua \
	     bin/opt_emptylines.lua \
	     bin/opt_locals.lua

APPREPORTS = bin/app_default.lua.txt \
	     bin/app_basic.lua.txt \
	     bin/app_maximum.lua.txt \
	     bin/app_experimental.lua.txt

GENSAMPLES = samples/numbers_on_diet.lua \
	     samples/strings_on_diet.lua \
	     samples/dump-llex-lexer.dat \
	     samples/dump-llex-parser.dat \
	     samples/llex-plugin-output.html \
	     samples/experimental1_output.lua

all: bin/$(ONEAPP) $(APPSAMPLES) $(GENSAMPLES) doc

# all-in-one application script

bin/$(ONEAPP): util/onefile.lua $(FILES)
	cd util && lua $(<F)

# samples for major processing options

bin/app_default.lua: bin/$(ONEAPP)
	cd bin && lua $(<F) $(<F) -o $(@F) --details > $(@F).txt

bin/app_basic.lua: bin/$(ONEAPP)
	cd bin && lua $(<F) $(<F) -o $(@F) --basic --details > $(@F).txt

bin/app_maximum.lua: bin/$(ONEAPP)
	cd bin && lua $(<F) $(<F) -o $(@F) --maximum --details > $(@F).txt

bin/app_experimental.lua: bin/$(ONEAPP)
	cd bin && lua $(<F) $(<F) -o $(@F) --maximum --opt-experimental --noopt-srcequiv --details > $(@F).txt

# samples for individual options

bin/opt_comments.lua: bin/$(ONEAPP)
	cd bin && lua $(<F) $(<F) -o $(@F) --none --quiet --opt-comments

bin/opt_whitespace.lua: bin/$(ONEAPP)
	cd bin && lua $(<F) $(<F) -o $(@F) --none --quiet --opt-whitespace

bin/opt_emptylines.lua: bin/$(ONEAPP)
	cd bin && lua $(<F) $(<F) -o $(@F) --none --quiet --opt-emptylines

bin/opt_locals.lua: bin/$(ONEAPP)
	cd bin && lua $(<F) $(<F) -o $(@F) --none --quiet --opt-locals

# other samples

samples/numbers_on_diet.lua: samples/numbers_original.lua bin/$(ONEAPP)
	lua bin/$(ONEAPP) $< -o $@ --none --opt-numbers --quiet

samples/strings_on_diet.lua: samples/strings_original.lua bin/$(ONEAPP)
	lua bin/$(ONEAPP) $< -o $@ --none --opt-strings --quiet

samples/dump-llex-lexer.dat: src/llex.lua bin/$(ONEAPP)
	lua bin/$(ONEAPP) $< --dump-lexer > $@

samples/dump-llex-parser.dat: src/llex.lua bin/$(ONEAPP)
	lua bin/$(ONEAPP) $< --dump-parser > $@

samples/llex-plugin-output.html: src/llex.lua bin/$(ONEAPP)
	lua bin/$(ONEAPP) $< -o $@ --plugin html --quiet

samples/experimental1_output.lua: samples/experimental1.lua bin/$(ONEAPP)
	lua bin/$(ONEAPP) $< -o $@ --none --opt-experimental --noopt-srcequiv --quiet

# documentation

doc:
	cd doc/src && make

# housekeeping

clean:
	rm -f bin/$(ONEAPP) $(APPSAMPLES) $(APPREPORTS) $(GENSAMPLES)
	cd doc/src && make clean

.PHONY: all clean doc
