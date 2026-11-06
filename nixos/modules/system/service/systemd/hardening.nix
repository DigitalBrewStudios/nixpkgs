# Systemd-specific hardening options for modular services.
#
# This module provides the `systemd.hardening` option tree on every service
# instance. It is a curated, NixOS-style surface for common systemd sandboxing
# options, with the corresponding `serviceConfig` keys set at `lib.mkDefault`
# priority. That way, `systemd.service.serviceConfig.<Key>` remains the escape
# hatch for fine control (e.g. overriding one key, or passing values that have
# no curated option).
#
# All options default to "unset" (`false` / `[]`), in which case nothing is
# written to `serviceConfig`: hardening is opt-in.
#
# This option tree comes from the systemd service manager integration
# (`modules/system/service/systemd`), so it is absent in configurations using a
# different manager. It applies to the service's main unit, i.e. the
# `systemd.services.""` unit of the instance (the `systemd.service` alias).
#
# See:
# - https://nixos.org/manual/nixos/unstable/#modular-services
# - systemd.service(5), systemd.exec(5) and `systemd-analyze security` for how
#   to inspect the effective sandboxing of an instance.
{
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkDefault
    mkOption
    singleton
    types
    ;

  # The option is only rendered into `serviceConfig` when it has a meaningful
  # value beyond the "unset" defaults (`false` / `[]`).
  isSet = value: value != false && value != null && value != [ ];

  # Hardening option name -> systemd `serviceConfig` key.
  systemdKeys = {
    privateTmp = "PrivateTmp";
    privateDevices = "PrivateDevices";
    privateUsers = "PrivateUsers";
    privateIPC = "PrivateIPC";
    protectHome = "ProtectHome";
    protectSystem = "ProtectSystem";
    protectHostname = "ProtectHostname";
    protectClock = "ProtectClock";
    protectKernelTunables = "ProtectKernelTunables";
    protectKernelModules = "ProtectKernelModules";
    protectKernelLogs = "ProtectKernelLogs";
    noNewPrivileges = "NoNewPrivileges";
    capabilityBoundingSet = "CapabilityBoundingSet";
    ambientCapabilities = "AmbientCapabilities";
    restrictAddressFamilies = "RestrictAddressFamilies";
    restrictNamespaces = "RestrictNamespaces";
    lockPersonality = "LockPersonality";
    restrictSuidSgid = "RestrictSUIDSGID";
    memoryDenyWriteExecute = "MemoryDenyWriteExecute";
    systemCallArchitectures = "SystemCallArchitectures";
    systemCallFilter = "SystemCallFilter";
  };
in
{
  _class = "service";

  options.systemd.hardening = {
    privateTmp = mkOption {
      description = ''
        Give the unit a private `/tmp` directory.

        Services that legitimately share temporary files via `/tmp` with other
        units must keep this disabled (`false`), otherwise they are isolated
        from each other.
      '';
      type = types.bool;
      default = false;
    };
    privateDevices = mkOption {
      description = ''
        Mount a private minimal `/dev` (only pseudo devices) for the unit.

        This can break services that require access to real devices, unless
        the specific device access is granted via other means (e.g. `DeviceAllow`
        rules through {option}`system.service.serviceConfig`).
      '';
      type = types.bool;
      default = false;
    };
    privateUsers = mkOption {
      description = ''
        Run the unit with a private user ID mapping, i.e. in its own user
        namespace.
      '';
      type = types.bool;
      default = false;
    };
    privateIPC = mkOption {
      description = ''
        Isolate the unit's SysV IPC objects (POSIX shared memory segments and
        message queues) from the rest of the system.
      '';
      type = types.bool;
      default = false;
    };
    protectHome = mkOption {
      description = ''
        Protect the home directories (`/home`, `/root`, `/run/user`) of the
        unit:

        - `true` is equivalent to `"read-only"`
        - `"read-only"` mounts these paths read-only
        - `"tmpfs"` mounts these paths as inaccessible, empty tmpfs
        - `false` disables protection

        Set {option}`system.service.serviceConfig.ProtectHome` to override this
        with a value not covered here.
      '';
      type = types.enum [
        true
        "read-only"
        "tmpfs"
        false
      ];
      default = false;
    };
    protectSystem = mkOption {
      description = ''
        Protect the file system hierarchy of the unit:

        - `true` is equivalent to `"strict"`
        - `"strict"` mounts the entire hierarchy, except `/dev`, `/proc`,
          `/sys`, read-only
        - `"full"` mounts `/usr` and the boot loader directories read-only
        - `"mixed"` mounts `/usr` read-only, but keeps `/etc` writable
        - `false` disables protection

        Set {option}`system.service.serviceConfig.ProtectSystem` to override
        this with a value not covered here.
      '';
      type = types.enum [
        true
        "strict"
        "full"
        "mixed"
        false
      ];
      default = false;
    };
    protectHostname = mkOption {
      description = ''
        Prevent the service from changing the system hostname.
      '';
      type = types.bool;
      default = false;
    };
    protectClock = mkOption {
      description = ''
        Prevent the service from changing the system clock.
      '';
      type = types.bool;
      default = false;
    };
    protectKernelTunables = mkOption {
      description = ''
        Make kernel variables and interfaces (e.g. `/proc/sys`) read-only for
        the unit.
      '';
      type = types.bool;
      default = false;
    };
    protectKernelModules = mkOption {
      description = ''
        Remove the unit's privilege to load and unload kernel modules.
      '';
      type = types.bool;
      default = false;
    };
    protectKernelLogs = mkOption {
      description = ''
        Prevent the unit from accessing the kernel logs, e.g. `/dev/kmsg`.
      '';
      type = types.bool;
      default = false;
    };
    noNewPrivileges = mkOption {
      description = ''
        Prevent the process and its children from gaining extra privileges,
        e.g. via set-user-ID/set-group-ID binaries or existing file
        capabilities.
      '';
      type = types.bool;
      default = false;
    };
    capabilityBoundingSet = mkOption {
      description = ''
        The Linux capabilities the unit may retain; any other capability
        present at start-up is dropped. Restricting this to what the process
        really needs is a significant hardening win.

        E.g. a service that only needs to bind to privileged ports:
        `[ "CAP_NET_BIND_SERVICE" ]`. Use
        {option}`system.service.serviceConfig.CapabilityBoundingSet` instead if
        you need to drop *all* capabilities.
      '';
      type = types.coercedTo types.str singleton (types.listOf types.str);
      default = [ ];
    };
    ambientCapabilities = mkOption {
      description = ''
        Linux capabilities made unconditionally available to the unit's user,
        including for the standard, unprivileged special users. Complementary
        to {option}`systemd.hardening.capabilityBoundingSet`.
      '';
      type = types.coercedTo types.str singleton (types.listOf types.str);
      default = [ ];
    };
    restrictAddressFamilies = mkOption {
      description = ''
        Restrict the address families (`AF_*`) the unit may create sockets
        for, e.g. `[ "AF_UNIX" ]` for unix-socket IPC only.

        Use {option}`system.service.serviceConfig.RestrictAddressFamilies` if
        you need set values not expressed as a list of family names (in
        particular, restricting to *no* address families at all).
      '';
      type = types.coercedTo types.str singleton (types.listOf types.str);
      default = [ ];
    };
    restrictNamespaces = mkOption {
      description = ''
        Prevent the unit from creating any additional (Linux) namespaces.

        Use {option}`system.service.serviceConfig.RestrictNamespaces` if you
        need to allow particular namespaces only.
      '';
      type = types.bool;
      default = false;
    };
    lockPersonality = mkOption {
      description = ''
        Lock down the Linux execution domain to prevent execution of binaries
        for foreign or legacy architectures.
      '';
      type = types.bool;
      default = false;
    };
    restrictSuidSgid = mkOption {
      description = ''
        Prevent the unit from creating set-user-ID/set-group-ID files.
      '';
      type = types.bool;
      default = false;
    };
    memoryDenyWriteExecute = mkOption {
      description = ''
        Deny creating new memory mappings that are simultaneously writable and
        executable.

        Warning: incompatible with JIT compilers and runtimes that dynamically
        generate executable code (e.g. V8); do not enable for such services.
      '';
      type = types.bool;
      default = false;
    };
    systemCallArchitectures = mkOption {
      description = ''
        Restrict the architectures the unit can invoke system calls for, e.g.
        `[ "native" ]` to restrict to the unit's native architecture.
      '';
      type = types.coercedTo types.str singleton (types.listOf types.str);
      default = [ ];
    };
    systemCallFilter = mkOption {
      description = ''
        seccomp system call filter applied to the unit. Entries prefixed with
        `~` deny instead of allow, e.g. `[ "~@privileged" ]` to deny
        privileged system calls, or `[ "@system-service" ]` for a common
        allowlist baseline. See `systemd.exec(5)` for details and available
        filter groups.
      '';
      type = types.coercedTo types.str singleton (types.listOf types.str);
      default = [ ];
    };
  };

  config.systemd.services."" = {
    serviceConfig =
      # Each hardening option becomes a `serviceConfig` key at `mkDefault`
      # priority, unless it is unset according to `isSet`.
      lib.mkMerge (
        lib.mapAttrsToList
          (hardeningOption: value:
            lib.mkIf (isSet value) {
              ${systemdKeys.${hardeningOption}} = mkDefault value;
            })
          config.systemd.hardening
      );
  };
}
