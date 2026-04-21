{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrf.kernelModules = [ "ext4"];
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="JP"
  '';

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_ROOT_UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE_WITH_EFI_UUID";
    fsType = "vfat";
  };


  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  hardware.wirelessRegulatoryDatabase = true;

  time.timeZone = "Asia/Tokyo";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
      qt6Packages.fcitx5-configtool
    ];
  };
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
