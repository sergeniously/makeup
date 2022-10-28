#####################
# Boost makeup module
#  implements macros to find boost includes and libraries
# Provide variables:
#  BOOST_FOUND=yes|no: whether boost location is found or not
#  BOOST_INCLUDE_DIR: boost include directory if found, empty otherwise
#  BOOST_LIBRARY_DIR: boost libraries directory if found, empty otherwise
#  BOOST_LIBRARIES: found boost libraries with boost prefix, ready to be linked
#  BOOST_NOT_FOUND: not found libraries without boost prefix

# Macro to find boost location and define directory variables
# Options:
#   PATH:path: additional root path to search boost libraries
#   LIBS:list: specific libraries to search and store at BOOST_LIBRARIES variable
# Example:
#   $(call find_boost,PATH:$(HOME)/boost LIBS:system;regex)
define find_boost # ([PATH:path ...] [LIBS:list])
$(eval \
BOOST_INCLUDE_DIR=\
	$(subst /boost/version.hpp,,$(firstword \
		$(foreach path,$(call opt_each,$1,PATH:%,% %/include) \
			/opt/local/include /usr/local/include /opt/include /usr/include /opt/homebrew/include C:/Boost/include,\
			$(wildcard $(path)/boost/version.hpp))))
BOOST_LIBRARY_DIR=\
	$(realpath $(dir $(firstword $(foreach path,\
		$(wildcard $(call opt_each,$1,PATH:%,%/lib* %/stage/lib*) \
			/opt/local/lib* /usr/local/lib* /opt/lib* /usr/lib* /lib* /opt/homebrew/lib* C:/Boost/lib),\
		$(wildcard $(path)/libboost_system*)))))
BOOST_NOT_FOUND=
)$(eval \
BOOST_FOUND=$(if $(and $(BOOST_INCLUDE_DIR),$(BOOST_LIBRARY_DIR)),yes,no)
BOOST_LIBRARIES=\
	$(if $(BOOST_LIBRARY_DIR),$(foreach lib,$(sort $(call opt_list,$1,LIBS:%)),\
		$(if $(wildcard $(BOOST_LIBRARY_DIR)/libboost_$(lib)*),boost_$(lib),$(eval BOOST_NOT_FOUND+=$(lib)))))
)
endef
