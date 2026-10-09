# Pane — common tasks. Thin wrappers over Scripts/*; run `make help` for the list.
.DEFAULT_GOAL := help
.PHONY: help lint test test-all dev build editor clean

EDITOR_DIR := Editor
APP        := build/Pane.app

help: ## Show this help
	@awk 'BEGIN{FS=":.*## "} /^[a-zA-Z_-]+:.*## /{printf "  make %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

$(EDITOR_DIR)/node_modules: $(EDITOR_DIR)/package-lock.json
	cd $(EDITOR_DIR) && npm ci
	@touch $@

lint: $(EDITOR_DIR)/node_modules ## Typecheck the editor (tsc) and run SwiftLint if installed
	cd $(EDITOR_DIR) && npm run --silent typecheck
	@if command -v swiftlint >/dev/null 2>&1; then swiftlint lint --quiet; \
	else echo "swiftlint not installed, skipping (brew install swiftlint)"; fi

test: ## Run the PaneKit suite (pure Foundation)
	Scripts/test.sh

test-all: $(EDITOR_DIR)/node_modules ## Run every suite: PaneKit, typecheck, keyboard, WKWebView suites
	Scripts/test-all.sh

dev: $(EDITOR_DIR)/node_modules ## Debug build, then (re)launch build/Pane.app
	Scripts/build-app.sh --debug
	-@pkill -x Pane 2>/dev/null; sleep 0.3
	open $(APP)

build: $(EDITOR_DIR)/node_modules ## Release build of build/Pane.app (host architecture)
	Scripts/build-app.sh --release

editor: $(EDITOR_DIR)/node_modules ## Rebuild only the web editor bundle
	cd $(EDITOR_DIR) && node build.mjs

clean: ## Remove build outputs
	rm -rf build .build $(EDITOR_DIR)/dist
