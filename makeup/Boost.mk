#####################
# Boost makeup module
#  implements macros to find boost includes and libraries

define find_boost # ([PATH:path ...] [LIBS:list])
$(eval \
BOOST_INCLUDE_DIR=\
	$(subst /boost/version.hpp,,$(firstword \
		$(foreach path,$(call opt_each,$1,PATH:%,%/include) \
			/opt/local/include /usr/local/include /opt/include /usr/include /opt/homebrew/include C:/Boost/include,\
			$(wildcard $(path)/boost/version.hpp))))
BOOST_LIBRARY_DIR=\
	$(dir $(firstword $(foreach path,\
		$(wildcard $(foreach path,$(call opt_all,$1,PATH:%),$(path)/lib* $(path)/stage/lib*) \
			/opt/local/lib* /usr/local/lib* /opt/lib* /usr/lib* /lib* /opt/homebrew/lib* C:/Boost/lib),\
		$(wildcard $(path)/libboost_system*))))
)$(eval \
BOOST_FOUND=$(if $(and $(BOOST_INCLUDE_DIR),$(BOOST_LIBRARY_DIR)),yes,no)
BOOST_LIBRARIES=\
	$(if $(BOOST_LIBRARY_DIR),$(foreach lib,$(call opt_list,$1,LIBS:%),\
		$(if $(wildcard $(BOOST_LIBRARY_DIR)/libboost_$(lib)*),boost_$(lib))))
)
endef
