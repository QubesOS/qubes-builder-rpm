ifneq (,$(findstring fc,$(DIST)))
    FEDORA_PLUGIN_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
    DISTRIBUTION := fedora
    BUILDER_MAKEFILE = $(FEDORA_PLUGIN_DIR)Makefile.fedora
    TEMPLATE_SCRIPTS = $(FEDORA_PLUGIN_DIR)template_scripts
endif
