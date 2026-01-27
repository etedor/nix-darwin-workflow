{
  config,
  lib,
  ...
}:

let
  cfg = config.et42.workflow.input;
in
{
  options.et42.workflow.input = {
    enable = lib.mkEnableOption "input settings (disable autocorrect, etc.)";

    disableAutocorrect = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "disable spelling autocorrect";
    };

    disableNaturalScrolling = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "disable natural (inverted) scroll direction";
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults.NSGlobalDomain = lib.mkMerge [
      (lib.mkIf cfg.disableAutocorrect {
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
      })
      (lib.mkIf cfg.disableNaturalScrolling {
        "com.apple.swipescrolldirection" = false;
      })
    ];
  };
}
