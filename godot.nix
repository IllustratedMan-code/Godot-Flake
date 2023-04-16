# Godot.nix
# this modules focuses on building godot
# TODO : Add support for a custom.py
{ lib, pkgs, inputs, system }:
with pkgs;
with builtins;
let

  # godot version
  godotVersion = import ./version.nix { inherit system; };
  # godot custom.py
  godotCustom = import ./custom.nix { inherit lib system; };
  # godot build libraries
  godotLibraries = import ./libs.nix {
    inherit pkgs;
    use_x11 = true;
    use_mono = false;
  };

  # default installation for godot engine
  defaultInstall = ''
        mkdir -p "$out/bin"
        cp bin/godot.* $out/bin/godot-${godotVersion.version}-${target}
      '';
  
  # function to make a godot derivation
  mkGodotBase = {pname ? "godot", target ? "editor", tools ? true, installPhase ? defaultInstall, strip ? []} : stdenv.mkDerivation {

      # pass parameters
      inherit installPhase strip;

      # use variables from args
      name = (concatStringsSep "-" [pname target godotVersion.version]);
      src = inputs.godot;

      # get godot version from version modules
      version = godotVersion.version;
      platform = godotVersion.platform;

      # As a rule of thumb: Buildtools as nativeBuildInputs,
      # libraries and executables you only need after the build as buildInputs
      nativeBuildInputs = godotLibraries.buildDep ++ godotLibraries.buildTools;
      buildInputs = godotLibraries.runtimeDep;
      runtimeDependencies = godotLibraries.runtimeDep;
      enableParallelBuilding = true;

      # scons flags list 
      sconsFlags = [
        ("platfom=" + godotVersion.platform)
        ("target=" + target)
        (if tools then "tools=yes" else "tools=no")
        ("use_sowrap=false") # make sure to link to system libraries
        ("use_volk=false") # Get vulkan via system libraries
      ] ++ godotCustom.customSconsFlags;

      # apply the necessary patches
      patches = [
        ./patches/xfixes.patch # fix x11 libs
        ./patches/gl.patch # fix gl libs
      ];

      # some extra info
      meta = with lib; {
        homepage = pkgs.godot.meta.homepage;
        description = pkgs.godot.meta.description;
        license = licenses.mit;
      };
  };

# implementation
in {
  # mkGodot
  # function to male a godot build
  mkGodot = {target ? "editor"}: mkGodotBase {
      inherit target;
      tools = true;
      installPhase = ''
        mkdir -p "$out/bin"
        cp bin/godot.* $out/bin/godot-${godotVersion.version}-${target}
        mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
        cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/"
        substituteInPlace "$out/share/applications/org.godotengine.Godot.desktop" \
          --replace "Exec=godot" "Exec=$out/bin/godot"
        cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
        cp icon.png "$out/share/icons/godot.png"
      '';
      # Do not set GODOT4_BIN=out/bin/godot-${target} because we may build templates toos
    };

  # build a template
  mkGodotTemplate = {target ? "template_debug"} : mkGodotBase {
      inherit target;
      tools = false;
      installPhase = ''
        mkdir -p "$out/share/godot/templates/${godotVersion.version}"
        cp bin/godot.* $out/share/godot/templates/${godotVersion.version}/${godotVersion.platform}-${target}
      '';
      # https://docs.godotengine.org/en/stable/development/compiling/optimizing_for_size.html
      #strip = (oldAttrs.stripAllList or [ ]) ++ [ "share/godot/templates" ];
    };
}