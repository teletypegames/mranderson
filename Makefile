# -----------------------------------------
# Makefile – TIC-80 project builder
# -----------------------------------------

PROJECT = mranderson

ORDER      = $(PROJECT).inc
OUTPUT     = $(PROJECT).lua
OUTPUT_ZIP = $(PROJECT).html.zip
OUTPUT_TIC = $(PROJECT).tic

SRC_DIR    = inc
SRC        = $(shell sed 's|^|$(SRC_DIR)/|' $(ORDER))

ASSETS_LUA = inc/meta/meta.assets.lua

GAME_LANG ?= lua

all: build

build: $(OUTPUT)

$(OUTPUT): $(SRC) $(ORDER)
	@rm -f $(OUTPUT)
	@while read f; do \
		cat "$(SRC_DIR)/$$f" >> $(OUTPUT); \
		echo "" >> $(OUTPUT); \
	done < $(ORDER)

export: build
	@if [ -z "$(VERSION)" ]; then \
		echo "ERROR: VERSION not set!"; \
		exit 1; \
	fi
	@echo "==> Exporting HTML for version $(VERSION)"
	@tic80 --cli --skip --fs=. \
		--cmd="load $(OUTPUT) & save $(PROJECT)-$(VERSION) & export html $(PROJECT)-$(VERSION).html & exit"
	@echo "==> Creating versioned files"
	@if [ -f "$(PROJECT)-$(VERSION).tic" ]; then \
		cp $(PROJECT)-$(VERSION).tic $(PROJECT).tic; \
	fi
	@if [ -f "$(PROJECT)-$(VERSION).html.zip" ]; then \
		cp $(PROJECT)-$(VERSION).html.zip $(PROJECT).html.zip; \
	fi
	@echo "==> Generated files:"
	@ls -lh $(PROJECT)-$(VERSION).* $(PROJECT).tic $(PROJECT).html.zip 2>/dev/null || true

# -----------------------------------------
# Native binaries — self-contained TIC-80 players with the cart baked in.
# The player templates are downloaded from tic80.com at export time, so
# this target needs network access. All upstream players are x86-64.
# -----------------------------------------

BINARY_SLUGS = win-x64 linux-x64 mac-x64

# $(1) slug, $(2) exported file, $(3) file name inside the package
# (unixos zip őrzi a végrehajtási bitet)
define f_pack_binary
	set -e; \
	PKG_DIR="$(PROJECT)-$(VERSION)-$(1)"; \
	rm -rf "$$PKG_DIR" "$$PKG_DIR.zip"; \
	mkdir -p "$$PKG_DIR"; \
	mv "$(2)" "$$PKG_DIR/$(3)"; \
	chmod +x "$$PKG_DIR/$(3)"; \
	zip -r "$$PKG_DIR.zip" "$$PKG_DIR" >/dev/null; \
	rm -rf "$$PKG_DIR"; \
	echo "==> $$PKG_DIR.zip kesz"
endef

binaries: build
	@if [ -z "$(VERSION)" ]; then \
		echo "ERROR: VERSION not set!"; \
		exit 1; \
	fi
	@echo "==> Exporting native players for version $(VERSION)"
	@tic80 --cli --skip --fs=. \
		--cmd="load $(OUTPUT) & export win $(PROJECT)-win & export linux $(PROJECT)-linux & export mac $(PROJECT)-mac & exit"
	@$(call f_pack_binary,win-x64,$(PROJECT)-win.exe,$(PROJECT).exe)
	@$(call f_pack_binary,linux-x64,$(PROJECT)-linux,$(PROJECT))
	@$(call f_pack_binary,mac-x64,$(PROJECT)-mac,$(PROJECT))

watch:
	make build
	fswatch -o $(SRC_DIR) $(ORDER) assets | while read; do make build; done

import_assets:
	@for t in $(ASSET_TYPES); do \
		for f in $(ASSETS_DIR)/$$t/*.png; do \
			[ -e "$$f" ] || continue; \
			echo "==> Importing $$f as $$t..."; \
			tic80 --cli --skip --fs=. --cmd="import $$t $$f & exit"; \
		done; \
	done

export_assets: build
	@echo "==> Exporting TIC-80 asset sections"
	@mkdir -p inc/meta
	@sed -n '/^-- <PALETTE>/,/^-- <\/PALETTE>/p;\
	         /^-- <TILES>/,/^-- <\/TILES>/p;\
	         /^-- <SPRITES>/,/^-- <\/SPRITES>/p;\
	         /^-- <MAP>/,/^-- <\/MAP>/p;\
	         /^-- <SFX>/,/^-- <\/SFX>/p;\
	         /^-- <MUSIC>/,/^-- <\/MUSIC>/p' \
		$(OUTPUT) > $(ASSETS_LUA)

clean:
	@rm -f $(PROJECT)-*.tic $(PROJECT)-*.html.zip $(OUTPUT)
	@rm -f $(PROJECT)-*-win-x64.zip $(PROJECT)-*-linux-x64.zip $(PROJECT)-*-mac-x64.zip
	@rm -f $(PROJECT)-win.exe $(PROJECT)-linux $(PROJECT)-mac
	@echo "==> Cleaned build artifacts"

.PHONY: all build export binaries watch import_assets export_assets clean

