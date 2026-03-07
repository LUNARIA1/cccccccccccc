#!/bin/bash
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🚀 RisuAI + Cloudflare Tunnel 시작 ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ── 루트 여부 확인
if [ "$EUID" -ne 0 ]; then SUDO="sudo"; else SUDO=""; fi

# ── PATH 설정
export PATH="$HOME/.npm-global/bin:$HOME/bin:$PATH"

# ── 1. RisuAI 서버 시작 ────────────────────────────────────
echo -e "${BLUE}▶ RisuAI 서버 확인 중...${NC}"

if ! command -v pm2 &> /dev/null; then
    echo -e "${RED}❌ pm2가 없습니다. nrisu_gcp.sh 를 먼저 실행하세요.${NC}"
    exit 1
fi

if pm2 list | grep -q "risuai"; then
    echo -e "${GREEN}✅ RisuAI 이미 실행 중${NC}"
else
    echo -e "${YELLOW}⚡ RisuAI 시작 중...${NC}"
    cd ~/Risu-AI
    pm2 start server/node/server.cjs --name "risuai"
    sleep 2
    echo -e "${GREEN}✅ RisuAI 시작 완료${NC}"
fi

# ── 2. PM2 부팅 자동시작 등록
echo -e "${BLUE}▶ PM2 자동시작 설정 중...${NC}"
pm2 save --force > /dev/null 2>&1
STARTUP_CMD=$(pm2 startup 2>&1 | grep "sudo env" | head -1)
if [ ! -z "$STARTUP_CMD" ]; then
    eval "$STARTUP_CMD" > /dev/null 2>&1 || true
fi
echo -e "${GREEN}✅ 부팅 시 자동시작 등록됨${NC}"
echo ""

# ── 3. cloudflared 설치 확인
if ! command -v cloudflared &> /dev/null; then
    echo -e "${BLUE}📦 cloudflared 설치 중...${NC}"
    ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
    case "$ARCH" in
        amd64|x86_64)  CF_ARCH="amd64" ;;
        arm64|aarch64) CF_ARCH="arm64" ;;
        armv7l|armhf)  CF_ARCH="arm"   ;;
        *)             CF_ARCH="amd64" ;;
    esac
    CF_DEB="cloudflared-linux-${CF_ARCH}.deb"
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/${CF_DEB}" -o "/tmp/${CF_DEB}"
    $SUDO dpkg -i "/tmp/${CF_DEB}"
    rm -f "/tmp/${CF_DEB}"
    if ! command -v cloudflared &> /dev/null; then
        echo -e "${RED}❌ cloudflared 설치 실패${NC}"; exit 1
    fi
    echo -e "${GREEN}✅ cloudflared 설치 완료${NC}"
    echo ""
fi

# ── 4. 터널 모드 선택
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🎯 터널 모드 선택${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1) 🚀 Quick Tunnel  - 즉시 시작 (임시 URL, 계정 불필요)"
echo "2) 🔒 Named Tunnel  - 고정 URL  (Cloudflare 계정 필요)"
echo ""
read -p "선택 (1 또는 2): " MODE_CHOICE
echo ""

# ── 기존 터널 정리
stop_existing_tunnel() {
    pm2 delete cf-tunnel 2>/dev/null || true
    rm -f "$HOME/.cf-tunnel.pid"
}

# ── 터널을 pm2로 영구 등록
start_tunnel_persistent() {
    local CMD="$1"
    stop_existing_tunnel
    echo -e "${BLUE}🚀 터널 시작 중 (터미널 꺼도 유지됨)...${NC}"
    pm2 start --name "cf-tunnel" -- bash -c "$CMD" > /dev/null 2>&1
    pm2 save --force > /dev/null 2>&1
    sleep 3
}

# ── Quick Tunnel URL 추출
wait_for_url() {
    echo -e "${YELLOW}⏳ URL 생성 대기 중...${NC}"
    TIMEOUT=40; ELAPSED=0; URL=""
    while [ $ELAPSED -lt $TIMEOUT ]; do
        sleep 1; ELAPSED=$((ELAPSED + 1))
        URL=$(pm2 logs cf-tunnel --nostream --lines 100 2>/dev/null \
            | grep -o "https://[a-z0-9-]*\.trycloudflare\.com" | tail -1)
        [ ! -z "$URL" ] && break
        [ $((ELAPSED % 5)) -eq 0 ] && echo -n "."
    done
    echo ""
    echo "$URL"
}

