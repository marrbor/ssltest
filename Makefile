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
JAVA:=$(JAVA_HOME)/bin/java

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

## option of compile javascript (keep blank when don't want to compress)
JSCOMPOPT:=

# location
DIR:=$(abspath .)
PROP:=$(DIR)/gradle.properties
LOGDIR:=~/.Ruisdael/logs

# vert.x
VERTXVER:=$(call getval,$(PROP),vertxVersion)
VERTXDIR:=~/.gvm/vertx/$(VERTXVER)
VERTX:=$(VERTXDIR)/bin/vertx
REPOTXT:=$(VERTXDIR)/conf/repos.txt
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
JSCLSDIR:=$(RSRCDIR)/static-contents/js

# javascript source need compile.
JSCLSS:=$(addsuffix .min.js,$(basename $(subst $(JSSRCDIR),$(JSCLSDIR),$(call gathersrc,$(JSSRCDIR)))))

# get lib-basis version
LIBBASISVER:=$(strip $(shell cat src/main/resources/mod.json |grep 'lib-basis' |sed -e 's/[^0-9\.]//g'))

# gradlew
GRADLEW:=$(DIR)/gradlew
GOPT:=-PlibBasisVersion=$(LIBBASISVER)
#GOPT:=--info -PlibBasisVersion=$(LIBBASISVER)
#GOPT:=--debug -PlibBasisVersion=$(LIBBASISVER)

# other workspace to release.
LOCALREPO:=~/.m2/repository/survei/$(MODNAME)

# condition of workspace
NONCOMMIT:=$(shell git status -s)
MASTERDIF:=$(shell git remote show origin |grep 'up to date')
BRANCH=$(shell git branch --contains |grep '*' |grep 'master')

.PHONY: build run test install release clean

build: $(JSCLSS)
	$(GRADLEW) $(GOPT) copyMod

# compile javascript have to be done before 'copyMod'
$(JSCLSDIR)/%.min.js: $(JSSRCDIR)/%.js
ifneq ($(strip $(JSLINT)),)
	-$(JSLINT) $(JSLINTFLAG) $<
endif
ifeq ($(strip $(JSCOMPLVL)),)
	cp -f $< $@
else
	$(JAVA) -jar $(JSCOMPILER) $(JSCOMPOPT) --compilation_level $(JSCOMPLVL) --js $< --js_output_file $@
endif

run: build $(LOGDIR) repotxt
	cd $(BLDDIR) && $(VERTX) runmod $(MODULE) $(VOPT)

repotxt:
	@grep 'contents.iperfecta-dev.local' $(REPOTXT) >/dev/null || \
	echo -e "\n# Inhouse Maven repo.\nmaven:http://deployment:2009Invensys@contents.iperfecta-dev.local/nexus/content/repositories/Ruisdael" >>$(REPOTXT)


reload: clean run

retest: clean test

$(LOGDIR):
	mkdir -p $@

test:
	$(GRADLEW) $(GOPT) $@

install: $(JSCLSS)
ifneq "$(NONCOMMIT)" ""
	$(warning "Non-commit file(s) are remaining. Do not forget commit them.")
endif
	$(GRADLEW) $(GOPT) $@

uninstall:
	rm -rf $(LOCALREPO)

release: $(JSCLSS)
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

clean:
ifneq ($(strip $(JSCLSS)),)
	-rm -f $(JSCLSS)
endif
	$(GRADLEW) $(GOPT) $@

fatjar:
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
	@echo "INCLUDES:$(INCLUDES)"
	@echo "VERTXDIR:$(VERTXDIR)"
	@echo "NONCOMMIT:$(NONCOMMIT)"
	@echo "MASTERDIF:$(MASTERDIF)"
	@echo "BRANCH:$(BRANCH)"
	@echo "JSCLSS:$(JSCLSS)"
	@echo "LIBBASISVER:$(LIBBASISVER)"
	@echo "GOPT:$(GOPT)"
