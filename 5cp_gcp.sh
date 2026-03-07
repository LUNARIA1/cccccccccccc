#!/bin/bash
set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  ☁️  Cloudflare Tunnel 설정      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════╝${NC}"
echo ""

# 루트 여부 확인
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Risu-AI 실행 여부 확인
if ! command -v pm2 &> /dev/null || ! pm2 list | grep -q "risuai"; then
    echo -e "${YELLOW}⚠️  Risu-AI가 실행되지 않았습니다.${NC}"
    echo "먼저 Risu-AI를 시작해주세요:"
    echo "  cd ~/Risu-AI && pm2 start server/node/server.cjs --name risuai"
    echo ""
    read -p "계속하시겠습니까? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        exit 0
    fi
fi

# cloudflared 설치 확인
if ! command -v cloudflared &> /dev/null; then
    echo -e "${BLUE}📦 cloudflared 설치 중...${NC}"

    # 아키텍처 감지
    ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
    case "$ARCH" in
        amd64|x86_64)  CF_ARCH="amd64" ;;
        arm64|aarch64) CF_ARCH="arm64" ;;
        armv7l|armhf)  CF_ARCH="arm"   ;;
        *)             CF_ARCH="amd64" ;;
    esac

    # cloudflared 최신 버전 .deb 다운로드 및 설치
    CF_DEB="cloudflared-linux-${CF_ARCH}.deb"
    curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/${CF_DEB}" -o "/tmp/${CF_DEB}"
    $SUDO dpkg -i "/tmp/${CF_DEB}"
    rm -f "/tmp/${CF_DEB}"

    if ! command -v cloudflared &> /dev/null; then
        echo -e "${RED}❌ 설치 실패${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ cloudflared 설치 완료!${NC}"
    echo ""
fi

# PATH 확인 및 추가
if ! echo $PATH | grep -q "$HOME/bin"; then
    export PATH=$HOME/bin:$PATH
    if ! grep -q 'export PATH=$HOME/bin:$PATH' ~/.bashrc; then
        echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
    fi
fi

# bin 디렉토리 생성
mkdir -p $HOME/bin

# 터널 모드 선택
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}🎯 터널 모드 선택${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1) 🚀 Quick Tunnel - 즉시 시작 (임시 URL, 계정 불필요)"
echo "2) 🔒 Named Tunnel - 고정 URL (Cloudflare 계정 필요)"
echo ""
read -p "선택 (1 또는 2): " MODE_CHOICE

if [ "$MODE_CHOICE" = "1" ]; then
    # ============ Quick Tunnel 모드 ============
    echo ""
    echo -e "${BLUE}🚀 Quick Tunnel 모드 선택됨${NC}"
    echo ""

    # 관리 스크립트 생성
    echo -e "${BLUE}📝 관리 스크립트 생성 중...${NC}"

    # 시작 스크립트
    cat > $HOME/bin/cf-tunnel-start << 'SCRIPT1'
#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PID_FILE="$HOME/.cf-tunnel.pid"

# 이미 실행 중인지 확인
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  터널이 이미 실행 중입니다. (PID: $PID)${NC}"
        echo ""

        if [ -f "$HOME/.cf-tunnel-url" ]; then
            URL=$(cat "$HOME/.cf-tunnel-url")
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BOLD}${GREEN}📍 공개 URL:${NC}"
            echo ""
            echo -e "${BOLD}${BLUE}   $URL${NC}"
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        fi
        exit 0
    fi
fi

echo -e "${BLUE}🚀 Cloudflare Quick Tunnel 시작 중...${NC}"
echo ""

# 기존 로그 삭제
rm -f ~/cf-tunnel.log

# 백그라운드에서 시작
nohup cloudflared tunnel --url http://localhost:6001 > ~/cf-tunnel.log 2>&1 &
echo $! > "$PID_FILE"

echo -e "${YELLOW}⏳ URL 생성 대기 중...${NC}"

# URL이 나올 때까지 최대 30초 대기
TIMEOUT=30
ELAPSED=0
URL=""

while [ $ELAPSED -lt $TIMEOUT ]; do
    sleep 1
    ELAPSED=$((ELAPSED + 1))

    # 프로세스가 살아있는지 확인
    if ! kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo -e "${RED}❌ 터널 시작 실패${NC}"
        echo ""
        echo "로그 내용:"
        cat ~/cf-tunnel.log
        rm -f "$PID_FILE"
        exit 1
    fi

    # URL 추출 시도
    URL=$(grep -o "https://[a-z0-9-]*\.trycloudflare\.com" ~/cf-tunnel.log 2>/dev/null | tail -1)

    if [ ! -z "$URL" ]; then
        break
    fi

    # 진행 표시
    if [ $((ELAPSED % 3)) -eq 0 ]; then
        echo -n "."
    fi
