################################
# External Project makeup module
#  implements macros to create targets to build third-party external projects

# Directories to download, extract and build external projects
# Should be defined in project makeup.mk file
EPARC?=$(ROOT_BINARY_DIR)/EP/archives
EPSRC?=$(ROOT_BINARY_DIR)/EP/sources
EPINC?=$(ROOT_BINARY_DIR)/EP/include
EPBIN?=$(ROOT_BINARY_DIR)/EP/binary
EPLOG?=$(ROOT_BINARY_DIR)/EP/logs

help::
	$(call help,source EPSRC=dir (default: $(EPSRC)),\
		Downloading and extracting sources of all external projects in EPSRC directory)

# Macro add_external_project:
#  adds a target to download, verify and extract external project sources into $(EPSRC) directory
#  additional targets to patch, configure and build need to be added by another macros below
#  after external project is built it creates timestamp file to avoid rebuilding until clean
#  @DEPENDS:list: specifies dependency target of the external project (can be multiply specified)
#  @INCLUDE:dir: specifies a relative path to include directory to create a symbolic link in $(EPINC)
#  @BINARY:path: specifies a relative path with wildcard pattern to binaries that must be moved to $(EPBIN) after building
# TODO: add URL and FILE options to download an archive or just extract existent one
define add_external_project # (name, [DEPENDS:one;two;...] [INCLUDE:dir] [BINARY:dir/lib* ...])
$(eval \
all: $1
$1: $(EPLOG)/$1.timestamp
	@ echo "$(COLOR_BUILD)$1 is 100% done$(COLOR_OFF) (see $(EPLOG)/$1.log)"

$(EPLOG)/$1.timestamp: $(call get_depends,$2)
	@ +$(MAKE) build-$1 || { cat $(EPLOG)/$1.log; \
		echo "$(COLOR_ERROR)Failed to build external project: $1$(COLOR_OFF)"; \
		false; } # if building fails print complete log and do not touch
	$(foreach path,$(call opt_all,$2,BINARY:%),cp -f $(EPSRC)/$1/$(path) $(EPBIN)$(NEWLINE)$(TAB))
	@ touch $(EPLOG)/$1.timestamp

$1_TARGET_FILES+=$(EPLOG)/$1.timestamp
$1_BINARY_FILES+=$(addprefix $(EPBIN)/,$(notdir $(call opt_all,$2,BINARY:%)))

build-$1:: configure-$1
configure-$1:: patch-$1
patch-$1:: include-$1
include-$1: source-$1
	@# optionally create symbolic link to include directory of the external project
	$(call opt_one,$2,INCLUDE:%,ln -sf $(EPSRC)/$1/% $(EPINC)/$1)

sources: source-$1 # aggregate source targets

reset-$1: clean-$1
	mkdir -p $(EPARC) $(EPINC) $(EPBIN) $(EPLOG) $(EPSRC)/$1

clean-$1:: # do verbose only if timestamp exists
	@ test -f $(EPLOG)/$1.timestamp && echo "Cleaning external project: $1" || true
	rm -rf $(EPSRC)/$1 $(EPLOG)/$1.log $(EPLOG)/$1.timestamp
	$(foreach file,$(notdir $(call opt_all,$2,BINARY:%)),rm -f $(EPBIN)/$(file)$(NEWLINE)$(TAB))
	$(call opt_one,$2,INCLUDE:%,rm -f $(EPINC)/$1)
clean: clean-$1

help::
	$(call help,$1,Building external project: $1)
)
endef

# Macro adds a target to clone sources from a remote git repository @url
#   @BRANCH:name: specifies a name of a specific branch for a git repository to be cloned
#   @COMMIT:hash: specifies a hash of a specific commit for a git repository to be checked out
define clone_external_project # (name, url, [BRANCH:name] [COMMIT:hash])
$(eval \
source-$1: reset-$1
	@ echo "$(COLOR_EXTERNAL)Cloning external project: $1$(COLOR_OFF)"
	git clone $(call opt_one,$3,BRANCH:%,--branch=%) $2 $(EPSRC)/$1 >> $(EPLOG)/$1.log 2>&1
	$(call opt_one,$3,COMMIT:%,(cd $(EPSRC)/$1 && git checkout %) >> $(EPLOG)/$1.log 2>&1)
)
endef

