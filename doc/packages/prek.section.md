# prek {#prek}

[prek](https://github.com/j178/prek) is a fast, drop-in replacement for [pre-commit](https://pre-commit.com), re-engineered in Rust, used to run git pre-commit hooks.

The [`prek` package](https://search.nixos.org/packages?channel=unstable&show=prek) provides functions for configuring prek using the module system, which are [documented below](#sec-functions-library-prek), along with [their options](#sec-prek-options-reference).

Alternatively, prek can be configured with a plain `.pre-commit-config.yaml` at the repository root.

In the Nixpkgs development shell, prek comes pre-configured; run `prek init -t pre-commit` to install the git hooks.

## Options Reference {#sec-prek-options-reference}

The following attributes can be passed to [`withConfig`](#pkgs.prek.withConfig) or [`evalConfig`](#pkgs.prek.evalConfig):

```{=include=} options
id-prefix: opt-prek-
list-id: configuration-variable-list
source: ../prek-options.json
```
