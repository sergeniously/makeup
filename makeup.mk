####################
# makeup kernel file
# ! This file implements generic logic

# Detect absolute root path of sources (makeup.mk location)
ROOT_SOURCE_DIR:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))
# Detect absolute root path to build targets
ROOT_BINARY_DIR:=$(or $(BUILD_DIR),$(ROOT_SOURCE_DIR)/build)

CURRENT_SOURCE_DIR=$(CURDIR)
# Detect current binary directory based on current source directory
CURRENT_BINARY_DIR:=$(ROOT_BINARY_DIR)$(CURDIR:$(ROOT_SOURCE_DIR)%=%)
# For concise usage according to CURDIR
BINDIR=$(CURRENT_BINARY_DIR)

# Default install directory
ROOT_INSTALL_DIR:=$(or $(DESTDIR),$(ROOT_SOURCE_DIR)/install)

# Include standard modules independently
include $(ROOT_SOURCE_DIR)/makeup/Core.mk
include $(ROOT_SOURCE_DIR)/makeup/Test.mk
include $(ROOT_SOURCE_DIR)/makeup/Install.mk
# Include project-specific file if it exists
-include $(ROOT_SOURCE_DIR)/makeup/Project.mk

ifndef VERBOSE
.SILENT: # suppress display of executed commands
endif

# Disable built-in rules to avoid circular dependency dropping
.SUFFIXES: # (if not enough try MAKEFLAGS+=--no-builtin-rules)

# Default target to build when no arguments are given to make
.DEFAULT_GOAL := all

# No-file targets to build independently
.PHONY: all check install clean

built: # informative target to print built binaries
	- find $(CURRENT_BINARY_DIR) -type f 2> /dev/null

$(CURRENT_BINARY_DIR):
	mkdir -p $@

help::
	@ echo "Use some of the following commands for current directory:"
	$(call help,all,Building everything that can be built (default target))
	$(call help,built,Printing all built files for current and subdirectories)
	$(call help,check,Running test programs or commands if there are such ones)
	$(call help,install DESTDIR=dir (default: $(ROOT_INSTALL_DIR)),Installing built target files in DESTDIR directory)
	$(call help,clean,Deleting everything that was built for current directory)
