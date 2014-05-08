#
# Wrap gradlew
#
#  Do not modify value in this file directly except $(VOPT). Modify 'gradle.properties' instead.
#


# function
getval=$(shell cat $(1) |grep -e '^$(2)' |awk -F"=" '{print $$2}')

# tools
FIND:=/usr/bin/find
JSONLINT:=~/Ruisdael/tools/bin/JsonLint.groovy
GROOVY:=$(HOME)/.gvm/groovy/current/bin/groovy

# location
DIR:=$(abspath .)
PROP:=$(DIR)/gradle.properties
LOGDIR:=~/.Ruisdael/logs

# vert.x
VERTXVER:=$(call getval,$(PROP),vertxVersion)
VERTXDIR:=~/.gvm/vertx/$(VERTXVER)
VERTX:=$(VERTXDIR)/bin/vertx
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

# other workspace to release.
SANDBOX:=~/Ruisdael/sandbox
LOCALREPO:=~/.m2/repository/iperfecta/$(MODNAME)

# include modules.
LIBS:=iperfecta~lib-basis~$(call getval,$(PROP),libBasisVersion) iperfecta~lib-reporter~$(call getval,$(PROP),libReporterVersion)
INCLUDES:=$(strip $(shell cat src/main/resources/mod.json |grep -e '^ *"includes"' |sed -e 's/^.*://' -e 's/"//g' -e 's/,/ /g'))
INCCHK:=$(filter-out $(LIBS),$(INCLUDES))

# condition of workspace
NONCOMMIT:=$(shell git status -s)
MASTERDIF:=$(shell git remote show origin |grep 'up to date')
BRANCH=$(shell git branch --contains |grep '*' |grep 'master')

.PHONY: build run test install release clean

build: $(MODFILES)

run: $(MODFILES) $(LOGDIR)
	cd $(BLDDIR) && $(VERTX) runmod $(MODULE) $(VOPT)

reload: clean run

retest: clean test

# compile java source
$(CLSDIR)/%.class: $(JSRCDIR)/%.java
ifneq "$(INCCHK)" ""
	$(error "Dependency mismatch:$(INCCHK)")
endif
	$(GRADLEW) $(GOPT) copyMod

# compile groovy source
$(CLSDIR)/%.class: $(GSRCDIR)/%.groovy
ifneq "$(INCCHK)" ""
	$(error "Dependency mismatch:$(INCCHK)")
endif
	$(GRADLEW) $(GOPT) copyMod

# copy other source/resource files
$(CLSDIR)/%: $(RSRCDIR)/%
ifneq "$(INCCHK)" ""
	$(error "Dependency mismatch:$(INCCHK)")
endif
	$(GRADLEW) $(GOPT) copyMod

$(LOGDIR):
	mkdir -p $@

test:
ifneq "$(INCCHK)" ""
	$(error "Dependency mismatch:$(INCCHK)")
endif
	$(GRADLEW) $(GOPT) $@

install:
ifneq "$(INCCHK)" ""
	$(error "Dependency mismatch:$(INCCHK)")
endif
ifneq "$(NONCOMMIT)" ""
	$(warning "Non-commit file(s) are remaining. Do not forget commit them.")
endif
	$(GRADLEW) $(GOPT) $@

uninstall:
	rm -rf $(LOCALREPO)

release:
ifneq "$(INCCHK)" ""
	$(error "Dependency mismatch:$(INCCHK)")
endif
ifneq "$(NONCOMMIT)" ""
	$(error "Non-commit file(s) are remaining. Commit them first.")
endif
ifeq  "$(MASTERDIF)" ""
	$(error "Non-marge file(s) or Non-push file(s) are remaining. Marge/Push them first.")
endif
ifeq "$(BRANCH)" ""
	$(error "This is not master branch. Marge/Push them first.")
endif
	$(GRADLEW) $(GOPT) uploadArchives

# release to other workspace.
SMODDIR:=$(SANDBOX)/mods/$(MODULE)
sandbox: $(MODFILES)
ifneq "$(INCCHK)" ""
	$(error "Dependency mismatch:$(INCCHK)")
endif
	cp -rf $(RSRCDIR)/* $(SMODDIR)
	cp -rf $(BLDDIR)/classes/main/* $(SMODDIR)

clean:
	$(GRADLEW) $(GOPT) $@

chkconf:
	$(GROOVY) $(JSONLINT) conf.json

check:
	@echo "owner:$(MODOWNER)"
	@echo "name:$(MODNAME)"
	@echo "version:$(MODVER)"
	@echo "vertx:$(VERTX)"
	@echo "vertx option:$(VOPT)"
	@echo "module:$(MODULE)"
	@echo "srcs:$(SRCS)"
	@echo "class:$(CLSS)"
	@echo "localrepo:$(LOCALREPO)"
	@echo "modfiles:$(MODFILES)"
	@echo "LIBS:$(LIBS)"
	@echo "INCLUDES:$(INCLUDES)"
	@echo "INCCHK:$(INCCHK)"
	@echo "VERTXDIR:$(VERTXDIR)"
	@echo "NONCOMMIT:$(NONCOMMIT)"
	@echo "MASTERDIF:$(MASTERDIF)"
	@echo "BRANCH:$(BRANCH)"
