##################
# Qt makeup module
#  implements macros to build Qt applications

# Macro to find Qt applications and libraries and define QT variables to use them
# Example: $(call find_qt, Core Gui, /usr/lib/qt5)
define find_qt # (libraries ... [, paths ...])
$(foreach QMAKE,$(call find_program,qmake,$(2),REQUIRED RECURSIVE),$(eval \
QT_VERSION:=$(firstword $(subst ., ,$(shell $(QMAKE) -query QT_VERSION)))
QT_INCLUDE_DIR:=$(shell $(QMAKE) -query QT_INSTALL_HEADERS)
QT_LIBRARY_DIR:=$(shell $(QMAKE) -query QT_INSTALL_LIBS)
QT_BINARY_DIR:=$(shell $(QMAKE) -query QT_INSTALL_BINS)
QT_DEFINITIONS:=QT_DEPRECATED_WARNINGS QT_NO_DEBUG \
	$(call uppercase,$(1:%=QT_%_LIB))
))$(eval \
QT_INCLUDE_DIR+=$(1:%=$(QT_INCLUDE_DIR)/Qt%)
QT_LIBRARIES:=$(1:%=Qt$(QT_VERSION)%)
QT_LRELEASE:=$(QT_BINARY_DIR)/lrelease
QT_UIC:=$(QT_BINARY_DIR)/uic
QT_MOC:=$(QT_BINARY_DIR)/moc
QT_RCC:=$(QT_BINARY_DIR)/rcc
)
endef

# Macro to create Qt .qrc resource file that aggregates any files (qml, images ...)
#  and return absolute path of it so that it is easy to add it to source file list
define add_qt_resource # (name.qrc, files ...)
$(foreach target,$(call binary,$(1)),$(eval \
$(target): $(2) | $(BINDIR)
	@ echo "$(COLOR_PREPROCESS)Generating Qt resource file: $(abspath $(1))$(COLOR_OFF)"
	echo "<RCC><qresource prefix='/'>" > $$@
	printf "<file alias='%s'>%s</file>\n" $(foreach entry,$(2),$(entry) $(abspath $(entry))) >> $$@
	echo "</qresource></RCC>" >> $$@
clean-$(1):
	rm -f $(target)
clean: clean-$(1)
)$(target))
endef

# Macro to compile ts translation files into one qm file and save it in @destination
define install_qt_translations # (ts-files ..., destination)
$(foreach target,$(basename $(notdir $(firstword $(1)))),$(eval \
install-translations::
	@ echo "$(COLOR_INSTALL)Installing Qt translation file $(target).qm in $(2) ...$(COLOR_OFF)";
	mkdir -p $(2) && $(QT_LRELEASE) $(1) -qm $(2)/$(target).qm
install: install-translations
))
endef

define add_source.h
$(foreach binary,$(call binary,$(1).cpp),\
$(eval $(binary): $(1))$(eval $(binary).o: $(binary) Makefile)\
$(binary) $(binary).o)
endef

define add_source.qrc
$(foreach binary,$(call binary,$(1).cpp),\
$(eval $(binary): $(1))$(eval $(binary).o: $(binary) Makefile)\
$(binary) $(binary).o)
endef

define add_source.ui
$(foreach binary,$(call binary,$(patsubst %.ui,ui_%.h,$(notdir $(1)))),\
$(eval $(binary): $(1))$(binary))
endef

# Describe rules to make Qt related intermediate files
$(BINDIR)/ui_%.h: | $(BINDIR)
	@ echo "$(COLOR_PREPROCESS)Preprocessing Qt UI file: $(abspath $<)$(COLOR_OFF)"
	$(QT_UIC) -o $@ $<

$(BINDIR)/%.h.cpp: | $(BINDIR)
	@ echo "$(COLOR_PREPROCESS)Preprocessing Qt header file: $(abspath $<)$(COLOR_OFF)"
	$(QT_MOC) $(filter -D% -I%,$(CXXFLAGS)) -o $@ $<

$(BINDIR)/%.qrc.cpp: | $(BINDIR)
	@ echo "$(COLOR_PREPROCESS)Preprocessing Qt resource file: $(abspath $<)$(COLOR_OFF)"
	$(QT_RCC) -name $(basename $(<F)) -o $@ $<

# Do not auto remove intermediate files
.PRECIOUS: %.h.cpp %.qrc.cpp
