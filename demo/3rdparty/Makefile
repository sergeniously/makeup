include ../../makeup.mk

# Import module to deal with external sources 
$(call import_modules,ExternalProject)

# Add, configure and build external project
$(call add_external_project,az-json,INCLUDE:headers BINARY:build/sources/libaz-json.a)
$(call clone_external_project,az-json,https://github.com/sergeniously/az-json.git,BRANCH:master)
$(call configure_external_project,az-json,cmake -B build)
$(call build_external_project,az-json,make -C build)
$(call install_external_project,az-json,,$(ROOT_INSTALL_DIR)/usr/lib)
