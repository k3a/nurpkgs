{ fetchurl
, lib
, stdenv
, squashfsTools
, makeWrapper
, electron
, libsecret
}:

stdenv.mkDerivation rec {
  pname = "tradingview";
  version = "2.0.1";
  revision = "30";

  src = fetchurl {
    url = "https://api.snapcraft.io/api/v1/snaps/download/nJdITJ6ZJxdvfu8Ch7n5kH5P99ClzBYV_${revision}.snap";
    hash = "sha512-YBuXEORTXEXaz76oWVF4ovogakTmNBU8pjRA0WY5q1ATF/KqyycN1Gtn0f+Gk4NBE8XaB9IAL5etKLPoLJaMsw==";
  };

  nativeBuildInputs = [ squashfsTools makeWrapper ];

  dontConfigure = true;
  dontBuild = true;

  # Prevent double wrapping
  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    unsquashfs "$src" "resources/app.asar" "resources/app.asar.unpacked" "meta/gui"
    cd squashfs-root
    runHook postUnpack
  '';

  installPhase =
    ''
      runHook preInstall

      # desktop file and icon
      mkdir -p "$out/share/${pname}"
      cp -R resources "$out/share/${pname}"
      install -Dm644 meta/gui/${pname}.desktop "$out/share/applications/${pname}.desktop"
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace 'Icon=''${SNAP}/meta/gui/icon.png' 'Icon=${pname}' \
        --replace 'Categories=Finance;' 'Categories=Office;Finance'
      install -Dm644 meta/gui/icon.png $out/share/pixmaps/${pname}.png

      makeWrapper ${electron}/bin/electron \
        $out/bin/${pname} \
        --add-flags $out/share/${pname}/resources/app.asar \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libsecret ]}

      runHook postInstall
    '';

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    homepage = "https://www.tradingview.com/";
    description = "Standalone app for the charting and trading platform";
    license = licenses.unfree;
    maintainers = with maintainers; [ k3a ];
    platforms = [ "x86_64-linux" ];
  };
}
