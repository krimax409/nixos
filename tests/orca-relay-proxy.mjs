import assert from 'node:assert/strict'
import { once } from 'node:events'
import { createServer } from 'node:http'
import { createRequire } from 'node:module'
import test from 'node:test'

const require = createRequire(import.meta.url)
const { WebSocket: Ws, WebSocketServer } = require(process.argv[2])
const configureRelayProxy = process.argv[3] ? require(process.argv[3]) : () => () => undefined
const directFetch = globalThis.fetch
const directWebSocket = globalThis.WebSocket
const worker = 'orca-pc-relay.krimax298.workers.dev'
const cell = 'edge.relay.orca.dev'

function dial(socket) {
  return new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      socket.close()
      reject(new Error('WebSocket did not finish connecting'))
    }, 2500)
    socket.addEventListener('error', () => {
      clearTimeout(timeout)
      resolve()
    }, { once: true })
    socket.addEventListener('open', () => {
      clearTimeout(timeout)
      socket.close()
      resolve()
    }, { once: true })
  })
}

await test('Only Orca relay traffic uses the loopback HTTP proxy', async (t) => {
  const connects = []
  const proxy = createServer()
  proxy.on('connect', (req, socket) => {
    connects.push(req.url)
    socket.end('HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\nConnection: close\r\n\r\n')
  })
  proxy.listen(2080, '127.0.0.1')
  await once(proxy, 'listening')
  const local = new WebSocketServer({ host: '127.0.0.1', port: 0 })
  await once(local, 'listening')
  local.on('connection', (peer) => peer.on('message', (msg) => peer.send(msg.toString())))
  async function expectProxy(host, request) {
    connects.length = 0
    await request()
    assert.deepEqual(connects, [`${host}:443`])
  }
  function health(host) {
    return fetch(`https://${host}/health`, { signal: AbortSignal.timeout(2000) }).catch(() => {})
  }
  try {
    const agentForRelay = configureRelayProxy()
    for (const path of ['/v1/host/control', '/v1/host/data/test']) {
      await t.test(`Orca WebSocket ${path} uses CONNECT`, () => {
        const url = `wss://${cell}${path}`
        return expectProxy(cell, () => dial(new Ws(url, { agent: agentForRelay(url) })))
      })
    }
    await t.test('Orca director HTTP uses CONNECT', () => {
      return expectProxy('relay.onorca.dev', () => health('relay.onorca.dev'))
    })
    await t.test('Orca does not proxy unrelated HTTPS', async () => {
      connects.length = 0
      await health('not-a-relay.invalid')
      assert.deepEqual(connects, [])
    })
    globalThis.fetch = directFetch
    globalThis.WebSocket = directWebSocket
    configureRelayProxy({ nativeWebSocket: true })
    await t.test('Cloudflare plugin WebSocket uses CONNECT', () => {
      return expectProxy(worker, () => dial(new WebSocket(`wss://${worker}/v1/c/test`)))
    })
    await t.test('Cloudflare Worker HTTP uses CONNECT', () => expectProxy(worker, () => health(worker)))
    await t.test('Cloudflare plugin does not proxy unrelated HTTPS', async () => {
      connects.length = 0
      await health('not-a-relay.invalid')
      assert.deepEqual(connects, [])
    })
    await t.test('The plugin can still use a direct loopback WebSocket', async () => {
      connects.length = 0
      const ws = new WebSocket(`ws://127.0.0.1:${local.address().port}`)
      try {
        await once(ws, 'open', { signal: AbortSignal.timeout(2000) })
        const reply = once(ws, 'message', { signal: AbortSignal.timeout(2000) })
        ws.send('local')
        assert.equal((await reply)[0].data, 'local')
        assert.deepEqual(connects, [])
      } finally { ws.close() }
    })
  } finally {
    for (const peer of local.clients) peer.terminate()
    await Promise.all([new Promise((resolve) => local.close(resolve)), new Promise((resolve) => proxy.close(resolve))])
  }
})
