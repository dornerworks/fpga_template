# -*- mode:makefile -*-
# Copyright (c) 2015, DornerWorks Ltd.

PRJ_MK := $(wildcard */[mM]akefile)
PRJ_DIRS := $(patsubst %/,%,$(dir $(PRJ_MK)))
PRJ_NAMES := $(notdir $(abspath $(PRJ_DIRS)))
IP_MK := $(wildcard ip_repo/*/[mM]akefile)
IP_DIRS := $(patsubst %/,%,$(dir $(IP_MK)))
IP_NAMES := $(notdir $(IP_DIRS))

.PHONY: all
.PHONY: init
.PHONY: init-prj
.PHONY: $(foreach x,$(PRJ_DIRS),init-$(x))
.PHONY: $(foreach x,$(PRJ_DIRS),clean-$(x))
.PHONY: $(foreach x,$(PRJ_DIRS),distclean-$(x))
.PHONY: $(foreach x,$(IP_DIRS),distclean-$(x))
.PHONY: clean-prj
.PHONY: clean
.PHONY: distclean-prj
.PHONY: distclean-ip
.PHONY: distclean

all:

init: init-prj

init-prj: $(foreach x,$(PRJ_NAMES),init-$(x))

$(foreach x,$(PRJ_NAMES),init-$(x)):
	$(MAKE) -C ./$(subst init-,,$@) init

$(foreach x,$(PRJ_NAMES),clean-$(x)):
	$(MAKE) -C ./$(subst clean-,,$@) clean

$(foreach x,$(PRJ_NAMES),distclean-$(x)):
	$(MAKE) -C ./$(subst distclean-,,$@) distclean

$(foreach x,$(IP_NAMES),clean-$(x)):
	$(MAKE) -C ./ip_repo/$(subst clean-,,$@) clean

$(foreach x,$(IP_NAMES),distclean-$(x)):
	$(MAKE) -C ./ip_repo/$(subst distclean-,,$@) distclean

clean-prj: $(foreach x,$(PRJ_NAMES),clean-$(x))
clean-ip: $(foreach x,$(IP_NAMES),clean-$(x))

distclean-prj: $(foreach x,$(PRJ_NAMES),distclean-$(x))
distclean-ip: $(foreach x,$(IP_NAMES),distclean-$(x))

clean: clean-ip clean-prj
distclean: distclean-ip distclean-prj
