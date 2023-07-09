# Based on https://github.com/NickCao/nixos-riscv/blob/master/edk2-vf2.nix

{ inputs
, lib
, stdenv
, buildPackages
, python3
, buildTarget ? "RELEASE"
}:
let
  version = "LoongArch";
  src = inputs.edk2;
  platforms = inputs.edk2-platforms;

  basetools = buildPackages.stdenv.mkDerivation {
    pname = "BaseTools";
    inherit version src;

    strictDeps = true;
    buildInputs = [ buildPackages.libuuid ];

    makeFlags = [ "-C" "BaseTools/Source/C" ];

    enableParallelBuilding = true;

    installPhase = ''
      runHook preBuild
      install -Dm555 BaseTools/Source/C/bin/* -t $out/bin
      runHook postBuild
    '';
  };
in
stdenv.mkDerivation {
  pname = "edk2-ovmf";
  inherit version src;

  postPatch = ''
    patchShebangs BaseTools/BinWrappers
    ln -sv ${basetools}/bin BaseTools/Source/C/bin
    substituteInPlace BaseTools/Conf/tools_def.template \
      --replace "-mno-explicit-relocs" ""
  '';

  preConfigure = ''
    export PACKAGES_PATH=.:${platforms}:${inputs.edk2-non-osi}
    source edksetup.sh BaseTools
  '';

  # depsBuildBuild = [ buildPackages.stdenv.cc ]; # for cpp
  nativeBuildInputs = [ python3 ];

  env = {
    PYTHON_COMMAND = "python3";
    GCC5_LOONGARCH64_PREFIX = stdenv.cc.targetPrefix;
  };

  hardeningDisable = [ "all" ];   # significantly enhances performance

  buildPhase = ''
    runHook preBuild
    build --arch=LOONGARCH64 --platform=Platform/Loongson/LoongArchQemuPkg/Loongson.dsc --tagname=GCC5 --buildtarget=${buildTarget}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/FV
    cp -rv Build/LoongArchQemu/${buildTarget}_GCC5/FV/*.fd $out/
    runHook postInstall
  '';

  dontFixup = true;

  meta = {
    description = "Sample LoongArch UEFI firmware for QEMU and KVM";
    homepage = "https://github.com/loongson/";
    license = lib.licenses.bsd2;
  };
}