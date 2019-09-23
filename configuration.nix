# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;
  nix = {
    gc.automatic = true;
    useSandbox = true;
  };

  # Use the systemd-boot EFI boot loader.
  boot.earlyVconsoleSetup = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "2";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];
  boot.initrd = {
    kernelModules = [ "i915" "hid_generic" "usbhid" "usb_common" ];
    luks.devices = { luksroot = { device = "/dev/nvme0n1p2"; } ; };
  };
  boot.extraModprobeConfig = ''
    options i915 enable_psr=1 enable_rc6=7 enable_fbc=1 semaphores=1 lvds_downclock=1 enable_guc=-1 fastboot=1
  '';

  networking.hostName = "caspar";
  networking.hostId = "a2efc36e";

  # Set up systemd-networkd
  networking.dhcpcd.enable = false;
  networking.useNetworkd = true;

  networking.wireless.iwd.enable = true;
  systemd.network.enable = true;
  systemd.network.networks.wlp2s0 = { 
    enable = true;
    matchConfig = { Name = "wlp2s0"; };
    DHCP = "ipv4";
  };

  services.resolved.enable = true;

  i18n = {
    consoleFont = "${pkgs.terminus_font}/share/consolefonts/ter-v24n.psf.gz";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "US/Pacific";

  fileSystems = {
    "/root" = { device = "rpool/home/root"; fsType = "zfs"; };
    "/home/mattikus" = { device = "rpool/home/mattikus"; fsType = "zfs"; };
    "/var/log" = { device = "rpool/var/log"; fsType = "zfs"; };
    "/var/cache" = { device = "rpool/var/cache"; fsType = "zfs"; };
    "/var/tmp" = { device = "rpool/var/tmp"; fsType = "zfs"; };
    "/var/spool" = { device = "rpool/var/spool"; fsType = "zfs"; };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    bash zsh hicolor_icon_theme wget vim neovim curl git lsof
    qt5.qtwayland google-chrome
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  #services.xserver.enable = true;
  #services.xserver.layout = "us";
  #services.xserver.xkbOptions = "ctrl:nocaps";
  #services.xserver.libinput.enable = true;

  #services.xserver.displayManager.job.logToFile = true;
  #services.xserver.displayManager.lightdm.enable = true;

  #services.xserver.windowManager.i3 = {
    #enable = true;
    #package = pkgs.i3-gaps;
    #extraPackages = with pkgs; [
      #dmenu
      #i3status
      #rofi
      #xsecurelock
      #dex
      #gnome3.gnome-keyring
      #gnome3.seahorse
      #google-chrome
      #kitty
      #xss-lock
    #];
  #};

  programs.zsh.enable = true;
  programs.bash.enableCompletion = true;
  programs.tmux.enable = true;
  programs.mtr.enable = true;

  hardware.opengl = {
    extraPackages = with pkgs; [ vaapiIntel libvdpau-va-gl vaapiVdpau ];
  };

  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      xwayland
      i3status
      rofi
      gnome3.gnome-keyring
      gnome3.seahorse
      google-chrome
      alacritty
      kitty
      vaapiIntel
      libvdpau-va-gl
      vaapiVdpau
    ];
    extraSessionCommands =
      ''
      [[ -f ~/.xsession-errors ]] && mv ~/.xsession-errors{,.old}
      exec &> >(tee ~/.xsession-errors)

      eval "$(gnome-keyring-daemon --start --components=ssh,secrets)"
      export SSH_AUTH_SOCK
      export XKB_DEFAULT_LAYOUT=us
      export XKB_DEFAULT_OPTIONS=ctrl:nocaps,terminate:ctrl_alt_bksp

      export CLUTTER_BACKEND=wayland
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
      '';
  };

  services.gnome3 = {
    gnome-keyring.enable = true;
    seahorse.enable = true;
    gvfs.enable = false;
  };

  security.pam.services.login.enableGnomeKeyring = true;
  services.logind.extraConfig = ''
    HandlePowerKey=hibernate
    HandleSuspendKey=suspend
    HandleHibernateKey=hibernate
    HandleLidSwitch=suspend
  '';

  services.fwupd.enable = true;

  services.nixosManual.showManual = true;

  users.users.mattikus = {
    isNormalUser = true;
    uid = 1000;
    description = "Matt Kemp";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.03"; # Did you read the comment?

}
