{
  lib,
  ...
}:

{
  imports = [
    ./apps
    ./system
  ];

  options.et42.workflow = {
    user = lib.mkOption {
      type = lib.types.str;
      description = "primary user for home-manager configuration";
    };
  };
}
