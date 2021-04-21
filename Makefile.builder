ifneq (,$(findstring fc,$(DIST)))
    DISTRIBUTION := fedora
endif

ifneq (,$(findstring centos,$(DIST)))
    DISTRIBUTION := centos
endif

ifneq (,$(findstring $(DIST), leap tumbleweed))
    DISTRIBUTION := opensuse
    DIST_TAG := $(DIST)
endif

ifneq (,$(DISTRIBUTION))
    RPM_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    BUILDER_MAKEFILE = $(RPM_PLUGIN_DIR)Makefile.rpmbuilder
    TEMPLATE_SCRIPTS = $(RPM_PLUGIN_DIR)template_scripts
endif