#######################
# Install makeup module
#  implements macros to install targets, directories or files

# Macro to add rule to install target files of target @names in @destination
#  (note: double-colon means adding recipes to target)
define install_targets # (names ..., destination, [MODE:123])
$(eval \
install:: $(call get_targets,$1)
	@ echo "$(COLOR_INSTALL)Installing $$(^F) in $2 ...$(COLOR_OFF)";
	mkdir -p $2 && install $(call opt_one,$3,MODE:%,-m %) $$^ $2
)
endef

# Macro to add rule to install @dirs in @destination
define install_directories # (dirs ..., destination, [comment ...])
$(eval \
install::
	@ echo "$(COLOR_INSTALL)$(or $(strip $3),Installing directories $1 in $2 ...)$(COLOR_OFF)";
	mkdir -p $2 && cp -rf $1 $2
)
endef

# Macro to install @files in @destination
# @files are acceptable to be wildcard patterns
# option RENAME can be used only if one file is being installed
# Example: $(call install_files,config,$(INSTALL_DIR)/etc, MODE:666 RENAME:foo.cfg)
define install_files # (files ..., destination, [MODE:123] [RENAME:name], [comment ...])
$(eval \
install::
	@ echo "$(COLOR_INSTALL)$(or $(strip $4),Installing files $1) in $2 ...$(COLOR_OFF)";
	mkdir -p $2 && install $(call opt_one,$3,MODE:%,-m %) $1 $(strip $2)/$(call opt_one,$3,RENAME:%)
)
endef

# Macro to append a command to install target
define install_command # (command ..., [destination], [comment])
$(eval \
install::
	@ echo "$(COLOR_INSTALL)$(or $(strip $3),Installing command)$(if $2, in $2) ...$(COLOR_OFF)";
	$(if $2,mkdir -p $2 && cd $2 && )$1
)
endef
