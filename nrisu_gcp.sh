#!/bin/bash

set -e  # 에러 발생 시 중단

echo "🚀 RisuAI 설치를 시작합니다 (Google Cloud VM)..."

# 루트 여부 확인
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# ── 스왑 설정 ──────────────────────────────────────────────
echo "💾 메모리 확인 중..."
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
SWAP_NOW_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')

echo "   RAM: ${TOTAL_RAM_GB}GB / 스왑: $((SWAP_NOW_KB / 1024 / 1024))GB"

# RAM이 4GB 미만이면 스왑 자동 설정
if [ "$TOTAL_RAM_GB" -lt 4 ] && [ "$SWAP_NOW_KB" -lt 1048576 ]; then
    echo "⚠️  RAM이 ${TOTAL_RAM_GB}GB로 부족합니다. 스왑을 설정합니다..."

    # 기존 스왑파일 제거
    if [ -f /swapfile ]; then
        $SUDO swapoff /swapfile 2>/dev/null || true
        $SUDO rm -f /swapfile
    fi

    # RAM의 2배 또는 최소 4GB 스왑 생성
    SWAP_SIZE_GB=4
    if [ "$TOTAL_RAM_GB" -ge 2 ]; then
        SWAP_SIZE_GB=$((TOTAL_RAM_GB * 2))
    fi

    echo "📝 ${SWAP_SIZE_GB}GB 스왑 생성 중..."
    $SUDO fallocate -l ${SWAP_SIZE_GB}G /swapfile
    $SUDO chmod 600 /swapfile
    $SUDO mkswap /swapfile
    $SUDO swapon /swapfile

    # 재부팅 후에도 유지
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' | $SUDO tee -a /etc/fstab > /dev/null
    fi

    # 스왑 사용 적극성 낮춤 (RAM 최대한 쓰고 스왑은 나중에)
    $SUDO sysctl vm.swappiness=10 > /dev/null
    if ! grep -q 'vm.swappiness' /etc/sysctl.conf; then
        echo 'vm.swappiness=10' | $SUDO tee -a /etc/sysctl.conf > /dev/null
    fi

    echo "✅ 스왑 ${SWAP_SIZE_GB}GB 설정 완료!"
else
    echo "✅ 메모리 충분, 스왑 설정 불필요"
fi
echo ""

# apt 패키지 업데이트
echo "📦 패키지 업데이트 중..."
$SUDO apt update -y
$SUDO apt upgrade -y

# 필요한 패키지 설치
echo "📦 필수 패키지 설치 중..."
$SUDO apt install -y git curl

# Node.js 설치 (LTS 버전, NodeSource 저장소 사용)
echo "📦 Node.js 설치 중..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO bash -
    $SUDO apt install -y nodejs
fi
echo "✅ Node.js 버전: $(node -v)"

# pnpm 설치
echo "📥 pnpm 설치 중..."
npm install -g pnpm

# Git 클론
INSTALL_DIR="$HOME/Risu-AI"
echo "📥 RisuAI 다운로드 중..."
if [ -d "$INSTALL_DIR" ]; then
    echo "⚠️  이미 설치된 디렉토리가 있습니다. 삭제 후 다시 설치합니다..."
    rm -rf "$INSTALL_DIR"
fi
git clone "https://github.com/kwaroran/RisuAI.git" "$INSTALL_DIR"
cd "$INSTALL_DIR"

# NODE_OPTIONS 환경변수 설정 (실제 가용 메모리 기준으로 자동 계산)
echo "⚙️  환경변수 설정 중..."
TOTAL_MEM_MB=$(( ($(grep MemTotal /proc/meminfo | awk '{print $2}') + $(grep SwapTotal /proc/meminfo | awk '{print $2}')) / 1024 ))
NODE_MEM_MB=$(( TOTAL_MEM_MB * 75 / 100 ))  # 전체의 75%만 Node에 할당
echo "   Node.js 메모리 한도: ${NODE_MEM_MB}MB (전체 ${TOTAL_MEM_MB}MB의 75%)"

BASHRC="$HOME/.bashrc"
# 기존 NODE_OPTIONS 제거 후 새로 추가
sed -i '/NODE_OPTIONS/d' "$BASHRC"
echo "export NODE_OPTIONS=--max_old_space_size=${NODE_MEM_MB}" >> "$BASHRC"

# 환경변수 즉시 적용
export NODE_OPTIONS=--max_old_space_size=${NODE_MEM_MB}

# 의존성 설치
echo "📦 의존성 설치 중..."
pnpm install

# PM2 설치
echo "📦 PM2 설치 중..."
npm install -g pm2@latest

# 빌드
echo "🔨 빌드 중..."
pnpm run build

# PM2로 서버 시작
echo "🚀 서버 시작 중..."
pm2 start server/node/server.cjs --name "risuai"

# PM2 부팅 시 자동 시작 설정
echo "⚙️  PM2 자동 시작 설정 중..."
pm2 save
pm2 startup | tail -1 | $SUDO bash || true

echo ""
echo "✅ 설치 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 설치 위치: $INSTALL_DIR"
echo "🔍 서버 상태: pm2 status"
echo "📋 서버 로그: pm2 logs risuai"
echo "🔄 서버 재시작: pm2 restart risuai"
echo "⏹️  서버 중지: pm2 stop risuai"
echo ""
echo "🌐 외부 접속 허용이 필요하다면 GCP 방화벽에서 포트를 열어주세요."
echo "   (VPC 네트워크 → 방화벽 → 인바운드 규칙 추가)"
