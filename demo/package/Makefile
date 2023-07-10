include ../../makeup.mk

$(call import_modules,Package Deb Rpm)

PACKAGE_CHANGES=\
	* added deb-package generator \
	* added rpm-package generator

$(call package_add,makeup,deb rpm)
$(call package_install,makeup,deb rpm,cp -Taf $(ROOT_INSTALL_DIR) {PACKAGE_INSTALL_DIR})
$(call package_scriplet,makeup,deb rpm,preinstall,scriplets/pre-install.sh)
$(call package_scriplet,makeup,deb rpm,postinstall,scriplets/post-install.sh)

$(call rpm_package_files_find,makeup,$(ROOT_INSTALL_DIR))
$(call deb_package_override,makeup,auto_build auto_test)
