{
  config,
  lib,
  ...
}:

let
  cfg = config.et42.workflow.hammerspoon;
  user = config.et42.workflow.user;

  # path to embedded spoon files
  spoonPath = ./spoon;

  # generate init.lua that loads the spoon with config
  initLua = ''
    -- load WindowManager spoon from nix store
    package.path = package.path .. ";${spoonPath}/?.lua"

    local WindowManager = dofile("${spoonPath}/init.lua")

    -- apply config
    WindowManager.padding = ${toString cfg.padding}
    WindowManager.ultrawideThreshold = ${toString cfg.ultrawideThreshold}
    WindowManager.ultrawideLeftWidth = ${toString cfg.ultrawideLeftWidth}
    WindowManager.ultrawideCenterWidth = ${toString cfg.ultrawideCenterWidth}
    WindowManager.ultrawideRightWidth = ${toString cfg.ultrawideRightWidth}
    WindowManager.standardLeftWidth = ${toString cfg.standardLeftWidth}
    WindowManager.standardRightWidth = ${toString cfg.standardRightWidth}
    WindowManager.ultrawideSwapMode = "${cfg.ultrawideSwapMode}"
    WindowManager.terminalApp = "${cfg.terminalApp}"
    WindowManager.enableInputToggle = ${if cfg.enableInputToggle then "true" else "false"}

    -- override resourcePath to use nix store
    hs.spoons.resourcePath = function(file)
      return "${spoonPath}/" .. file
    end

    WindowManager:init():start()
  '';
in
{
  options.et42.workflow.hammerspoon = {
    enable = lib.mkEnableOption "Hammerspoon window manager";

    padding = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "gap between tiles and screen edges (px)";
    };

    ultrawideThreshold = lib.mkOption {
      type = lib.types.float;
      default = 2.0;
      description = "aspect ratio threshold for ultrawide detection (21:9 ≈ 2.33, 16:9 ≈ 1.78)";
    };

    ultrawideLeftWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.30;
      description = "ultrawide left column width (0.0-1.0)";
    };

    ultrawideCenterWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.40;
      description = "ultrawide center column width (0.0-1.0)";
    };

    ultrawideRightWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.30;
      description = "ultrawide right column width (0.0-1.0)";
    };

    standardLeftWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.50;
      description = "standard left column width (0.0-1.0)";
    };

    standardRightWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.50;
      description = "standard right column width (0.0-1.0)";
    };

    ultrawideSwapMode = lib.mkOption {
      type = lib.types.enum [ "left-center" "center-right" ];
      default = "left-center";
      description = "which columns to swap with ctrl+alt+down";
    };

    terminalApp = lib.mkOption {
      type = lib.types.str;
      default = "Ghostty";
      description = "terminal app for cmd+` toggle";
    };

    enableInputToggle = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "ctrl+alt+cmd+i toggle monitor input (requires m1ddc)";
    };
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "hammerspoon" ];

    home-manager.users.${user}.home.file.".hammerspoon/init.lua".text = initLua;
  };
}
