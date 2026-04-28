#!/data/data/com.termux/files/usr/bin/bash

set -e  # 에러 발생 시 중단

echo "🚀 RisuAI 설치를 시작합니다 (Termux)..."

# Termux 패키지 업데이트
echo "📦 패키지 업데이트 중..."
pkg update -y
pkg upgrade -y

# 필요한 패키지 설치
echo "📦 필수 패키지 설치 중..."
pkg install -y nodejs git

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
if ! grep -q "NODE_OPTIONS=--max_old_space_size=4096" "$HOME/.bashrc"; then
    echo 'export NODE_OPTIONS=--max_old_space_size=4096' >> "$HOME/.bashrc"
fi

# 환경변수 즉시 적용
export NODE_OPTIONS=--max_old_space_size=4096

# 의존성 설치
echo "📦 의존성 설치 중..."
pnpm install

# PM2 설치
echo "📦 PM2 설치 중..."
npm install -g pm2@latest

# Temporary upstream build fix for duplicate `let betas = []` in anthropic.ts.
echo "Applying RisuAI build compatibility patch..."
node <<'NODE'
const fs = require('fs');
const file = 'src/ts/process/request/anthropic.ts';
let text = fs.readFileSync(file, 'utf8');
let seen = false;
let patched = false;

text = text.replace(/^(\s*)let betas(?::[^=]+)?=\s*\[\];\s*$/gm, (line, indent) => {
  if (!seen) {
    seen = true;
    return line;
  }

  patched = true;
  return `${indent}betas = [];`;
});

fs.writeFileSync(file, text);
console.log(patched ? 'Patched duplicate betas declaration.' : 'No duplicate betas declaration found.');
NODE

# 빌드
echo "🔨 빌드 중..."
pnpm run build

# PM2로 서버 시작
echo "🚀 서버 시작 중..."
pm2 start server/node/server.cjs

echo ""
echo "✅ 설치 완료!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📍 설치 위치: $INSTALL_DIR"
echo "🔍 서버 상태: pm2 status"
echo "📋 서버 로그: pm2 logs"
echo "🔄 서버 재시작: pm2 restart server"
echo "⏹️  서버 중지: pm2 stop server"
