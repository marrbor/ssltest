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
SRCDIR:=$(DIR)/src/main
JSRCDIR:=$(DIR)/src/main/java
GSRCDIR:=$(DIR)/src/main/groovy
RSRCDIR:=$(DIR)/src/main/resources

BLDDIR:=$(DIR)/build
MODDIR:=$(BLDDIR)/mods
MODOWNER:=$(call getval,$(PROP),modowner)
MODNAME:=$(call getval,$(PROP),modname)
MODVER:=$(call getval,$(PROP),version)
MODULE:=$(MODOWNER)~$(MODNAME)~$(MODVER)
CLSDIR:=$(MODDIR)/$(MODULE)

# source files that need compiled.
RSRCS:=$(shell $(FIND) $(RSRCDIR) -type f)

# source files that need not compiled.
JSRCS:=$(shell $(FIND) $(JSRCDIR) -type f)
GSRCS:=$(shell $(FIND) $(GSRCDIR) -type f)

# module files.
MODFILES:=$(subst $(RSRCDIR),$(CLSDIR),$(RSRCS)) $(addsuffix .class,$(basename $(subst $(JSRCDIR),$(CLSDIR),$(JSRCS) $(subst $(GSRCDIR),$(CLSDIR),$(GSRCS)))))

# gradlew
GRADLEW:=$(DIR)/gradlew
GOPT:=
#GOPT:=--info
#GOPT:=--debug

.PHONY: build run test install release clean

build: $(MODFILES)

run: $(MODFILES) $(LOGDIR)
	cd $(BLDDIR) && $(VERTX) runmod $(MODULE) $(VOPT)

# compile java source
$(CLSDIR)/%.class: $(JSRCDIR)/%.java
	$(GRADLEW) $(GOPT) copyMod

# compile groovy source
$(CLSDIR)/%.class: $(GSRCDIR)/%.groovy
	$(GRADLEW) $(GOPT) copyMod

# copy other source/resource files
$(CLSDIR)/%: $(RSRCDIR)/%
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
	@echo "modfiles:$(MODFILES)"
