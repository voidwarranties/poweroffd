{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf mkMerge;
  inherit (pkgs) writeShellScript writeShellScriptBin;

  poweroffdScript = writeShellScript "poweroffd.sh" "${builtins.readFile ./src/poweroffd.sh}";
  SCpowerOffScript = writeShellScriptBin "SC_poweroff.sh" "${builtins.readFile ./src/SC_poweroff.sh}";
  SCpowerOffPopupScript = writeShellScriptBin "SC_poweroff_popup.sh" "${builtins.readFile ./src/SC_poweroff_popup.sh}";

  cfg = config.services.poweroffd;
in {
  options = {
    services.poweroffd = {
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
        default = "";
        description = "Username for the MQTT server connection.";
      };

      mqttPassword = mkOption {
        type = types.str;
        default = "";
        description = "Password for the MQTT server connection.";
      };

      mqttTopic = mkOption {
        type = types.str;
        default = "";
        description = "Topic for the MQTT connection.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # FIXME: Consider not running as root
      systemd.services.poweroffd = {
        description = "Poweroffd Space Control";
        wantedBy = ["multi-user.target"];
        after = [
          "network-online.target"
        ];
        wants = ["network-online.target"];
        serviceConfig = {
          ExecStart = "${poweroffdScript}";
        };
        environment = {
          MQTT_HOST = cfg.mqttHost;
          MQTT_PORT = builtins.toString cfg.mqttPort;
          MQTT_USERNAME = cfg.mqttUsername;
          MQTT_PASSWORD = cfg.mqttPassword;
          MQTT_TOPIC = cfg.mqttTopic;
        };
        path = with pkgs; [
          mosquitto
          sudo
          xorg.xhost
          xorg.xset
          # Zenity with gtk3 for extra speed?
          (zenity.overrideAttrs (oldAttrs: rec {
            version = "3.44.0";
            src = fetchurl {
              url = "mirror://gnome/sources/zenity/${lib.versions.majorMinor version}/${oldAttrs.pname}-${version}.tar.xz";
              sha256 = "wVWCMB7ZC51CzlIdvM+ZqYnyLxIEG91SecZjbamev2U=";
            };
            nativeBuildInputs = [
              meson
              ninja
              pkg-config
              gettext
              itstool
              libxml2
              wrapGAppsHook
            ];
            buildInputs = [
              gtk3
              xorg.libX11
            ];
            patches = [
              ./zenity-fix-icon-install.patch
            ];
          }))
          SCpowerOffPopupScript
          SCpowerOffScript
        ];
      };
    }
  ]);
}
