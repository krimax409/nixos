{ configRoot, ... }:
{
  # Репозиторий живёт в домашнем каталоге; /etc/nixos/nixos-config — симлинк
  # для совместимости (nh, nft/nfs, шаблоны). Идемпотентно.
  system.activationScripts.nixos-config-link = ''
    if [ -L /etc/nixos ]; then
      rm /etc/nixos
    fi
    mkdir -p /etc/nixos
    ln -sfn ${configRoot} /etc/nixos/nixos-config
  '';
}
