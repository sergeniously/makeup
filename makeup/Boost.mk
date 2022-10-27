#####################
# Boost makeup module
#  implements macros to find boost includes and libraries

# Macro to find boost location and define directory variables
# Options:
#   PATH:path: additional root path to search boost libraries
#   LIBS:list: specific libraries to search and store to BOOST_LIBRARIES variable
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
)$(eval \
BOOST_FOUND=$(if $(and $(BOOST_INCLUDE_DIR),$(BOOST_LIBRARY_DIR)),yes,no)
BOOST_LIBRARIES=\
	$(if $(BOOST_LIBRARY_DIR),$(foreach lib,$(call opt_list,$1,LIBS:%),\
		$(if $(wildcard $(BOOST_LIBRARY_DIR)/libboost_$(lib)*),boost_$(lib))))
)
endef
