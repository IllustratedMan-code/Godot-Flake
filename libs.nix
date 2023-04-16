# libs.nix
# Godot libraries for build and runtime
{ pkgs, use_llvm ? true, use_x11 ? true, use_openGL ? true, use_mono ? true }:
let

  conditionalLib = c: l: (if (c == true) then l else [ ]);

  # mono/C#
  libMono = with pkgs; [ mono6 msbuild dotnetPackages.Nuget ];
  # llvm compiler
  libllvm = with pkgs; [ llvm lld clang ];
  # x11 libraries
  libXorg = with pkgs.xorg; [
    libX11
    libXcursor
    libXi
    libXinerama
    libXrandr
    libXrender
    libXext
    libXfixes
  ];

  # OpenGL libraries
  libOpenGL = with pkgs; [ glslang libGLU libGL ];

in {

  buildTools = with pkgs;
    [
      scons
      pkg-config
      installShellFiles
      autoPatchelfHook
      bashInteractive
      patchelf
      gcc
    ] ++ conditionalLib use_llvm libllvm;

  # runtime dependencies
  runtimeDep = with pkgs;
    [
      udev
      systemd
      systemd.dev
      libpulseaudio
      freetype
      openssl
      alsa-lib
      fontconfig.lib
      speechd
      libxkbcommon
      dbus.lib
      vulkan-loader
    ] ++ conditionalLib use_x11 libXorg;

  # build dependancies
  buildDep = with pkgs;
    [ zlib yasm vulkan-headers ] ++ conditionalLib use_x11 libXorg
    ++ conditionalLib use_openGL libOpenGL ++ conditionalLib use_mono libMono;
}
