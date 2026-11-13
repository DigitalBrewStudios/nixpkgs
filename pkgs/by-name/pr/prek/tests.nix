{
  lib,
  runCommand,
  runCommandLocal,
  testers,
  prek,
  nixfmt,
}:
let
  inherit (prek) buildConfig withConfig;

  prekExamplePackage = withConfig {
    settings = {
      repos = [
        {
          repo = "builtin";
          hooks = [
            { id = "trailing-whitespace"; }
            { id = "end-of-file-fixer"; }
          ];
        }
        {
          repo = "local";
          hooks = [
            {
              id = "nixfmt";
              name = "nixfmt";
              language = "system";
              entry = "nixfmt";
              files = "\\.nix$";
            }
          ];
        }
      ];
    };
    runtimeInputs = [ nixfmt ];
  };

  wellFormattedTree = runCommandLocal "well-formatted-project" { } ''
    mkdir "$out"
    cat > "$out/file.nix" <<EOF
    {
      foo = "bar";
      attrs = { };
      list = [ ];
    }
    EOF
  '';

  unformattedTree = runCommandLocal "unformatted-project" { } ''
    mkdir "$out"
    cat > "$out/file.nix" <<EOF
    {
      foo="bar";
      attrs={};
      list=[];
    }
    EOF
  '';
in
{
  nixfmtExampleCheckPasses = prekExamplePackage.check wellFormattedTree;

  nixfmtExampleCheckFails = testers.testBuildFailure' {
    # `prek run` exits nonzero because the nixfmt hook modified files, so the
    # builder fails before reaching `git diff --exit-code`.
    drv = prekExamplePackage.check unformattedTree;
    expectedBuilderExitCode = 1;
    expectedBuilderLogEntries = [
      "- hook id: nixfmt"
      "- files were modified by this hook"
    ];
  };
}
