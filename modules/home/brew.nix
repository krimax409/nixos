# Homebrew (linuxbrew) as an escape hatch for CLI tools not worth packaging
# as Nix derivations.
#
# Design: only PATH + env are declarative. The brew installation itself is
# imperative by nature — bootstrap once with:
#
#   git clone https://github.com/Homebrew/brew ~/.linuxbrew/Homebrew
#   mkdir -p ~/.linuxbrew/bin && ln -sf ../Homebrew/bin/brew ~/.linuxbrew/bin/brew
#
# then `brew install <formula>`. Brew lives entirely in ~/.linuxbrew, so it
# survives nixos-rebuild/generation switches like any other user data.
# Verified live: bottles pour and run on this system (glibc-compatible).
{ config, ... }:
{
  home.sessionVariables = {
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_NO_ENV_HINTS = "1";
  };

  # Brew's bin goes LAST in PATH so nix/system binaries win on name
  # collisions (notably brew's own git in Cellar). Brew is the fallback
  # source for tools, not the primary one.
  programs.zsh.envExtra = ''
    export PATH="$PATH:$HOME/.linuxbrew/bin"
  '';
  programs.bash.profileExtra = ''
    export PATH="$PATH:$HOME/.linuxbrew/bin"
  '';
}
