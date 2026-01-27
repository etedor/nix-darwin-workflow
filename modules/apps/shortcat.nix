{
  config,
  lib,
  ...
}:

let
  cfg = config.et42.workflow.apps.shortcat;
in
{
  options.et42.workflow.apps.shortcat = {
    enable = lib.mkEnableOption "Shortcat keyboard-driven UI navigation";
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "shortcat" ];
  };
}
