########################
# Postgres makeup module
# implements macros to preprocess embedded Postgres SQL files

define find_postgres
$(foreach pg_config,$(call find_program,pg_config,,REQUIRED),$(eval \
POSTGRES_INCLUDE_DIR:=$(shell $(pg_config) --includedir --includedir-server)
POSTGRES_LIBRARY_DIR:=$(shell $(pg_config) --libdir)
POSTGRES_LIBRARIES:=ecpg
ECPG:=$(call find_program,ecpg,,REQUIRED)
))
endef

define add_source.pgc
$(foreach binary,$(call binary,$(1).cpp),\
$(binary) $(binary).o $(eval \
$(binary).o: $(binary) Makefile
$(binary): $(1)))
endef

$(BINDIR)/%.pgc.cpp: | $(BINDIR)
	@ echo "$(COLOR_PREPROCESS)Preprocessing embedded Postgres SQL: $(abspath $<)$(COLOR_OFF)"
	$(ECPG) -o $@ $<
