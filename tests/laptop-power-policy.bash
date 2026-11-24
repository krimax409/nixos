#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
nix eval --no-write-lock-file --json .#nixosConfigurations.laptop.config --apply 'c: {
  startup = builtins.elem "multi-user.target" (c.systemd.services.tlp.wantedBy or []);
  conflictingUnit = (c.systemd.services.cpufreq.enable or false) || c.services.power-profiles-daemon.enable;
  tlpConfig = c.environment.etc."tlp.conf".text or "";
}' | jq -er '
  if (.startup | not) then error("TLP does not start on laptop boot")
  elif .conflictingUnit then error("another service also controls the CPU policy")
  else
    (.["tlpConfig"] | split("\n")) as $config
    | ([
        "TLP_DISABLE_DEFAULTS=1",
        "CPU_SCALING_GOVERNOR_ON_AC=performance",
        "CPU_ENERGY_PERF_POLICY_ON_AC=performance",
        "CPU_SCALING_GOVERNOR_ON_BAT=powersave",
        "CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power",
        "CPU_BOOST_ON_AC=1",
        "CPU_BOOST_ON_BAT=1"
      ] - $config) as $missing
    | if ($missing | length) > 0 then error("missing TLP settings: " + ($missing | join(", ")))
      else "PASS: laptop keeps performance on AC and uses balanced battery CPU policy with boost"
      end
  end
'
