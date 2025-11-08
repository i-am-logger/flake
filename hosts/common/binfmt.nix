{ pkgs
, ...
}:
{
  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];

    # registrations.aarch64-linux = {
    #   interpreter = "${pkgs.qemu}/bin/qemu-aarch64";
    #   magicOrExtension = ''\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00'';
    #   mask = ''\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff'';
    #   interpreterArgs = [
    #     "-cpu"
    #     "max"
    #     "-L"
    #     "${pkgs.qemu.outPath}/share/qemu"
    #     "-E"
    #     "QEMU_CPU=max"
    #     "-U"
    #     "-n"
    #     "0" # Auto-detect CPU cores
    #   ];
    # };
  };
}
