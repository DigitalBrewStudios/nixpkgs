{
  lib,
  gitMinimal,
  runCommandLocal,
  gitSetupHook,
  stdenvNoCC,
  wrapper,
}:
/**
  Test that the given project tree is formatted with the prek config.

  Input argument is the path to the project tree.
*/
project:
runCommandLocal "${lib.getName wrapper}-check"
  {
    __structuredAttrs = true;
    strictDeps = true;
    nativeBuildInputs = [
      gitMinimal
      gitSetupHook
      wrapper
    ];
    inherit project;
    env = {
      LANG = if stdenvNoCC.buildPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8";
      LC_ALL = if stdenvNoCC.buildPlatform.isDarwin then "en_US.UTF-8" else "C.UTF-8";
    };
    meta.description = "Check that the project tree is formatted";
  }
  ''
    # Copy project files into the build-dir
    cp -r "$project" project
    chmod -R a+w project
    cd project

    # Setup a git repo
    git init --initial-branch main
    git add .
    git commit -m init --quiet

    # Keep prek's cache (hook environments, logs) inside the build dir
    export PREK_HOME="$PWD/.prek-home"

    # Run prek
    prek --version
    prek run --all-files

    # Ensure nothing changed
    git status
    git --no-pager diff --exit-code
    touch "$out"
  ''
