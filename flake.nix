{
  description = "OVMF for LoongArch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    edk2 = {
      flake = false;
      url = "git+https://github.com/loongson/edk2.git?ref=LoongArch&submodules=1";
    };

    edk2-platforms = {
      flake = false;
      url = "git+https://github.com/loongson/edk2-platforms.git?ref=devel-LoongArch&submodules=1";
    };

    edk2-non-osi = {
      flake = false;
      url = "github:tianocore/edk2-non-osi";
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      pkgs-cross = pkgs.pkgsCross.loongarch64-linux;
    in {
      packages = {
        ovmf = pkgs-cross.callPackage ./edk2.nix {
          inherit inputs;
        };
        ovmf-debug = self.packages.${system}.ovmf.override {
          buildTarget = "DEBUG";
        };
      };
      defaultPackage = self.packages.${system}.ovmf;
    });
}
