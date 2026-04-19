{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.et42.workflow.apps.iss;
  user = config.et42.workflow.user;
  iss = pkgs.callPackage ./package.nix { };

  domain = "com.interversehq.InstantSpaceSwitcher";

  # carbon modifiers: 4096 = ctrl, 2048 = option
  hotkeys = {
    "hotkey.space1" = ''{"keyCode":18,"keyEquivalent":"1","displayKey":"1","modifiers":4096}'';
    "hotkey.space2" = ''{"keyCode":19,"keyEquivalent":"2","displayKey":"2","modifiers":4096}'';
    "hotkey.space3" = ''{"keyCode":20,"keyEquivalent":"3","displayKey":"3","modifiers":4096}'';
    "hotkey.space4" = ''{"keyCode":21,"keyEquivalent":"4","displayKey":"4","modifiers":4096}'';
    "hotkey.space5" = ''{"keyCode":23,"keyEquivalent":"5","displayKey":"5","modifiers":4096}'';
    "hotkey.space6" = ''{"keyCode":22,"keyEquivalent":"6","displayKey":"6","modifiers":4096}'';
    "hotkey.space7" = ''{"keyCode":26,"keyEquivalent":"7","displayKey":"7","modifiers":4096}'';
    "hotkey.space8" = ''{"keyCode":28,"keyEquivalent":"8","displayKey":"8","modifiers":4096}'';
    "hotkey.space9" = ''{"keyCode":25,"keyEquivalent":"9","displayKey":"9","modifiers":4096}'';
    "hotkey.space10" = ''{"keyCode":29,"keyEquivalent":"0","displayKey":"0","modifiers":4096}'';
    "hotkey.left" = ''{"keyCode":123,"keyEquivalent":"\uf702","displayKey":"\u2190","modifiers":4096}'';
    "hotkey.right" = ''{"keyCode":124,"keyEquivalent":"\uf703","displayKey":"\u2192","modifiers":4096}'';
    "hotkey.lastSpace" = ''{"keyCode":48,"keyEquivalent":"\t","displayKey":"\u21e5","modifiers":2048}'';
  };

  hotkeyCommands = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      key: json: "  _iss '${key}' '${json}'"
    ) hotkeys
  );
in
{
  options.et42.workflow.apps.iss = {
    enable = lib.mkEnableOption "InstantSpaceSwitcher instant workspace switching";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ iss ];

    # disable native Ctrl+1-9 so ISS can register them
    system.defaults.CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
      "118".enabled = lib.mkForce false;
      "119".enabled = lib.mkForce false;
      "120".enabled = lib.mkForce false;
      "121".enabled = lib.mkForce false;
      "122".enabled = lib.mkForce false;
      "123".enabled = lib.mkForce false;
      "124".enabled = lib.mkForce false;
      "125".enabled = lib.mkForce false;
      "126".enabled = lib.mkForce false;
      "127".enabled = lib.mkForce false;
    };

    system.activationScripts.postActivation.text = ''
      _iss() {
        sudo -u ${user} /usr/bin/defaults write ${domain} "$1" \
          -data "$(/usr/bin/printf '%s' "$2" | /usr/bin/xxd -p | /usr/bin/tr -d '\n')"
      }
    ${hotkeyCommands}
    '';
  };
}
