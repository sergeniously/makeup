################################
# External Project makeup module
#  implements macros to create targets to build third-party external projects

# Directories to download, extract and build external projects
# Should be defined in project makeup.pj file
EPARC?=$(ROOT_BINARY_DIR)/EP/archives
EPINC?=$(ROOT_BINARY_DIR)/EP/include
EPSRC?=$(ROOT_BINARY_DIR)/EP/sources
EPLOG?=$(ROOT_BINARY_DIR)/EP/logs

$(EPARC) $(EPINC) $(EPLOG):
	mkdir -p $@
$(EPSRC)/%:
	mkdir -p $@

# Macro add_external_project:
#  adds a target to download, verify and extract external project sources into $(EPSRC) directory
#  additional targets to patch, configure and build need to be added by another macros below
#  after external project is built it creates timestamp file to avoid rebuilding until clean
#  @MD5:HASH: specifies MD5 checksum to verify the archive file after downloading
#  @DEPEND:name: specifies dependency target of the external project (can be multiply specified)
#  @INCLUDE:dir: specifies a relative path to include directory to create a symbolic link in $(EPINC)
# TODO: add URL and FILE options to download an archive or just extract existent one
define add_external_project # (name, url, [MD5:HASH] [DEPEND:name ...] [INCLUDE:dir])
$(eval \
all: $(1)
$(1): $(EPLOG)/$(1).timestamp
	@ echo "$(COLOR_BUILD)$(1) is 100% done$(COLOR_OFF) (see $(EPLOG)/$(1).log)"

$(EPLOG)/$(1).timestamp: $(call get_depends,$(3))
	@ +$(MAKE) build-$(1) || { cat $(EPLOG)/$(1).log; \
		echo "$(COLOR_ERROR)Failed to build external project: $(1)$(COLOR_OFF)"; \
		false; } # if building fails print complete log and do not touch
	@ touch $(EPLOG)/$(1).timestamp

$(1)_TARGET_FILES+=$(EPLOG)/$(1).timestamp

build-$(1): configure-$(1)
configure-$(1): patch-$(1)
patch-$(1): download-$(1)
download-$(1): clean-$(1) | $(EPARC) $(EPINC) $(EPLOG) $(EPSRC)/$(1)
	@ echo "$(COLOR_EXTERNAL)Downloading external project: $(1)$(COLOR_OFF)"
	wget --timestamping --directory-prefix=$(EPARC) --output-file=$(EPLOG)/$(1).log $(2)
	@# optionally match MD5 checksum of downloaded archive with specified MD5 checksum
	$(call opt_one,$(3),MD5:%,echo %\ \ $(EPARC)/$(notdir $(2)) | md5sum --check >> $(EPLOG)/$(1).log 2>&1)
	$(if $(filter %.tar.gz,$(2)),tar --extract --file=$(EPARC)/$(notdir $(2)) --directory=$(EPSRC)/$(1) --strip-components=1)
	$(if $(filter %.zip,$(2)),unzip -q -d $(EPSRC)/$(1) $(EPARC)/$(notdir $(2)))	
	@# optionally create symbolic link to include directory of the external project
	$(call opt_one,$(3),INCLUDE:%,ln -sf $(EPSRC)/$(1)/% $(EPINC)/$(1))
download: download-$(1)

clean-$(1): # do verbose only if timestamp exists
	@ $(if $(wildcard $(EPLOG)/$(1).timestamp),echo "Cleaning external project: $(1)")
	rm -rf $(EPARC)/$(notdir $(2)) $(EPSRC)/$(1) $(EPLOG)/$(1).log $(EPLOG)/$(1).timestamp
	$(call opt_one,$(3),INCLUDE:%,rm -f $(EPINC)/$(1))
clean: clean-$(1)
)
endef

# Macro patch_external_project:
#  adds optional target to perform patching step
# Example: $(call patch_external_project,foo,patch main.coo foo.patch)
define patch_external_project # (name, command1, ..., command4)
$(eval \
patch-$(1):
	@ echo "$(COLOR_EXTERNAL)Patching external project: $(1)$(COLOR_OFF)"
	$(if $(2),cd $(EPSRC)/$(1) && $(2))
	$(if $(3),cd $(EPSRC)/$(1) && $(3))
	$(if $(4),cd $(EPSRC)/$(1) && $(4))
	$(if $(5),cd $(EPSRC)/$(1) && $(5))
)
endef

# Macro configure_external_project:
#  adds optional target to perform configuring step
# Example: $(call configure_external_project,foo,./configure)
define configure_external_project # (name, command1, ..., command4)
$(eval \
configure-$(1):
	@ echo "$(COLOR_EXTERNAL)Configuring external project: $(1)$(COLOR_OFF)"
	$(if $(2),cd $(EPSRC)/$(1) && $(2) >> $(EPLOG)/$(1).log 2>&1)
	$(if $(3),cd $(EPSRC)/$(1) && $(3) >> $(EPLOG)/$(1).log 2>&1)
	$(if $(4),cd $(EPSRC)/$(1) && $(4) >> $(EPLOG)/$(1).log 2>&1)
	$(if $(5),cd $(EPSRC)/$(1) && $(5) >> $(EPLOG)/$(1).log 2>&1)
)
endef

# Macro build_external_project:
#  adds optional target to perform building step
# Example: $(call build_external_project,foo,make all)
define build_external_project # (name, command1, ..., command4)
$(eval \
build-$(1):
	@ echo "$(COLOR_EXTERNAL)Building external project: $(1)$(COLOR_OFF)"
	$(if $(2),cd $(EPSRC)/$(1) && $(2) >> $(EPLOG)/$(1).log 2>&1)
	$(if $(3),cd $(EPSRC)/$(1) && $(3) >> $(EPLOG)/$(1).log 2>&1)
	$(if $(4),cd $(EPSRC)/$(1) && $(4) >> $(EPLOG)/$(1).log 2>&1)
	$(if $(5),cd $(EPSRC)/$(1) && $(5) >> $(EPLOG)/$(1).log 2>&1)
)
endef

# Macro install_external_project:
#  adds optional target to install goods of external project on <make install> command
# Example: $(call install_external_project,foo,install libfoo.so $(DESTDIR))
define install_external_project # (name, command1, ..., command4)
$(eval \
install-$(1):
	@ echo "$(COLOR_INSTALL)Installing external project: $(1)$(COLOR_OFF)"
	$(if $(2),cd $(EPSRC)/$(1) && $(2) >> $(EPLOG)/$(1).log)
	$(if $(3),cd $(EPSRC)/$(1) && $(3) >> $(EPLOG)/$(1).log)
	$(if $(4),cd $(EPSRC)/$(1) && $(4) >> $(EPLOG)/$(1).log)
	$(if $(5),cd $(EPSRC)/$(1) && $(5) >> $(EPLOG)/$(1).log)
install: install-$(1)
)
endef
