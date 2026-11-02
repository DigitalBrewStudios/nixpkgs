{ pkgs, ... }:
{ lib, ... }:
let
  inherit (lib) types mkOption;
in
{
  options = {
    process = lib.mkOption {
      type = types.submodule ./command-line.nix;
      example = lib.literalExpression ''
        TODO
      '';
      description = ''
        TODO
      '';
    };

    configData = mkOption {
      default = { };
      example = lib.literalExpression ''
        {
          "server.conf" = {
            text = '''
              port = 8080
              workers = 4
            ''';
          };
          "ssl/cert.pem" = {
            source = ./cert.pem;
          };
        }
      '';
      description = ''
        Configuration data files for the service

        These files are made available to the service and can be updated without restarting the service process, enabling configuration reloading.
        The service manager implementation determines how these files are exposed to the service (e.g., via a specific directory path).
        This path is available in the `path` sub-option for each `configData.<name>` entry.

        This is particularly useful for services that support configuration reloading via signals (e.g., SIGHUP) or which pick up changes automatically, so that no downtime is required in order to reload the service.
      '';

      type = types.lazyAttrsOf (types.submodule (lib.modules.importApply ./config-data.nix pkgs));
    };
  };
}
