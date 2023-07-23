#######################
# Package makeup module
#  Implements generic logic to create distribution packages.
# Support: s.belenkov@securitycode.ru
# NOTE THAT: specific logic to create different types of packages
#  must be implemented in corresponding modules (see Deb.mk, Rpm.mk).
# HOW TO create custom package generator:
# 1) create custom module file in makeup directory (for example: Custom.mk);
# 2) define there following macros with package type prefix corresponding to module file name:
#  + custom_package_add(name,file) which must implement following targets:
#   * name-custom-build: target to generate custom package;
#   * name-custom-configuration: target to generate configuration for custom package;
#   * name-custom-configure:: target to generate necessary files for custom package configuration;
#   * name-custom-reset:: target to create environment for custom package (e.g. directories);
#   * name-custom-clean:: target to clean files of custom package;
#  + custom_package_install(name,command):
#     macro to override command to provide files for custom package;
#     it also must replace {PACKAGE_INSTALL_DIR} in a command with actual package files directory; 
#     it is recommended to implement this macro by adding recipes to name-custom-configure target.
#  + custom_package_preinstall_scriplet(name):
#  + custom_package_postinstall_scriplet(name):
#  + custom_package_preuninstall_scriplet(name):
#  + custom_package_postuninstall_scriplet(name):
#     macros which must return file paths to custom package scriplets.
# 3) optionally define specific macros for custom package which prefferebly
#     should add recipes to name-custom-configure target.
# 4) import Custom module in Makefile add call macros from Package module.
#######################

# Default directory for built packages
# Can be set in project makeup.mk file
PACKAGE_DIR?=$(BINDIR)

PACKAGE_NAME=$(PROJECT_NAME)
PACKAGE_DESCRIPTION=$(PROJECT_DESCRIPTION)
PACKAGE_VERSION=$(PROJECT_VERSION)
PACKAGE_VENDOR=$(PROJECT_COPYRIGHT)
PACKAGE_EMAIL=$(PROJECT_EMAIL)
PACKAGE_URL=$(PROJECT_URL)

PACKAGE_RELEASE=1
PACKAGE_ARCHITECTURE=noarch
PACKAGE_CHANGES=$(error Package changes are required)

# Package scriplet preprocessor command
PACKAGE_SCRIPLET_PREP:=$(call find_program,clang cpp)
# Package scriplet modificator command (on Darwin OS sed requires argument for in-place option!)
PACKAGE_SCRIPLET_EDIT:=$(call equal,$(shell uname -s),Darwin,sed -i '',sed -i)
# Variables to be replaced in scriplets of all packages (can be overrided or extended)
PACKAGE_SCRIPLET_VARS=PACKAGE_NAME PACKAGE_VERSION PACKAGE_DESCRIPTION \
	PACKAGE_VENDOR PACKAGE_EMAIL PACKAGE_URL
# Definitions to be used by scrilet preprocessor (can be overrided or extended)
PACKAGE_SCRIPLET_DEFS=$(PACKAGE_ARCHITECTURE)

# Macro to make a command to print a colorful package comment
define package_comment # (type, message ...)
@ echo "$(COLOR_PACKAGE)$1: $2$(COLOR_OFF)"
endef

# Macro to add package of different types.
# Usage: $(call package_add,name,types,[file])
# Where:
#  @name: package name in lowercase without spaces
#  @types: package types (e.g. deb rpm etc)
#  @file: package file name without suffix (default: @name-version-architecture)
define package_add
$(foreach type,$2,$(foreach file,$(PACKAGE_DIR)/$(strip \
$(or $3,$(or $(PACKAGE_NAME),$1)-$(PACKAGE_VERSION)-$(PACKAGE_ARCHITECTURE)).$(type)),$(eval \

all $(type): $1-$(type)-package

$1-$(type)-package: $1-$(type)-build
	@ echo "$(COLOR_BUILD)$1 $(type) package is 100% done$(COLOR_OFF)\
		$(if $(VERBOSE),,(see $(PACKAGE_DIR)/$(type)/$1/log))."

$1-$(type)-build: $1-$(type)-configuration

$1-$(type)-configuration: $1-$(type)-configure

$1-$(type)-configure:: $1-$(type)-reset
	$(call package_comment,$(type),Configuring $1 package...)

$1-$(type)-reset:: $1-$(type)-clean

clean: $1-$(type)-clean

)$(call $(type)_package_add,$1,$(file))))
endef

# Macro to add custom stage script package.
# Usage: $(call package_scriplet,name,types,stage,script,[options ...])
# Where:
#  @name: package name to provide scriplet for
#  @types: package types to provide scriplet for
#  @stage: one of [preinstall,postinstall,preuninstall,postuninstall]
#  @script: path to a script template with {VARIABLE} replacements
#  @options:
#   DEF:Name ...: additional definitions for preprocessor to work with
#   VAR:Name ...: additional variables to be replaced in a @script ({Name} -> $(Name))
# Example: $(call package_scriplet,name,deb,preinstall,preinstall.sh,DEF:LINUX VAR:LICENSE)
define package_scriplet
$(foreach type,$2,$(foreach script,$(call $(type)_package_$3_scriplet,$1),$(eval \
$1-$(type)-configure::
	# Generating $3 scriplet for $1
	$(if $(PACKAGE_SCRIPLET_PREP),\
		$(PACKAGE_SCRIPLET_PREP) -undef -nostdinc -x assembler-with-cpp -o $(script) -E $4 \
		$(foreach def,$(type) $(PACKAGE_SCRIPLET_DEFS) $(call opt_all,$5,DEF:%),-D$(def)), \
		$(warning Cannot preprocess scriplet)cp $4 $(script))
	$(PACKAGE_SCRIPLET_EDIT) -e '/^\# [0-9]/d' -e '/^$$$$/N;/^\n$$$$/D' \
		$(foreach var,$(sort $(PACKAGE_SCRIPLET_VARS) $(call opt_all,$5,VAR:%)),\
			-e 's|{$(var)}|$($(var))|g') $(script)
)))
endef

# Macro to provide a command to install files for package.
# Usage: $(call package_install,name,types,command)
# Where:
#  @name: package name to install files for;
#  @types: package types (e.g. deb, rpm, etc);
#  @command: command to install files for package.
define package_install
$(foreach type,$2,$(call $(type)_package_install,$1,$3))
endef
