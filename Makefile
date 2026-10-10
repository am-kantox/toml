.PHONY: help build escript archive install-escript clean format quality test all

help: ## Show this help message
	@echo "Toml Build Commands"
	@echo "==================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build both escript and hex archive
	mix deps.get
	mix compile
	mix escript.build
	mix archive.build
	@echo ""
	@echo "✓ Built successfully:"
	@ls -lh toml tomlex-*.ez

escript: ## Build escript only
	mix deps.get
	mix compile
	mix escript.build
	@echo "✓ Escript built: toml"

archive: ## Build hex archive only
	mix deps.get
	mix compile
	mix archive.build
	@echo "✓ Archive built"

install-escript: escript ## Build and install escript to /usr/local/bin
	@echo "Installing escript to /usr/local/bin/toml..."
	sudo cp toml /usr/local/bin/toml
	sudo chmod +x /usr/local/bin/toml
	@echo "✓ Installed. Run 'toml --version' to verify."

clean: ## Clean build artifacts
	mix clean
	rm -f toml tomlex-*.ez
	@echo "✓ Cleaned"

format: ## Format code
	mix format

quality: ## Run quality checks (format, credo, dialyzer)
	mix quality

test: ## Run tests
	mix test

all: clean build test ## Clean, build, and test everything
	@echo ""
	@echo "======================================="
	@echo "✓ All build and test steps completed!"
	@echo "======================================="
