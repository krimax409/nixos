import hashlib
import json
import struct
import sys
from pathlib import Path


def digest(data):
    return hashlib.sha256(data).hexdigest()


archive = Path(sys.argv[1])
raw = archive.read_bytes()
marker, header_size, payload_size, json_size = struct.unpack_from('<IIII', raw)
if marker != 4 or payload_size != header_size - 4 or 16 + json_size > 8 + header_size:
    sys.exit('Unexpected Orca ASAR header')

header = json.loads(raw[16:16 + json_size])
entry = header['files']['out']['files']['main']['files']['index.js']
offset = int(entry['offset'])
base = 8 + header_size
start = base + offset
end = start + entry['size']
source = raw[start:end]
if digest(source) != '322041c3a3435b9188cf561597d2cb758ae5e2ee4051e2b912dae60d29492223':
    sys.exit('Orca bundle is not the verified 1.4.274 build; recheck the relay proxy patch')

patches = {
    b'function sla(e,t){return new ei.default(e,{headers:':
        b'function sla(e,t){return new ei.default(e,{agent:orcaRelayAgent(e),headers:',
    b'new ei.default(e,{perMessageDeflate:!1,maxPayload:mca})':
        b'new ei.default(e,{agent:orcaRelayAgent(e),perMessageDeflate:!1,maxPayload:mca})',
    b'env:U0i(),execArgv:[],serialization:`advanced`':
        b'env:U0i(),execArgv:t===`truongthanhquan.cloudflare-relay`?[`--require`,process.resourcesPath+`/orca-relay-worker-proxy.cjs`]:[],serialization:`advanced`',
}
for old, new in patches.items():
    if source.count(old) != 1:
        sys.exit('Orca relay proxy patch point changed')
    source = source.replace(old, new)
source = b'const orcaRelayAgent = require(process.resourcesPath + "/orca-relay-proxy.cjs")();\n' + source
size_delta = len(source) - entry['size']
entry['size'] = len(source)
integrity = entry['integrity']
block_size = integrity['blockSize']
integrity['hash'] = digest(source)
integrity['blocks'] = [digest(source[i:i + block_size]) for i in range(0, len(source), block_size)]


def adjust_offsets(node):
    for item in node['files'].values():
        if 'files' in item:
            adjust_offsets(item)
        elif 'offset' in item and int(item['offset']) > offset:
            item['offset'] = str(int(item['offset']) + size_delta)


adjust_offsets(header)
encoded = json.dumps(header, ensure_ascii=False, separators=(',', ':')).encode()
padding = b'\0' * (-len(encoded) % 4)
size = len(encoded) + len(padding)
archive.chmod(0o644)
archive.write_bytes(struct.pack('<IIII', 4, 8 + size, 4 + size, len(encoded)) + encoded + padding
                    + raw[base:start] + source + raw[end:])
