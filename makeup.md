
# Introducing

**makeup** is a library of Makefile macros which helps and eases creating short Makefiles in cmake manner. Since it uses native Makefile features it is useful for those projects which are restricted to be upgraded for using external build system utilities such as cmake or so on.

## Features

+ Provide cmake-like syntax of Makefiles
+ Produce cmake-like colorful output of building
+ Rebuild objects on Makefile change
+ Rebuild objects on header files change
+ Rebuild objects on dependencies change
+ Create binaries in separate customized build directory so that:
  + there is no need to go to build directory to run make (*better than cmake*)
  + objects files are not mixed with source files (*no need to clean before commit*)
+ Extendable by modules (*allows to build any kind of binaries: java, python, etc*)
+ Allows to build **Qt** programs and libraries without using of **.pro** files (*provided by Qt module*)
+ Allows to download and build third-party libraries (*provided by ExternalProject module*)

# Quick start

1) Just copy **makeup.mk** kernel file and **makeup** directory to the root of your project.
2) Optionally create project-related file **makeup.pj** near to makeup.mk and fill it with project-specific variables and options. This file is automatically included in makeup.mk file.
3) Create Makefile and from inside of it include makeup.mk file.

Now, this new Makefile is ready to use all makeup features.

## Example (see demo/Makefile)

Here is an example of Makefile to build simple C++ program which uses external json library:
```makefile
include ../makeup.mk
$(call makeup_import,ExternalProject)

# Add, configure and build external project
$(call add_external_project,az-json,https://github.com/sergeniously/az-json/archive/refs/heads/master.zip,\
	MD5:d4d87ba48c545a9d3ccdf582610b874d INCLUDE:az-json-master/headers BINARY:build/sources/libaz-json.a)
$(call configure_external_project,az-json,cmake -S az-json-master -B build)
$(call build_external_project,az-json,make -C build)

# Link external project to program
$(call include_directories,$(EPINC))
$(call link_directories,$(EPBIN))
$(call link_libraries,az-json)

# Add program dependent of az-json library
$(call add_program,makeup, main.cpp, DEPEND:az-json)

# Install external project and program
$(call install_external_project,az-json,,$(ROOT_INSTALL_DIR)/usr/local/lib)
$(call install_targets,makeup,$(ROOT_INSTALL_DIR)/usr/local/bin)
$(call install_command,touch makeup.cfg,$(ROOT_INSTALL_DIR)/etc,\
	Pretending to create makeup configuration)
```

Now it is easy to build. Just run *make all* command:
```ansi
~/makeup/demo > make all
Configuring external project: az-json
Building external project: az-json
az-json is 100% done (see ~/makeup/build/EP/logs/az-json.log)
Compiling CPP-file: ~/makeup/demo/main.cpp
Building executable program: ~/makeup/build/demo/makeup
```

It is also ready for running *make install* command:
```ansi
~/makeup/demo > make install
Installing external project az-json in ~/makeup/install/usr/local/lib ...
Installing makeup in ~/makeup/install/usr/local/bin ...
Pretending to create makeup configuration in ~/makeup/install/etc ...
```
