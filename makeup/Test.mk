####################
# Test makeup module
#  implements macros to add test targets

# Macro add_test_directory(dir)
define add_test_directory
$(eval \
check-dir-$(1):
	@+ $(MAKE) -C $(1) check
check: check-dir-$(1)
clean-dir-$(1):
	@ $(MAKE) -C $(1) clean
clean: clean-dir-$(1)
)
endef

# Macro add_test_program(test-name, program)
define add_test_program
$(eval \
check-$(1): $(BINDIR)/$(2)
	@ echo "$(COLOR_TEST)Running tests: $(1) ($(2))$(COLOR_OFF)"
	$(BINDIR)/$(2)
check: check-$(1)
)
endef

# Macro add_test_command(test-name, command ...)
define add_test_command
$(eval \
check-$(1): $(TARGET_FILES)
	@ echo "$(COLOR_TEST)Running tests: $(1) ($(firstword $(2)))$(COLOR_OFF)"
	$(2)
check: check-$(1)
)
endef
