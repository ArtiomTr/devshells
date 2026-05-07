{ pkgs }:
{ toolchainVersion, extraPackages ? [ ] }:
let
  baseRustToolchain =
    if toolchainVersion == "stable" then
      pkgs.rust-bin.stable.latest.default
    else if toolchainVersion == "beta" then
      pkgs.rust-bin.beta.latest.default
    else if toolchainVersion == "nightly" then
      pkgs.rust-bin.nightly.latest.default
    else
      pkgs.rust-bin.stable.${toolchainVersion}.default;

  rustToolchain = baseRustToolchain.override {
    extensions = [ "rust-src" ];
  };
in
pkgs.mkShell {
  packages = [
    rustToolchain
    pkgs.pkg-config
  ] ++ map (name: pkgs.${name}) extraPackages;

  RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
}
