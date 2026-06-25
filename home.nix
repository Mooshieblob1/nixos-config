# home-manager configuration for user blob. Built as part of the system via
# the home-manager NixOS module wired up in flake.nix, so it applies on
# `sudo nixos-rebuild switch` — there is no separate `home-manager switch`.
#
# This is intentionally a minimal scaffold. The Hyprland rice (fish, hypr,
# waybar, wallust, etc.) still lives as plain files under ~/.config and is not
# managed here yet; migrate those into home-manager incrementally.

{ ... }:

{
  home.username = "blob";
  home.homeDirectory = "/home/blob";

  # Pin HM's stateful defaults to the system release. Match system.stateVersion
  # and leave it alone after the first switch.
  home.stateVersion = "26.05";

  # Let home-manager manage itself.
  programs.home-manager.enable = true;

  # direnv + nix-direnv: auto-load per-project flake dev shells on cd. Lets the
  # MooshieUI Tauri toolchain (webkitgtk, rust, pnpm, openssl) load without a
  # manual `nix develop`, so VSCode's terminal and rust-analyzer pick it up.
  # Fish shell hook is added separately in ~/.config/fish/conf.d/direnv.fish
  # because fish isn't managed by home-manager here.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Git, managed declaratively. The GitHub credential helper delegates to gh
  # (token in its keyring). Referencing gh by name rather than a /nix/store
  # path means it survives garbage collection and gh upgrades — a hardcoded
  # store path in the old imperative ~/.gitconfig broke after a `nix-collect-
  # garbage -d`. HM writes ~/.config/git/config, so the legacy ~/.gitconfig
  # must be removed or it shadows this.
  programs.git = {
    enable = true;
    userName = "Mooshieblob1";
    userEmail = "kentvuong88@gmail.com";
    extraConfig = {
      credential."https://github.com".helper = "!gh auth git-credential";
      credential."https://gist.github.com".helper = "!gh auth git-credential";
    };
  };
}
