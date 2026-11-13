{ lib, config, ... }:
{
  options = {
    name = lib.mkOption {
      type = lib.types.str;
      default = lib.getName config.package + "-with-config";
      defaultText = lib.literalExpression "\"\${getName package}-with-config\"";
      description = ''
        Name to use for the wrapped prek package.
      '';
    };

    runtimeInputs = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      description = ''
        Packages to include on prek's PATH.
      '';
    };

    configFile = lib.mkOption {
      type = lib.types.path;
      # Ensure file is copied to the store
      apply = file: if lib.isDerivation file then file else "${file}";
      defaultText = lib.literalMD "generated from [](#opt-prek-settings)";
      description = ''
        The prek config file.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      defaultText = lib.literalExpression "pkgs.prek";
      description = ''
        The prek package to wrap.
      '';
      internal = true;
    };
  };
}
