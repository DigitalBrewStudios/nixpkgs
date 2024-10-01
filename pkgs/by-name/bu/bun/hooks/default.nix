{
  lib,
  stdenvNoCC,
  prefetch-bun-deps,
  makeSetupHook,
  bun,
  rustPlatform,
}:
{
  prefetch-bun-deps = rustPlatform.makeRustPackage (finalAttrs: {
    pname = "nix-prefetch-bun";
    version = lib.trivial.release;

    src = lib.sourceFilesBySuffices ./. [
      ".rs"
      ".toml"
      ".lock"
    ];

    cargoLock.lockFile = ./Cargo.lock;

    meta = {
      description = "Prefetch dependencies from bun (for use with `bun.fetchDeps`)";
      mainProgram = "prefetch-bun-deps";
      maintainers = with lib.maintainers; [ eveeifyeve ];
      license = lib.licenses.mit;
      broken = true; # Experiemential and WIP, Doesn't work yet
    };
  });
  fetchDeps = lib.extendMkDerivation {
    constructDrv = stdenvNoCC.mkDerivation;
    excludeDrvArgNames = [
      "pname"
      "version"
      "workspaces"
      "useArchitechure"
      "installFlags"
    ];
    extendDrvArgs =
      finalAttrs:
      {
        workspaces ? [ ],
        useArchitecture ? false,
        ...
      }@args:
      {
        name = "${args.pname}-${args.version}-deps";

        __structuredAttrs = true;
        strictDeps = true;

        nativeBuildInputs = [
          prefetch-bun-deps
        ]
        ++ args.nativeBuildInputs or [ ];

        buildPhase = ''
          runHook preBuild

          prefetch-bun-deps $src \
          ${lib.concatStringsSep " " (lib.map (package: "--filter=${package}") workspaces)} \
          ${
            lib.concatStringsSep " " (
              if useArchitecture then
                [
                  "--os=${stdenvNoCC.hostPlatform.node.platform}"
                  "--cpu=${stdenvNoCC.hostPlatform.node.arch}"
                ]
              else
                [ ]
            )
          } \
          $out

          runHook postBuild
        '';

        dontInstall = true;
        dontConfigure = true;
        dontFixup = true;

        outputHashMode = "recursive";
      };
  };
  configHook = makeSetupHook {
    name = "bun-config-hook";
    propagatedBuildInputs = [ bun ];
  } ./bun-config-hook.sh;
}
