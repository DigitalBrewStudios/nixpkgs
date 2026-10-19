# Non-module dependencies (importApply)
{ formats }:

# Service module
{
  options,
  config,
  name,
  lib,
  ...
}:
let
  cfg = config.php-fpm;
  settingsFormat = formats.toml { };
  configFile = "vine.toml";
  configOutPath = config.configData.${configFile}.path;
in
{
  _class = "service";

  options.pumpkin-vine = {
    package = lib.mkOption {
      description = "Package to use for git-pages";
      defaultText = "The git-pages package that provided this module.";
      type = lib.types.package;
    };

    settings = lib.mkOption {
      type = settingsFormat.type;
      description = ''
        Settings to set in `vine.toml`.

        ::: {.note}
        See the [pumpkin vine implementation code](https://github.com/Pumpkin-MC/Vine/blob/master/src/config.rs) on how to configure the server.
        :::
      '';
      default = { };
    };
  };

  config = {
    process = {
      runtimeDirectory.name = name;
      argv = [
        "${cfg.package}/bin/vine"
        configOutPath
      ];
    };

    configData.${configFile}.source = settingsFormat.generate configFile cfg.settings;
    identity = {
      uid = 2613;
      gid = 2613;
    };
  }
  // lib.optionalAttrs (options ? systemd) {

    systemd.service = {
      after = [ "network.target" ];
      wants = [ "network.target" ];
      serviceConfig = {
        Restart = "always";
        DynamicUser = true;

        BindReadOnlyPaths = [ configOutPath ];

        # systemd service hardening
        ProtectHome = true;
        MemoryDenyWriteExecute = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
        RestrictNamespaces = true;
        LockPersonality = true;
        ProtectKernelLogs = true;
        ProtectKernelTunables = true;
        ProtectHostname = true;
        ProtectKernelModules = true;
        PrivateUsers = true;
        ProtectClock = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = "@system-service";
      };
    };

  };

  meta.maintainers = with lib.maintainers; [
    eveeifyeve
  ];
}
