.PHONY: lint fmt

NIX_FILES := $(shell rg --files -g '*.nix')
FLAKE_FILES := $(shell rg --files -g 'flake.nix')

lint:
	@for flake in $(FLAKE_FILES); do \
		dir=$$(dirname "$$flake"); \
		echo "Checking $$dir"; \
		nix flake check --all-systems "./$$dir"; \
	done

fmt:
	@nix run nixpkgs#nixpkgs-fmt -- $(NIX_FILES)
