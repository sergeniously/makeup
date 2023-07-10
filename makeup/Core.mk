####################
# Core makeup module
#  implements core macros
#  included automatically

# Define common building applications
# in case they are not set or empty
STRIP:=$(or $(STRIP),strip)
MAKE:=$(or $(MAKE),make)

# Variables for colorful output
# May be overrided in makeup.mk
ifeq ($(shell tput colors 2>/dev/null),256)
COLOR_INFO=\033[01;37m# Bold white
COLOR_ERROR?=\033[01;31m# Bold red
COLOR_BUILD?=\033[01;32m# Bold green
COLOR_COMPILE?=\033[0;32m# Plain green
COLOR_PREPROCESS?=\033[0;33m# Plain yellow
COLOR_DEPENDENCY?=\033[01;35m# Bold purple
COLOR_EXTERNAL?=\033[01;34m# Bold blue
COLOR_PACKAGE?=\033[01;35m# Bold purple
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

define help # (target, comment ...)
@ echo "> $(COLOR_INFO)make $(1)$(COLOR_OFF)"; echo "    $(strip $(2))"
endef

# Macro to join @words with @splitter
define join_with # (splitter, words)
$(subst $() $(),$(1),$(strip $(2)))
endef

ifeq ($(shell which tr),)
# Macros to natively convert text to uppercase/lowercase forms
alphabet=a b c d e f g h i j k l m n o p q r s t u v w x y z
ALPHABET=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

define uppercase
$(strip $(eval _=$(1))\
$(foreach N,1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26,\
$(eval _=$(subst $(word $(N),$(alphabet)),$(word $(N),$(ALPHABET)),$(_))))$(_))
endef
define lowercase
$(strip $(eval _=$(1))\
$(foreach N,1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26,\
$(eval _=$(subst $(word $(N),$(ALPHABET)),$(word $(N),$(alphabet)),$(_))))$(_))
endef
else # short versions of macros that use tr utility
define uppercase
$(shell echo "$(1)" | tr [a-z] [A-Z])
endef
define lowercase
$(shell echo "$(1)" | tr [A-Z] [a-z])
endef
endif

# Extract all values of options with specified @pattern
# Example: $(call opt_all, FILE:one FILE:two, FILE:%, rm -f %) -> rm -f one two
define opt_all # (options ..., pattern, [replace])
$(subst %,$(patsubst $2,%,$(filter $2,$1)),$(or $3,%))
endef

# Extract the first value of options with specified @pattern
# Example: $(call opt_one, MODE:123 DIR:any, MODE:%, -m %) -> -m 123
define opt_one # (options ..., pattern, [replace], [default])
$(or $(patsubst $2,$(or $3,%),$(firstword $(filter $2,$1))),$4)
endef

# Return @replace string if @pattern is not found in @options
# Example: $(call opt_not, DIR:one DEPEND:two, EXCLUDE, YES) -> YES
# Example: $(call opt_not, DEPEND:two EXCLUDE, EXCLUDE, YES) -> 
define opt_not # (options ..., pattern, replace)
$(if $(filter $2,$1),,$3)
endef

# Extract all values of options with specified @pattern
# Example: $(call opt_all, FILE:one FILE:two, FILE:%, --file=%) -> --file=one --file=two
define opt_each # (options ..., pattern, [replace])
$(foreach word,$(patsubst $2,%,$(filter $2,$1)),$(subst %,$(word),$(or $3,%)))
endef

# Extract lists of values separated by colon from options with specified pattern
# Example: $(call opt_list, FILES:one;two;tri, FILES:%, cp -f %) -> cp -f one two tri
define opt_list # (options ..., pattern, [replace])
$(subst %,$(subst ;, ,$(patsubst $2,%,$(filter $2,$1))),$(or $3,%))
endef

# Extract COMMENT:string from options (all underlines in string are replaced with a space)
# Example: $(call opt_comment,COMMENT:Some_phrase) -> Some phrase
define opt_comment # (options ..., [default])
$(subst _, ,$(patsubst COMMENT:%,%,$(filter COMMENT:%,$1)))
endef

# Macro find_program(names ..., [PATH:dir ...] [REQUIRED] [RECURSIVE])
#  searches executable @names in @PATH or in system $PATH and return one found variant
#  if REQUIRED option specified and program is not found it generates an error and stops working
#  if RECURSIVE option specified a program will be searched recursively in @paths (use carefully!)
# Example: QMAKE=$(call find_program, qmake, PATH:/usr/lib/qt5 REQUIRED)
define find_program
$(or \
	$(firstword $(foreach name,$1,$(foreach path,$(call opt_all,$2,PATH:%),\
		$(shell find $(path) $(call opt_not,$2,RECURSIVE,-maxdepth 1) -executable -name $(name) 2>/dev/null)))),\
	$(firstword $(shell which $1)),\
	$(if $(filter REQUIRED,$2),
		$(error Program $1 is not found)))
endef

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
$(eval DEPEND_FILES=$(filter %.d,$(OBJECT_FILES:%.o=%.d)))
endef

# Macro to get target files corresponding to already added @names targets
#$(foreach name,$(1),$(filter $(BINDIR)/$(name) $(BINDIR)/lib$(name).%,$(TARGET_FILES)))
define get_targets # (names ...)
$(foreach name,$(1),$($(name)_TARGET_FILES))
endef

# Macro to extract dependency target files or names from a list of options
define get_depends # (options ...)
$(foreach name,$(call opt_all,$1,DEPEND:%) $(call opt_list,$1,DEPENDS:%),$(or $(call get_targets,$(name)),$(name)))
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
$(eval LINK_OPTIONS+=$(foreach path,$1,-L$(path) -Wl,-rpath,$(path)))
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

# Universal macro to create binary target file
#  it is supposed to be used by concrete modules
# Arguments:
# $(1:name): a target name to aggregate target files
# $(2:file): a basename of a file that will be created in BINDIR
# $(3:sources): a list of prerequisite source files for target @file
# $(4:comment): a comment to print of what is going to be done
# $(5:command): a command to create binary target @file
# $(6:options):
#  [DEPEND:name ...]: additional dependency for target @file
#  [EXCLUDE_FROM_ALL]: do not add target to default all target
# Example: $(call add_binary_target,foo,libfoo.a,foo.cpp,Building static library,g++ $$^ -o $$@)
define add_binary_target # (name, file, sources ..., comment, command, options ...)
$(eval \
# add rules for objects
$(call add_sources,$(3))
# add dependencies for objects
-include $(DEPEND_FILES)

$(2): $(BINDIR)/$(2)
	@ echo "$(COLOR_INSTALL)Target $2 is 100% built$(COLOR_OFF)"

$(BINDIR)/$(2): $(OBJECT_FILES) $(call get_depends,$(6))
	@ echo "$(COLOR_BUILD)$(or $(4),Building binary file): $$@$(COLOR_OFF)"
	$(or $(5),$(error command is not provided for $(1)))

$(call opt_not,$(6),EXCLUDE_FROM_ALL,all: $(2))

clean-$(1)::
	rm -f $(BINDIR)/$(2) $(OBJECT_FILES) $(DEPEND_FILES)
clean: clean-$(1)

help::
	$(call help,$(2),$(or $(4),Building binary file) $(BINDIR)/$(2))

$(1)_TARGET_FILES += $(BINDIR)/$(2)
)
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

# Macro to build sub directory target
define add_subdir_target # (name, [DIR:dir] [DEPEND:name ...] [EXCLUDE_FROM_ALL])
$(foreach directory,$(call opt_one,$(2),DIR:%,%,$(1)),$(eval \
.PHONY: $(1) # in case a name matches a dir name

$(call opt_not,$(2),EXCLUDE_FROM_ALL,all: $(1))

$(1): $(call opt_all,$(2),DEPEND:%)
	@+ $(MAKE) -C $(directory) all

check-$(1):
	@+ $(MAKE) -C $(directory) check
check: check-$(1)

clean-$(1):
	@ $(MAKE) -C $(directory) clean
clean: clean-$(1)

install::
	@ $(MAKE) -C $(directory) install

help::
	$(call help,$(1),Building default target in subdirectory <$(directory)>)
))
endef


# Macro to include modules from makeup directory
#  example: $(call import_modules,ExternalProject Qt)
# TODO: add second @dir-patterns argument to include modules only for specific sub directories
#  so that it will be easy to implement different building strategies for specific directories
#  from within the project makeup.mk file like that:
#   $(call import_modules,Cpp,sources/cpp/%)
#   $(call import_modules,Qt,sources/cpp/gui/%)
define import_modules # (modules ...)
$(eval include $(1:%=$(MAKEUP_DIR)/%.mk))
endef
