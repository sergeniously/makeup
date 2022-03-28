#####################
# C/Cpp makeup module

# Compiling & linking Cpp applications
# in case they are not set or empty
AR:=$(or $(AR),ar)
CC:=$(or $(CC),gcc)
CXX:=$(or $(CXX),g++)

# Add environment link options if they are provided
LINK_OPTIONS+=$(LDFLAGS)
LINK_LIBRARIES+=$(LDLIBS)

# Rules to build c/cpp object files
$(BINDIR)/%.c.o: | $(BINDIR)
	@ echo "$(COLOR_COMPILE)Compiling C-file: $(abspath $<)$(COLOR_OFF)"
	$(CC) $(CFLAGS) $(COMPILE_OPTIONS) -MMD -o $@ -c $(abspath $<)

$(BINDIR)/%.cpp.o: | $(BINDIR)
	@ echo "$(COLOR_COMPILE)Compiling CPP-file: $(abspath $<)$(COLOR_OFF)"
	$(CXX) $(CXXFLAGS) $(COMPILE_OPTIONS) -MMD -o $@ -c $(abspath $<)

# Macro check_c_compiler_flag(flag)
# Macro check_cxx_compiler_flag(flag)
#  check whether @flag is supported by C/CXX compilers
#  returns 'ok' if flag is supported and 'no' otherwise
#  example: SUPPORTED:=$(call check_c_compiler_flag, -Wall)
define check_c_compiler_flag
$(if $(findstring error,$(shell echo "int i;" | $(CC) -x c $(1) -S -o - - 2>&1)),no,ok)
endef
define check_cxx_compiler_flag
$(if $(findstring error,$(shell echo "int i;" | $(CXX) -x c++ $(1) -S -o - - 2>&1)),no,ok)
endef

define set_c_standard # (standard)
$(eval CFLAGS:=-std=$(1) $(filter-out -std=%,$(CFLAGS)))
endef

define set_cxx_standard # (standard)
$(eval CXXFLAGS:=-std=$(1) $(filter-out -std=%,$(CXXFLAGS)))
endef

define add_source.c
$(foreach binary,$(call binary,$(1).o),\
$(eval $(binary): $(1) Makefile)$(binary))
endef

define add_source.cpp
$(foreach binary,$(call binary,$(1).o),\
$(eval $(binary): $(1) Makefile)$(binary))
endef

# Private macro to create static library
define add_STATIC_library # (name, sources ..., options ...)
$(call add_binary_target,$(1),lib$(1).a,$(2),Building static library,\
$(AR) rcs $$@ $$(filter %.o,$$^),$(3))
endef

# Private macro to create shared library
define add_SHARED_library # (name, sources ..., options ...)
$(call add_binary_target,$(1),lib$(1).so,$(2),Building shared library,\
$(CXX) $(LINK_OPTIONS) $$(filter %.o,$$^) $(LINK_LIBRARIES) -shared -o $$@,$(3))
endef

# Public macro add_library:
#  generates rules to build and clean static or shared (or both) libraries
# Example: $(call add_library, foo, STATIC SHARED, foo.cpp)
define add_library # (name, STATIC SHARED, sources ..., options ...)
$(foreach TYPE,$(filter STATIC SHARED,$(2)),$(call add_$(TYPE)_library,$(1),$(3),$(4)))
endef

# Public macro add_program:
#  generates rules to build, run and clean executable program
# Example: $(call add_program,bar,main.cpp,DEPEND:foo)
define add_program # (name, sources ..., options ...)
$(call add_binary_target,$(1),$(1),$(2),Building executable program,\
$(CXX) $(LINK_OPTIONS) $$(filter %.o,$$^) $(LINK_LIBRARIES) -o $$@,$(3))\
$(eval \
# helper target to run a program
run-$(1): $(BINDIR)/$(1)
	$(BINDIR)/$(1)
run: run-$(1)
)
endef
