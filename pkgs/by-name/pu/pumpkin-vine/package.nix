{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
  minecraftServers,
  formats,
}:
let
  pumpkinSrc = fetchFromGitHub {
    owner = "Pumpkin-MC";
    repo = "Pumpkin";
    rev = "e077274271538b2b7601e0665ab4173d158eb71b";
    hash = "sha256-l8QFgtwpMnffu9wfMQIV1iwlZgKXGZzGuN3vTuPMEM4=";
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "pumpkin-vine";
  version = "0.1.0-unstable-2026-09-18";
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "yunuservices";
    repo = "Vine";
    rev = "8beb5fae88bf60bf82642888136ddfee6201ca28";
    hash = "sha256-Xa6uQ7ZbvCT4tQgt3849Av/x+6bMMCpGx7yq+RNSty8=";
  };

  postPatch = ''
    cp -r ${pumpkinSrc}/assets "$cargoDepsCopy/assets"
    #chmod -R u+w "$cargoDepsCopy/assets"
  '';

  cargoHash = "sha256-4UhGA+jx/v65hEpHSQHke0EuewpIntNqbSHjkroed6w";

  env = {
    # Requires Server Jar to Vendor
    PUMPKIN_MINECRAFT_SERVER_JAR = minecraftServers.vanilla-26-3.src;

    # reduce peak RAM usage during the build
    CARGO_PROFILE_RELEASE_LTO = "thin";
    # split codegen into more units (should reduce memory peak)
    CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "16";
  };

  passthru = {
    updateScript = nix-update-script { extraArgs = [ "--version=branch" ]; };
    services.default = {
      imports = [
        (lib.modules.importApply ./service.nix {
          inherit formats;
        })
      ];
      pumpkin-vine.package = lib.mkDefault finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "Empowering everyone to connect and scale fast, efficient Minecraft networks";
    homepage = "https://github.com/Pumpkin-MC/Vine";
    license =
      with lib.licences;
      AND [
        gpl3Only
        unfreeRedistributable # Requires minecraft jar as an asset.
      ];
    maintainers = with lib.maintainers; [ eveeifyeve ];
    mainProgram = "vine";
  };
})
