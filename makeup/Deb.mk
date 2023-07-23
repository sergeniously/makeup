###################
# Deb makeup module
#  Implements macros to generate debian package.

DEB_DIR:=$(PACKAGE_DIR)/deb
DEB_APP=$(call find_program,dh,REQUIRED)

DEB_PACKAGE_ARCHITECTURE=$(PACKAGE_ARCHITECTURE)
DEB_PACKAGE_VERSION=$(PACKAGE_VERSION)
DEB_PACKAGE_RELEASE=$(PACKAGE_RELEASE)
DEB_PACKAGE_DESCRIPTION=$(PACKAGE_DESCRIPTION)
DEB_PACKAGE_MAINTAINER=$(PACKAGE_VENDOR) <$(PACKAGE_EMAIL)>
DEB_PACKAGE_HOMEPAGE=$(PACKAGE_URL)
DEB_PACKAGE_EPOCH=
DEB_PACKAGE_DEPENDS=$$$${shlibs:Depends}, $$$${misc:Depends}
DEB_PACKAGE_SECTION=unknown
DEB_PACKAGE_PRIORITY=optional
DEB_PACKAGE_SHLIBDEPS=OFF
DEB_PACKAGE_DISTRIBUTION=UNRELEASED
DEB_PACKAGE_URGENCY=low
DEB_PACKAGE_DATETIME=$(shell date -R)

DEB_COMPATIBILITY_LEVEL=10
DEB_SOURCE_FORMAT=3.0 (quilt)

DEB_BUILD_DEPENDS=debhelper (>=$(DEB_COMPATIBILITY_LEVEL))
DEB_BUILD_OPTIONS=nostrip nocheck

DEB_ARCHIVE_TYPE=gnutar
DEB_COMPRESSION_TYPE=gzip

# Private macro to implement specific logic to generate debian packages.
#  It is called by Package module, so DO NOT call it manually!
# Signature: $(call deb_package_add,name,file)
define deb_package_add
$(eval \
$1-deb-build:
	$(call package_comment,deb,Generating $1 package: $2 ...)
	cd $(DEB_DIR)/$1 && DEB_BUILD_OPTIONS="$(DEB_BUILD_OPTIONS)" fakeroot $$(DEB_APP) binary \
		$(if $(VERBOSE),,> $(DEB_DIR)/$1/log 2>&1)

$1-deb-configuration:
	# Generating control file for $1
	printf "%s\n" \
		'Source: $1' \
		'Section: $(DEB_PACKAGE_SECTION)' \
		'Priority: $(DEB_PACKAGE_PRIORITY)' \
		'Maintainer: $(DEB_PACKAGE_MAINTAINER)' \
		'Homepage: $(DEB_PACKAGE_HOMEPAGE)' \
		$(if $(DEB_BUILD_DEPENDS),'Build-Depends: $(DEB_BUILD_DEPENDS)') \
		'Standards-Version: 3.8.4' \
		'' 'Package: $1' \
		'Architecture: $(DEB_PACKAGE_ARCHITECTURE)' \
		$(if $(DEB_PACKAGE_DEPENDS),'Depends: $(DEB_PACKAGE_DEPENDS)') \
		$(if $(DEB_PACKAGE_DESCRIPTION),'Description: $(DEB_PACKAGE_DESCRIPTION)') \
			> $(DEB_DIR)/$1/debian/control

$1-deb-configure::
	# Generating initial configuration files for $1
	printf "#!/usr/bin/make -f\n\n$(if $(VERBOSE),export DH_VERBOSE=1\n\n)%%:\n\tdh \$$$$@\n\n" \
		>> $(DEB_DIR)/$1/debian/rules
	printf "override_dh_builddeb:\n\tdh_builddeb --filename=$(notdir $2) --destdir=$(PACKAGE_DIR)\n\n" \
		>> $(DEB_DIR)/$1/debian/rules
	chmod +x $(DEB_DIR)/$1/debian/rules

	printf "%s (%s) %s; urgency=%s\n\n" \
		'$1' '$(DEB_PACKAGE_VERSION)' '$(DEB_PACKAGE_DISTRIBUTION)' '$(DEB_PACKAGE_URGENCY)' \
		>> $(DEB_DIR)/$1/debian/changelog
	printf "  %s\n" $(subst '',,'$(subst *,' '*,$(PACKAGE_CHANGES))') \
		>> $(DEB_DIR)/$1/debian/changelog
	printf "\n -- %s  %s\n" '$(DEB_PACKAGE_MAINTAINER)' '$(DEB_PACKAGE_DATETIME)' \
		>> $(DEB_DIR)/$1/debian/changelog

	mkdir -p $(DEB_DIR)/$1/debian/source
	echo '$(DEB_SOURCE_FORMAT)' > $(DEB_DIR)/$1/debian/source/format
	echo '$(DEB_COMPATIBILITY_LEVEL)' > $(DEB_DIR)/$1/debian/compat

$1-deb-reset::
	mkdir -p $(DEB_DIR)/$1/debian

$1-deb-clean::
	rm -rf $(DEB_DIR)/$1
)
endef

# Public macro to override dh targets in debian rules file.
# Usage: $(call deb_package_override,name,targets ...,[commands ...])
# Where:
#  @name: package name to override targets for
#  @targets: target names to override (e.g: strip, auto_test, etc)
#  @commands: custom commands to perform for dh @targets
#   * leave it empty to skip specified @targets
# Example: $(call deb_package_override,package,auto_test,echo no tests)
define deb_package_override
$(eval \
$1-deb-configure::
	# Overriding $2 rule$(if $(word 2,$2),s) for $1
	printf "$(2:%=override_dh_%):\n$(if $3,\t$3\n)\n" >> $(DEB_DIR)/$1/debian/rules
)
endef

# Private macro to provide install command for debian package.
# Signature: $(call deb_package_install,name,command)
define deb_package_install
$(call deb_package_override,$1,auto_install,$(subst {PACKAGE_INSTALL_DIR},$(DEB_DIR)/$1/debian/$1,$2))
endef

# Private macros to direct scriplets.
# Signature: $(call deb_package_<stage>_scriplet,name)
define deb_package_preinstall_scriplet
$(DEB_DIR)/$1/debian/preinst
endef

define deb_package_postinstall_scriplet
$(DEB_DIR)/$1/debian/postinst
endef

define deb_package_preuninstall_scriplet
$(DEB_DIR)/$1/debian/prerm
endef

define deb_package_postuninstall_scriplet
$(DEB_DIR)/$1/debian/postrm
endef