done

echo ""
echo ""

if [ -z "$URL" ]; then
    echo -e "${RED}❌ URL을 가져올 수 없습니다${NC}"
    echo ""
    echo "로그를 확인하세요: tail -f ~/cf-tunnel.log"
    exit 1
fi

# URL 저장
echo "$URL" > ~/.cf-tunnel-url

# 성공 메시지와 URL 크게 표시
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                  ✅ 터널 시작 완료!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}🌍 공개 URL:${NC}"
echo ""
echo -e "${BOLD}${BLUE}   $URL${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 이 URL을 브라우저에서 열어보세요!${NC}"
echo -e "${YELLOW}💡 터널을 중지하려면: ${GREEN}cf-tunnel-stop${NC}"
echo -e "${YELLOW}💡 로그 보기: ${GREEN}tail -f ~/cf-tunnel.log${NC}"
echo ""
SCRIPT1

    # 중지 스크립트
    cat > $HOME/bin/cf-tunnel-stop << 'SCRIPT_STOP'
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PID_FILE="$HOME/.cf-tunnel.pid"

if [ ! -f "$PID_FILE" ]; then
    echo -e "${YELLOW}⚠️  실행 중인 터널이 없습니다.${NC}"
    exit 0
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
    echo -e "${YELLOW}🛑 터널 중지 중... (PID: $PID)${NC}"
    kill "$PID"
    sleep 1

    # 강제 종료가 필요한 경우
    if kill -0 "$PID" 2>/dev/null; then
        kill -9 "$PID"
    fi

    rm -f "$PID_FILE"
    echo -e "${GREEN}✅ 터널이 중지되었습니다.${NC}"
else
    echo -e "${YELLOW}⚠️  프로세스가 이미 종료되었습니다.${NC}"
    rm -f "$PID_FILE"
fi
SCRIPT_STOP

    # 상태 확인 스크립트
    cat > $HOME/bin/cf-tunnel-status << 'SCRIPT_STATUS'
#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

PID_FILE="$HOME/.cf-tunnel.pid"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}☁️  Cloudflare Tunnel 상태${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -f "$HOME/.cf-tunnel-url" ]; then
    URL=$(cat $HOME/.cf-tunnel-url)
    echo -e "${BOLD}🌍 공개 URL: ${BLUE}$URL${NC}"
    echo ""
fi

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo -e "${GREEN}✅ 터널 실행 중 (PID: $PID)${NC}"
        echo ""
        echo "최근 로그 (마지막 10줄):"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        tail -n 10 ~/cf-tunnel.log 2>/dev/null || echo "로그 없음"
    else
        echo -e "${RED}❌ 터널 중지됨${NC}"
        rm -f "$PID_FILE"
    fi
else
    echo -e "${YELLOW}⚠️  터널이 실행되지 않았습니다.${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "명령어:"
echo "  시작: cf-tunnel-start"
echo "  중지: cf-tunnel-stop"
echo "  재시작: cf-tunnel-restart"
echo "  로그: tail -f ~/cf-tunnel.log"
SCRIPT_STATUS

    # 재시작 스크립트
    cat > $HOME/bin/cf-tunnel-restart << 'SCRIPT_RESTART'
