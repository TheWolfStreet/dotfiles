# {
#   pkgs,
#   config,
#   lib,
#   ...
# }: let
#   inherit (lib) types;
#   inherit (lib.modules) mkIf mkMerge;
#   cfg = config.modules.desktop.browsers.chromium;
# in {
#   options.modules.desktop.browsers.chromium = with types; {
#     enable = mkBoolOpt true;
#   };
#
#   config = mkIf cfg.enable (mkMerge [
#     {
#       programs.chromium = {
#         package = pkgs.ungoogled-chromium;
#         extensions = let
#           createChromiumExtensionFor = browserVersion: {
#             id,
#             sha256,
#             version,
#           }: {
#             inherit id;
#             crxPath = builtins.fetchurl {
#               url = "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=${browserVersion}&x=id%3D${id}%26installsource%3Dondemand%26uc";
#               name = "${id}.crx";
#               inherit sha256;
#             };
#             inherit version;
#           };
#           createChromiumExtension = createChromiumExtensionFor (lib.versions.major package.version);
#         in [
#           (createChromiumExtension {
#             })
#         ];
#       };
#     }
#   ]);
# }
