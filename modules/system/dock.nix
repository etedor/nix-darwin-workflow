{
  config,
  lib,
  ...
}:

let
  cfg = config.et42.workflow.system.dock;
in
{
  options.et42.workflow.system.dock = {
    enable = lib.mkEnableOption "dock configuration";

    orientation = lib.mkOption {
      type = lib.types.enum [ "bottom" "left" "right" ];
      default = "bottom";
      description = "dock position on screen";
    };

    autohide = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "automatically hide the dock";
    };

    persistentApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "apps to pin to the dock";
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults.dock = {
      inherit (cfg) orientation autohide;

      persistent-apps = cfg.persistentApps;

      tilesize = 48;
      magnification = false;
      launchanim = false;
      show-recents = false;
      mru-spaces = false;
      mineffect = "scale";
      minimize-to-application = true;
      wvous-br-corner = 1; # disable quick note
    };
  };
}
