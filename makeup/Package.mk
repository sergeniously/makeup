#######################
# Package makeup module
#  Implements generic logic to create distribution packages.
# NOTE THAT: specific logic to create different types of packages
#  must be implemented in corresponding modules (see Deb.mk, Rpm.mk).
# HOW TO create custom package generator:
# 1) create custom module file in makeup directory (for example: Custom.mk);
# 2) define there following macros with package type prefix corresponding to module file name:
#  + custom_package_add(name,file) which must implement following targets:
#   * custom-package-build: target to generate custom package;
#   * custom-package-configuration: target to generate configuration for custom package;
#   * custom-package-configure:: target to generate necessary files for custom package configuration;
#   * custom-package-reset:: target to create environment for custom package (e.g. directories);
#   * custom-package-clean:: target to clean files of custom package;
#  + custom_package_install(name,command):
#     macro to override command to provide files for custom package;
#     it also must replace {PACKAGE_INSTALL_DIR} in a command with actual package files directory; 
#     it is recommended to implement this macro by adding recipes to custom-package-configure target.
#  + custom_package_preinstall_scriplet(name):
#  + custom_package_postinstall_scriplet(name):
#  + custom_package_preuninstall_scriplet(name):
#  + custom_package_postuninstall_scriplet(name):
#     macros which must return file paths to custom package scriplets.
# 3) optionally define specific macros for custom package which prefferebly
#     should add recipes to custom-package-configure target.
# 4) import Custom module in Makefile add call macros from Package module.
#######################

# Default directory for built packages
# Can be set in project makeup.mk file
PACKAGE_DIR?=$(BINDIR)

PACKAGE_ARCHITECTURE=any
PACKAGE_NAME=$(PROJECT_NAME)
PACKAGE_DESCRIPTION=$(PROJECT_DESCRIPTION)
PACKAGE_VERSION=$(PROJECT_VERSION)
PACKAGE_RELEASE=1
PACKAGE_VENDOR=$(PROJECT_COPYRIGHT)
PACKAGE_EMAIL=$(PROJECT_EMAIL)
PACKAGE_URL=$(PROJECT_URL)

PACKAGE_CHANGES=$(error Package changes are required)

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

$1-$(type)-reset:: $1-$(type)-clean

clean: $1-$(type)-clean

)$(call $(type)_package_add,$1,$(file))))
endef

# Macro to add custom stage script package.
# Usage: $(call package_scriplet,name,types,stage,script,[variables ...])
# Where:
#  @name: package name to provide scriplet for
#  @types: package types to provide scriplet for
#  @stage: one of [preinstall,postinstall,preuninstall,postuninstall]
#  @script: path to a script template with {VARIABLE} replacements
#  @variables: additional variables to replace in a @script
define package_scriplet
$(foreach type,$2,$(foreach script,$(call $(type)_package_$3_scriplet,$1),$(eval \
$1-$(type)-configure::
	$(call package_comment,$(type),Configuring $3 scriplet for $1;)
	cp -f $4 $(script)
	sed -i $(script) \
		-e "s|{PACKAGE_TYPE}|$(type)|g" \
		-e "s|{PACKAGE_ARCH}|$(PACKAGE_ARCHITECTURE)|g" \
		-e "s|{PACKAGE_NAME}|$(or $(PACKAGE_NAME),$1)|g" \
		-e "s|{PACKAGE_VERSION}|$(PACKAGE_VERSION)|g" \
		-e "s|{PACKAGE_DESCRIPTION}|$(PACKAGE_DESCRIPTION)|g" \
		-e "s|{PACKAGE_VENDOR}|$(PACKAGE_VENDOR)|g" \
		-e "s|{PACKAGE_EMAIL}|$(PACKAGE_EMAIL)|g" \
		-e "s|{PACKAGE_URL}|$(PACKAGE_URL)|g" \
		$(subst =,}|,$(5:%=-e "s|{%|g"))
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