#!/bin/bash
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 터널 재시작 중...${NC}"
cf-tunnel-stop
sleep 2
cf-tunnel-start
SCRIPT_RESTART

    # 실행 권한 부여
    chmod +x $HOME/bin/cf-tunnel-*

    echo -e "${GREEN}✅ 관리 스크립트 생성 완료!${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🚀 지금 바로 터널을 시작합니다!${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # ==== 여기서 바로 터널 시작! ====
    PID_FILE="$HOME/.cf-tunnel.pid"

    # 기존 터널 확인
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  터널이 이미 실행 중입니다.${NC}"
            if [ -f "$HOME/.cf-tunnel-url" ]; then
                URL=$(cat "$HOME/.cf-tunnel-url")
                echo ""
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${BOLD}${GREEN}📍 공개 URL:${NC}"
                echo ""
                echo -e "${BOLD}${BLUE}   $URL${NC}"
                echo ""
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            fi
            exit 0
        fi
    fi

    echo -e "${BLUE}🚀 Cloudflare Quick Tunnel 시작 중...${NC}"
    echo ""

    rm -f ~/cf-tunnel.log
    nohup cloudflared tunnel --url http://localhost:6001 > ~/cf-tunnel.log 2>&1 &
    echo $! > "$PID_FILE"

    echo -e "${YELLOW}⏳ URL 생성 대기 중...${NC}"

    TIMEOUT=30
    ELAPSED=0
    URL=""

    while [ $ELAPSED -lt $TIMEOUT ]; do
        sleep 1
        ELAPSED=$((ELAPSED + 1))

        if ! kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo ""
            echo -e "${RED}❌ 터널 시작 실패${NC}"
            echo ""
            echo "로그 내용:"
            cat ~/cf-tunnel.log
            rm -f "$PID_FILE"
            exit 1
        fi

        URL=$(grep -o "https://[a-z0-9-]*\.trycloudflare\.com" ~/cf-tunnel.log 2>/dev/null | tail -1)

        if [ ! -z "$URL" ]; then
            break
        fi

        if [ $((ELAPSED % 3)) -eq 0 ]; then
            echo -n "."
        fi
    done

    echo ""
    echo ""

    if [ -z "$URL" ]; then
        echo -e "${RED}❌ URL을 가져올 수 없습니다${NC}"
        echo ""
        echo "로그를 확인하세요: tail -f ~/cf-tunnel.log"
        exit 1
    fi

    echo "$URL" > ~/.cf-tunnel-url

    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ 터널 시작 완료!                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${GREEN}🌍 공개 URL:${NC}"
    echo ""
    echo -e "${BOLD}${BLUE}   $URL${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}💡 이 URL을 브라우저에서 열어보세요!${NC}"
    echo -e "${YELLOW}💡 터널을 중지하려면: ${GREEN}cf-tunnel-stop${NC}"
    echo -e "${YELLOW}💡 로그 보기: ${GREEN}tail -f ~/cf-tunnel.log${NC}"
    echo ""

