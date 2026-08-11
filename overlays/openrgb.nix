# Build OpenRGB from a local source tree (a local branch / PR) instead of the
# pinned nixpkgs release, so OpenRGB-side changes can be built and tested on this
# machine. Two workstreams live here:
#
#   * CLI latency. Every scripted `openrgb -d <dev> -m <mode> -c <hex>` costs
#     ~1.4s: a fixed, unconditional `std::this_thread::sleep_for(1s)` at the end
#     of cli_post_detection() (cli.cpp), plus ~0.44s to connect to the SDK server
#     and pull every device descriptor. The set itself is synchronous and
#     near-instant. The sleep is device-independent, which is why an SMBus DRAM
#     stick and a USB-HID keyboard both measure the same ~1.43s.
#   * Keychron K2 HE (0x3434:0x0E20) RGB driver -- native 0xA8 protocol
#     (QMKKeychronController) vs the OpenRGB-QMK Raw-HID protocol.
#
# Fed by the `openrgb-src` git+file flake input (flake = false => tracked files
# only). Iterate: commit on the branch, `nix flake lock --update-input
# openrgb-src`, then `nix build /etc/nixos#openrgb-local` for just the binary, or
# rebuild the system once the overlay is wired into systems/yoga to swap the
# openrgb that vogix's server + the CLI resolve to.
#
# Takes the source tree path and returns a standard overlay.
openrgbSrc:
_: prev: {
  openrgb = prev.openrgb.overrideAttrs (old: {
    version = "local";
    src = openrgbSrc;

    # The nixpkgs recipe carries two patches on top of the 1.0rc2 release. The
    # systemd-service PREFIX patch (upstream commit b58b3c04) is already merged
    # in the tracked source, so re-applying it fails; keep only the
    # nixpkgs-local system-plugins-env patch, which still applies cleanly.
    patches = builtins.filter
      (p: !prev.lib.hasInfix "Install-systemd-service" (toString p))
      (old.patches or [ ]);
  });
}
