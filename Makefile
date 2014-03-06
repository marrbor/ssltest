DIR:=.
GRADLEW:=$(DIR)/gradlew
GOPT:=
#GOPT:=--info
#GOPT:=--debug

build:
	$(GRADLEW) $(GOPT) modZip

run:
	$(GRADLEW) $(GOPT) runMod

test:
	$(GRADLEW) $(GOPT) $@

install:
	$(GRADLEW) $(GOPT) $@

release:
	$(GRADLEW) $(GOPT) uploadArchives

clean:
	$(GRADLEW) $(GOPT) $@
