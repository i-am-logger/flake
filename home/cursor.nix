{ lib
, stdenv
, fetchurl
, makeWrapper
, appimage-run
}:

stdenv.mkDerivation rec {
  pname = "cursor";
  version = "0.40.3"; # Updated to match the actual version

  src = fetchurl {
    url = "https://download.cursor.sh/linux/appImage/x64"; # Updated URL
    sha256 = "qF9vqfvGRGDJ4dZxYzvRFdIKxt6ieiQXupPiOzkF4us=";
  };

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/512x512/apps
    cp $src $out/share/cursor.AppImage
    chmod +x $out/share/cursor.AppImage
    makeWrapper ${appimage-run}/bin/appimage-run $out/bin/cursor \
      --add-flags "$out/share/cursor.AppImage"
    
    # Create a basic .desktop file
    cat > $out/share/applications/cursor.desktop << EOF
    [Desktop Entry]
    Name=Cursor
    Exec=cursor
    Icon=cursor
    Type=Application
    Categories=Development;IDE;
    EOF
  '';

  meta = with lib; {
    description = "The AI Code Editor";
    homepage = "https://cursor.sh/";
    license = licenses.unfree;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
}
