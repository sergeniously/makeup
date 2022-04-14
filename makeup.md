<h1 align="center">makeup:<br>use makefiles in cmake manner</h1>

- [Introducing](#introducing)
  - [Features](#features)
- [Quick start](#quick-start)
  - [Example](#example)
- [Documentation](#documentation)
  - [Built-in targets](#built-in-targets)
  - [Built-in variables](#built-in-variables)
  - [Built-in functions](#built-in-functions)
    - [find_program](#findprogram)

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

## Example

Here is an example of Makefile to build a simple C++ program which uses external json library (see demo/Makefile):
```makefile
include ../makeup.mk
$(call makeup_import,Cpp ExternalProject)

# Add, configure and build external project
$(call add_external_project,az-json,\
	https://github.com/sergeniously/az-json/archive/refs/heads/master.zip,\
	MD5:d4d87ba48c545a9d3ccdf582610b874d \
	INCLUDE:az-json-master/headers \
	BINARY:build/sources/libaz-json.a)
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

Now it is easy to build. Just run `make all` command:
```ansi
~/makeup/demo > make all
Configuring external project: az-json
Building external project: az-json
az-json is 100% done (see ~/makeup/build/EP/logs/az-json.log)
Compiling CPP-file: ~/makeup/demo/main.cpp
Building executable program: ~/makeup/build/demo/makeup
```

It is also ready for running `make install` command:
```ansi
~/makeup/demo > make install
Installing external project az-json in ~/makeup/install/usr/local/lib ...
Installing makeup in ~/makeup/install/usr/local/bin ...
Pretending to create makeup configuration in ~/makeup/install/etc ...
```

# Documentation

## Built-in targets

**makeup** implements some built-in targets for some special reasons:

+ **help** target prints some details about some available targets which are provided by Makefile in the current source directory.

+ **all** (default) target builds everything that can be built for the current source directory.

+ **clean** target deletes everything that was built for the current source directory.

+ **install** target installs built target files in DESTDIR directory.

+ **check** target runs test targets if there are such ones.

+ **show-built** target shows objects and binaries which are built for current source directory and its subdirectories.

Further details and another Makefile-dependent targets can be shown by `make help` command. Feel free to use it every time you need help.

## Built-in variables

**makeup** provides some built-in variables which have special useful values:

+ **ROOT_SOURCE_DIR**<br>
Contains an absolute path to the makeup.mk location. It is supposed to be a root directory of a project.

+ **ROOT_BINARY_DIR**<br>
Contains an absolute path of the root directory for building. By default it is set as *<ROOT_SOURCE_DIR>/build*, but can be changed in two ways:
  + specify *BUILD_DIR* in make command: `make all BUILD_DIR=dir`
  + override it in project file **makeup.pj**: `ROOT_BINARY_DIR=dir`

+ **ROOT_INSTALL_DIR**<br>
Contains an absolute path of the root directory to install target files.
Default value is *<ROOT_SOURCE_DIR>/install*. Can be changed by specifying INSTALL_DIR or DESTDIR variables in `make install` command.

+ **CURRENT_SOURCE_DIR**<br>
It is a synonym for standard Makefile variable **CURDIR** that is set to the absolute path of the current working (source) directory.

+ **CURRENT_BINARY_DIR**<br>
Contains the absolute path of the current building (binary) directory that responds to the current working directory. For example, if the current working directory equals to *ROOT_SOURCE_DIR/demo*, then the current building directory will be *ROOT_BINARY_DIR/demo*. There is also a short form of this variable: **BINDIR**.

## Built-in functions

Here are some generic functions supported by **makeup**:

### find_program
Searches an executable program by names in specified paths or in default locations specified in system environment variable *$PATH* and returns one found variant.
```
$(call find_program, names ..., [paths ...], [REQUIRED] [RECURSIVE])
```
Arguments:
1) **names**: specify one or more possible names for the program.
2) **paths**: specify directories to search in addition to the default locations.
3) **options**: 
    + **REQUIRED**: stop processing with an error message if nothing is found.
    + **RECURSIVE**: recursively search the program in specified paths (use carefully).

Example:
```Makefile
QMAKE=$(call find_program, qmake, /usr/lib/qt5, REQUIRED)
```
