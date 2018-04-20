ifneq (,$(findstring fc,$(DIST)))
    DISTRIBUTION := fedora
    RPM_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    BUILDER_MAKEFILE = $(RPM_PLUGIN_DIR)Makefile.rpmbuilder
    TEMPLATE_SCRIPTS = $(RPM_PLUGIN_DIR)template_scripts
endif

ifneq (,$(findstring centos,$(DIST)))
    DISTRIBUTION := centos
    RPM_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    BUILDER_MAKEFILE = $(RPM_PLUGIN_DIR)Makefile.rpmbuilder
    TEMPLATE_SCRIPTS = $(RPM_PLUGIN_DIR)template_scripts
endif
