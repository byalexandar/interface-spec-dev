{ system ? builtins.currentSystem }:
let
  sourcesnix = builtins.fetchurl https://raw.githubusercontent.com/nmattia/niv/506b896788d9705899592a303de95d8819504c55/nix/sources.nix;
  nixpkgs_src = (import sourcesnix { sourcesFile = ./sources.json; inherit pkgs; }).nixpkgs;

  pkgs =
    import nixpkgs_src {
      inherit system;
      overlays = [
        (self: super: {
          sources = import sourcesnix { sourcesFile = ./sources.json; pkgs = super; };
        })
        # nixpkgs's rustc does not inclue the wasm32-unknown-unknown target, so
        # lets add it here. With this we can build the universal canister with stock
        # nixpkgs + naersk, in particular no dependency on internal repositories.
        (self: super: {
          rustc = super.rustc.overrideAttrs (old: {
	    configureFlags = self.lib.lists.forEach old.configureFlags (flag:
              if self.lib.strings.hasPrefix "--target=" flag
              then flag + ",wasm32-unknown-unknown"
              else flag
            );
          });
        })
      ];
    };
in
pkgs
