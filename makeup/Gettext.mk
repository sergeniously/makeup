#######################
# Gettext makeup module
#  implements macros to deal with po-files
#  PROJECT_* variables must be set outside

define find_gettext
$(eval \
XGETTEXT:=$(call find_program,xgettext,,REQUIRED)
MSGMERGE:=$(call find_program,msgmerge,,REQUIRED)
MSGFMT:=$(call find_program,msgfmt,,REQUIRED)
)
endef

# Macro to generate rules to create PO-translation file
# Options:
#  (required) LANG:lang ...
#    programming language of sources
#  (required) KEY:key ...
#    names of translation functions used in sources
#  (optional) NO_DATES
#    remove meaningless creation & revision date lines
# Example: $(call add_gettext_translation,russian,ru/foo.po, foo.cpp, LANG:c++ KEY:tr NO_DATES)
define add_gettext_translation # (language, po-file, sources ..., options ...)
$(foreach pot_file,$(call binary,$(2:%.po=%.pot)),$(eval \
all: $(1)
$(1): $(pot_file)
$(pot_file): $(3)
	@ echo "$(COLOR_BUILD)Generating $(1) PO translation file: $(abspath $(2))$(COLOR_OFF)"

	mkdir -p $(dir $(2)) $(dir $(pot_file))

	$(XGETTEXT) $(call opt_all,$(4),LANG:%,--language=%) $(call opt_all,$(4),KEY:%,--keyword=%) \
		--package-name="$(PROJECT_NAME)" --package-version="$(PROJECT_VERSION)" \
		--copyright-holder="$(PROJECT_COPYRIGHT)" --msgid-bugs-address="$(PROJECT_EMAIL)" \
		--from-code UTF-8 --no-wrap --no-location --sort-output --output=$$@ $$^

	$(MSGMERGE) --quiet --no-wrap --no-location --no-fuzzy-matching --sort-output $(2) $$@ --output-file $(2)

	$(call opt_one,$(4),NO_DATES,sed -i -e '/POT-Creation-Date/d' -e '/PO-Revision-Date/d' $(2))

clean-$(1):
	rm -f $(pot_file)
clean: clean-$(1)

help::
	$(call help,$(1),Generating PO translation file $(2))
))
endef

define install_gettext_translation # (po-file, destination)
$(eval \
install:: $(1)
	@ echo "$(COLOR_INSTALL)Installing PO translation file $(1) in $(2) ...$(COLOR_OFF)"
	mkdir -p $(2) && $(MSGFMT) $(1) -o $(2)/$(notdir $(1:%.po=%.mo))
)
endef
