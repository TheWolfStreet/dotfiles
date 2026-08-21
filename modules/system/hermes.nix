{
  config,
  inputs,
  lib,
  pkgs,
  username,
  ...
}: let
  implPath = /home/${username}/.hermes/nixos/hermes.nix;
  implExists = builtins.pathExists implPath;
  hermesPkg = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  imports = lib.optional implExists implPath;

  options.hermes.enable = lib.mkEnableOption "Hermes Agent";

  config = lib.mkIf config.hermes.enable {
    warnings = lib.optional (!implExists) ''
      Hermes: no NixOS implementation was detected at ${toString implPath}; using generic Hermes only.
    '';

    home-manager.users.${username}.home.packages =
      lib.optional (!implExists) hermesPkg;
  };
}
