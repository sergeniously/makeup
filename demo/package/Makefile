include ../../makeup.mk

$(call import_modules,Package Deb Rpm)

PACKAGE_CHANGES=\
	* added deb-package generator \
	* added rpm-package generator

PACKAGE_ARCHITECTURE:=$(shell uname -m)

$(call package_add,makeup,deb rpm)
$(call package_install,makeup,deb rpm,cp -Taf $(ROOT_INSTALL_DIR) {PACKAGE_INSTALL_DIR})
$(foreach stage,preinstall postinstall preuninstall postuninstall,\
	$(call package_scriplet,makeup,deb rpm,$(stage),scriplets/$(stage).sh))

$(call rpm_package_files_find,makeup,$(ROOT_INSTALL_DIR))
$(call deb_package_override,makeup,auto_build auto_test)
