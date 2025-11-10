.PHONY: help setup build-rust run-dev run-prod clean test

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

##@ General

help: ## Display this help message
	@echo "$(BLUE)Flutter IDE - Development Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make $(GREEN)<target>$(NC)\n\n"} \
		/^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } \
		/^##@/ { printf "\n$(BLUE)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup

setup: ## Initial project setup (install dependencies)
	@echo "$(BLUE)Setting up Flutter IDE project...$(NC)"
	@echo "$(YELLOW)1. Installing Dart dependencies...$(NC)"
	cd .. && melos bootstrap
	@echo "$(YELLOW)2. Building Rust components...$(NC)"
	$(MAKE) build-rust
	@echo "$(YELLOW)3. Generating code...$(NC)"
	$(MAKE) codegen
	@echo "$(GREEN)✓ Setup complete!$(NC)"

install: ## Install Flutter dependencies only
	@echo "$(BLUE)Installing Flutter dependencies...$(NC)"
	flutter pub get
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

##@ Code Generation

codegen: ## Generate code (MobX, Injectable, Freezed)
	@echo "$(BLUE)Generating code...$(NC)"
	@echo "$(YELLOW)Running build_runner for all modules...$(NC)"
	cd modules/editor_core && dart run build_runner build --delete-conflicting-outputs
	cd modules/lsp_domain && dart run build_runner build --delete-conflicting-outputs
	cd modules/lsp_application && dart run build_runner build --delete-conflicting-outputs
	cd modules/lsp_infrastructure && dart run build_runner build --delete-conflicting-outputs
	cd modules/ide_presentation && dart run build_runner build --delete-conflicting-outputs
	@echo "$(GREEN)✓ Code generation complete$(NC)"

codegen-watch: ## Watch and auto-generate code
	@echo "$(BLUE)Watching for changes...$(NC)"
	cd modules/ide_presentation && dart run build_runner watch --delete-conflicting-outputs

##@ Rust Components

build-rust: ## Build all Rust components (editor_native, lsp_bridge)
	@echo "$(BLUE)Building Rust components...$(NC)"
	@echo "$(YELLOW)1. Building editor_native...$(NC)"
	cd modules/editor_native && cargo build --release
	@echo "$(YELLOW)2. Building lsp_bridge...$(NC)"
	cd modules/lsp_bridge && cargo build --release
	@echo "$(GREEN)✓ Rust components built$(NC)"

build-rust-dev: ## Build Rust components in dev mode
	@echo "$(BLUE)Building Rust components (debug)...$(NC)"
	cd modules/editor_native && cargo build
	cd modules/lsp_bridge && cargo build
	@echo "$(GREEN)✓ Rust components built (debug)$(NC)"

run-lsp-bridge: ## Run LSP Bridge server (required for LSP features)
	@echo "$(BLUE)Starting LSP Bridge server...$(NC)"
	@echo "$(YELLOW)Listening on ws://127.0.0.1:9999$(NC)"
	cd modules/lsp_bridge && cargo run --release

run-lsp-bridge-dev: ## Run LSP Bridge server in dev mode
	@echo "$(BLUE)Starting LSP Bridge server (debug)...$(NC)"
	RUST_LOG=debug cd modules/lsp_bridge && cargo run

##@ Development

run-dev: ## Run app in development mode
	@echo "$(BLUE)Starting Flutter IDE (development)...$(NC)"
	@echo "$(YELLOW)Note: Make sure LSP Bridge is running (make run-lsp-bridge)$(NC)"
	flutter run -d macos

run-web: ## Run app in web browser
	@echo "$(BLUE)Starting Flutter IDE (web)...$(NC)"
	flutter run -d chrome --web-renderer canvaskit

run-macos: ## Run app on macOS
	@echo "$(BLUE)Starting Flutter IDE (macOS)...$(NC)"
	flutter run -d macos

run-windows: ## Run app on Windows
	@echo "$(BLUE)Starting Flutter IDE (Windows)...$(NC)"
	flutter run -d windows

hot-reload: ## Hot reload without restarting
	@echo "$(YELLOW)Press 'r' in running Flutter terminal for hot reload$(NC)"
	@echo "$(YELLOW)Press 'R' for hot restart$(NC)"

