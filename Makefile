# ============================================================
#  Victim2Victor — single-file build (unframe method)
#
#  The composer (make/tpl.mk) streams each page layout and
#  inlines the CSS, JS and its section partials into a static
#  page — ui/layout.html → ui/dist/index.html (home) and
#  ui/layout-about.html → ui/dist/about.html. No bundler, no
#  npm, just make + awk. Those files are what Pages serves.
# ============================================================

BUILD_DIR := ui/dist
SRC       := ui/layout.html
SRC_ABOUT := ui/layout-about.html
PAGES     := $(BUILD_DIR)/index.html $(BUILD_DIR)/about.html
MAP       := make/web.map
COMPS     := $(wildcard ui/comps/*.html)
IMGS      := $(wildcard ui/img/*)

# the compose macro (vendored from unframe-kit; no submodule needed)
include make/tpl.mk

.PHONY: all dev stg prd clean

all: dev

# ------------------------------------------------------------
#  dev / stg / prd differ only in the back-end (Supabase) calls.
#  The JS source fences those with //online markers:
#    //online-start … //online-end   a block of back-end code
#    … code …  //online              a single back-end line
#  dev strips both (offline: mailto fallback only); stg and prd
#  keep them (online: forms insert into Supabase). See README.
# ------------------------------------------------------------

## dev — offline single-file build (back-end calls stripped)
dev:
	@mkdir -p $(BUILD_DIR)/img
	$(call compose,$(SRC),$(MAP),$(BUILD_DIR)/index.html)
	$(call compose,$(SRC_ABOUT),$(MAP),$(BUILD_DIR)/about.html)
	@cp $(IMGS) $(BUILD_DIR)/img/
	@sed -i -e '/\/\/online-start/,/\/\/online-end/d' -e '/\/\/online$$/d' $(PAGES)
	@echo "dev: offline build (Supabase calls stripped) → $(PAGES)"

## stg — online build for staging (Supabase calls kept; rows tagged env=0)
stg:
	@mkdir -p $(BUILD_DIR)/img
	$(call compose,$(SRC),$(MAP),$(BUILD_DIR)/index.html)
	$(call compose,$(SRC_ABOUT),$(MAP),$(BUILD_DIR)/about.html)
	@cp $(IMGS) $(BUILD_DIR)/img/
	@sed -i 's/\(var SUPABASE_ENV *= *\)1/\10/' $(PAGES)
	@echo "staging.victim2victor.co.za" > $(BUILD_DIR)/CNAME
	@echo "stg: online build (Supabase calls kept, env=0 staging) → $(PAGES)"

## prd — online build for production (Supabase calls kept; rows tagged env=1)
prd:
	@mkdir -p $(BUILD_DIR)/img
	$(call compose,$(SRC),$(MAP),$(BUILD_DIR)/index.html)
	$(call compose,$(SRC_ABOUT),$(MAP),$(BUILD_DIR)/about.html)
	@cp $(IMGS) $(BUILD_DIR)/img/
	@echo "victim2victor.co.za" > $(BUILD_DIR)/CNAME
	@echo "prd: online build (Supabase calls kept, env=1 production) → $(PAGES)"

## clean — remove the generated output
clean:
	@rm -rf $(BUILD_DIR)
