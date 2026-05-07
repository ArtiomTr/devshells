{ pkgs }:
{ toolchainVersion, extraPackages ? [ ] }:
let
  rustToolchain =
    if toolchainVersion == "stable" then
      pkgs.rust-bin.stable.latest.default
    else if toolchainVersion == "beta" then
      pkgs.rust-bin.beta.latest.default
    else if toolchainVersion == "nightly" then
      pkgs.rust-bin.nightly.latest.default
    else
      pkgs.rust-bin.stable.${toolchainVersion}.default;
in
pkgs.mkShell {
  packages = [
    rustToolchain
    pkgs.pkg-config
  ] ++ map (name: pkgs.${name}) extraPackages;
}
