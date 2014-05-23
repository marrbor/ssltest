#
# Wrap gradlew
#
#  Do not modify value in this file directly except $(VOPT). Modify 'gradle.properties' instead.
#


# function
getval=$(shell cat $(1) |grep -e '^$(2)' |awk -F"=" '{print $$2}')
gathersrc=$(shell test -d $(1) && $(FIND) $(1) -type f)

# tools
FIND:=/usr/bin/find
TOOLDIR:=../../tools
GROOVY:=$(HOME)/.gvm/groovy/current/bin/groovy
JAVA:=/usr/bin/java

JSCOMPILER:=$(TOOLDIR)/thirdparty/closurecompiler/compiler.jar

JSONLINT:=$(TOOLDIR)/bin/JsonLint.groovy

# gjslint (set blank when don't want to check.)
#JSLINT:=
JSLINT:=/usr/bin/gjslint
JSLINTFLAG:=--strict
#JSLINTFLAG:=--nojsdoc

## compile java script (set blank when don't want to compile)
#JSCOMPLVL:=
#JSCOMPLVL:=WHITESPACE_ONLY
JSCOMPLVL:=SIMPLE_OPTIMIZATIONS
#JSCOMPLVL:=ADVANCED_OPTIMIZATIONS

## option of compile java script (keep blank when don't want to compress)
JSCOMPOPT:=

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
JSSRCDIR:=$(DIR)/src/main/javascript
RSRCDIR:=$(DIR)/src/main/resources

BLDDIR:=$(DIR)/build
MODDIR:=$(BLDDIR)/mods
MODOWNER:=$(call getval,$(PROP),modowner)
MODNAME:=$(call getval,$(PROP),modname)
MODVER:=$(call getval,$(PROP),version)
MODULE:=$(MODOWNER)~$(MODNAME)~$(MODVER)
CLSDIR:=$(MODDIR)/$(MODULE)
JSCLSDIR:=$(CLSDIR)/static-contents/js

# source files that need not compiled.
RSRCS:=$(shell $(FIND) $(RSRCDIR) -type f)

# source and class files that need compiled. java, groovy and javascript.
JCLSS:=$(addsuffix .class,$(basename $(subst $(JSRCDIR),$(CLSDIR),$(call gathersrc,$(JSRCDIR)))))
GCLSS:=$(addsuffix .class,$(basename $(subst $(GSRCDIR),$(CLSDIR),$(call gathersrc,$(GSRCDIR)))))
JSCLSS:=$(addsuffix .min.js,$(basename $(subst $(JSSRCDIR),$(JSCLSDIR),$(call gathersrc,$(JSSRCDIR)))))

# module files.
MODFILES:=$(subst $(RSRCDIR),$(CLSDIR),$(RSRCS)) $(JSCLSS) $(JCLSS) $(GCLSS)

# gradlew
GRADLEW:=$(DIR)/gradlew
GOPT:=
#GOPT:=--info
#GOPT:=--debug

# other workspace to release.
SANDBOX:=../../sandbox
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

# compile javascript have to be done before 'copyMod'


# compile javascript source
$(JSCLSDIR)/%.min.js: $(JSSRCDIR)/%.js
ifneq ($(strip $(JSLINT)),)
	-$(JSLINT) $(JSLINTFLAG) $<
endif
ifeq ($(strip $(JSCOMPLVL)),)
	cp -f $< $@
else
	$(JAVA) -jar $(JSCOMPILER) $(JSCOMPOPT) --compilation_level $(JSCOMPLVL) --js $< --js_output_file $@
endif

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

install: $(MODFILES)
ifneq "$(INCCHK)" ""
	$(error "Dependency mismatch:$(INCCHK)")
endif
ifneq "$(NONCOMMIT)" ""
	$(warning "Non-commit file(s) are remaining. Do not forget commit them.")
endif
	$(GRADLEW) $(GOPT) $@

uninstall:
	rm -rf $(LOCALREPO)

release: $(MODFILES)
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
	@echo "localrepo:$(LOCALREPO)"
	@echo "modfiles:$(MODFILES)"
	@echo "LIBS:$(LIBS)"
	@echo "INCLUDES:$(INCLUDES)"
	@echo "INCCHK:$(INCCHK)"
	@echo "VERTXDIR:$(VERTXDIR)"
	@echo "NONCOMMIT:$(NONCOMMIT)"
	@echo "MASTERDIF:$(MASTERDIF)"
	@echo "BRANCH:$(BRANCH)"
	@echo "JCLSS:$(JCLSS)"
	@echo "GCLSS:$(GCLSS)"
	@echo "JSCLSS:$(JSCLSS)"
