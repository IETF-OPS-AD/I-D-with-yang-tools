# SPDX-FileCopyrightText: 2025 IETF
# SPDX-License-Identifier: 0BSD

YANGDIR ?= yang

STDYANGDIR ?= tools/yang
$(STDYANGDIR):
	git clone --depth 10 -b main https://github.com/YangModels/yang $@

YANGRFC ?= $(STDYANGDIR)/standard/ietf/RFC
YANGEXP ?= $(STDYANGDIR)/experimental/ietf-extracted-YANG-modules
YANGIEEE8021 ?= $(STDYANGDIR)/standard/ieee/published/802.1/

OPTIONS=--ietf --tree-print-structures --tree-print-groupings -f tree --tree-line-length=69

YANG_PATH=$(YANGDIR):$(YANGRFC):$(YANGEXP):$(YANGIEEE8021)

YANG=$(wildcard $(YANGDIR)/*.yang)
STDYANG=$(wildcard $(YANGDIR)/ietf-*.yang)
TXT=$(patsubst $(YANGDIR)/%.yang,$(YANGDIR)/trees/%.tree,$(YANG))

.PHONY: yang-lint yang-gen-tree yang-clean pyang-setup

$(YANGDIR)/trees:
	mkdir -p $@

pyang-setup: $(STDYANGDIR)
pyang-lint: pyang-setup $(STDYANG)
ifeq ($(STDYANG),)
	$(info No files matching $(YANGDIR)/ietf-*.yang found. Skipping pyang-lint.)
else
	pyang $(OPTIONS) -p $(YANG_PATH) $(STDYANG)
endif

yang-gen-tree: $(YANGDIR)/trees pyang-lint $(TXT)

yang-clean:
	rm -f $(TXT)

FORCE:

$(YANGDIR)/trees/%.tree: $(YANGDIR)/%.yang $(YANGDIR)/trees FORCE
	pyang $(OPTIONS) -p $(YANG_PATH) $< > $@
