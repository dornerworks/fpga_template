# -*- mode:makefile -*-
# Copyright (c) 2015, DornerWorks Ltd.

# path to the vivado XPR project file
PRJ_XPR := ./prj/$(PRJ_NAME).xpr

# project initialization script; to initialize after VCS checkout
INIT_TCL := ./$(PRJ_NAME)_init.tcl

# script used to save existing project state to the initialization scripts
# this is for better version control compatibility
SAVE_TCL := $(PROJECT_ROOT)/bin/vivado/save_project.tcl

# script used to launch and manage synthesis and implementation runs
RUN_TCL := $(PROJECT_ROOT)/bin/vivado/launch_run.tcl

# common batch mode command line arguments
BATCH := $(VIVADO) -nolog -nojournal -notrace -mode batch



# default target; re-creates project from TCL scripts.
.PHONY: all
all: init

# re-create projects from TCL scripts
.PHONY: init
init:
	$(BATCH) -source $(INIT_TCL)
	$(RM) .Xil

# save project state to TCL scripts
.PHONY: save
save:
	$(BATCH) -source $(SAVE_TCL) $(PRJ_XPR)

# launch synthesis and implementation runs
.PHONY: $(PRJ_RUNS)
$(PRJ_RUNS):
	$(BATCH) -source $(RUN_TCL) $(PRJ_XPR) -tclargs $(PRJ_FLAGS) -out_dir ./out/$@ $@

# clean run outputs
.PHONY: clean
clean:
	@$(RM) ./out

# clean all generate and non-version control outputs
.PHONY: distclean
distclean: clean
	@$(RM) .Xil .srcs ./bd ./prj
	@if [ -d ./ip ]; then \
	   find ./ip -mindepth 2 -maxdepth 2 -not -name *.xci -exec rm -rf {} + ; \
	 fi;
