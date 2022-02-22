# Copyright (c) 2022 Corey Hinshaw
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

PAGE_DIR=     pages
POST_DIR=     posts
TMPL_DIR=     templates
STATIC_DIR=   static
OUT_DIR=      output
POST_OUT_DIR= $(OUT_DIR)/posts
CONFIG=       config.mk

ECHO=     echo
MKDIR=    mkdir
GREP=     grep
RM=       rm
CP=       cp
SED=      sed
FIND=     find
SORT=     sort
UNIQ=     uniq
CUT=      cut
BASENAME= basename

SED_INPLACE=-i

SITE_NAME=
DOMAIN=              localhost
BASE_PATH=
INDEX=               index.gmi
TAG_TEXT=            Filed under:
DEPLOY_CMD=
CONTENT_PLACEHOLDER= %%CONTENT%%
TAG_PLACEHOLDER=     %%TAG%%
POSTS_PLACEHOLDER=   %%POSTS%%
URL=                 gemini://$(DOMAIN)$(BASE_PATH)

PAGE_TMPL=  $(TMPL_DIR)/page
POST_TMPL=  $(TMPL_DIR)/post
INDEX_TMPL= $(TMPL_DIR)/index
TAG_TMPL=   $(TMPL_DIR)/tag

include $(CONFIG)

null=
space=$(null) $(null)

post_out_path=$(foreach file,$(notdir $(1)),$(POST_OUT_DIR)/$(subst $(space),/,$(wordlist 1,2,$(subst -, ,$(file))))/$(lastword $(subst _, ,$(file))))
post_paths=$(foreach post,$(1),$(filter %::$(post),$(POSTS_MAP)))
post_src_path=$(foreach post,$(1),$(subst $(post)::,,$(filter $(post)::%,$(POSTS_MAP))))
tagname=$(basename $(notdir $(1)))
tag_posts=$(shell $(GREP) -lr '^TAGS:.* $(1)\b' $(POST_DIR) | $(SORT))

