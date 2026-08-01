function FindProxyForURL(url, host) {
  if (
    isPlainHostName(host) ||
    host === "localhost" ||
    host === "::1" ||
    shExpMatch(host, "127.*") ||
    shExpMatch(host, "10.*") ||
    shExpMatch(host, "192.168.*") ||
    shExpMatch(host, "*.local")
  ) {
    return "DIRECT";
  }

  return "PROXY 127.0.0.1:2080; DIRECT";
}