##@ Production

run-prod: ## Run app in production mode
	@echo "$(BLUE)Starting Flutter IDE (production)...$(NC)"
	flutter run --release -d linux

build-linux: ## Build Linux release
	@echo "$(BLUE)Building for Linux...$(NC)"
	flutter build linux --release
	@echo "$(GREEN)✓ Linux build complete: build/linux/x64/release/bundle/$(NC)"

build-web: ## Build web release
	@echo "$(BLUE)Building for Web...$(NC)"
	flutter build web --release --web-renderer canvaskit
	@echo "$(GREEN)✓ Web build complete: build/web/$(NC)"

build-macos: ## Build macOS release
	@echo "$(BLUE)Building for macOS...$(NC)"
	flutter build macos --release
	@echo "$(GREEN)✓ macOS build complete: build/macos/Build/Products/Release/$(NC)"

build-windows: ## Build Windows release
	@echo "$(BLUE)Building for Windows...$(NC)"
	flutter build windows --release
	@echo "$(GREEN)✓ Windows build complete: build/windows/runner/Release/$(NC)"

build-all: ## Build for all platforms
	@echo "$(BLUE)Building for all platforms...$(NC)"
	$(MAKE) build-linux
	$(MAKE) build-web
	@echo "$(GREEN)✓ All builds complete$(NC)"

##@ Testing

test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	flutter test
	@echo "$(GREEN)✓ Tests complete$(NC)"

test-coverage: ## Run tests with coverage
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	flutter test --coverage
	@echo "$(GREEN)✓ Coverage report: coverage/lcov.info$(NC)"

##@ Code Quality

lint: ## Run linter
	@echo "$(BLUE)Running linter...$(NC)"
	flutter analyze
	@echo "$(GREEN)✓ Lint complete$(NC)"

format: ## Format code
	@echo "$(BLUE)Formatting code...$(NC)"
	dart format .
	@echo "$(GREEN)✓ Code formatted$(NC)"

format-check: ## Check code formatting
	@echo "$(BLUE)Checking code format...$(NC)"
	dart format --set-exit-if-changed .

##@ Cleanup

clean: ## Clean build artifacts
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	flutter clean
	cd modules/editor_native && cargo clean
	cd modules/lsp_bridge && cargo clean
	@echo "$(GREEN)✓ Clean complete$(NC)"

clean-generated: ## Clean generated code
	@echo "$(BLUE)Cleaning generated code...$(NC)"
	find . -name "*.g.dart" -type f -delete
	find . -name "*.freezed.dart" -type f -delete
	@echo "$(GREEN)✓ Generated code cleaned$(NC)"

reset: clean clean-generated ## Full reset (clean + remove dependencies)
	@echo "$(BLUE)Full reset...$(NC)"
	rm -rf .dart_tool
	rm -rf pubspec.lock
	@echo "$(GREEN)✓ Full reset complete$(NC)"

##@ Docker (Optional)

docker-build: ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(NC)"
	docker build -t flutter-ide .

docker-run: ## Run in Docker container
	@echo "$(BLUE)Running in Docker...$(NC)"
	docker run -p 9999:9999 flutter-ide

##@ Quick Start

quickstart: setup ## Quick start (setup + run dev)
	@echo "$(GREEN)Starting development environment...$(NC)"
	@echo "$(YELLOW)Starting LSP Bridge in background...$(NC)"
	$(MAKE) run-lsp-bridge-dev &
	@sleep 2
	@echo "$(YELLOW)Starting Flutter app...$(NC)"
	$(MAKE) run-dev

dev: ## Start full development environment
	@echo "$(BLUE)Starting development environment...$(NC)"
	@echo "$(YELLOW)Terminal 1: LSP Bridge Server$(NC)"
	@echo "Run: make run-lsp-bridge-dev"
	@echo ""
	@echo "$(YELLOW)Terminal 2: Flutter App$(NC)"
	@echo "Run: make run-dev"
	@echo ""
	@echo "$(GREEN)Or use 'make quickstart' to start both$(NC)"
