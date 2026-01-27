{
  config,
  lib,
  ...
}:

let
  cfg = config.et42.workflow.apps.borders;
  user = config.et42.workflow.user;

  # allow vscode color previews
  stripHash = s: lib.removePrefix "#" s;
in
{
  options.et42.workflow.apps.borders = {
    enable = lib.mkEnableOption "jankyborders window highlighting";

    activeColor = lib.mkOption {
      type = lib.types.str;
      default = "#00a5ff"; # macOS blue
      description = "border color for focused window";
    };

    activeAlpha = lib.mkOption {
      type = lib.types.str;
      default = "ff"; # fully opaque
      description = "alpha value for focused window border (hex 00-ff)";
    };

    inactiveColor = lib.mkOption {
      type = lib.types.str;
      default = "#48484c"; # macOS gray
      description = "border color for unfocused windows";
    };

    inactiveAlpha = lib.mkOption {
      type = lib.types.str;
      default = "b3"; # 70% opacity
      description = "alpha value for unfocused window borders (hex 00-ff)";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user}.services.jankyborders = {
      enable = true;
      settings = {
        active_color = "0x${cfg.activeAlpha}${stripHash cfg.activeColor}";
        inactive_color = "0x${cfg.inactiveAlpha}${stripHash cfg.inactiveColor}";
        width = 4.0;
        style = "round";
        hidpi = true;
      };
    };
  };
}
