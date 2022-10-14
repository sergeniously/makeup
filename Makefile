
.PHONY: help install project

INSTALL_DIR=/usr/local/include

help:
	@echo "Run <make install> to instal makeup to the default location"
	@echo "Run <make project DIR=project/dir> to create a project file"

install:
	@test -e $(INSTALL_DIR)/makeup && echo "makeup is already installed" || \
		{ @echo "Installing makeup components into the system..."; \
		  sudo ln -fs $(abspath makeup) $(INSTALL_DIR)/makeup; }

project:
	@test -e $(INSTALL_DIR)/makeup || { echo "makeup is not yet installed"; false; }
	@$(if $(DIR),echo "Creating makeup project file $(DIR)/makeup.mk ...",echo "You must specify DIR variable"; false)
	@test -f $(DIR)/makeup.mk && rm -f $(DIR)/makeup.mk || mkdir -p $(DIR)
	@echo "#####################" >> $(DIR)/makeup.mk
	@echo "# makeup project file" >> $(DIR)/makeup.mk
	@echo "include makeup/.mk" >> $(DIR)/makeup.mk
