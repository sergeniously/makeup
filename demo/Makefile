include ../makeup.mk

# Import module to deal with external sources 
$(call import_modules,ExternalProject)

# Add, configure and build external project
$(call add_external_project,az-json,INCLUDE:headers BINARY:build/sources/libaz-json.a)
$(call clone_external_project,az-json,git@github.com:sergeniously/az-json.git,BRANCH:master)
$(call configure_external_project,az-json,cmake -B build)
$(call build_external_project,az-json,make -C build)

# Link external project to program
$(call include_directories,$(EPINC))
$(call link_directories,$(EPBIN))
$(call link_libraries,az-json)

# Build program
$(call add_program,makeup,main.cpp,DEPEND:az-json)

# Install external project and program
$(call install_external_project,az-json,,$(ROOT_INSTALL_DIR)/usr/local/lib)
$(call install_targets,makeup,$(ROOT_INSTALL_DIR)/usr/local/bin)
$(call install_command,touch makeup.cfg,$(ROOT_INSTALL_DIR)/etc,\
	Pretending to create makeup configuration)