find_title:=$(SED) -En '/^\# .+/ {s/^\# (.+)/\1/p;q}'
post_vars:=post_src=$${post\#*::};post_out=$${post%::*};
post_link_vars:=url="$(URL)$${post_out\#$(OUT_DIR)}";text="$$($(find_title) $$post_out)";date=$$($(BASENAME) $$post_src | $(CUT) -d_ -f1);link="=> $${url} $${date}: $${text}";
fill_placeholders:=-e '/TEMPLATE:/d' -e "s~%%TITLE%%~$$title~g" -e 's/%%SITE_NAME%%/$(SITE_NAME)/g' -e 's/%%DOMAIN%%/$(DOMAIN)/g' -e 's|%%BASE_PATH%%|$(BASE_PATH)|g' -e 's|%%URL%%|$(URL)|g'
set_template=template=$$($(SED) -En '/^TEMPLATE: .+/ {s|^TEMPLATE: (.+)$$|$(TMPL_DIR)/\1|p;q}' $<)

SRC_DIR:=$(PAGE_DIR) $(POST_DIR) $(TMPL_DIR) $(STATIC_DIR)

SRC_PAGES:=$(shell $(FIND) $(PAGE_DIR) -type f -name '*.gmi')
OUT_PAGES:=$(patsubst $(PAGE_DIR)/%,$(OUT_DIR)/%,$(SRC_PAGES))

OUT_INDEXES:=$(addprefix $(OUT_DIR)/,$(INDEX))

SRC_POSTS:=$(wildcard $(POST_DIR)/*.gmi)
OUT_POSTS:=$(call post_out_path,$(SRC_POSTS))
POSTS_MAP:=$(join $(addsuffix ::,$(OUT_POSTS)),$(SRC_POSTS))

TAGS:=$(shell $(GREP) -hr '^TAGS:' $(POST_DIR) | $(SED) -e 's/^TAGS: //g;s/ /\n/g' | $(SORT) | $(UNIQ))
TAG_INDEXES:=$(addprefix $(POST_OUT_DIR)/,$(addsuffix .gmi,$(TAGS)))

SRC_STATIC:=$(shell $(FIND) $(STATIC_DIR) -type f)
OUT_STATIC:=$(patsubst $(STATIC_DIR)/%,$(OUT_DIR)/%,$(SRC_STATIC))

.PHONY: all gemini clean init deploy

all: $(OUT_PAGES) $(OUT_INDEXES) $(OUT_POSTS) $(TAG_INDEXES) $(OUT_STATIC)

gemini: all

clean:
	@$(FIND) $(OUT_DIR) -mindepth 1 -depth -delete -printf 'remove %p\n'

init: $(SRC_DIR) $(PAGE_TMPL) $(POST_TMPL) $(INDEX_TMPL) $(TAG_TMPL) $(OUT_INDEXES) $(CONFIG)

deploy:
	$(DEPLOY_CMD)

$(SRC_DIR):
	@$(ECHO) "CREATE directory: $@"
	@$(MKDIR) -p $@

$(CONFIG):
	@$(ECHO) "CREATE config: $@"
	@$(ECHO) -e "#SITE_NAME=\n#DOMAIN=localhost\n#BASE_PATH=\n#TAG_TEXT=Filed under:\n#INDEX=index.gmi\n#DEPLOY_CMD=" > $@

$(PAGE_TMPL) $(POST_TMPL):
	@$(ECHO) "CREATE template: $@"
	@$(MKDIR) -p $(dir $@)
	@$(ECHO) -e "$(CONTENT_PLACEHOLDER)\n\n=> $(URL)/ Back to homepage" > $@

$(INDEX_TMPL):
	@$(ECHO) "CREATE template: $@"
	@$(MKDIR) -p $(dir $@)
	@$(ECHO) "$(CONTENT_PLACEHOLDER)" > $@

$(TAG_TMPL):
	@$(ECHO) "CREATE template: $@"
	@$(MKDIR) -p $(dir $@)
	@$(ECHO) -e "# Posts filed under $(TAG_PLACEHOLDER)\n\n$(POSTS_PLACEHOLDER)\n\n=> $(URL)/ Back to homepage" > $@

$(addprefix $(PAGE_DIR)/,$(INDEX)):
	@$(ECHO) "CREATE index: $@"
	@$(MKDIR) -p $(dir $@)
	@$(ECHO) -e "# $(DOMAIN)\n\n$(POSTS_PLACEHOLDER)" > $@

$(TAG_INDEXES): $(OUT_POSTS) $(TAG_TMPL) $(CONFIG)
	@$(ECHO) "BUILD tag: '$@'  template: '$(TAG_TMPL)'"
	@$(MKDIR) -p $(dir $@)
	@$(SED) -e 's/$(TAG_PLACEHOLDER)/$(call tagname,$@)/g' $(TAG_TMPL) > $@
	@for post in $(call post_paths,$(call tag_posts,$(call tagname,$@))); do \
		$(post_vars) \
		$(post_link_vars) \
		$(SED) $(SED_INPLACE) -e "/$(POSTS_PLACEHOLDER)/a\
	$$link" $@; \
	done
	@$(SED) $(SED_INPLACE) -e '/$(POSTS_PLACEHOLDER)/d' $(fill_placeholders) $@

$(OUT_DIR)/%.gmi: $(PAGE_DIR)/%.gmi $(PAGE_TMPL) $(CONFIG)
	@$(MKDIR) -p $(dir $@)
	@$(set_template); \
	title="$$($(find_title) $<)"; \
	$(ECHO) "BUILD page: '$@'  template: '$${template:-$(PAGE_TMPL)}'"; \
	$(SED) -e '/$(CONTENT_PLACEHOLDER)/r$<' -e '/$(CONTENT_PLACEHOLDER)/d' $${template:-$(PAGE_TMPL)} | $(SED) $(fill_placeholders) > $@

.SECONDEXPANSION:
$(OUT_INDEXES): $(PAGE_DIR)/$$(notdir $$@) $(OUT_POSTS) $(INDEX_TMPL) $(CONFIG)
	@$(MKDIR) -p $(dir $@)
	@$(set_template); \
	title="$$($(find_title) $<)"; \
	$(ECHO) "BUILD index: '$@'  template: '$${template:-$(INDEX_TMPL)}'"; \
	$(SED) -e '/$(CONTENT_PLACEHOLDER)/r$<' -e '/$(CONTENT_PLACEHOLDER)/d' $${template:-$(INDEX_TMPL)} | $(SED) $(fill_placeholders) > $@
	@for post in $$(echo $(POSTS_MAP) | sort); do \
		$(post_vars) \
		$(post_link_vars) \
		$(SED) $(SED_INPLACE) -e "/$(POSTS_PLACEHOLDER)/a\
	$$link" $@; \
	done
	@$(SED) $(SED_INPLACE) -e '/$(POSTS_PLACEHOLDER)/d' $(fill_placeholders) $@

$(POST_OUT_DIR)/%.gmi: $$(call post_src_path,$$@) $(POST_TMPL) $(CONFIG)
	@$(MKDIR) -p $(dir $@)
	@$(set_template); \
	title="$$($(find_title) $<)"; \
	$(ECHO) "BUILD post: '$@'  template: '$${template:-$(POST_TMPL)}'"; \
	$(SED) -e '/$(CONTENT_PLACEHOLDER)/r$<' -e '/$(CONTENT_PLACEHOLDER)/d' $${template:-$(POST_TMPL)} | $(SED) -r -e '/^TAGS: / { s///;s/ /\n/g;s|([^\n]*)|=> $(URL)/\1.gmi \1|g;s/^(.)/$(TAG_TEXT)\n\1/ }' $(fill_placeholders) > $@

$(OUT_DIR)/%: $(STATIC_DIR)/%
	@$(ECHO) "COPY file: '$@'"
	@$(MKDIR) -p $(dir $@)
	@$(CP) $< $@
