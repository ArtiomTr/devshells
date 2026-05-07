{
  description = "Reusable dev shells monorepo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    haumea = {
      url = "github:nix-community/haumea/v0.2.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, flake-utils, haumea, rust-overlay, ... }:
    let
      lib = nixpkgs.lib;
      mkRustShell = import ./lib/mk-rust-shell.nix;

      shellGroups = lib.filterAttrs
        (name: type:
          type == "directory"
          && !(lib.hasPrefix "." name)
          && !(lib.hasPrefix "_" name)
          && name != "lib"
        )
        (builtins.readDir ./.);

      shellTree = lib.mapAttrs
        (name: _: haumea.lib.load { src = ./. + "/${name}"; })
        shellGroups;

      collectShellSpecs = path: value:
        if builtins.isAttrs value && value ? builder then
          let
            normalizedPath = lib.filter (segment: segment != "default") path;
          in
          [
            {
              name = lib.concatStringsSep "-" normalizedPath;
              builder = value.builder;
              config = builtins.removeAttrs value [ "builder" ];
            }
          ]
        else if builtins.isAttrs value then
          lib.concatLists
            (lib.mapAttrsToList
              (name: child: collectShellSpecs (path ++ [ name ]) child)
              value)
        else
          [ ];

      shellSpecs = collectShellSpecs [ ] shellTree;

      mkShellFor = pkgs: spec:
        if spec.builder == "rust" then
          mkRustShell { inherit pkgs; } spec.config
        else
          throw "Unsupported dev shell builder: ${spec.builder}";
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ rust-overlay.overlays.default ];
          };

          shells = lib.listToAttrs (map
            (spec: {
              name = spec.name;
              value = mkShellFor pkgs spec;
            })
            shellSpecs);
        in
        {
          devShells = shells // lib.optionalAttrs (builtins.hasAttr "rust-stable" shells) {
            default = shells."rust-stable";
          };
        }) // {
      lib = {
        inherit shellSpecs shellTree;
      };
    };
}
