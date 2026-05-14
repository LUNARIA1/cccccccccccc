#!/bin/bash
# =============================================================
#  PocketRisu One-Touch Installer
#  Ubuntu 24.04 LTS (x86_64) 기준
#  사용법: bash <(curl -fsSL https://raw.githubusercontent.com/<your-id>/<your-repo>/main/pocketrisu-onetouch.sh)
# =============================================================

set -e

# ── 색상 ──────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log()  { echo -e "${CYAN}[PocketRisu]${RESET} $1"; }
ok()   { echo -e "${GREEN}[✓]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }
err()  { echo -e "${RED}[✗]${RESET} $1"; exit 1; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║     PocketRisu One-Touch Installer       ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── 1. 최신 버전 확인 ────────────────────────────────────────
log "최신 버전 확인 중..."
VERSION=$(curl -s https://api.github.com/repos/PocketRisu/PocketRisu/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4)

if [ -z "$VERSION" ]; then
  warn "GitHub API로 버전 감지 실패 → v1.6.0 으로 진행합니다."
  VERSION="v1.6.0"
fi
ok "설치 버전: $VERSION"

# ── 2. 포터블 패키지 다운로드 ────────────────────────────────
INSTALL_DIR="$HOME/pocketrisu"

# v1.6.0부터 파일명이 PocketRisu-*, 이전은 RisuAI-NodeOnly-*
VERSION_NUM="${VERSION#v}"  # v 제거
MAJOR=$(echo "$VERSION_NUM" | cut -d. -f1)
MINOR=$(echo "$VERSION_NUM" | cut -d. -f2)

if [ "$MAJOR" -gt 1 ] || { [ "$MAJOR" -eq 1 ] && [ "$MINOR" -ge 6 ]; }; then
  TARBALL="PocketRisu-${VERSION}-linux-x64.tar.gz"
  REPO="PocketRisu/PocketRisu"
else
  TARBALL="RisuAI-NodeOnly-${VERSION}-linux-x64.tar.gz"
  REPO="mrbart3885/Risuai-NodeOnly"
fi

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${TARBALL}"
DOWNLOAD_PATH="$HOME/pocketrisu-install.tar.gz"

log "포터블 패키지 다운로드 중..."
log "$DOWNLOAD_URL"
curl -fsSL "$DOWNLOAD_URL" -o "$DOWNLOAD_PATH" \
  || err "다운로드 실패. URL을 확인하세요: $DOWNLOAD_URL"

log "압축 해제 중..."
mkdir -p "$INSTALL_DIR"
tar -xzf "$DOWNLOAD_PATH" -C "$INSTALL_DIR" --strip-components=1
rm "$DOWNLOAD_PATH"
ok "설치 경로: $INSTALL_DIR"

# ── 3. nvm + Node.js 22 설치 ─────────────────────────────────
log "nvm 설치 중..."
export NVM_DIR="$HOME/.nvm"

if [ ! -f "$NVM_DIR/nvm.sh" ]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

source "$NVM_DIR/nvm.sh"
ok "nvm 로드 완료"

log "Node.js 22 설치 중..."
nvm install 22 --silent
nvm use 22
ok "Node.js $(node -v) 준비 완료"

# ── 4. pm2 설치 ──────────────────────────────────────────────
log "pm2 설치 중..."
npm install -g pm2 --silent
ok "pm2 $(pm2 -v) 설치 완료"

# ── 5. PATH 영구 등록 ─────────────────────────────────────────
NODE_BIN_PATH="$NVM_DIR/versions/node/$(nvm version)/bin"
BASHRC="$HOME/.bashrc"

if ! grep -q "$NODE_BIN_PATH" "$BASHRC" 2>/dev/null; then
  echo "export PATH=\"$NODE_BIN_PATH:\$PATH\"" >> "$BASHRC"
fi
export PATH="$NODE_BIN_PATH:$PATH"
ok "pm2 PATH 등록 완료"

# ── 6. 서버 시작 ──────────────────────────────────────────────
log "PocketRisu 서버 시작 중..."
cd "$INSTALL_DIR"

# 이미 실행 중이면 재시작, 아니면 새로 시작
pm2 describe risuai > /dev/null 2>&1 \
  && pm2 restart risuai \
  || pm2 start ./start.sh --name risuai

ok "서버 프로세스 시작됨"

# ── 7. Cloudflare 터널 시작 ───────────────────────────────────
log "Cloudflare 터널 시작 중..."

pm2 describe tunnel > /dev/null 2>&1 \
  && pm2 restart tunnel \
  || pm2 start "${INSTALL_DIR}/bin/cloudflared tunnel --url http://localhost:6001" --name tunnel

ok "터널 프로세스 시작됨"

# ── 8. pm2 저장 ───────────────────────────────────────────────
pm2 save --force > /dev/null 2>&1
ok "pm2 프로세스 목록 저장 완료"

# ── 9. 터널 URL 대기 & 출력 ──────────────────────────────────
log "터널 URL 생성 대기 중 (최대 20초)..."
TUNNEL_URL=""
for i in $(seq 1 20); do
  TUNNEL_URL=$(pm2 logs tunnel --lines 50 --nostream 2>/dev/null \
    | grep -oP 'https://[a-zA-Z0-9\-]+\.trycloudflare\.com' | tail -1)
  [ -n "$TUNNEL_URL" ] && break
  sleep 1
done

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║               설치 완료!                             ║${RESET}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════╣${RESET}"

if [ -n "$TUNNEL_URL" ]; then
  echo -e "${BOLD}║  🌐 접속 주소:${RESET}"
  echo -e "${BOLD}║     ${GREEN}${TUNNEL_URL}${RESET}"
else
  warn "터널 URL을 자동으로 찾지 못했습니다."
  echo -e "${BOLD}║  아래 명령어로 직접 확인하세요:${RESET}"
  echo -e "${BOLD}║     ${YELLOW}pm2 logs tunnel --lines 50 --nostream${RESET}"
fi

echo -e "${BOLD}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${BOLD}║  📋 자주 쓰는 명령어                                 ║${RESET}"
echo -e "${BOLD}╠══════════════════════════════════════════════════════╣${RESET}"
echo -e "${BOLD}║  서버 상태 확인   →  ${CYAN}pm2 list${RESET}"
echo -e "${BOLD}║  서버 재시작      →  ${CYAN}pm2 restart risuai${RESET}"
echo -e "${BOLD}║  터널 URL 재확인  →  ${CYAN}pm2 logs tunnel --lines 50 --nostream${RESET}"
echo -e "${BOLD}║  업데이트         →  ${CYAN}cd ~/pocketrisu && ./update.sh && pm2 restart risuai${RESET}"
echo -e "${BOLD}║  로그 실시간 보기 →  ${CYAN}pm2 logs risuai${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
warn "SSH를 닫아도 서버는 계속 실행됩니다."
warn "VM 자체를 재부팅하면 서버가 꺼집니다. (재부팅 후 이 스크립트를 다시 실행하세요)"
echo ""
