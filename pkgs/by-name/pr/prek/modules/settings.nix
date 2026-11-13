{
  lib,
  pkgs,
  config,
  modulesPath,
  ...
}:
let
  settingsFormat = pkgs.formats.yaml { };
in
{
  options.settings = lib.mkOption {
    type = lib.types.submoduleWith {
      specialArgs = { inherit modulesPath; };
      modules = [
        { freeformType = settingsFormat.type; }
      ];
    };
    default = { };
    description = ''
      Settings used to build a prek config file.
    '';
  };

  config.configFile = lib.mkOptionDefault (
    settingsFormat.generate "pre-commit-config.yaml" config.settings
  );
}
