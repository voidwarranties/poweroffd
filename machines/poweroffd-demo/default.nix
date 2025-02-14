{pkgs}: {modulesPath, ...}: let
  i3ConfigFile = pkgs.writeTextFile {
    name = "i3-config";
    text = builtins.readFile ./i3config;
  };
in {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/virtualisation/qemu-vm.nix")
  ];

  config = {
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      qemu.options = [
        "-enable-kvm"
        "-vga virtio"
      ];
      forwardPorts = [
        {
          from = "host";
          host.port = 2222;
          guest.port = 22;
        }
      ];
    };

    nix.settings.experimental-features = ["nix-command" "flakes"];
    services.openssh.enable = true;

    networking.hostName = "poweroffd-demo";

    # Localization
    time.timeZone = "Europe/Brussels";
    i18n.defaultLocale = "en_US.UTF-8";

    services.xserver = {
      enable = true;
      xkb.layout = "us";
      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu
        ];
        configFile = i3ConfigFile;
      };
    };
    services.displayManager.defaultSession = "none+i3";
    services.displayManager.autoLogin = {
      enable = true;
      user = "demo";
    };

    security.sudo.wheelNeedsPassword = false;
    users.users.demo = {
      createHome = true;
      isNormalUser = true;
      extraGroups = ["networkmanager" "wheel"];
      initialPassword = "demo";
    };

    services.poweroffd = {
      enable = true;
      mqttHost = "10.98.71.22";
      mqttTopic = "computers/poweroffd-demo";
    };

    system.stateVersion = "24.11";
  };
}
