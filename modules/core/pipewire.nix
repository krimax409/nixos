import ../../lib/mkModule.nix {
  namespace = "kdk.modules";
  name = "pipewire";
  description = "PipeWire audio with PulseAudio compat";
  category = "hardware";
  cfg =
    _cfg:
    { pkgs, ... }:
    {
      services.pulseaudio.enable = false;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
      hardware.alsa.enablePersistence = true;
      environment.systemPackages = with pkgs; [ pulseaudioFull ];
    };
}
