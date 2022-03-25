#####################
# C/Cpp makeup module

# Rules to build c/cpp object files
$(BINDIR)/%.c.o: | $(BINDIR)
	@ echo "$(COLOR_COMPILE)Compiling C-file: $(abspath $<)$(COLOR_OFF)"
	$(CC) $(CFLAGS) -MMD -o $@ -c $(abspath $<)

$(BINDIR)/%.cpp.o: | $(BINDIR)
	@ echo "$(COLOR_COMPILE)Compiling CPP-file: $(abspath $<)$(COLOR_OFF)"
	$(CXX) $(CXXFLAGS) -MMD -o $@ -c $(abspath $<)

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

define add_c_source
$(foreach binary,$(call binary,$(1).o),\
$(eval $(binary): $(1) Makefile)$(binary))
endef

define add_cpp_source
$(foreach binary,$(call binary,$(1).o),\
$(eval $(binary): $(1) Makefile)$(binary))
endef

# Macro add_library:
#  generates rules to build and clean static or shared (or both) libraries
# Example: $(call add_library, foo, STATIC SHARED, foo.cpp)

SHARED_LIBRARY_RECIPE=$(CXX) $(LDFLAGS) $$(filter %.o,$$^) $(LDLIBS) -shared -o $$@
SHARED_LIBRARY_SUFFIX=so

STATIC_LIBRARY_RECIPE=$(AR) rcs $$@ $$(filter %.o,$$^)
STATIC_LIBRARY_SUFFIX=a

define add_library # (name, STATIC SHARED, sources ..., [DEPEND:target ...])
$(foreach TYPE,$(2),$(foreach library,lib$(1).$($(TYPE)_LIBRARY_SUFFIX),$(eval \
all: $(library)
$(1) $(library): $(BINDIR)/$(library)
$(BINDIR)/$(library): $(call add_sources,$(3)) $(call get_depends,$(4))
	@ echo "$(COLOR_BUILD)Building $(TYPE) library: $$@$(COLOR_OFF)"
	$($(TYPE)_LIBRARY_RECIPE)

$(1)_TARGET_FILES += $(BINDIR)/$(library)

# additional dependencies for objects
-include $(DEPEND_FILES)

clean-$(1)::
	rm -f $(BINDIR)/$(library) $(OBJECT_FILES) $(DEPEND_FILES)
clean: clean-$(1)
)))
endef

# Macro add_program:
#  generates rules to build, run and clean executable program
# Example: $(call add_program,bar,main.cpp,DEPEND:foo)
define add_program # (name, sources ..., [DEPEND:target ...])
$(eval \
all: $(1)
$(1): $(BINDIR)/$(1)
$(BINDIR)/$(1): $(call add_sources,$(2)) $(call get_depends,$(3))
	@ echo "$(COLOR_BUILD)Building executable program: $$@$(COLOR_OFF)"
	$(CXX) $(LDFLAGS) $$(filter %.o,$$^) $(LDLIBS) -o $$@

$(1)_TARGET_FILES += $(BINDIR)/$(1)

# additional dependencies for objects
-include $(DEPEND_FILES)

clean-$(1)::
	rm -f $(BINDIR)/$(1) $(OBJECT_FILES) $(DEPEND_FILES)
clean: clean-$(1)

# helper target to run a program
run-$(1): $(BINDIR)/$(1)
	$(BINDIR)/$(1)
run: run-$(1)
)
endef
