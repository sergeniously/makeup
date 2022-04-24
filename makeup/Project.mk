#####################
# makeup project file
# ! This file will be automatically included by makeup.mk
# ! Place here the project-specific code or leave it empty

PROJECT_NAME=makeup
PROJECT_VERSION=1.0.0
PROJECT_COPYRIGHT=Sergeniously
PROJECT_URL=https://github.com/sergeniously/makeup
PROJECT_EMAIL=sergeniously@github.com

# Uncomment to override directories to download, extract and build external projects
#EPARC:=$(ROOT_BINARY_DIR)/3rdparty/archives
#EPSRC:=$(ROOT_BINARY_DIR)/3rdparty/sources
#EPINC:=$(ROOT_BINARY_DIR)/3rdparty/include
#EPBIN:=$(ROOT_BINARY_DIR)/3rdparty/binary
#EPLOG:=$(ROOT_BINARY_DIR)/3rdparty/logs


# Import Cpp module by default
$(call makeup_import,Cpp)

# Default compiler options
$(call set_c_standard,c99)
$(call set_cxx_standard,c++17)
$(call add_compile_options,-Wall)
