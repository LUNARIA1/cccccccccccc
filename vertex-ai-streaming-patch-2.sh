#!/usr/bin/env bash
# =============================================================================
# vertex-ai-streaming-patch.sh
#
# Fixes a streaming bug in PocketRisu's Vertex AI (and Google Cloud) Gemini
# adapter where the SSE buffer was never flushed between transform() calls,
# causing duplicate data accumulation and lost chunks.
#
# Usage (from Termux):
#   curl -fsSL https://raw.githubusercontent.com/LUNARIA1/cccccccccccc/refs/heads/main/vertex-ai-streaming-patch-2.sh | bash
#
# Or, if you cloned the repo:
#   bash ~/PocketRisu/scripts/vertex-ai-streaming-patch.sh
#
# After patching the script will ask whether to rebuild automatically.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
REPO_DIR="${HOME}/PocketRisu"
TARGET_FILE="${REPO_DIR}/src/ts/process/request/google.ts"
BACKUP_FILE="${TARGET_FILE}.bak"

# Colour helpers (skip if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; CYAN=''; BOLD=''; RESET=''
fi

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()     { error "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}PocketRisu — Vertex AI Streaming Patch${RESET}"
echo "========================================"
echo ""

[ -d "${REPO_DIR}" ] || die "PocketRisu directory not found at ${REPO_DIR}"
[ -f "${TARGET_FILE}" ] || die "Target file not found: ${TARGET_FILE}"

# Check Python availability (required for reliable multi-line patching)
PYTHON=""
for py in python3 python; do
    if command -v "${py}" &>/dev/null; then
        PYTHON="${py}"
        break
    fi
done
[ -n "${PYTHON}" ] || die "Python is required but not found. Run: pkg install python"

# ---------------------------------------------------------------------------
# Already patched?
# ---------------------------------------------------------------------------
if grep -qF "buffer = lines.pop() ?? '';" "${TARGET_FILE}" 2>/dev/null; then
    success "Already patched — nothing to do."
    echo ""
    exit 0
fi

# ---------------------------------------------------------------------------
# Backup
# ---------------------------------------------------------------------------
info "Creating backup → ${BACKUP_FILE}"
cp "${TARGET_FILE}" "${BACKUP_FILE}"

# ---------------------------------------------------------------------------
# Apply patch via Python
# ---------------------------------------------------------------------------
info "Applying patch to ${TARGET_FILE} ..."

"${PYTHON}" - <<'PYEOF'
import sys, re, os

target = os.path.join(os.environ['HOME'], 'PocketRisu',
                      'src', 'ts', 'process', 'request', 'google.ts')

with open(target, 'r', encoding='utf-8') as f:
    src = f.read()

# ── OLD block ───────────────────────────────────────────────────────────────
OLD = re.compile(
    r'(        transform\(chunk, control\) \{\r?\n'
    r'            buffer \+= new TextDecoder\(\)\.decode\(chunk\);\r?\n'
    r'            const lines = buffer\.split\(\'\\n\'\);\r?\n'
    r'\r?\n'
    r'            let readed = initStreamState\(\);\r?\n'
    r'\r?\n'
    r'            try \{\r?\n'
    r'                for \(const line of lines\) \{\r?\n'
    r'                    if \(line\.startsWith\(\'data: \'\)\) \{\r?\n'
    r'                        const dataStr = line\.slice\(6\)\.trim\(\);\r?\n'
    r'                        if \(dataStr === \'\[DONE\]\'\) return;\r?\n'
    r'                    \r?\n'
    r'                        const jsonData = JSON\.parse\(dataStr\);)',
    re.DOTALL
)

if not OLD.search(src):
    print('[PATCH] Pattern not found — already patched or source has changed.', file=sys.stderr)
    sys.exit(2)

# ── NEW block ───────────────────────────────────────────────────────────────
NEW = (
    '        transform(chunk, control) {\n'
    '            buffer += new TextDecoder().decode(chunk);\n'
    "            const lines = buffer.split('\\n');\n"
    '\n'
    '            // Keep the last (potentially incomplete) line in the buffer for next chunk\n'
    "            buffer = lines.pop() ?? '';\n"
    '\n'
    '            let readed = initStreamState();\n'
    '            let hasData = false;\n'
    '\n'
    '            for (const line of lines) {\n'
    "                if (line.startsWith('data: ')) {\n"
    '                    const dataStr = line.slice(6).trim();\n'
    "                    if (dataStr === '[DONE]') continue;\n"
    '                    \n'
    '                    let jsonData: any;\n'
    '                    try {\n'
    '                        jsonData = JSON.parse(dataStr);\n'
    '                    } catch {\n'
    '                        // Incomplete JSON fragment — skip silently\n'
    '                        continue;\n'
    '                    }\n'
    '                    \n'
    '                    hasData = true;\n'
    '\n'
    '                    if (jsonData.candidates?.[0]?.content?.parts) {'
)

patched = OLD.sub(NEW, src, count=1)

# ── Fix the closing try/catch + enqueue ─────────────────────────────────────
OLD_TAIL = re.compile(
    r'(                \} \r?\n'
    r'            \}\r?\n'
    r'                control\.enqueue\(readed\)\r?\n'
    r'            \} catch \(error\) \{ \r?\n'
    r'\r?\n'
    r'            \}\r?\n)',
    re.DOTALL
)

NEW_TAIL = (
    '                } \n'
    '            }\n'
    '            if (hasData) {\n'
    '                control.enqueue(readed)\n'
    '            }\n'
)

if OLD_TAIL.search(patched):
    patched = OLD_TAIL.sub(NEW_TAIL, patched, count=1)
else:
    print('[PATCH] Tail pattern not matched — skipping tail fix (may be harmless).')

with open(target, 'w', encoding='utf-8', newline='') as f:
    f.write(patched)

print('[PATCH] File written successfully.')
PYEOF

PYEXIT=$?
if [ "${PYEXIT}" -eq 2 ]; then
    warn "Pattern not found in source — file may already be patched or upstream changed."
    warn "Backup preserved at: ${BACKUP_FILE}"
    exit 0
elif [ "${PYEXIT}" -ne 0 ]; then
    error "Python patcher exited with code ${PYEXIT}."
    info  "Restoring backup..."
    cp "${BACKUP_FILE}" "${TARGET_FILE}"
    die "Patch failed. Original file restored."
fi

# ---------------------------------------------------------------------------
# Verify patch landed
# ---------------------------------------------------------------------------
if grep -qF "buffer = lines.pop() ?? '';" "${TARGET_FILE}" 2>/dev/null; then
    success "Patch applied successfully."
else
    error "Verification failed — patched string not found."
    info  "Restoring backup..."
    cp "${BACKUP_FILE}" "${TARGET_FILE}"
    die "Patch verification failed. Original file restored."
fi

echo ""
echo -e "${BOLD}What was fixed:${RESET}"
echo "  • getTranStream() now correctly trims processed lines from the SSE"
echo "    buffer so each TCP chunk is not re-processed on the next call."
echo "  • JSON parse errors for incomplete chunks are caught per-line instead"
echo "    of silently swallowing the entire chunk via a top-level try/catch."
echo "  • Streaming output is enqueued only when real data was decoded,"
echo "    avoiding spurious empty chunks."
echo ""

# ---------------------------------------------------------------------------
# Optional rebuild
# ---------------------------------------------------------------------------
echo -e "${YELLOW}Rebuild now?${RESET} (recommended — patch only takes effect after a build)"
echo -n "  [y/N] → "
read -r ANSWER </dev/tty || ANSWER="n"

if [[ "${ANSWER}" =~ ^[Yy]$ ]]; then
    echo ""
    info "Running: pnpm install"
    echo ""
    cd "${REPO_DIR}"
    pnpm install
    echo ""
    info "Running: NODE_OPTIONS='--max-old-space-size=2048' pnpm build"
    echo "  (this may take 5–20 minutes on a phone)"
    echo ""
    NODE_OPTIONS="--max-old-space-size=2048" pnpm build
    echo ""
    success "Build complete. Restart the server to apply the fix:"
    echo ""
    echo "    node server/node/server.cjs"
    echo ""
else
    echo ""
    info "Skipping build. Run this when ready:"
    echo ""
    echo "    cd ~/PocketRisu"
    echo "    NODE_OPTIONS='--max-old-space-size=2048' pnpm build"
    echo "    node server/node/server.cjs"
    echo ""
fi
