#
# Wrap gradlew
#
#  Do not modify value in this file directly except $(VOPT). Modify 'gradle.properties' instead.
#


# function
getval=$(shell cat $(1) |grep -e '^$(2)' |awk -F"=" '{print $$2}')

# tools
FIND:=/usr/bin/find

# location
DIR:=$(abspath .)
PROP:=$(DIR)/gradle.properties
LOGDIR:=~/.Ruisdael/logs

# vert.x
VERTXVER:=$(call getval,$(PROP),vertxVersion)
VERTX:=$(DIR)/vert.x-$(VERTXVER)/bin/vertx
#VOPT:=$(call getval,$(PROP),runModArgs)
VOPT:=-conf $(DIR)/conf.json

# module information
SRCDIR:=$(DIR)/src/main/resources
BLDDIR:=$(DIR)/build
CLSDIR:=$(BLDDIR)/resources/main
MODDIR:=$(BLDDIR)/mods
MODOWNER:=$(call getval,$(PROP),modowner)
MODNAME:=$(call getval,$(PROP),modname)
MODVER:=$(call getval,$(PROP),version)
MODULE:=$(MODOWNER)~$(MODNAME)~$(MODVER)
MODULECP:=$(MODDIR)/$(MODULE)

SRCS:=$(shell $(FIND) $(SRCDIR) -type f)
CLSS:=$(subst $(SRCDIR),$(CLSDIR),$(SRCS))

# gradlew
GRADLEW:=$(DIR)/gradlew
GOPT:=
#GOPT:=--info
#GOPT:=--debug

.PHONY: build run test install release clean

build: $(CLSS)

run: $(CLSS) $(LOGDIR)
	cd $(BLDDIR) && $(VERTX) runmod $(MODULE) $(VOPT)

$(CLSDIR)%: $(SRCDIR)/%
	$(GRADLEW) $(GOPT) copyMod

$(LOGDIR):
	mkdir -p $@

test:
	$(GRADLEW) $(GOPT) $@

install:
	$(GRADLEW) $(GOPT) $@

release:
	$(GRADLEW) $(GOPT) uploadArchives

clean:
	$(GRADLEW) $(GOPT) $@

check:
	@echo "owner:$(MODOWNER)"
	@echo "name:$(MODNAME)"
	@echo "version:$(MODVER)"
	@echo "vertx:$(VERTXVER)"
	@echo "vertx option:$(VOPT)"
	@echo "module:$(MODULE)"
	@echo "srcs:$(SRCS)"
	@echo "class:$(CLSS)"
