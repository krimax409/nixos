{ pkgs, ... }:
{
  home.packages = with pkgs; [
    claude-code
    proxychains-ng
  ];

  home.file.".proxychains/proxychains.conf".text = ''
    strict_chain
    quiet_mode
    proxy_dns
    tcp_read_time_out 15000
    tcp_connect_time_out 8000

    [ProxyList]
    http 127.0.0.1 2080
  '';
}