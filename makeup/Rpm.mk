###################
# Rpm makeup module
#  Implements macros to generate rpm packages.

RPM_DIR:=$(PACKAGE_DIR)/rpm
RPM_APP=$(call find_program,rpmbuild,REQUIRED)

RPM_PACKAGE_ARCHITECTURE=$(PACKAGE_ARCHITECTURE)
RPM_PACKAGE_VERSION=$(PACKAGE_VERSION)
RPM_PACKAGE_RELEASE=$(PACKAGE_RELEASE)
RPM_PACKAGE_SUMMARY=$(PACKAGE_NAME)
RPM_PACKAGE_DESCRIPTION=$(PACKAGE_DESCRIPTION)
RPM_PACKAGE_LICENSE=$(PACKAGE_VENDOR)
RPM_PACKAGE_VENDOR=$(PACKAGE_VENDOR)
RPM_PACKAGE_URL=$(PACKAGE_URL)
RPM_PACKAGE_GROUP=unknown
RPM_PACKAGE_REQUIRES=
RPM_PACKAGE_CONFLICTS=
RPM_PACKAGE_AUTOREQ=no
RPM_PACKAGE_AUTOPROV=no
RPM_PACKAGE_DATETIME=$(shell date '+%a %b %d %Y')

# Private macro to generate rpm package.
#  It is called by Package module, so DO NOT call it manually!
# Signature: $(call rpm_package_add,name,file)
define rpm_package_add
$(eval \
$1-rpm-build:
	$(call package_comment,rpm,Generating $1 package: $2 ...)
	mkdir -p $(RPM_DIR)/$1/BUILD $(RPM_DIR)/$1/RPMS/$(RPM_PACKAGE_ARCHITECTURE)
	$$(RPM_APP) --verbose -bb --target=$(RPM_PACKAGE_ARCHITECTURE) --define="_build_pkgcheck_set %{nil}" \
		--define="_allow_root_build 1" --define="_topdir $(RPM_DIR)/$1" --buildroot=$(RPM_DIR)/$1/BUILDROOT \
		$(RPM_DIR)/$1/spec $(if $(VERBOSE),,> $(RPM_DIR)/$1/log 2>&1)
	mv -f $(RPM_DIR)/$1/RPMS/$(RPM_PACKAGE_ARCHITECTURE)/*.rpm $2

$1-rpm-configuration:
	# Generating specification file for $1
	printf "%s\n" 'Name: $1' \
		'Version: $(RPM_PACKAGE_VERSION)' \
		'Release: $(RPM_PACKAGE_RELEASE)' \
		'Summary: $(RPM_PACKAGE_SUMMARY)' \
		'License: $(RPM_PACKAGE_LICENSE)' \
		'Vendor: $(RPM_PACKAGE_VENDOR)' \
		'URL: $(RPM_PACKAGE_URL)' \
		'Group: $(RPM_PACKAGE_GROUP)' \
		$(if $(RPM_PACKAGE_REQUIRES),'Requires: $(RPM_PACKAGE_REQUIRES)') \
		$(if $(RPM_PACKAGE_CONFLICTS),'Conflicts: $(RPM_PACKAGE_CONFLICTS)') \
		'Autoreq: $(RPM_PACKAGE_AUTOREQ)' \
		'Autoprov: $(RPM_PACKAGE_AUTOPROV)' \
		'Source0: $1.tar.gz' \
		'' '%description' '$(RPM_PACKAGE_DESCRIPTION)' \
			> $(RPM_DIR)/$1/spec
		$$(foreach specfile,$$(wildcard $(RPM_DIR)/$1/specs/*),\
			(printf "\n%%%s\n" $$(notdir $$(specfile)) && cat $$(specfile)) >> $(RPM_DIR)/$1/spec$$(NEWLINE)$$(TAB))

$1-rpm-configure::
	# Generating changelog for $1
	printf "* %s %s <%s>\n" '$(RPM_PACKAGE_DATETIME)' '$(RPM_PACKAGE_VENDOR)' '$(PACKAGE_EMAIL)' \
		>> $(RPM_DIR)/$1/specs/changelog
	printf "%s\n" $(subst '',,'$(subst *,' '-,$(PACKAGE_CHANGES))') \
		>> $(RPM_DIR)/$1/specs/changelog

$1-rpm-reset::
	mkdir -p $(RPM_DIR)/$1/specs

$1-rpm-clean::
	rm -rf $(RPM_DIR)/$1
)
endef

# Public macro to specify additional section in package spec file.
# Usage: $(call rpm_package_specify,name,section,content)
# Where:
#  @name: package name to specify section for
#  @section: section name to embed into spec file with % prefix
#  @content: content of section to write as is
# Example: $(call rpm_package_specify,package,install,cp -Taf $(INSTALL_DIR) $(RPM_INSTALL_DIR))
define rpm_package_specify
$(eval \
$1-rpm-configure::
	# Specifying $2 directive for $1
	printf "%s\n" '$3' > $(RPM_DIR)/$1/specs/$(strip $2)
)
endef

# Public macro to specify %files directive with specified files.
# Usage: $(call rpm_package_files_list,name,files ...,[mode],[user],[group])
# Where:
#  @name: package name to specify files for
#  @files: package files without installation prefix
#  @mode: file mode attribute in numeric form
#  @user: file user name attribute
#  @group: file group name attribute
# Example: $(call rpm_package_files_list,package,/usr/bin/app /usr/lib/*,0123,root,root)
define rpm_package_files_list
$(eval \
$1-rpm-configure::
	# Specifying files directive for $1
	printf "$(if $3$4$5,%%attr($(or $3,-), $(or $4,-), $(or $5,-)) )%s\n" $2 \
		>> $(RPM_DIR)/$1/specs/files
)
endef

# Public macro to specify %files directive with files found in specified directory.
# Usage: $(call rpm_package_files_find,name,directory,[mode],[user],[group])
# Where:
#  @name: package name to specify files for
#  @directory: path to a directory to find files
#  @mode, @user, @group: see rpm_package_files_list
# Example: $(call rpm_package_files_find,package,$(INSTALL_DIR))
define rpm_package_files_find
$(call rpm_package_files_list,$1,$(subst $2,,$(and $(wildcard $2),$(shell find $2 -type f))),$3,$4,$5)
endef

# Private macro to provide install command for rpm package.
# Signature: $(call rpm_package_install,name,command)
define rpm_package_install
$(call rpm_package_specify,$1,install,$(subst {PACKAGE_INSTALL_DIR},$(RPM_DIR)/$1/BUILDROOT,$2))
endef

# Private macros to direct scriplets.
# Signature: $(call rpm_package_<stage>_scriplet,name)
define rpm_package_preinstall_scriplet
$(RPM_DIR)/$1/specs/pre
endef

define rpm_package_postinstall_scriplet
$(RPM_DIR)/$1/specs/post
endef

define rpm_package_preuninstall_scriplet
$(RPM_DIR)/$1/specs/preun
endef

define rpm_package_postuninstall_scriplet
$(RPM_DIR)/$1/specs/postun
endef
