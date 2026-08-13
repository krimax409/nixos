function FindProxyForURL(url, host) {
  if (
    isPlainHostName(host) ||
    host === "localhost" ||
    host === "::1" ||
    shExpMatch(host, "127.*") ||
    shExpMatch(host, "10.*") ||
    shExpMatch(host, "192.168.*") ||
    // Tailscale CGNAT-диапазон 100.64.0.0/10: peers тайлнета (hermes-vm и
    // прочие) должны идти напрямую через интерфейс tailscale0. Через прокси
    // они отдают 502, из-за чего Hermes Desktop не мог получить
    // WebSocket-тикет у gateway.
    isInNet(host, "100.64.0.0", "255.192.0.0") ||
    shExpMatch(host, "*.ts.net") ||
    shExpMatch(host, "*.local")
  ) {
    return "DIRECT";
  }

  return "PROXY 127.0.0.1:2080; DIRECT";
}
