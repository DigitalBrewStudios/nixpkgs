{
  lib,
  stdenv,
  callPackages,
  fetchFromGitHub,
  rustPlatform,
  installShellFiles,
  pkg-config,
  aws-lc,
  versionCheckHook,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "prek";
  version = "0.5.10";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "j178";
    repo = "prek";
    tag = "v${finalAttrs.version}";
    hash = "sha256-qSW7qRytEOVD7ldCVuOr6Qhiskc4HE/IyWuOmAkrgzU=";
  };

  cargoHash = "sha256-49S+KrlDQS+97kjcU+VpMP4qr+eaOap1dNwTbIa/8Qw=";

  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];

  buildInputs = [
    aws-lc
  ];

  # many tests just do not work, as they require network access
  # best to disable all, as the upstream already tests everything
  doCheck = false;

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd prek \
      --bash <($out/bin/prek util generate-shell-completion bash) \
      --fish <($out/bin/prek util generate-shell-completion fish) \
      --nushell <($out/bin/prek util generate-shell-completion nushell) \
      --zsh <($out/bin/prek util generate-shell-completion zsh)
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  passthru = {
    inherit (callPackages ./lib.nix { })
      evalConfig
      withConfig
      buildConfig
      ;

    tests = callPackages ./tests.nix { };

    # Documentation for functions defined in `./lib.nix`
    functionsDoc = callPackages ./functions-doc.nix { };

    # Documentation for options declared in `prek.evalConfig` configurations
    optionsDoc = callPackages ./options-doc.nix { };

    updateScript = nix-update-script { };
  };

  meta = {
    homepage = "https://github.com/j178/prek";
    description = "Better `pre-commit`, re-engineered in Rust ";
    mainProgram = "prek";
    changelog = "https://github.com/j178/prek/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.thunze ];
  };
})
