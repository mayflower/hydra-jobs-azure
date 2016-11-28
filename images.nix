{ nixpkgs, system ? "x86_64-linux" }:
let
  buildAzureImage = (import <nixpkgs/nixos> {
    inherit system;
    configuration = import <nixpkgs/nixos/modules/virtualisation/azure-image.nix>;
  }).config.system.build.azureImage;
in
{
  azure-image = buildAzureImage;
}

