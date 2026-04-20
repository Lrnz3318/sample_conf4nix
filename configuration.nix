{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_ROOT_UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_EFI_UUID";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/REPLACE_WITH_SWAP_UUID";
    }
  ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";

  i18n.defaultLocale = "en_US.UTF-8";
  console.useXkbConfig = true;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.openssh.enable = true;

  users.users.root.initialPassword = "Password";
  users.users.nix = {
    isNormalUser = true;
    description = "nix";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    initialPassword = "Password";
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    firefox
  ];

  system.stateVersion = "25.05";
}
