{
  lib,
  pkgs,
  ...
}:
{
  runtimeInputs = [
    # prek discovers the repository root with `git rev-parse`
    pkgs.gitMinimal
    # Used by the nixfmt and keep-sorted local hooks below
    pkgs.nixfmt
    pkgs.keep-sorted
  ];

  settings = {
    # Global exclude regex (see https://prek.j178.dev/reference/configuration/#top-level-exclude),
    # built from treefmt's `excludes` list in ./treefmt.nix.
    exclude = ''(^|/)([^/]*\.(lock|patch|diff)|package-lock\.json|pnpm-lock\.yaml|go\.mod|go\.sum|\.gitattributes|\.gitignore|\.gitmodules|COPYING|LICENSE)$'';

    repos = [
      # Rust-native hooks bundled with prek; see
      # https://prek.j178.dev/built-in-hooks/ and
      # https://prek.j178.dev/reference/built-in-hooks/
      {
        repo = "builtin";
        hooks = [
          { id = "trailing-whitespace"; }
          { id = "end-of-file-fixer"; }
          { id = "check-merge-conflict"; }
          { id = "detect-private-key"; }
        ];
      }
      {
        repo = "local";
        hooks = [
          # This uses nixfmt underneath, the default formatter for Nix code.
          # See https://github.com/NixOS/nixfmt
          {
            id = "nixfmt";
            name = "nixfmt";
            language = "system";
            entry = "nixfmt";
            files = "\\.nix$";
          }
          {
            id = "keep-sorted";
            name = "keep-sorted";
            language = "system";
            entry = "keep-sorted";
          }
        ];
      }
    ];
  };
}
