# version.nix
# get godot version
{ system }: {
  # this builds godot 4. we should instead read it from the input file
  version = "4.1-dev";
  # todo : test darwin support
  platform = if (system == "x86_64-linux") then "linuxbsd" else "darwin";
}
