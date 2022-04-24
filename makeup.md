<h1 align="center">makeup:<br>use makefiles in cmake manner</h1>

- [Introducing](#introducing)
  - [Features](#features)
- [Quick start](#quick-start)
  - [Example](#example)
- [Documentation](#documentation)
  - [Built-in targets](#built-in-targets)
  - [Built-in variables](#built-in-variables)
  - [Built-in functions](#built-in-functions)
    - [find_program](#find_program)
    - [add_compile_options](#add_compile_options)
    - [add_definitions](#add_definitions)
    - [include_directories](#include_directories)
    - [add_link_options](#add_link_options)
    - [link_directories](#link_directories)
    - [link_libraries](#link_libraries)
    - [add_binary_target](#add_binary_target)
    - [add_subdir_target](#add_subdir_target)

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
2) Optionally modify project file **makeup/Project.mk** filling it with project-specific variables and options. This file is automatically included in makeup.mk file.
3) Create Makefile and include makeup.mk file from inside of it.

Now, this new Makefile is ready to use all makeup features.

## Example

Here is an example of Makefile to build a simple C++ program which uses external json library (see [demo/Makefile](demo/Makefile)):
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

Here are some generic functions supported by **makeup**.

### find_program
Searches an executable program by names in specified paths or in default locations specified in system environment variable *$PATH* and returns one found variant.
```
$(call find_program, names ..., [PATH:dir ...] [REQUIRED] [RECURSIVE])
```
Arguments:
1) **names**: specify one or more possible names for the program.
2) **options**:
    + **PATH:dir** : specify directories to search in addition to the default locations.
    + **REQUIRED** : stop processing Makefile with an error message if nothing is found.
    + **RECURSIVE** : recursively search the program in specified paths (use carefully).

Example:
```Makefile
QMAKE=$(call find_program, qmake, PATH:/usr/lib/qt5 REQUIRED)
```

### add_compile_options
Appends compile options to COMPILE_OPTIONS variable that is used by modules to compile binary targets.

Example:
```Makefile
$(call add_compile_options, -Wall -O2)
```

### add_definitions
Appends definitions to COMPILE_OPTIONS variable in NAME[=VALUE] form
> **Note**: do not add them with -D prefixes as so they added automatically

Example:
```Makefile
$(call add_definitions, DEBUG PLATFORM=ANY)
```

### include_directories
Adds the given directories to those the compiler uses to search for include files. Relative paths are interpreted as relative to the current source directory. The given directories are added to COMPILE_OPTIONS variable with -I prefixes.

Example:
```Makefile
$(call include_directories, /usr/local/include $(EPINC))
```

### add_link_options
Appends any options to LINK_OPTIONS variable that is used by modules to perform linking step for binary targets.

Example:
```Makefile
$(call add_link_options, -fPIC)
```

### link_directories
Adds the paths in which the linker should search for libraries. Relative paths are interpreted as relative to the current source directory. The given paths are added to LINK_OPTIONS variable with -L prefixes.

Example:
```Makefile
$(call link_directories, /usr/local/lib $(EPBIN))
```

### link_libraries
Specifies libraries or flags to use when linking any targets created later. Also appends current binary path to those which have relative specifier.

Example:
```Makefile
$(call link_libraries, boost_system -l:libzip.a ../libany.so)
```

### add_binary_target
Universal function to create a binary target file. It is supposed to be used by modules to create executable programs or libraries.
```
$(call add_binary_target, name, file, sources ..., comment, command, [options ...])
```
Arguments:
1) **name**: a target name to aggregate target files.
2) **file**: a basename of a file that will be created in current binary directory.
3) **sources**: a list of prerequisite source files for target **file**.
4) **comment**: a comment to print of what is going to be done.
5) **command**: a command to create binary target **file**.
6) **options**:
   - **DEPEND:name ...**: additional dependency for target **file**.
   - **EXCLUDE_FROM_ALL**: do not add the target to default all target.

Example:
```Makefile
$(call add_binary_target,foo,libfoo.a,foo.cpp,Building static library,g++ $$^ -o $$@)
```

### add_subdir_target
Appends a target to build, clean, check or install targets in a subdirectory.
```
$(call add_subdir_target, name, [options ...])
```
Arguments:
1) **name**: a target name that may be the same as a subdirectory name.
2) **options**:
   - **DIR:name**: specify subdirectory name or path if the target **name** must be different from the subdirectory name.
   - **DEPEND:name ...**: additional dependency for target **name**.
   - **EXCLUDE_FROM_ALL**: do not add the target to default all target.

Example:
```Makefile
$(call add_subdir_target,lib,DIR:src/lib EXCLUDE_FROM_ALL)
$(call add_subdir_target,bin,DIR:src/bin DEPEND:lib)
```