elif [ "$MODE_CHOICE" = "2" ]; then
    # ============ Named Tunnel 모드 ============
    echo ""
    echo -e "${BLUE}🔒 Named Tunnel 모드 선택됨${NC}"
    echo ""

    # 인증 확인
    CF_CONFIG="$HOME/.cloudflared/cert.pem"
    if [ ! -f "$CF_CONFIG" ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}🔑 Cloudflare 계정 인증${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "Cloudflare 대시보드에서 인증을 진행합니다."
        echo "출력된 URL을 복사해 브라우저에서 열어 인증을 완료하세요."
        echo ""
        read -p "계속하려면 Enter를 누르세요..."

        cloudflared tunnel login

        if [ ! -f "$CF_CONFIG" ]; then
            echo -e "${RED}❌ 인증 실패${NC}"
            exit 1
        fi

        echo -e "${GREEN}✅ 인증 완료!${NC}"
        echo ""
    else
        echo -e "${GREEN}✅ 이미 인증되어 있습니다.${NC}"
        echo ""
    fi

    # 터널 이름 설정
    TUNNEL_NAME_FILE="$HOME/.cf-tunnel-name"
    if [ -f "$TUNNEL_NAME_FILE" ]; then
        TUNNEL_NAME=$(cat "$TUNNEL_NAME_FILE")
        echo -e "${GREEN}📌 기존 터널 이름: ${CYAN}$TUNNEL_NAME${NC}"
        echo ""
        read -p "새로운 이름으로 변경하시겠습니까? (y/n): " CHANGE_NAME
        if [ "$CHANGE_NAME" = "y" ]; then
            read -p "새로운 터널 이름: " NEW_NAME
            if [ ! -z "$NEW_NAME" ]; then
                TUNNEL_NAME="$NEW_NAME"
                echo "$TUNNEL_NAME" > "$TUNNEL_NAME_FILE"
            fi
        fi
    else
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}🎯 터널 이름 설정${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "터널 이름을 입력하세요 (영문/숫자/하이픈만)"
        echo "예: risu-tunnel, my-app"
        echo ""
        read -p "터널 이름 (Enter=자동생성): " TUNNEL_NAME

        if [ -z "$TUNNEL_NAME" ]; then
            TUNNEL_NAME="risu-$(date +%s | tail -c 8)"
            echo -e "${BLUE}자동 생성: ${CYAN}$TUNNEL_NAME${NC}"
        fi

        echo "$TUNNEL_NAME" > "$TUNNEL_NAME_FILE"
        echo ""
    fi

    # 터널 생성
    echo -e "${BLUE}🔍 터널 확인 중...${NC}"
    if ! cloudflared tunnel list 2>/dev/null | grep -q "$TUNNEL_NAME"; then
        echo -e "${YELLOW}📝 터널 생성 중...${NC}"
        cloudflared tunnel create "$TUNNEL_NAME"
        echo -e "${GREEN}✅ 터널 생성 완료!${NC}"
    else
        echo -e "${GREEN}✅ 터널이 이미 존재합니다.${NC}"
    fi
    echo ""

    # 터널 ID 가져오기
    TUNNEL_ID=$(cloudflared tunnel list | grep "$TUNNEL_NAME" | awk '{print $1}')

    if [ -z "$TUNNEL_ID" ]; then
        echo -e "${RED}❌ 터널 ID를 가져올 수 없습니다${NC}"
        exit 1
    fi

    # DNS 설정
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🌐 도메인 설정${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Cloudflare에 등록된 도메인이 있나요?"
    echo "예: example.com"
    echo ""
    read -p "도메인 입력 (없으면 Enter): " USER_DOMAIN

    if [ -z "$USER_DOMAIN" ]; then
        echo -e "${BLUE}💡 무료 .cfargotunnel.com 도메인 사용${NC}"
        TUNNEL_URL="${TUNNEL_ID}.cfargotunnel.com"
    else
        echo ""
        read -p "서브도메인 입력 (예: risu): " SUBDOMAIN
        if [ -z "$SUBDOMAIN" ]; then
            TUNNEL_URL="$USER_DOMAIN"
        else
            TUNNEL_URL="${SUBDOMAIN}.${USER_DOMAIN}"
        fi

        echo -e "${BLUE}📝 DNS 설정 중...${NC}"
        cloudflared tunnel route dns "$TUNNEL_NAME" "$TUNNEL_URL"
        echo -e "${GREEN}✅ DNS 설정 완료!${NC}"
    fi

    echo "https://$TUNNEL_URL" > ~/.cf-tunnel-url
    echo ""

    # config.yml 생성
    mkdir -p ~/.cloudflared
    cat > ~/.cloudflared/config.yml << EOF
tunnel: $TUNNEL_ID
credentials-file: $HOME/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $TUNNEL_URL
    service: http://localhost:6001
  - service: http_status:404
EOF

    echo -e "${GREEN}✅ 설정 완료!${NC}"
    echo ""

    # Named Tunnel용 시작 스크립트
    cat > $HOME/bin/cf-tunnel-start << 'SCRIPT_NAMED'
#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PID_FILE="$HOME/.cf-tunnel.pid"

# 이미 실행 중인지 확인
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  터널이 이미 실행 중입니다. (PID: $PID)${NC}"
        echo ""

        if [ -f "$HOME/.cf-tunnel-url" ]; then
            URL=$(cat "$HOME/.cf-tunnel-url")
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BOLD}${GREEN}📍 공개 URL:${NC}"
            echo ""
            echo -e "${BOLD}${BLUE}   $URL${NC}"
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        fi
        exit 0
    fi
fi

if [ ! -f "$HOME/.cloudflared/config.yml" ]; then
    echo -e "${RED}❌ 설정 파일이 없습니다. 5cp_gcp.sh를 먼저 실행하세요.${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 Cloudflare Named Tunnel 시작 중...${NC}"
echo ""

rm -f ~/cf-tunnel.log
nohup cloudflared tunnel run > ~/cf-tunnel.log 2>&1 &
echo $! > "$PID_FILE"

sleep 3

if kill -0 $(cat "$PID_FILE") 2>/dev/null; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ 터널 시작 완료!                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ -f "$HOME/.cf-tunnel-url" ]; then
        URL=$(cat "$HOME/.cf-tunnel-url")
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${GREEN}🌍 공개 URL (고정):${NC}"
        echo ""
        echo -e "${BOLD}${BLUE}   $URL${NC}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi

    echo ""
    echo -e "${YELLOW}💡 이 URL은 재시작해도 변경되지 않습니다!${NC}"
    echo -e "${YELLOW}💡 터널을 중지하려면: ${GREEN}cf-tunnel-stop${NC}"
    echo ""
else
    echo -e "${RED}❌ 터널 시작 실패${NC}"
    echo ""
    echo "로그 확인:"
    tail -n 20 ~/cf-tunnel.log
    rm -f "$PID_FILE"
    exit 1
