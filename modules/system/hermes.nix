{implementation ? null}: {
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}: let
  hermesPkg = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  imports = lib.optional (implementation != null) implementation;

  options.hermes.enable = lib.mkEnableOption "Hermes Agent";

  config = lib.mkIf (config.hermes.enable && implementation == null) {
    warnings = [
      ''
        Hermes: using the generic package without a local NixOS implementation.
      ''
    ];

    home-manager.users.${username}.home.packages = [hermesPkg];
  };
}