# ══════════════════════════════════════════════════
if [ "$MODE_CHOICE" = "1" ]; then

    start_tunnel_persistent "cloudflared tunnel --url http://localhost:6001"
    URL=$(wait_for_url)

    if [ -z "$URL" ]; then
        echo -e "${RED}❌ URL을 가져오지 못했습니다. 로그 확인: pm2 logs cf-tunnel${NC}"
        exit 1
    fi
    echo "$URL" > ~/.cf-tunnel-url

elif [ "$MODE_CHOICE" = "2" ]; then

    # 인증 확인
    CF_CONFIG="$HOME/.cloudflared/cert.pem"
    if [ ! -f "$CF_CONFIG" ]; then
        echo -e "${YELLOW}🔑 Cloudflare 계정 인증${NC}"
        echo "출력된 URL을 복사해서 브라우저에서 열어 인증하세요."
        read -p "계속하려면 Enter..."
        cloudflared tunnel login
        [ ! -f "$CF_CONFIG" ] && echo -e "${RED}❌ 인증 실패${NC}" && exit 1
        echo -e "${GREEN}✅ 인증 완료!${NC}"; echo ""
    else
        echo -e "${GREEN}✅ 이미 인증되어 있습니다.${NC}"; echo ""
    fi

    # 터널 이름
    TUNNEL_NAME_FILE="$HOME/.cf-tunnel-name"
    if [ -f "$TUNNEL_NAME_FILE" ]; then
        TUNNEL_NAME=$(cat "$TUNNEL_NAME_FILE")
        echo -e "${GREEN}📌 기존 터널: ${CYAN}$TUNNEL_NAME${NC}"
        read -p "변경하시겠습니까? (y/n): " CHANGE_NAME
        if [ "$CHANGE_NAME" = "y" ]; then
            read -p "새 터널 이름: " NEW_NAME
            [ ! -z "$NEW_NAME" ] && TUNNEL_NAME="$NEW_NAME" && echo "$TUNNEL_NAME" > "$TUNNEL_NAME_FILE"
        fi
    else
        read -p "터널 이름 (Enter=자동생성): " TUNNEL_NAME
        [ -z "$TUNNEL_NAME" ] && TUNNEL_NAME="risu-$(date +%s | tail -c 6)"
        echo "$TUNNEL_NAME" > "$TUNNEL_NAME_FILE"
        echo -e "${BLUE}터널 이름: ${CYAN}$TUNNEL_NAME${NC}"; echo ""
    fi

    # 터널 생성
    if ! cloudflared tunnel list 2>/dev/null | grep -q "$TUNNEL_NAME"; then
        cloudflared tunnel create "$TUNNEL_NAME"
    else
        echo -e "${GREEN}✅ 기존 터널 사용${NC}"
    fi

    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')
    [ -z "$TUNNEL_ID" ] && echo -e "${RED}❌ 터널 ID 오류${NC}" && exit 1

    # 도메인
    read -p "도메인 (없으면 Enter): " USER_DOMAIN
    if [ -z "$USER_DOMAIN" ]; then
        TUNNEL_URL="${TUNNEL_ID}.cfargotunnel.com"
    else
        read -p "서브도메인 (예: risu): " SUBDOMAIN
        TUNNEL_URL="${SUBDOMAIN:+$SUBDOMAIN.}${USER_DOMAIN}"
        cloudflared tunnel route dns "$TUNNEL_NAME" "$TUNNEL_URL"
    fi

    echo "https://$TUNNEL_URL" > ~/.cf-tunnel-url

    mkdir -p ~/.cloudflared
    cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $TUNNEL_URL
    service: http://localhost:6001
  - service: http_status:404
EOF

    start_tunnel_persistent "cloudflared tunnel run"
    URL="https://$TUNNEL_URL"

else
    echo -e "${RED}❌ 잘못된 선택${NC}"; exit 1
fi

# ── 완료 화면
URL_FINAL=$(cat ~/.cf-tunnel-url 2>/dev/null || echo "$URL")
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               ✅ 모든 설정 완료!                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}🌍 공개 URL:${NC}"
echo ""
echo -e "   ${BOLD}${BLUE}${URL_FINAL}${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BOLD}🎉 이 창 닫고 컴퓨터 꺼도 계속 접속 가능해요!${NC}"
echo ""
echo -e "📋 유용한 명령어:"
echo -e "   상태 확인:    ${CYAN}pm2 status${NC}"
echo -e "   RisuAI 로그:  ${CYAN}pm2 logs risuai${NC}"
echo -e "   터널 로그:    ${CYAN}pm2 logs cf-tunnel${NC}"
echo -e "   URL 확인:     ${CYAN}cat ~/.cf-tunnel-url${NC}"
echo -e "   전체 재시작:  ${CYAN}pm2 restart all${NC}"
echo ""
