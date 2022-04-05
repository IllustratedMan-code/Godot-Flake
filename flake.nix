{
  description = "A flake for building Godot from the master branch";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    Godot = {
      url = "github:godotengine/godot";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, Godot }: {
    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux"; };
      let
        options = {
          pulseaudio = true;
          udev = true;
        };
      in
      stdenv.mkDerivation {
        name = "godot";
        src = Godot;
        nativeBuildInputs = [
          pkgs.pkg-config
        ];

        buildInputs = [
          pkgs.pkg-config
          pkgs.udev
          pkgs.systemd
          pkgs.systemd.dev
          pkgs.gcc
          pkgs.python3
          pkgs.xorg.xorgserver
          pkgs.xorg.libX11.dev
          pkgs.xorg.libXcursor
          pkgs.xorg.libXrandr
          pkgs.xorg.libXinerama
          pkgs.xorg.libXi
          pkgs.xorg.libXext
          pkgs.xorg.libXfixes
          pkgs.freetype
          pkgs.openssl
          pkgs.zlib
          pkgs.libpulseaudio
          pkgs.yasm
          pkgs.mesa
          pkgs.scons
          pkgs.libGLU
          pkgs.alsa-lib.dev
        ];
        sconsFlags = "target=release_debug platform=linuxbsd";
        preConfigure = ''
          sconsFlags+=" ${
            lib.concatStringsSep " "
            (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}") options)
          }"
        '';

        outputs = [ "out" "dev" "man" ];

        installPhase = ''
          mkdir -p "$out/bin"
          cp bin/godot.* $out/bin/godot
          mkdir "$dev"
          cp -r modules/gdnative/include $dev
          mkdir -p "$man/share/man/man6"
          cp misc/dist/linux/godot.6 "$man/share/man/man6/"
          mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
          cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/"
          cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
          cp icon.png "$out/share/icons/godot.png"
          substituteInPlace "$out/share/applications/org.godotengine.Godot.desktop" \
            --replace "Exec=godot" "Exec=$out/bin/godot"
        '';
      };
  };

}
