#######################
# Install makeup module
#  implements macros to install targets, directories or files.

# Macro to install all @directories content to into @destination
# Usage: $(call, install_directories,directories ..., destination, [comment ...])
# Where:
#  @directories: source directories to install files from
#  @destination: destination directory to install files to
#  @comment: message to display about what is going on
# Example: $(call install_directories,include,$(DEST_DIR),Installing include files)
define install_directories
$(eval \
install::
	@ echo "$(COLOR_INSTALL)$(or $(strip $3),Installing directories $1 in $2 ...)$(COLOR_OFF)";
	mkdir -p $2 && cp -rf $1 $2
)
endef

# Macro to install @files in @destination directory
# Usage: $(call install_files, files, destination, [options], [comment])
# Where:
#  @files: paths or wildcard patterns to install
#  @destination: directory to install @files to
#  @options:
#   MODE:123: permission mode for each file
#   RENAME:pattern: new name pattern for each file
#  @comment: message to display about what is going on
# Example: $(call install_files,config,$(INSTALL_DIR)/etc,MODE:666 RENAME:foo.cfg,Istalling config)
define install_files
$(eval \
install:: $1
	@ echo "$(COLOR_INSTALL)$(or $(strip $4),Installing files $1) in $2 ...$(COLOR_OFF)";
	mkdir -p $2
	$(foreach file,$1,install $(call opt_one,$3,MODE:%,-m %) $(file) \
		$(strip $2)/$(patsubst %,$(call opt_one,$3,RENAME:%),$(notdir $(file)))$(NEWLINE)$(TAB))
)
endef

# Macro to perform a @command as a part of installation process
# Usage: $(call install_command,command ...,[destination],[comment])
# Where:
#  @command: a command to perform
#  @destination: working directory for a @command (created automatically)
#  @comment: message to display about what is going on
# Example: $(call install_command,touch config,$(DESTDIR)/etc,Installing config)
define install_command
$(eval \
install::
	@ echo "$(COLOR_INSTALL)$(or $(strip $3),Installing command)$(if $2, in $2) ...$(COLOR_OFF)";
	$(if $2,mkdir -p $2 && cd $2 && )$1
)
endef

# Macro to install target files of target @names in @destination directory
# Usage: $(call install_targets,names ..., destination, [options])
# Where:
#  @names: target names to install
#  @destination: directory to install files
#  @options: see $(install_files) options
# Example: $(call install_targets,program library,/tmp/install,MODE:123 RENAME:my%)
define install_targets
$(call install_files,$(call get_targets,$1),$2,$3,Installing targets $1)
endef
