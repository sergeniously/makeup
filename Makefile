
.PHONY: help demo install project

INSTALL_DIR=/usr/local/include

help:
	@echo "Run <make install> to instal makeup to the default location"
	@echo "Run <make project DIR=project/dir> to create a project file"
	@echo "Run <make demo> to build demo project in the demo directory"

demo:
	@make -C demo

install:
	@echo "Installing makeup to the default location..."
	@sudo ln -Fisn $(abspath makeup) $(INSTALL_DIR)/makeup

project:
	@$(if $(DIR),echo "Creating makeup project file $(DIR)/makeup.mk ...",echo "You must specify DIR variable" && false)
	@mkdir -p $(DIR) && cp -f $(CURDIR)/makeup.pj $(DIR)/makeup.mk
