include ../../makeup.mk

# Link external project to program
$(call include_directories,$(EPINC))
$(call link_directories,$(EPBIN))
$(call link_libraries,az-json)

# Build program
$(call add_program,makeup,main.cpp)

# Install program
$(call install_targets,makeup,$(ROOT_INSTALL_DIR)/usr/bin)
$(call install_command,touch makeup.cfg,$(ROOT_INSTALL_DIR)/etc,\
	Pretending to create makeup configuration)
