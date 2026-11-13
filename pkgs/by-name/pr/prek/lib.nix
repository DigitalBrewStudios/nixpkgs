{
  lib,
  pkgs,
  prek,
}:
rec {
  # NOTE: This does not delegate to `prek.evalConfig`: `withConfig`/`buildConfig`
  # call this sibling member instead, because they may be used against a
  # Nixpkgs snapshot (e.g. the CI-pinned one) whose `prek` does not have the
  # `evalConfig` passthru yet. The `prek` argument is only used as the default
  # package.
  /**
    Evaluate a prek configuration.

    # Type

    ```
    Module -> Configuration
    ```

    # Inputs

    `module`
    : A prek module. See [options reference](#sec-prek-options-reference).
  */
  evalConfig =
    module:
    lib.evalModules {
      class = "prekConfig";
      specialArgs.modulesPath = ./modules;
      modules = [
        {
          _file = "prek.evalConfig";
          _module.args.pkgs = lib.mkOptionDefault pkgs;
          package = lib.mkOptionDefault prek;
        }
        {
          _file = "<prek.evalConfig args>";
          imports = lib.toList module;
        }
        ./modules/default.nix
      ];
    };

  /**
    Wrap prek, configured using structured settings.

    # Check

    The resulting package has a `check` attribute of type `Path -> Derivation`.
    The derivation returned will only build if the path supplied is already formatted correctly.

    ```
    { pkgs }:
    let
      myPrek = pkgs.prek.withConfig ./prek-config.nix;
      project = ../.;
    in
    myPrek.check project
    ```

    # Type

    ```
    Module -> Derivation
    ```

    # Inputs

    `module`
    : A prek module. See [options reference](#sec-prek-options-reference).
  */
  withConfig =
    module:
    let
      configuration = evalConfig {
        _file = "<prek.withConfig args>";
        imports = lib.toList module;
      };
    in
    configuration.config.result;

  /**
    Build a prek config file from structured settings.

    # Type

    ```
    Module -> Derivation
    ```

    # Inputs

    `settings`
    : A settings module, used to build a prek config file.
      See [`settings` option reference](#opt-prek-settings).
  */
  buildConfig =
    module:
    let
      configuration = evalConfig {
        _file = "<prek.buildConfig args>";
        settings.imports = lib.toList module;
      };
    in
    configuration.config.configFile.overrideAttrs {
      passthru = {
        inherit (configuration.config) settings;
        options = (opt: opt.type.getSubOptions opt.loc) configuration.options.settings;
      };
    };
}
