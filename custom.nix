# custom.nix
# this modules focuses on generating or overriding the custom.py used to build godot
{ lib, system, optimize ? "speed", mono ? true, llvm ? true, lto ? true
, opengl ? true, udev ? true, fontconfig ? true, touch ? false, speechd ? false
, dbus ? true, pulseaudio ? true, }:
let

  linux = (system == "x86_64-linux");

  # TODO support override : 
  override = false;
  file = "./custom.py";

  # convert parameters to set
  options = lib.mkIf (override == false) {
    # optimize is one of "size"or "speed"
    optimize = optimize;
    # C# support
    module_mono_enabled = mono;
    # llvm
    use_llvm = llvm;
    use_lld = llvm;
    # link time optim
    use_lto = lto;
    # add a suffix to binaries
    extra_suffix = "_flake";
    # enable openGL3ES renderer
    opengl3 = opengl;
    # linux pulseaudio
    pulseaudio = pulseaudio && linux;
    # Use D-Bus to handle screensaver and portal desktop settings
    dbus = dbus && linux;
    # Use Speech Dispatcher for Text-to-Speech support
    speechd = speechd && linux;
    # Use fontconfig for system fonts support
    fontconfig = fontconfig && linux;
    # Use udev for gamepad connection callbacks
    udev = udev && linux;
    # Enable touch events
    touch = touch;
  };

  # convert true/false to "yes" "no" for scons
  boolToString = cond: if cond then "yes" else "no";

  # turn option set into scons options
  mkGodotOption = optionSet:
    (lib.mapAttrsToList (k: v:
      if (builtins.isBool v) then
        ("${k}=${boolToString v}")
      else
        "${k}=${builtins.toJSON v}") optionSet);

in {

  # we can use (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}") options); if we have values in nix format
  # resulting scons flag
  customSconsFlags = (mkGodotOption options);
}
