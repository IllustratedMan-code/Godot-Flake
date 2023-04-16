# Godot is a cross-platform open-source game engine written in C++
#
# This flake build godot, the cpp bindings and the export templates
#
{
  description = "the godot Engine, and the godot-cpp bindings for extensions";
  inputs = {
    # the godot Engine
    godot = {
      url = "github:godotengine/godot";
      flake = false;
    };
    # the godot cpp bindings to build GDExtensions
    godot-cpp = {
      url = "github:godotengine/godot-cpp";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      # only linux supported
      # TODO: support darwin and cross compilation
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;

      # helper function
      buildGodot = import ./godot.nix { inherit lib pkgs system inputs; };
      buildGdExt = import ./extensions.nix { inherit lib pkgs system inputs; };

      # godot engine
      godot-editor = buildGodot.mkGodot { }; # Godot Editor
      godot-template-release =
        buildGodot.mkGodotTemplate { target = "template_release"; };
      godot-template-debug =
        buildGodot.mkGodotTemplate { target = "template_debug"; };

      # whole godot package
      godot-engine = pkgs.buildEnv {
        name = "godot-engine";
        paths = [ godot-editor godot-template-release godot-template-debug ];
      };

      # godot cpp bindings
      godot-cpp-editor = buildGdExt.mkGodotCPP { target = "editor"; };

      # extension demo
      godot-cpp-demo = buildGdExt.buildExt {
        extName = "godot-cpp-demo";
        src = "${inputs.godot-cpp}/test";
      };

    in {

      # build functions :
      lib = { inherit buildGodot buildGdExt; };

      #packages
      packages."${system}" = with pkgs; {
        default = pkgs.linkFarmFromDrvs "godot-flake" [
          godot-engine
          godot-cpp-editor
          godot-cpp-demo
        ];
      };
      # dev-shell
      # TODO : Godot development tools
      devShells."${system}".default = with pkgs; mkShell { };
    };
}
