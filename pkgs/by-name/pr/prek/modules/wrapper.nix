{
  lib,
  pkgs,
  config,
  options,
  ...
}:
{
  options.result = lib.mkOption {
    type = lib.types.package;
    description = ''
      The wrapped prek package.
    '';
    readOnly = true;
    internal = true;
  };

  config.result = pkgs.symlinkJoin (finalAttrs: {
    pname = config.name;
    inherit (config.package) meta version;
    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
    paths = [ config.package ];
    env = {
      inherit (config) configFile;
      binPath = lib.makeBinPath config.runtimeInputs;
    };
    passthru = {
      inherit (config) runtimeInputs;
      inherit config options;
      check = pkgs.callPackage ../check-wrapper.nix {
        wrapper = finalAttrs.finalPackage;
      };
    };
    postBuild =
      let
        wrapPrefixPathArgument = lib.optionalString (
          config.runtimeInputs != [ ]
        ) "--prefix PATH : \"$binPath\"";
      in
      ''
        # `--config` is a global option of prek's CLI (`global = true` on the
        # `config` arg in `crates/prek/src/cli/mod.rs` of prek 0.5.10), so it is
        # accepted before any subcommand. Injecting it here makes the wrapped
        # prek always use this store config, for every subcommand, including
        # the Git hook shims, which `exec prek hook-impl ...` (see `HOOK_TMPL`
        # in `crates/prek/src/cli/install.rs`; the shim falls back to `prek`
        # from PATH, finding this wrapper). There is no `PREK_CONFIG`
        # environment variable (see `crates/prek-consts/src/env_vars.rs`).
        wrapProgram "$out/bin/prek" \
          --add-flags "--config $configFile " ${wrapPrefixPathArgument}
      '';
  });
}
