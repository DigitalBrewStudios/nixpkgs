{
  lib,
  stdenvNoCC,
  pkgsCross,
  bash,
}:

stdenvNoCC.mkDerivation (
  finalAttrs:
  let
    dxvk32 =
      if stdenvNoCC.hostPlatform.isDarwin then
        pkgsCross.mingw32.dxvk_1.override { enableMoltenVKCompat = true; }
      else
        pkgsCross.mingw32.dxvk_3;

    dxvk64 =
      if stdenvNoCC.hostPlatform.isDarwin then
        pkgsCross.mingwW64.dxvk_1.override {
          enableMoltenVKCompat = true;
        }
      else
        pkgsCross.mingwW64.dxvk_3;
  in
  {
    pname = "dxvk";
    inherit (dxvk64) version;

    outputs = [
      "out"
      "bin"
      "lib"
    ];

    strictDeps = true;

    buildCommand = ''
      mkdir -p $out/bin $bin $lib
      substitute ${./setup_dxvk.sh} $out/bin/setup_dxvk.sh \
        --subst-var-by bash ${bash}" \
        --subst-var-by dxvk32 ${dxvk32} \
        --subst-var-by dxvk64 ${dxvk64} \
        --subst-var-by version ${finalAttrs.version}
      chmod a+x $out/bin/setup_dxvk.sh
      declare -A dxvks=( [x32]=${dxvk32} [x64]=${dxvk64} )
      for arch in "''${!dxvks[@]}"; do
        ln -s "''${dxvks[$arch]}/bin" $bin/$arch
        ln -s "''${dxvks[$arch]}/lib" $lib/$arch
      done
    '';

    passthru = {
      inherit dxvk32 dxvk64;
    };

    __structuredAttrs = true;

    meta = {
      description = "Setup script for DXVK";
      mainProgram = "setup_dxvk.sh";
      homepage = "https://github.com/doitsujin/dxvk";
      changelog = "https://github.com/doitsujin/dxvk/releases";
      maintainers = [ lib.maintainers.reckenrode ];
      license = lib.licenses.zlib;
      platforms = [
        "i686-linux"
        "x86_64-linux"
      ];
    };
  }
)
