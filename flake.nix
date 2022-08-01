{
    inputs = {
        godot.url = "github:godotengine/godot";
        godot.flake = false;
    };
    outputs = {self, nixpkgs, ...}@inputs: 
        let
            system = "x86_64-linux";
            pkgs = import nixpkgs{inherit system;};
        in
    rec{
        packages."${system}" = with pkgs; {
            default = stdenv.mkDerivation rec{
                name = "godot";
                src = inputs.godot;
                nativeBuildInputs = [
                    scons
                    pkg-config
                    vulkan-loader
                    xorg.libX11
                    xorg.libXcursor
                    xorg.libXinerama
                    xorg.libXrandr
                    xorg.libXrender
                    xorg.libXi
                    xorg.libXext
                    xorg.libXfixes
                    udev
                    systemd
                    systemd.dev
                    libpulseaudio
                    freetype
                    openssl
                    alsa-lib
                    libGLU
                    zlib
                    yasm
                    autoPatchelfHook
                ];
                runtimeDependencies = [vulkan-loader libpulseaudio];
                patchPhase = ''
                    substituteInPlace platform/linuxbsd/detect.py --replace 'pkg-config xi ' 'pkg-config xi xfixes '
                '';
                enableParallelBuilding = true;
                buildInputs = nativeBuildInputs;
                
                sconsFlags = "platform=linuxbsd";
                installPhase = ''
                    mkdir -p "$out/bin"
                    cp bin/godot.* $out/bin/godot
                '';
            };
        };
        devShells."${system}".head = with pkgs; mkShell{
            nativeBuildInputs = [patchelf nodePackages.http-server];
            runtimeDependencies = nativeBuildInputs;
        };

    };
}
