const http = require('node:http')
const https = require('node:https')

const workerHost = 'orca-pc-relay.krimax298.workers.dev'
const orcaHosts = new Set(['relay.onorca.dev', 'relay.orca.dev', 'login.onorca.dev', 'login.orca.dev'])

module.exports = function configureRelayProxy({ nativeWebSocket = false } = {}) {
  const restore = http.setGlobalProxyFromEnv({ HTTPS_PROXY: 'http://127.0.0.1:2080', NO_PROXY: '' })
  const httpsAgent = https.globalAgent
  const dispatcher = globalThis[Symbol.for('undici.globalDispatcher.2')]
  restore()
  if (typeof dispatcher?.dispatch !== 'function') throw new Error('Orca relay proxy: missing Node dispatcher')

  function viaProxy(input) {
    const url = URL.parse(input?.url ?? input)
    if (!url || (url.protocol !== 'https:' && url.protocol !== 'wss:') || url.port) return false
    const host = url.hostname
    if (nativeWebSocket) return host === workerHost
    return orcaHosts.has(host) || host.endsWith('.relay.onorca.dev') || host.endsWith('.relay.orca.dev')
  }

  const fetch = globalThis.fetch
  globalThis.fetch = (input, init) => fetch(input, viaProxy(input) ? { ...init, dispatcher } : init)

  if (nativeWebSocket) {
    globalThis.WebSocket = class extends globalThis.WebSocket {
      constructor(url, options) {
        super(url, viaProxy(url)
          ? { ...(Array.isArray(options) || typeof options === 'string' ? { protocols: options } : options), dispatcher }
          : options)
      }
    }
  }

  return (url) => viaProxy(url) ? httpsAgent : undefined
}
