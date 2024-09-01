{ lib
, stdenv
, fetchurl
, makeWrapper
}:

stdenv.mkDerivation rec {
  pname = "cursor";
  version = "0.4";

  src = fetchurl {
    url = "https://downloader.cursor.sh/linux/appImage/x64";
    sha256 = "0000000000000000000000000000000000000000000000000000";
    # After downloading the file, replace the zeros with the actual hash by running:
    # nix-hash --type sha256 --flat /path/to/downloaded/cursor-appimage
  };

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/512x512/apps $out/libexec
    cp $src $out/libexec/cursor-appimage
    chmod +x $out/libexec/cursor-appimage

    makeWrapper $out/libexec/cursor-appimage $out/bin/cursor

    # Extract icon and desktop file from AppImage
    $out/libexec/cursor-appimage --appimage-extract usr/share/icons/hicolor/0x0/apps/cursor.png
    $out/libexec/cursor-appimage --appimage-extract usr/share/applications/cursor.desktop

    cp squashfs-root/usr/share/icons/hicolor/0x0/apps/cursor.png $out/share/icons/hicolor/512x512/apps/
    cp squashfs-root/usr/share/applications/cursor.desktop $out/share/applications/

    substituteInPlace $out/share/applications/cursor.desktop \
      --replace 'Exec=AppRun' 'Exec=cursor'
  '';

  meta = with lib; {
    description = "The AI Code Editor";
    homepage = "https://cursor.sh/";
    license = licenses.unfree; # Adjust if necessary
    maintainers = with maintainers; [ ]; # Add your name if you're maintaining this package
    platforms = [ "x86_64-linux" ];
  };
}
