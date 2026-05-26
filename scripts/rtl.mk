ifndef RTL_MK
RTL_MK = 1

RTL_INCDIRS += ${PROJVAR_PROJECT_ROOT}/macro

RTL_SRCFILES += $(wildcard ${PROJVAR_PROJECT_ROOT}/rtl/*.sv)

endif
