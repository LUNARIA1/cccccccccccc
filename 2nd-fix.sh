#!/usr/bin/env bash
# 2nd-fix.sh — Vertex AI streaming patch (restores backup then re-patches)
# curl -fsSL https://raw.githubusercontent.com/<YOUR_FORK>/PocketRisu/main/scripts/2nd-fix.sh | bash
set -euo pipefail

REPO="${HOME}/PocketRisu"
TARGET="${REPO}/src/ts/process/request/google.ts"
BACKUP="${TARGET}.bak"
PATCHER="/tmp/_pocketrisu_patch.js"

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; E='\033[0m'
ok()   { echo -e "${G}[OK]${E}    $*"; }
info() { echo -e "${C}[INFO]${E}  $*"; }
die()  { echo -e "${R}[ERROR]${E} $*" >&2; exit 1; }

echo ""
echo "=== PocketRisu Vertex AI Streaming Fix (2nd attempt) ==="
echo ""

[ -f "${TARGET}" ] || die "google.ts not found at ${TARGET}"
[ -f "${BACKUP}" ] || die ".bak not found. Run the original patch script first."

# Step 1: restore backup
info "Restoring backup..."
cp "${BACKUP}" "${TARGET}"
ok "Restored from ${BACKUP}"

# Step 2: write the patcher JS using a heredoc (no escaping issues)
info "Writing patcher..."
cat > "${PATCHER}" << 'JSEOF'
'use strict';
const fs = require('fs');
const f = process.env.HOME + '/PocketRisu/src/ts/process/request/google.ts';
let s = fs.readFileSync(f, 'utf8').replace(/\r\n/g, '\n');

if (s.includes("buffer = lines.pop() ?? '';")) {
  console.log('[OK] Already patched.'); process.exit(0);
}

const OLD1 =
  "const lines = buffer.split('\\n');\n" +
  "\n" +
  "            let readed = initStreamState();\n" +
  "\n" +
  "            try {\n" +
  "                for (const line of lines) {\n" +
  "                    if (line.startsWith('data: ')) {\n" +
  "                        const dataStr = line.slice(6).trim();\n" +
  "                        if (dataStr === '[DONE]') return;\n" +
  "                    \n" +
  "                        const jsonData = JSON.parse(dataStr);\n" +
  "                        \n" +
  "                        if (jsonData.candidates?.[0]?.content?.parts) {";

const NEW1 =
  "const lines = buffer.split('\\n');\n" +
  "\n" +
  "            // Keep the last (potentially incomplete) line in the buffer for next chunk\n" +
  "            buffer = lines.pop() ?? '';\n" +
  "\n" +
  "            let readed = initStreamState();\n" +
  "            let hasData = false;\n" +
  "\n" +
  "            for (const line of lines) {\n" +
  "                if (line.startsWith('data: ')) {\n" +
  "                    const dataStr = line.slice(6).trim();\n" +
  "                    if (dataStr === '[DONE]') continue;\n" +
  "                    \n" +
  "                    let jsonData;\n" +
  "                    try {\n" +
  "                        jsonData = JSON.parse(dataStr);\n" +
  "                    } catch {\n" +
  "                        // Incomplete JSON fragment — skip silently\n" +
  "                        continue;\n" +
  "                    }\n" +
  "                    \n" +
  "                    hasData = true;\n" +
  "\n" +
  "                    if (jsonData.candidates?.[0]?.content?.parts) {";

const OLD2 =
  "                    } \n" +
  "                }\n" +
  "                control.enqueue(readed)\n" +
  "            } catch (error) { \n" +
  "\n" +
  "            }";

const NEW2 =
  "                    } \n" +
  "                }\n" +
  "            if (hasData) {\n" +
  "                control.enqueue(readed)\n" +
  "            }";

if (!s.includes(OLD1)) {
  console.error('[ERROR] Head pattern not found. File may differ from expected.');
  process.exit(1);
}
s = s.replace(OLD1, NEW1);
console.log('[OK] Head patched.');

if (s.includes(OLD2)) {
  s = s.replace(OLD2, NEW2);
  console.log('[OK] Tail patched.');
} else {
  console.log('[WARN] Tail pattern not found (skipping).');
}

fs.writeFileSync(f, s, 'utf8');
console.log('[OK] Done!');
JSEOF

# Step 3: run the patcher
info "Running patcher..."
node "${PATCHER}"
rm -f "${PATCHER}"

# Step 4: build
echo ""
echo -e "${Y}Rebuild now? (Y/n)${E}"
echo -n "  → "
read -r ANS </dev/tty || ANS="y"
if [[ "${ANS}" =~ ^[Nn]$ ]]; then
  echo ""
  info "Run manually when ready:"
  echo "  cd ~/PocketRisu && NODE_OPTIONS='--max-old-space-size=2048' pnpm build && node server/node/server.cjs"
  echo ""
  exit 0
fi

echo ""
info "Building... (may take 5-20 min)"
cd "${REPO}"
NODE_OPTIONS="--max-old-space-size=2048" pnpm build
echo ""
ok "Build complete!"
echo ""
echo "  Start the server:  node server/node/server.cjs"
echo ""