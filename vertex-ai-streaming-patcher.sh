#!/usr/bin/env bash
# =============================================================================
# patch.sh — Vertex AI / Google Cloud Gemini streaming fix for PocketRisu
#
# Fixes a bug in getTranStream() where the SSE read buffer was never flushed
# between transform() calls, causing duplicate text and missing chunks.
#
# Works on a fresh install and on a system that already ran an earlier
# (broken) patch attempt.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/LUNARIA1/cccccccccccc/refs/heads/main/vertex-ai-streaming-patcher.sh | bash
# =============================================================================
set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO="${HOME}/PocketRisu"
TARGET="${REPO}/src/ts/process/request/google.ts"
BACKUP="${TARGET}.orig.bak"
# $TMPDIR is set on Termux; fall back to /tmp on Linux/macOS
PATCHER="${TMPDIR:-/tmp}/_pr_streaming_patch.js"

# ---------------------------------------------------------------------------
# Colours
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  G='\033[0;32m' Y='\033[1;33m' R='\033[0;31m' C='\033[0;36m' B='\033[1m' E='\033[0m'
else
  G='' Y='' R='' C='' B='' E=''
fi
ok()   { echo -e "${G}[OK]${E}    $*"; }
info() { echo -e "${C}[INFO]${E}  $*"; }
warn() { echo -e "${Y}[WARN]${E}  $*"; }
die()  { echo -e "${R}[ERROR]${E} $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
echo ""
echo -e "${B}PocketRisu — Vertex AI Streaming Patch${E}"
echo "========================================"
echo ""

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
[ -d "${REPO}" ]   || die "PocketRisu not found at ${REPO}"
[ -f "${TARGET}" ] || die "Source file not found: ${TARGET}"
command -v node &>/dev/null || die "'node' not found. Run: pkg install nodejs-lts"

# ---------------------------------------------------------------------------
# If the file looks broken (prior failed patch) restore from any available backup
# ---------------------------------------------------------------------------
# We detect a broken state by looking for both the patch sentinel AND the
# old try/catch tail that the previous patcher failed to remove.
FILE_CONTENT="$(cat "${TARGET}")"

ALREADY_CLEAN=false
if echo "${FILE_CONTENT}" | grep -qF "buffer = lines.pop() ?? ''" && \
   ! echo "${FILE_CONTENT}" | grep -qF "} catch (error) {"; then
  ALREADY_CLEAN=true
fi

if [ "${ALREADY_CLEAN}" = true ]; then
  ok "Already patched — nothing to do."
  echo ""
  exit 0
fi

# Look for a pristine backup created by this script on a previous run.
# Also accept the .bak left by earlier broken patch scripts.
RESTORE_FROM=""
for candidate in "${BACKUP}" "${TARGET}.bak"; do
  if [ -f "${candidate}" ]; then
    RESTORE_FROM="${candidate}"
    break
  fi
done

if [ -n "${RESTORE_FROM}" ]; then
  info "Restoring original from ${RESTORE_FROM} ..."
  cp "${RESTORE_FROM}" "${TARGET}"
  ok "Restored."
else
  info "No backup found — will patch the current file directly."
fi

# ---------------------------------------------------------------------------
# Take a fresh backup of the (now clean) original
# ---------------------------------------------------------------------------
if [ ! -f "${BACKUP}" ]; then
  cp "${TARGET}" "${BACKUP}"
  info "Backup saved → ${BACKUP}"
fi

# ---------------------------------------------------------------------------
# Write the Node.js patcher into a temp file using a single-quoted heredoc.
# Single-quoted heredocs pass content 100% verbatim — no shell interpolation,
# no backslash processing. Node.js then handles all the string escaping itself.
# ---------------------------------------------------------------------------
info "Writing patcher..."
cat > "${PATCHER}" << 'JSEOF'
'use strict';
const fs  = require('fs');
const f   = process.env.HOME + '/PocketRisu/src/ts/process/request/google.ts';
let   src = fs.readFileSync(f, 'utf8').replace(/\r\n/g, '\n');

// ── Guard ────────────────────────────────────────────────────────────────────
if (src.includes("buffer = lines.pop() ?? '';") &&
    !src.includes('} catch (error) {')) {
  console.log('[OK] Already patched.'); process.exit(0);
}

// ── PATCH 1 — replace the monolithic try-block with per-line error handling ──
// Note: '\\n' in a JS string literal is backslash+n (2 chars), which matches
// the literal \n that appears inside buffer.split('\n') in the source file.
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

// ── PATCH 2 — replace the closing try/catch + bare enqueue ───────────────────
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

// ── Apply ────────────────────────────────────────────────────────────────────
if (!src.includes(OLD1)) {
  process.stderr.write('[ERROR] Head pattern not found.\n');
  process.stderr.write('        The source file may differ from the expected version.\n');
  process.exit(1);
}
src = src.replace(OLD1, NEW1);
console.log('[OK] Head pattern replaced.');

if (src.includes(OLD2)) {
  src = src.replace(OLD2, NEW2);
  console.log('[OK] Tail pattern replaced.');
} else {
  console.log('[WARN] Tail pattern not found — skipping (file may already be partially patched).');
}

// ── Verify & write ───────────────────────────────────────────────────────────
if (!src.includes("buffer = lines.pop() ?? '';")) {
  process.stderr.write('[ERROR] Verification failed — patch did not apply.\n');
  process.exit(1);
}

fs.writeFileSync(f, src, 'utf8');
console.log('[OK] Patch verified and written.');
JSEOF

# ---------------------------------------------------------------------------
# Run the patcher
# ---------------------------------------------------------------------------
info "Applying patch..."
node "${PATCHER}"
PATCH_EXIT=$?
rm -f "${PATCHER}"

if [ "${PATCH_EXIT}" -ne 0 ]; then
  info "Restoring original..."
  cp "${BACKUP}" "${TARGET}"
  die "Patch failed. Original restored from backup."
fi

echo ""
ok "Patch applied successfully!"
echo ""
echo -e "  ${B}What was fixed:${E}"
echo "  • getTranStream(): SSE buffer now flushed between transform() calls"
echo "  • Per-line JSON parse errors no longer drop the entire chunk"
echo "  • Output only enqueued when real data was decoded"
echo ""

# ---------------------------------------------------------------------------
# Offer to rebuild
# ---------------------------------------------------------------------------
echo -e "${Y}Rebuild now?${E} (required for the fix to take effect)"
echo -n "  [Y/n] → "
read -r ANS </dev/tty || ANS="y"

if [[ "${ANS}" =~ ^[Nn]$ ]]; then
  echo ""
  info "Run these when ready:"
  echo ""
  echo "  cd ~/PocketRisu"
  echo "  NODE_OPTIONS='--max-old-space-size=2048' pnpm build"
  echo "  node server/node/server.cjs"
  echo ""
  exit 0
fi

echo ""
info "Installing dependencies..."
cd "${REPO}"
pnpm install

echo ""
info "Building... (may take 5–20 minutes on a phone)"
NODE_OPTIONS="--max-old-space-size=2048" pnpm build

echo ""
ok "Build complete! Start the server with:"
echo ""
echo "  node server/node/server.cjs"
echo ""
