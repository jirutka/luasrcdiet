#
# Simple Makefile to generate LuaSrcDiet documentation
# This file is part of LuaSrcDiet.
#
# by Kein-Hong Man <keinhong@gmail.com>, PUBLIC DOMAIN
#

LUA 	= lua
FWIKI	= fakewiki.lua

FILES	= \
	../LuaSrcDiet.html \
	../FeaturesAndUsage.html \
	../PerformanceStats.html \
	../TechNotes.html \
	sample.html

all:	$(FILES)

#%.html: %.wiki $(FWIKI)
#	$(LUA) $(FWIKI) $(<F)

../LuaSrcDiet.html: LuaSrcDiet.wiki $(FWIKI)
	$(LUA) $(FWIKI) $(<F)
	mv $(@F) $@

../FeaturesAndUsage.html: FeaturesAndUsage.wiki $(FWIKI)
	$(LUA) $(FWIKI) $(<F)
	mv $(@F) $@

../PerformanceStats.html: PerformanceStats.wiki $(FWIKI)
	$(LUA) $(FWIKI) $(<F)
	mv $(@F) $@

../TechNotes.html: TechNotes.wiki $(FWIKI)
	$(LUA) $(FWIKI) $(<F)
	mv $(@F) $@

sample.html: sample.wiki $(FWIKI)
	$(LUA) $(FWIKI) $(<F)

clean:
	rm -f $(FILES)

.PHONY: all clean