fi
SCRIPT_NAMED

    # 공통 스크립트들 (stop, status, restart)
    cat > $HOME/bin/cf-tunnel-stop << 'SCRIPT_STOP2'
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PID_FILE="$HOME/.cf-tunnel.pid"

if [ ! -f "$PID_FILE" ]; then
    echo -e "${YELLOW}⚠️  실행 중인 터널이 없습니다.${NC}"
    exit 0
fi

PID=$(cat "$PID_FILE")

if kill -0 "$PID" 2>/dev/null; then
    echo -e "${YELLOW}🛑 터널 중지 중... (PID: $PID)${NC}"
    kill "$PID"
    sleep 1

    if kill -0 "$PID" 2>/dev/null; then
        kill -9 "$PID"
    fi

    rm -f "$PID_FILE"
    echo -e "${GREEN}✅ 터널이 중지되었습니다.${NC}"
else
    echo -e "${YELLOW}⚠️  프로세스가 이미 종료되었습니다.${NC}"
    rm -f "$PID_FILE"
fi
SCRIPT_STOP2

    cat > $HOME/bin/cf-tunnel-status << 'SCRIPT_STATUS2'
#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

PID_FILE="$HOME/.cf-tunnel.pid"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}☁️  Cloudflare Tunnel 상태${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -f "$HOME/.cf-tunnel-url" ]; then
    URL=$(cat $HOME/.cf-tunnel-url)
    echo -e "${BOLD}🌍 공개 URL: ${BLUE}$URL${NC}"
    echo ""
fi

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo -e "${GREEN}✅ 터널 실행 중 (PID: $PID)${NC}"
        echo ""
        echo "최근 로그 (마지막 10줄):"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        tail -n 10 ~/cf-tunnel.log 2>/dev/null || echo "로그 없음"
    else
        echo -e "${RED}❌ 터널 중지됨${NC}"
        rm -f "$PID_FILE"
    fi
else
    echo -e "${YELLOW}⚠️  터널이 실행되지 않았습니다.${NC}"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "명령어:"
echo "  시작: cf-tunnel-start"
echo "  중지: cf-tunnel-stop"
echo "  재시작: cf-tunnel-restart"
echo "  로그: tail -f ~/cf-tunnel.log"
SCRIPT_STATUS2

    cat > $HOME/bin/cf-tunnel-restart << 'SCRIPT_RESTART2'
#!/bin/bash
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔄 터널 재시작 중...${NC}"
cf-tunnel-stop
sleep 2
cf-tunnel-start
SCRIPT_RESTART2

    # 실행 권한 부여
    chmod +x $HOME/bin/cf-tunnel-*

    echo -e "${GREEN}✅ 관리 스크립트 생성 완료!${NC}"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🚀 지금 바로 터널을 시작합니다!${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    PID_FILE="$HOME/.cf-tunnel.pid"

    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo -e "${YELLOW}⚠️  터널이 이미 실행 중입니다.${NC}"
            echo ""
            URL=$(cat "$HOME/.cf-tunnel-url")
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${BOLD}${GREEN}📍 공개 URL:${NC}"
            echo ""
            echo -e "${BOLD}${BLUE}   $URL${NC}"
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            exit 0
        fi
    fi

    echo -e "${BLUE}🚀 Cloudflare Named Tunnel 시작 중...${NC}"
    echo ""

    rm -f ~/cf-tunnel.log
    nohup cloudflared tunnel run > ~/cf-tunnel.log 2>&1 &
    echo $! > "$PID_FILE"

    sleep 3

    if kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                  ✅ 터널 시작 완료!                      ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        URL=$(cat "$HOME/.cf-tunnel-url")
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${GREEN}🌍 공개 URL (고정):${NC}"
        echo ""
        echo -e "${BOLD}${BLUE}   $URL${NC}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}💡 이 URL은 재시작해도 변경되지 않습니다!${NC}"
        echo -e "${YELLOW}💡 터널을 중지하려면: ${GREEN}cf-tunnel-stop${NC}"
        echo ""
    else
        echo -e "${RED}❌ 터널 시작 실패${NC}"
        echo ""
        echo "로그 확인:"
        tail -n 20 ~/cf-tunnel.log
        rm -f "$PID_FILE"
        exit 1
    fi

else
    echo -e "${RED}❌ 잘못된 선택${NC}"
    exit 1
fi
