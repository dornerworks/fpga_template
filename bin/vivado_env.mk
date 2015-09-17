# -*- mode:makefile -*-
# Copyright (c) 2015, DornerWorks Ltd.

UNAME_S := $(shell uname -s | tr A-Z a-z)

ifneq ($(findstring mingw,$(UNAME_S)),)
  include $(PROJECT_ROOT)/bin/vivado/mingw_env.mk
endif

ifneq ($(findstring cygwin,$(UNAME_S)),)
  include $(PROJECT_ROOT)/bin/vivado/cygwin_env.mk
endif

ifneq ($(findstring linux,$(UNAME_S)),)
  include $(PROJECT_ROOT)/bin/vivado/linux_env.mk
endif

TOUCH := touch
ECHO := echo -e
SED := sed
RM := rm -rf
TAR := tar
MKDIR := mkdir -p

TIMESTAMP := $$( date +%Y%m%d_%H%M%S )

PRJ_BIN := $(PROJECT_ROOT)/bin
PROJECT_RULES := $(PROJECT_ROOT)/bin/vivado/project_rules.mk
VIVADO_RULES := $(PROJECT_ROOT)/bin/vivado/vivado_rules.mk
XSIM_RULES := $(PROJECT_ROOT)/bin/vivado/xsim_rules.mk
