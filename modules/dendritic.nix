{ inputs, ... }:
{

  imports = [
    (inputs.flake-file.flakeModules.dendritic or { })
  ];

  flake-file.inputs.systems.url = "github:nix-systems/default";
  systems = import inputs.systems;

  flake-file.inputs.nixpkgs.url = "https://channels.nixos.org/nixos-25.11/nixexprs.tar.xz";

}