# Macro adds a target to download sources from @url
#   @MD5:hash: specifies MD5 checksum to verify the archive file after downloading
define download_external_project # (name, url, [MD5:hash])
$(eval \
source-$1: reset-$1
	@ echo "$(COLOR_EXTERNAL)Downloading external project: $1$(COLOR_OFF)"
	#wget -nv --timestamping --directory-prefix=$(EPARC) --output-file=$(EPLOG)/$1.log $2
	curl --output $(EPARC)/$(notdir $2) $2
	$(call opt_one,$3,MD5:%,echo %\ \ $(EPARC)/$(notdir $2) | md5sum --check >> $(EPLOG)/$1.log 2>&1)
	$(foreach file,$(notdir $(call opt_one,$2,%.tar.gz,%.tar.gz)),tar --extract --file=$(EPARC)/$(file) --directory=$(EPSRC)/$1 --strip-components=1)
	$(foreach file,$(notdir $(call opt_one,$2,%.zip,%.zip)),unzip -q -d $(EPSRC)/$1 $(EPARC)/$(file))

clean-$1:: # additional cleaning target to delete an archive
	rm -f $(EPARC)/$(notdir $2)
)
endef

# Macro adds a target to extract sources from @file
define extract_external_project # (name, file)
$(eval \
source-$1: reset-$1
	@ echo "$(COLOR_EXTERNAL)Extracting external project: $1$(COLOR_OFF)"
	$(call opt_one,$2,%.tar.gz,tar --extract --file=%.tar.gz --directory=$(EPSRC)/$1 --strip-components=1)
	$(call opt_one,$2,%.zip,unzip -q -d $(EPSRC)/$1 %.zip)
)
endef

# Macro patch_external_project:
#  appends a command to patch external project
# Example: $(call patch_external_project,foo,patch main.coo foo.patch)
define patch_external_project # (name, command ..., comment ...)
$(eval \
patch-$1::
	@ echo "$(COLOR_EXTERNAL)Patching external project: $1$(if $3,($3))$(COLOR_OFF)"
	cd $(EPSRC)/$1 && ($2) >> $(EPLOG)/$1.log 2>&1
)
endef

# Macro configure_external_project:
#  appends a command to configure external project
# Example: $(call configure_external_project,foo,./configure)
define configure_external_project # (name, command ..., comment ...)
$(eval \
configure-$1::
	@ echo "$(COLOR_EXTERNAL)Configuring external project: $1$(if $3,($3))$(COLOR_OFF)"
	cd $(EPSRC)/$1 && ($2) >> $(EPLOG)/$1.log 2>&1
)
endef

# Macro build_external_project:
#  appends a command to build external project
# Example: $(call build_external_project,foo,make all)
define build_external_project # (name, command ..., comment ...)
$(eval \
build-$1::
	@ echo "$(COLOR_EXTERNAL)Building external project: $1$(if $3,($3))$(COLOR_OFF)"
	cd $(EPSRC)/$1 && ($2) >> $(EPLOG)/$1.log 2>&1
)
endef

# Macro install_external_project:
#  adds a command to install external project @files in @destination on <make install>
#  where @files are wildcard paths which are relative to $(EPSRC) directory
# TODO: automatically install files specified by BINARY:% options for add_external_project
# Example: $(call install_external_project,foo,build/libfoo.so,$(DESTDIR),MODE:755)
define install_external_project # (name, files ..., destination, [MODE:123])
$(call install_files,$(or $(addprefix $(EPSRC)/$1/,$2),$($1_BINARY_FILES)),$3,$4,\
Installing external project $1 files $(notdir $2))
endef
