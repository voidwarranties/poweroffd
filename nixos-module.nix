{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf mkMerge;

  poweroffdScript = writeShellScriptBin "poweroffd.sh" "${builtins.readFile ./src/poweroffd.sh}";

  cfg = config.services.backtab;
in {
  options = {
    services.backtab = {
      enable = lib.mkEnableOption "poweroffd";

      mqttHost = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Hostname address of the MQTT server to connect to.";
      };

      mqttPort = mkOption {
        type = types.int;
        default = 1883;
        description = "Port of the MQTT server to connect to.";
      };

      mqttUsername = mkOption {
        type = types.str;
        description = "Username for the MQTT server connection.";
      };

      mqttPassword = mkOption {
        type = types.str;
        description = "Password for the MQTT server connection.";
      };

      mqttTopic = mkOption {
        type = types.str;
        description = "Topic for the MQTT connection.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      users.groups.poweroffd = {};
      users.users.poweroffd = {
        isNormalUser = true;
        group = "poweroffd";
      };

      systemd.services.backtab = {
        description = "Poweroffd Space Control";
        wantedBy = ["multi-user.target"];
        after = [
          "network-online.target"
        ];
        wants = ["network-online.target"];
        serviceConfig = {
          User = "poweroffd";
          Group = "poweroffd";
          ExecStart = "${poweroffdScript}";
        };
        # path = with pkgs; [zenity mosquitto];
      };
    }
  ]);
}
