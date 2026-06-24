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
}
