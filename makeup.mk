####################
# makeup kernel file
# ! This file implements generic macros to create targets using cmake-like syntax

# Detect absolute root path of sources (makeup.mk location)
ROOT_SOURCE_DIR:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))
# Detect absolute root path to build targets
ROOT_BINARY_DIR:=$(or $(BUILD_DIR),$(ROOT_SOURCE_DIR)/build)

CURRENT_SOURCE_DIR=$(CURDIR)
# Detect current binary directory based on current source directory
CURRENT_BINARY_DIR=$(ROOT_BINARY_DIR)$(CURDIR:$(ROOT_SOURCE_DIR)%=%)

# Default install directory
ROOT_INSTALL_DIR:=$(or $(DESTDIR),$(ROOT_SOURCE_DIR)/install)

# Define common building applications
# in case they are not set or empty
STRIP:=$(or $(STRIP),strip)
MAKE:=$(or $(MAKE),make)

# Variables for colorful output
# May be overrided in makeup.pj
ifeq ($(shell tput colors 2>/dev/null),256)
COLOR_ERROR?=\033[01;31m# Bold red
COLOR_BUILD?=\033[01;32m# Bold green
COLOR_COMPILE?=\033[0;32m# Plain green
COLOR_PREPROCESS?=\033[0;33m# Plain yellow
COLOR_DEPENDENCY?=\033[01;35m# Bold purple
COLOR_EXTERNAL?=\033[01;34m# Bold blue
COLOR_INSTALL?=\033[01;37m# Bold white
COLOR_TEST?=\033[0;36m# Plain cyan
COLOR_OFF:=\033[0m
endif

# Comma variable to use in call arguments
# E.g.: $(call func, one$(,)two$(,)three)
,=,

# Newline and tab variables to be used to generate multiline recipes
define NEWLINE


endef
define TAB
	
endef

ifndef VERBOSE
.SILENT: # suppress display of executed commands
endif

# Disable built-in rules to avoid circular dependency dropping
.SUFFIXES: # (if not enough try MAKEFLAGS+=--no-builtin-rules)

# Default target to build when no arguments are given to make
.DEFAULT_GOAL := all

# No-file targets to build independently
.PHONY: all check install clean

show-built: # informative target to show current built binaries
	- find $(CURRENT_BINARY_DIR) -type f 2> /dev/null

$(CURRENT_BINARY_DIR):
	mkdir -p $@

# Macro find_program(names ..., paths ..., [REQUIRED] [RECURSIVE])
#  searches executable @names in @paths or in system $PATH and return one found variant
#  if REQUIRED option specified and program is not found it generates an error and stops working
#  if RECURSIVE option specified a program will be searched recursively in @paths (use carefully!)
# Example: QMAKE=$(call find_program, qmake, /usr/lib/qt5, REQUIRED)
define find_program
$(or \
	$(firstword $(foreach name,$(1),$(foreach path,$(2),\
		$(shell find $(path) $(if $(filter RECURSIVE,$(3)),,-maxdepth 1) -executable -name $(name) 2>/dev/null)))),\
	$(firstword $(shell which $(1))),\
	$(if $(filter REQUIRED,$(3)),
		$(error Program $(1) is not found)))
endef

# Macro to join @words with @splitter
define join_with # (splitter, words)
$(subst $() $(),$(1),$(strip $(2)))
endef

# Extract all values of options with specified @pattern
#  example: $(call opt_all, DIR:foo DEPEND:bar DEPEND:tar, DEPEND:%) -> bar tar
define opt_all # (options ..., pattern, [replace])
$(patsubst $(2),$(or $(3),%),$(filter $(2),$(1)))
endef

# Extract the first value of options with specified @pattern
#  example: $(call opt_one, MODE:123 DIR:any, MODE:%, -m %) -> -m 123
define opt_one # (options ..., pattern, [replace], [default])
$(or $(patsubst $(2),$(or $(3),%),$(firstword $(filter $(2),$(1)))),$(4))
endef

# For concise usage below
BINDIR=$(CURRENT_BINARY_DIR)

# Macro to convert source file paths into binary file paths
define binary # ([BINDIR/|CURDIR/][subdir/]file) -> BINDIR/[subdir_]file
$(foreach source,$(subst $(BINDIR)/,,$(subst $(CURDIR)/,,$(abspath $(1)))),\
$(BINDIR)/$(subst /,_,$(subst $(ROOT_SOURCE_DIR)/,,$(source))))
endef

# Macro to add rules to build objects from sources
#  for each source file it calls appropriate macro according to its suffix
#  for example, for *.c file it calls add_source.c macro implemented in Cpp module
#  also defines OBJECT_FILES and DEPEND_FILES variables that contain added object files
define add_sources
$(eval OBJECT_FILES=$(foreach source,$(1),$(call add_source$(suffix $(source)),$(source))))\
$(eval DEPEND_FILES=$(filter %.d,$(OBJECT_FILES:%.o=%.d)))\
$(value OBJECT_FILES)
endef

# Macro to get target files corresponding to already added @names targets
#$(foreach name,$(1),$(filter $(BINDIR)/$(name) $(BINDIR)/lib$(name).%,$(TARGET_FILES)))
define get_targets # (names ...)
$(foreach name,$(1),$($(name)_TARGET_FILES))
endef

# Macro to extract dependency target files or names from a list of options
define get_depends # (options ...)
$(foreach name,$(call opt_all,$(1),DEPEND:%),$(or $(call get_targets,$(name)),$(name)))
endef

# Adds compile options as is
define add_compile_options
$(eval COMPILE_OPTIONS+=$(1))
endef

# Macro to add definitions for compiler in NAME[=VALUE] form
#  do not add them with -D prefixes as so they added automatically
define add_definitions # (DEFINES ...)
$(eval COMPILE_OPTIONS+=$(1:%=-D%))
endef

# Macro to add directories to search include files by compiler
define include_directories # (paths ...)
$(eval COMPILE_OPTIONS+=$(1:%=-I%))
endef

# Adds link options as is
define add_link_options
$(eval LINK_OPTIONS+=$(1))
endef

# Macro to add directories to search libraries by linker
define link_directories # (paths ...)
$(eval LINK_OPTIONS+=$(1:%=-L%) -Wl,-rpath,$(subst $() $(),:,$(1)))
endef

# Macro to link libraries or options
#  adds explicitly linked libraries (*.a *.so) or options (-*) as is
#  also appends binary path to those which have relative specifier
#  example: $(call link_libraries,boost_system -l:libzip.a)
define link_libraries # (-options ... libraries ...)
$(eval \
LINK_LIBRARIES+=$(foreach lib,$(1),$(if $(filter %.a %.so -%,$(lib)),\
$(if $(filter ../%,$(lib)),$(abspath $(BINDIR)/$(lib)),$(lib)),-l$(lib))))
endef

# Macro add_dependencies:
#  adds relative sub- or parent-directory @dependencies for @target and rules to build and clean them
#  ! to add internal dependencies use optional DEPEND:name arguments of program/library adding macros
# Example: $(call add_dependencies,foo, ../libbar.a sub/libtar.so)
define add_dependencies # (target, dependencies ...)
$(foreach dependency,$(2),$(eval \
$(call get_targets,$(1)): $(abspath $(BINDIR)/$(dependency)) # attach @dependency to @target files
$(abspath $(BINDIR)/$(dependency)): build-$(1)-dependencies # define rule to build this @dependency

build-$(1)-dependencies:: # append recipes to build @dependency
	@ echo "$(COLOR_DEPENDENCY)Checking and building $(1) dependency: $(notdir $(dependency))$(COLOR_OFF)"
	@+ $(MAKE) -C $(dir $(dependency)) $(notdir $(dependency))

clean-$(1)-dependencies:: # clean only child directories to avoid recursion
	$(foreach directory,$(filter $(CURDIR)/%,$(dir $(abspath $(dependency)))),$(MAKE) -C $(directory) clean)
clean: clean-$(1)-dependencies
))
endef

# Macro add_test_directory(dir)
define add_test_directory
$(eval \
check-dir-$(1):
	@ $(MAKE) -C $(1) check
check: check-dir-$(1)
clean-dir-$(1):
	@ $(MAKE) -C $(1) clean
clean: clean-dir-$(1)
)
endef

# Macro add_test_program(test-name, program)
define add_test_program
$(eval \
check-$(1): $(BINDIR)/$(2)
	@ echo "$(COLOR_TEST)Running tests: $(1) ($(2))$(COLOR_OFF)"
	$(BINDIR)/$(2)
check: check-$(1)
)
endef

# Macro add_test_command(test-name, command ...)
define add_test_command
$(eval \
check-$(1): $(TARGET_FILES)
	@ echo "$(COLOR_TEST)Running tests: $(1) ($(firstword $(2)))$(COLOR_OFF)"
	$(2)
check: check-$(1)
)
endef

# Macro to build sub directory target
define add_subdir_target # (name, [DIR:dir] [DEPEND:name ...] [EXCLUDE_FROM_ALL])
$(eval \
.PHONY: $(1) # in case a name matches a dir name

$(if $(filter EXCLUDE_FROM_ALL,$(2)),,all: $(1))

$(1): $(call opt_all,$(2),DEPEND:%)
	@+ $(MAKE) -C $(call opt_one,$(2),DIR:%,,$(1)) all

check-$(1):
	@ $(MAKE) -C $(call opt_one,$(2),DIR:%,,$(1)) check
check: check-$(1)

install-$(1):
	@ $(MAKE) -C $(call opt_one,$(2),DIR:%,,$(1)) install
install: install-$(1)

clean-$(1):
	@ $(MAKE) -C $(call opt_one,$(2),DIR:%,,$(1)) clean
clean: clean-$(1)
)
endef

# Macro to add rule to install target files of target @names in @destination
#  (note: double-colon means adding recipes to target)
define install_targets # (names ..., destination, [MODE:123])
$(eval \
install-targets:: $(call get_targets,$(1))
	@ echo "$(COLOR_INSTALL)Installing $$(^F) in $(2) ...$(COLOR_OFF)";
	mkdir -p $(2) && install $(call opt_one,$(3),MODE:%,-m %) -t $(2) $$^
install: install-targets
)
endef

# Macro to add rule to install @dirs in @destination
define install_directories # (dirs ..., destination)
$(eval \
install-directories::
	@ echo "$(COLOR_INSTALL)Installing directories $(1) in $(2) ...$(COLOR_OFF)";
	mkdir -p $(2) && cp -rf $(1) $(2)
install: install-directories
)
endef

# Macro to install files (RENAME can be used only if one file is installed)
# Example: $(call install_files,config,$(INSTALL_DIR)/etc, MODE:666 RENAME:foo.cfg)
define install_files # (files ..., destination, [MODE:123] [RENAME:name])
$(eval \
install-files::
	@ echo "$(COLOR_INSTALL)Installing files $(1) in $(2) ...$(COLOR_OFF)";
	mkdir -p $(2)
	$(foreach file,$(1),install $(call opt_one,$(3),MODE:%,-m %) -T $(file) \
		$(2)/$(call opt_one,$(3),RENAME:%,%,$(notdir $(file)))$(NEWLINE)$(TAB))
install: install-files
)
endef

# Macro to include modules from makeup directory
#  example: $(call makeup_import,ExternalProject Qt)
# TODO: add second @dir-patterns argument to include modules only for specific sub directories
#  so that it will be easy to implement different building strategies for specific directories
#  from within the project makeup.pj file like that:
#   $(call makeup_import,Cpp,sources/cpp/%)
#   $(call makeup_import,Qt,sources/cpp/gui/%)
define makeup_import # (modules ...)
$(eval include $(1:%=$(ROOT_SOURCE_DIR)/makeup/%.mk))
endef

# Include project related file if it exists
-include $(ROOT_SOURCE_DIR)/makeup.pj
