{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.et42.workflow.vscode;
  user = config.et42.workflow.user;

  baseExtensions = import ./extensions.nix { pkgs = cfg.extensionPkgs; };

  baseSettings = {
    "[nix]".editor.defaultFormatter = "jnoortheen.nix-ide";
    "[json]".editor.defaultFormatter = "esbenp.prettier-vscode";
    "[yaml]".editor.defaultFormatter = "esbenp.prettier-vscode";
    "[markdown]".editor.defaultFormatter = "esbenp.prettier-vscode";
    "[python]".editor.defaultFormatter = "ms-python.black-formatter";
    "[shellscript]".editor.defaultFormatter = "foxundermoon.shell-format";

    nix = {
      enableLanguageServer = true;
      serverPath = "nil";
      serverSettings.nil.nix.flake.autoArchive = true;
    };

    editor = {
      fontFamily = cfg.fontFamily;
      fontSize = 12;
      fontLigatures = true;
      formatOnSave = true;
      trimAutoWhitespace = true;
      stickyScroll.enabled = true;
    };

    window.zoomLevel = 0;
    explorer.decorations.colors = true;
    explorer.excludeGitIgnore = true;

    workbench = {
      colorTheme = "Monokai Pro";
      iconTheme = "Monokai Pro Icons";
      editor.labelFormat = "short";
      tree.indent = 12;
      tree.renderIndentGuides = "always";
    };

    "chat.disableAIFeatures" = true;
  };

  baseKeybindings = [
    {
      key = "ctrl+tab";
      command = "workbench.action.nextEditorInGroup";
    }
    {
      key = "ctrl+shift+tab";
      command = "workbench.action.previousEditorInGroup";
    }
  ];
in
{
  options.et42.workflow.vscode = {
    enable = lib.mkEnableOption "VSCode with base config";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vscode;
      description = "VSCode package to use";
    };

    extensionPkgs = lib.mkOption {
      type = lib.types.unspecified;
      default = pkgs;
      description = "pkgs to use for building extensions";
    };

    extraExtensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "additional VSCode extensions to install";
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "additional VSCode settings to merge with base config";
    };

    extraKeybindings = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "additional VSCode keybindings";
    };

    fontFamily = lib.mkOption {
      type = lib.types.str;
      default = "SF Mono";
      description = "editor font family";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.nil ];
    programs.direnv.enable = true;

    home-manager.users.${user}.programs.vscode = {
      enable = true;
      package = cfg.package;

      profiles.default = {
        extensions = baseExtensions ++ cfg.extraExtensions;
        userSettings = lib.recursiveUpdate baseSettings cfg.extraSettings;
        keybindings = baseKeybindings ++ cfg.extraKeybindings;
      };
    };
  };
}
