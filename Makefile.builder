ifneq (,$(findstring fc,$(DIST)))
    DISTRIBUTION := fedora
    FEDORA_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    BUILDER_MAKEFILE = $(FEDORA_PLUGIN_DIR)Makefile.fedora
    TEMPLATE_SCRIPTS = $(FEDORA_PLUGIN_DIR)template_scripts
endif

ifneq (,$(findstring centos,$(DIST)))
    DISTRIBUTION := centos
    FEDORA_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    BUILDER_MAKEFILE = $(FEDORA_PLUGIN_DIR)Makefile.fedora
    TEMPLATE_SCRIPTS = $(FEDORA_PLUGIN_DIR)template_scripts
endif
