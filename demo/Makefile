include ../makeup.mk
$(call makeup_import,ExternalProject)

# Describe external project
$(call add_external_project,az-json,https://github.com/sergeniously/az-json/archive/refs/heads/master.zip,\
	MD5:d4d87ba48c545a9d3ccdf582610b874d INCLUDE:az-json-master/headers BINARY:build/sources/libaz-json*)
$(call configure_external_project,az-json,cmake -S az-json-master -B build)
$(call build_external_project,az-json,make -C build)

# Link external project to program
$(call include_directories,$(EPINC))
$(call link_directories,$(EPBIN))
$(call link_libraries,az-json)

# Build and install program
$(call add_program,makeup,main.cpp, DEPEND:az-json)
$(call install_targets,makeup,$(ROOT_INSTALL_DIR))
