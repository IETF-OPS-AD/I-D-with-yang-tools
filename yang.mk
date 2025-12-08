# SPDX-FileCopyrightText: 2025 IETF
# SPDX-License-Identifier: 0BSD

SHELL := bash

YANGDIR ?= ./yang
EXDIR ?= ./yang/examples
YANGSONLIB ?=$(YANGDIR)/tools/yang-library.json

STDYANGDIR ?= ./yang/models
$(STDYANGDIR):
	git clone --depth 10 -b main https://github.com/YangModels/yang $@

YANGRFC ?= $(STDYANGDIR)/standard/ietf/RFC
YANGEXP ?= $(STDYANGDIR)/experimental/ietf-extracted-YANG-modules
YANGIEEE8021 ?= $(STDYANGDIR)/standard/ieee/published/802.1/
YANG_PATH=$(YANGDIR):$(YANGRFC):$(YANGEXP):$(YANGIEEE8021)

PYANG_OPTIONS=--ietf --tree-print-structures --tree-print-groupings -f tree --tree-line-length=69

# -c, --ctype {config,nonconfig,all} 
# -s, --scope {syntax,semantics,all}
YANGSON_OPTIONS= -p $(YANG_PATH) $(YANGSONLIB) -c all -s syntax

YANG=$(wildcard $(YANGDIR)/*.yang)
JSONEX=$(wildcard $(EXDIR)/valid-*.json)
STDYANG=$(wildcard $(YANGDIR)/ietf-*.yang)
TXT=$(patsubst $(YANGDIR)/%.yang,$(YANGDIR)/trees/%.tree,$(YANG))

.PHONY: yang-gen-tree yang-clean pyang-setup

$(YANGDIR)/trees:
	mkdir -p $@

pyang-setup: $(STDYANGDIR)

pyang-lint: pyang-setup $(STDYANG)
ifeq ($(STDYANG),)
	$(info No files matching $(YANGDIR)/ietf-*.yang found. Skipping pyang-lint.)
else
	pyang $(PYANG_OPTIONS) -p $(YANG_PATH) $(STDYANG)
endif

yang-gen-tree: $(YANGDIR)/trees pyang-lint $(TXT)

yangson-validate: $(JSONEX)
ifeq ($(JSONEX),)
	$(info No files matching $(EX)/valid-*.json found. Skipping yangson.)
else
	for file in $(EXDIR)/valid-*.json; do yangson $(YANGSON_OPTIONS) -v $${file} || exit 1; done
endif

yang-clean:
	rm -f $(TXT)

FORCE:

$(YANGDIR)/trees/%.tree: $(YANGDIR)/%.yang $(YANGDIR)/trees FORCE
	pyang $(PYANG_OPTIONS) -p $(YANG_PATH) $< > $@
