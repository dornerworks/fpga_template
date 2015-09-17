# -*- mode:makefile -*-

include $(PROJECT_ROOT)/bin/vivado_env.mk

include $(PROJECT_RULES)

.PHONY: archive
archive:
	ws=$$(basename $$PWD); \
	$(TAR) cvjf ../$${ws}-$(TIMESTAMP).tar.bz2 -C .. $$ws
