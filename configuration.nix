# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader. lanzaboote replaces the stock systemd-boot module to provide
  # Secure Boot, so systemd-boot must be force-disabled here; lanzaboote still
  # uses the systemd-boot stub under the hood and keeps generation entries.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;

  # Secure Boot via lanzaboote. Signing keys live outside the Nix store in
  # /var/lib/sbctl (created once with `sudo sbctl create-keys`). After the
  # first switch, enroll them while firmware is in Setup Mode with
  # `sudo sbctl enroll-keys --microsoft` (--microsoft is required here because
  # Windows boots from this same ESP and the NVIDIA option ROM is MS-signed).
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  # Swap on the existing nvme0n1p6 partition (32 GiB, label "swap"), on the
  # same disk as / and /boot. Referenced by UUID so it survives device renaming.
  swapDevices = [
    { device = "/dev/disk/by-uuid/54fd7efa-9abb-4110-9a3b-6dac97d46c04"; }
  ];

  # NTFS read/write driver for the Windows data drives mounted below.
  boot.supportedFilesystems = [ "ntfs" ];

  # Extra data drives, mounted on first access via systemd automount. "nofail"
  # plus the automount unit mean a missing or dirty disk never blocks boot.
  # NTFS volumes are mapped to user blob (uid 1000 / gid 100 = users).
  fileSystems."/mnt/blorb" = {
    device = "/dev/disk/by-uuid/01DD0288FF0EC9F0"; # NTFS "Blorb Drive"
    fsType = "ntfs-3g";
    options = [ "nofail" "x-systemd.automount" "uid=1000" "gid=100" "windows_names" ];
  };
  fileSystems."/mnt/faer" = {
    device = "/dev/disk/by-uuid/F05E0CA05E0C6228"; # NTFS "Faer Drive"
    fsType = "ntfs-3g";
    options = [ "nofail" "x-systemd.automount" "uid=1000" "gid=100" "windows_names" ];
  };
  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/a866d335-a92b-4d26-bf7b-940feee5b6f7"; # ext4 "Games"
    fsType = "ext4";
    options = [ "nofail" "x-systemd.automount" ];
  };
  fileSystems."/mnt/linux" = {
    device = "/dev/disk/by-uuid/253010ac-2cb2-468f-9f6f-4519ba59f063"; # ext4 other-OS root (sda3)
    fsType = "ext4";
    options = [ "nofail" "x-systemd.automount" ];
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Perth";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # NVIDIA proprietary driver (RTX 5070 / Blackwell).
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    # Blackwell (RTX 50-series) is ONLY supported by the open kernel modules.
    open = true;
    nvidiaSettings = true;
    # Preserve VRAM across S3 suspend (nvidia-suspend/resume services).
    # Without this, Blackwell loses GPU memory on resume -> Xid 13 -> Hyprland crash.
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "au";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Disable mouse acceleration (flat profile = 1:1 movement).
  services.libinput = {
    enable = true;
    mouse.accelProfile = "flat";
  };

  # ratbagd: libratbag daemon that exposes `ratbagctl`, used by the waybar
  # mouse module to cycle the Logitech G903's DPI presets. Battery level is
  # read directly from the hid-logitech sysfs power_supply class (no service).
  services.ratbagd.enable = true;

  # Enable fish as a login shell.
  programs.fish.enable = true;

  # nix-ld: provide a real glibc loader so generic dynamically-linked
  # binaries run (e.g. the Claude Code VS Code extension's bundled native
  # binary). Without this, /lib64/ld-linux-x86-64.so.2 is stub-ld and such
  # binaries fail with "cannot run dynamically linked executable".
  programs.nix-ld.enable = true;

  # Steam (enables steam, steam-run, and required udev/firewall bits).
  programs.steam.enable = true;

  # Hyprland (Wayland tiling compositor) — appears as a session at GDM
  # alongside GNOME so we can fall back if anything goes wrong.
  programs.hyprland.enable = true;

  # Terminate the login session's processes on logout/shutdown. Without this,
  # GUI apps in the bare session scope (e.g. Firefox) aren't killed until the
  # final systemd-shutdown sweep — after the FS is unmounted — so their
  # end-of-session writes (prefs, extension grants) are lost on reboot.
  services.logind.settings.Login.KillUserProcesses = true;

  # Thunar file manager (GTK3, themes cleanly from the wallust palette).
  # The module wires up the xfconf dbus service; gvfs gives trash/mount
  # support and tumbler generates thumbnails.
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."blob" = {
    isNormalUser = true;
    description = "blob";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Make firefox the default browser.
  xdg.mime.defaultApplications = {
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";
  };

  # Passwordless sudo for the wheel group (blob is a member).
  security.sudo.wheelNeedsPassword = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    claude-code
    vesktop

    # Secure Boot key management (create/enroll/verify keys for lanzaboote).
    sbctl

    # Microsoft's proprietary Visual Studio Code build (unfree). The package
    # provides the `code` binary; bound to Super+C in hyprland.conf.
    vscode

    # Cursor theme (white rounded modern) — set as XCURSOR_THEME in hyprland.conf.
    bibata-cursors

    # Hyprland baseline toolkit — terminal, bar, launcher, notifications,
    # wallpaper, lockscreen, idle, plus screenshot + clipboard utilities.
    ghostty
    waybar
    wofi
    mako
    awww
    hyprlock
    hypridle
    grim
    slurp
    hyprshot
    wl-clipboard
    wl-clip-persist
    cliphist
    brightnessctl
    playerctl
    polkit_gnome
    btop

    # Rice stack (szymonwilczek/dotfiles).
    wallust
    starship
    fastfetch
    lazygit
    tmux
    zathura
    neovim
    stow
    git

    # Fonts.
    nerd-fonts.jetbrains-mono
    nerd-fonts.hack
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];
  

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

  # Logitech G903 emits high-resolution scroll (REL_WHEEL_HI_RES), causing
  # sub-notch "halfway click" scrolling. Disable the hi-res codes so libinput
  # falls back to one discrete event per physical notch.
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Logitech G903 No Hi-Res Scroll]
    MatchName=Logitech G903*
    MatchUdevType=mouse
    AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;
  '';

}
