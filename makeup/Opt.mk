###################
# Opt makeup module
#  implements macros to extract options
#  included automatically

# Extract all values of options with specified @pattern
# Example: $(call opt_all, FILE:one FILE:two, FILE:%, rm -f %) -> rm -f one two
# FIXME: default value is not used!
#define opt_all # (options ..., pattern, [replace], [default])
#$(or $(subst %,$(patsubst $2,%,$(filter $2,$1)),$(or $3,%)),$4)
#endef
define opt_all # (options ..., pattern, [replace])
$(patsubst $(2),$(or $(3),%),$(filter $(2),$(1)))
endef

# Extract the first value of options with specified @pattern
# Example: $(call opt_one, MODE:123 DIR:any, MODE:%, -m %) -> -m 123
define opt_one # (options ..., pattern, [replace], [default])
$(or $(patsubst $2,$(or $3,%),$(firstword $(filter $2,$1))),$4)
endef

# Return @replace string if @pattern is not found in @options
# Example: $(call opt_not, DIR:one DEPEND:two, EXCLUDE, YES) -> YES
# Example: $(call opt_not, DEPEND:two EXCLUDE, EXCLUDE, YES) -> 
define opt_not # (options ..., pattern, replace)
$(if $(filter $2,$1),,$3)
endef

# Extract all values of options with specified @pattern
# Example: $(call opt_all, FILE:one FILE:two, FILE:%, --file=%) -> --file=one --file=two
define opt_each # (options ..., pattern, [replace])
$(foreach word,$(patsubst $2,%,$(filter $2,$1)),$(subst %,$(word),$(or $3,%)))
endef

# Extract lists of values separated by colon from options with specified pattern
# Example: $(call opt_list, FILES:one;two;tri, FILES:%, cp -f %) -> cp -f one two tri
define opt_list # (options ..., pattern, [replace])
$(subst %,$(subst ;, ,$(patsubst $2,%,$(filter $2,$1))),$(or $3,%))
endef

# Extract quoted value of @option (option:"value") from list of @options
# Example: $(call opt_quote,DIR:name COMMAND:"echo yes",COMMAND) -> echo yes
# Example: $(call opt_quote,DIR:name COMMENT:"one two",COMMENT,# %) -> # one two
# Example: $(call opt_quote,DIR:name COMMENT:"one two",UNKNOWN,%,no) -> no
define opt_quote # (options ...,option,[replace],[default])
$(if $(findstring $2:",$1),$(subst %,$(subst $$,$() $(),$(firstword $(subst "$$,$() $(),$(lastword $(subst $2:",$() $(),$(subst $() $(),$$,$1)$$))))),$(or $3,%)),$(call opt_one,$1,$2:%,$3,$4))
endef

# Extract COMMENT:"string" from options
# Example: $(call opt_comment,COMMENT:"hello world") -> hello world
define opt_comment # (options ...,[replace],[default])
$(call opt_quote,$1,COMMENT,$2,$3)
endef
