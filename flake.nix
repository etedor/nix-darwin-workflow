{
  description = "shared darwin workflow configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, ... }:
    {
      darwinModules = {
        default = import ./modules;
      };
    };
}
