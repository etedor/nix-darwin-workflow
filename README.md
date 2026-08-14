# nix-darwin-workflow

macOS workflow configuration for nix-darwin.

## Usage

Add to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin-workflow.url = "github:etedor/nix-darwin-workflow";
  };

  outputs = { self, nixpkgs, darwin, home-manager, darwin-workflow, ... }:
  let
    username = "username";
  in
  {
    darwinConfigurations.hostname = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        home-manager.darwinModules.home-manager
        darwin-workflow.darwinModules.default
        {
          users.users.${username}.home = "/Users/${username}";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.${username} = { };

          et42.workflow = {
            user = username;

            system = {
              dock.enable = true;
              input.enable = true;
              spaces.enable = true;
            };

            apps = {
              borders.enable = true;
              hammerspoon.enable = true;
              ice.enable = true;
              shortcat.enable = true;
              vscode.enable = true;
            };
          };
        }
      ];
    };
  };
}
```

## Customization

Override defaults with module options:

```nix
et42.workflow = {
  apps.borders.activeColor = "#01ff90";
  apps.hammerspoon = {
    padding = 10;
    ultrawideLeftWidth = 0.20;
    enableMonitorControl = true;
  };
  apps.vscode = {
    extraExtensions = [ pkgs.vscode-extensions.golang.go ];
    extraSettings = { "go.useLanguageServer" = true; };
  };
};
```
