# -*- mode:makefile -*-
# Copyright (c) 2015, DornerWorks Ltd.

# directory to collect outputs in
OUT := ./out

# list of all simulations
SIMS := $(foreach x,$(PRJ),$($(x)_SIMS))

# phony targets to build an individual test without running it
SIM_BLD := $(foreach x,$(SIMS),$x.bld)

# relative path to xsim directory from $(OUT)
XSIM_DIR := $$( python $(PROJECT_ROOT)/bin/relpath.py '.' '$(OUT)' )

# list of all 'bld' targets
XSIM_BLD := $(foreach x,$(SIMS),$(OUT)/$x/xsim.bld)

# create a <sim>_PRJ variable for each sim indicating which project file to use
$(foreach x,$(PRJ),$(foreach y,$($(x)_SIMS),$(eval $(y)_PRJ := $x)))

# the sed script to extract xsim dependencies
XSIM_DEPS := "/^[ \t]*$$/d" -e "s/^[ \t]*vhdl[ \t]\+[a-zA-Z0-9_]\+[ \t]\+\(.*\)$$/\t\1 \\\/g"



# by default, build the simulations only
.PHONY: all
all: build

# for debugging
.PHONY: vars
vars:
	@$(ECHO) $(PRJ)
	@$(ECHO) $(SIMS)
	@$(ECHO) $(XSIM_DIR)
	@$(ECHO) $(XSIM_BLD)

# list all simulations that can be run
.PHONY: list
list:
	@echo "Projects:"; \
	 for x in $(PRJ); do \
	   echo "  $$x"; \
	 done; \
	 echo ""
	@echo "Simulations:"; \
	 for x in $(SIMS); do \
	   echo "  $$x"; \
	 done; \
	 echo ""

# targets to run individual sims
.PHONY: $(SIMS)
$(SIMS): %: $(OUT)/%/xsim.bld
	@cd $(dir $<); \
	 rm -rf xsim*.log xsim*.jou; \
	 if [ "x$(MODE)" == "x" ]; then \
	   MODE="cli"; \
	 else \
	   MODE=$$( echo $(MODE) | awk '{print tolower($$0)}' ); \
	 fi; \
	 if [ "$${MODE}" == "cli" ]; then \
	   if [ -e $(XSIM_DIR)/$@.tcl ]; then \
	     CMD="$(XSIM) -tclbatch $(XSIM_DIR)/$@.tcl"; \
	   else \
	     CMD="$(XSIM) -R"; \
	   fi; \
	 elif [ "$${MODE}" == "gui" ]; then \
	   if [ -e $(XSIM_DIR)/$@.wcfg ]; then \
	     CMD="$(XSIM) -gui -view $(XSIM_DIR)/$@.wcfg"; \
	   elif [ -e $(XSIM_DIR)/default.wcfg ]; then \
	     CMD="$(XSIM) -gui -view $(XSIM_DIR)/default.wcfg"; \
	   else \
	     CMD="$(XSIM) -gui"; \
	   fi; \
	 fi; \
	 CMD="$${CMD} $@"; \
	 if [ "x$${CMD}" != "x" ]; then \
	   $(ECHO) "$${CMD}"; \
	   $${CMD}; \
	 fi;

# provide a 'suite' target to run all
.PHONY: suite
suite: $(PRJ)

# build/compile the simulations
.PHONY: build
build: $(XSIM_BLD)

# build/compile a single simulation
.PHONY: $(SIM_BLD)
$(SIM_BLD): %.bld: $(OUT)/%/xsim.bld

# create targets for each project
$(foreach x,$(PRJ),$(eval .PHONY: $(x)))
$(foreach x,$(PRJ),$(eval $(x): $($(x)_SIMS)))

# targets to build each simulation
$(XSIM_BLD): OUT_DIR = $(dir $@)
$(XSIM_BLD): TC = $(notdir $(patsubst %/,%,$(OUT_DIR)))
$(XSIM_BLD): PRJ = $($(TC)_PRJ).prj
$(XSIM_BLD): XFLAGS_ = $(XFLAGS) $($($(TC)_PRJ)_XFLAGS) $($(TC)_XFLAGS)
$(XSIM_BLD):
	$(MKDIR) -p $(OUT_DIR)
	cd $(OUT_DIR); \
	$(XELAB) $(XFLAGS_) -prj $(XSIM_DIR)/../$(PRJ) $(TC)
	$(TOUCH) $@
	$(ECHO) "$@: \\" > $(OUT_DIR)/xsim.deps
	$(SED) -e $(XSIM_DEPS) < $(PRJ) >> $(OUT_DIR)/xsim.deps
	$(ECHO) "\t$(PRJ)" >> $(OUT_DIR)/xsim.deps

# default clean target
.PHONY: clean
clean:
	@$(RM) $(OUT) xsim.* *.log *.pb

# the distclean target is the same as the clean target
.PHONY: distclean
distclean: clean

# include dependencies generated for each simulation
include $(wildcard $(OUT)/*/xsim.deps)
