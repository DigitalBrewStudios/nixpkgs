# To build this derivation, run `nix-build -A prek.optionsDoc`
{
  lib,
  prek,
  nixosOptionsDoc,
}:

let
  configuration = prek.evalConfig [ ];

  root = toString configuration._module.specialArgs.modulesPath;
  revision = lib.trivial.revisionWithDefault "master";
  removeRoot = file: lib.removePrefix "/" (lib.removePrefix root file);

  transformDeclaration =
    file:
    let
      fileStr = toString file;
      subpath = "pkgs/by-name/pr/prek/modules/" + removeRoot fileStr;
    in
    assert lib.hasPrefix root fileStr;
    {
      url = "https://github.com/NixOS/nixpkgs/blob/${revision}/${subpath}";
      name = subpath;
    };
in
nixosOptionsDoc {
  documentType = "none";
  options = removeAttrs configuration.options [ "_module" ];
  transformOptions = opt: opt // { declarations = map transformDeclaration opt.declarations; };
}
