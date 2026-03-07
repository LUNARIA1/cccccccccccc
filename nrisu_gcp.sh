#!/bin/bash

set -e  # 에러 발생 시 중단

echo "🚀 RisuAI 설치를 시작합니다 (Google Cloud VM)..."

# 루트 여부 확인
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

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

# NODE_OPTIONS 환경변수 설정
echo "⚙️  환경변수 설정 중..."
BASHRC="$HOME/.bashrc"
if ! grep -q "NODE_OPTIONS=--max_old_space_size=4096" "$BASHRC"; then
    echo 'export NODE_OPTIONS=--max_old_space_size=4096' >> "$BASHRC"
fi

# 환경변수 즉시 적용
export NODE_OPTIONS=--max_old_space_size=4096

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
