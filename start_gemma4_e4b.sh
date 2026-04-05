#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════╗
# ║  start_gemma4_e4b.sh                                         ║
# ║  Galaxy Z Fold 4 (12GB RAM) 에서 Gemma 4 E4B 구동             ║
# ║  Cloudflare 터널 + RisuAI 연결용                              ║
# ║                                                               ║
# ║  사용법 (Termux):                                             ║
# ║  curl -sL <RAW_URL> -o ~/start.sh                            ║
# ║  chmod +x ~/start.sh && ~/start.sh                           ║
# ╚═══════════════════════════════════════════════════════════════╝
set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  설정 - 필요하면 여기를 수정하세요
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# 모델 설정 (HuggingFace repo/파일명)
# 기본값: 공식 Gemma 4 E4B Q4_K_M
# MODEL_REPO="ggml-org/gemma-4-E4B-it-GGUF"
# MODEL_FILE="gemma-4-E4B-it-Q4_K_M.gguf"

# ── 언센서드 모델을 쓰려면 위 두 줄을 주석하고 아래를 활성화 ──
MODEL_REPO="HauhauCS/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-GGUF"
MODEL_FILE="Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf"

# 추론 설정 (12GB RAM 기기 최적화)
CTX_SIZE=13000          # 컨텍스트 길이 (8192~12288 권장, OOM 시 줄이세요)
THREADS=4              # CPU 스레드 (Fold4: 4 권장, 발열 시 줄이세요)
PORT=5001              # 로컬 서버 포트

# 작업 디렉토리
WORK="$HOME/gemma4"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  아래부터는 수정하지 않아도 됩니다
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; B='\033[1m';    N='\033[0m'

info()  { printf "${G}[✓]${N} %s\n" "$*"; }
warn()  { printf "${Y}[!]${N} %s\n" "$*"; }
fail()  { printf "${R}[✗]${N} %s\n" "$*"; exit 1; }
step()  { printf "\n${C}${B}━━ %s ━━${N}\n" "$*"; }
line()  { printf "${C}─────────────────────────────────────────────${N}\n"; }

SERVER_PID=""
TUNNEL_PID=""
API_KEY=""

cleanup() {
    echo ""
    warn "종료 중..."
    [ -n "$SERVER_PID" ]  && kill "$SERVER_PID"  2>/dev/null
    [ -n "$TUNNEL_PID" ]  && kill "$TUNNEL_PID"  2>/dev/null
    command -v termux-wake-unlock &>/dev/null && termux-wake-unlock 2>/dev/null
    exit 0
}
trap cleanup INT TERM EXIT

# ──────────────────────────────────────────────
# 0. 사전 점검
# ──────────────────────────────────────────────
step "0/5 사전 점검"

# Termux 환경 확인
if [ ! -d "/data/data/com.termux" ]; then
    fail "이 스크립트는 Termux 환경에서만 실행할 수 있습니다."
fi

# 저장공간 확인 (~7GB 필요)
AVAIL_MB=$(df "$HOME" 2>/dev/null | awk 'NR==2{print int($4/1024)}')
if [ -n "$AVAIL_MB" ] && [ "$AVAIL_MB" -lt 7000 ]; then
    warn "저장공간이 부족할 수 있습니다 (남은 공간: ${AVAIL_MB}MB, 권장: 7GB+)"
    warn "5초 후 계속합니다... (Ctrl+C로 중단)"
    sleep 5
fi

# 슬립 방지
if command -v termux-wake-lock &>/dev/null; then
    termux-wake-lock 2>/dev/null && info "화면 꺼짐 방지 활성화"
else
    warn "termux-wake-lock 없음 → Termux:API 앱 설치 권장 (화면 꺼지면 멈출 수 있음)"
fi

mkdir -p "$WORK"
info "작업 디렉토리: $WORK"

# ──────────────────────────────────────────────
# 1. 패키지 설치
# ──────────────────────────────────────────────
step "1/5 패키지 설치"
pkg update -y 2>/dev/null
pkg install -y git cmake make clang curl 2>/dev/null
info "패키지 설치 완료"

# ──────────────────────────────────────────────
# 2. llama.cpp 빌드
# ──────────────────────────────────────────────
step "2/5 llama.cpp 빌드"
LLAMA_DIR="$WORK/llama.cpp"
SERVER_BIN="$LLAMA_DIR/build/bin/llama-server"

if [ -x "$SERVER_BIN" ]; then
    info "llama-server 이미 빌드됨 → 스킵"
else
    if [ -d "$LLAMA_DIR" ]; then
        info "기존 소스 업데이트"
        cd "$LLAMA_DIR" && git pull --ff-only 2>/dev/null || true
    else
        info "llama.cpp 클론 중..."
        git clone --depth 1 https://github.com/ggml-org/llama.cpp "$LLAMA_DIR"
    fi

    cd "$LLAMA_DIR"
    info "빌드 중... (수 분 소요)"
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DGGML_OPENMP=ON 2>&1 | tail -3
    cmake --build build --config Release -j"$(nproc)" --target llama-server 2>&1 | tail -5

    [ -x "$SERVER_BIN" ] || fail "llama-server 빌드 실패"
    info "빌드 완료"
fi

# ──────────────────────────────────────────────
# 3. 모델 다운로드
# ──────────────────────────────────────────────
step "3/5 모델 다운로드"
MODEL_DIR="$WORK/models"
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"
mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_PATH" ]; then
    SIZE_MB=$(du -m "$MODEL_PATH" | cut -f1)
    info "모델 파일 존재 (${SIZE_MB}MB) → 스킵"
else
    MODEL_URL="https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILE}"
    info "다운로드: $MODEL_FILE"
    warn "~5.3GB — Wi-Fi 환경에서 진행하세요"
    echo ""

    curl -L -C - --progress-bar \
        -o "$MODEL_PATH" \
        "$MODEL_URL" \
    || fail "다운로드 실패. URL을 확인하세요: $MODEL_URL"

    info "다운로드 완료"
fi

# ──────────────────────────────────────────────
# 4. cloudflared 설치
# ──────────────────────────────────────────────
step "4/5 Cloudflare 터널 준비"
CF_BIN="$WORK/cloudflared"

if [ -x "$CF_BIN" ]; then
    info "cloudflared 이미 설치됨"
else
    info "cloudflared 다운로드 중..."
    CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    curl -L --progress-bar -o "$CF_BIN" "$CF_URL" \
        || fail "cloudflared 다운로드 실패"
    chmod +x "$CF_BIN"
    info "cloudflared 설치 완료"
fi

# ──────────────────────────────────────────────
# 5. 서버 + 터널 시작
# ──────────────────────────────────────────────
step "5/5 서버 시작"

# API 키 생성
API_KEY="sk-$(head -c 30 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)"

# 이전 프로세스 정리
pkill -f "llama-server.*$PORT" 2>/dev/null || true
pkill -f "cloudflared.*tunnel" 2>/dev/null || true
sleep 1

# llama-server 시작
info "llama-server 시작 중..."
"$SERVER_BIN" \
    --model "$MODEL_PATH" \
    --ctx-size "$CTX_SIZE" \
    --threads "$THREADS" \
    --parallel 1 \
    --cache-type-k q4_0 \
    --cache-type-v q4_0 \
    --host 127.0.0.1 \
    --port "$PORT" \
    --api-key "$API_KEY" \
    --log-disable \
    > "$WORK/server.log" 2>&1 &
SERVER_PID=$!

# 서버 준비 대기
info "모델 로딩 중... (1~3분 소요, 기다려 주세요)"
READY=0
for _ in $(seq 1 180); do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo ""
        fail "서버 비정상 종료. 로그 확인:\n  cat $WORK/server.log"
    fi
    if curl -sf http://127.0.0.1:"$PORT"/health 2>/dev/null | grep -q 'ok\|no slot\|status'; then
        READY=1
        break
    fi
    printf "."
    sleep 2
done
echo ""

if [ "$READY" -ne 1 ]; then
    fail "서버 시작 타임아웃 (6분). 로그 확인:\n  cat $WORK/server.log"
fi
info "서버 준비 완료"

# 모델 ID 조회
MODEL_ID=$(curl -sf \
    -H "Authorization: Bearer $API_KEY" \
    "http://127.0.0.1:$PORT/v1/models" 2>/dev/null \
    | grep -o '"id" *: *"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"/\1/' \
) || true
[ -z "$MODEL_ID" ] && MODEL_ID="$MODEL_FILE"

# Cloudflare 터널 시작
info "Cloudflare 터널 생성 중..."
"$CF_BIN" tunnel --url "http://127.0.0.1:$PORT" \
    > "$WORK/tunnel.log" 2>&1 &
TUNNEL_PID=$!

TUNNEL_URL=""
for _ in $(seq 1 30); do
    TUNNEL_URL=$(grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' "$WORK/tunnel.log" 2>/dev/null | head -1)
    [ -n "$TUNNEL_URL" ] && break
    sleep 2
done

if [ -z "$TUNNEL_URL" ]; then
    fail "터널 생성 실패. 로그 확인:\n  cat $WORK/tunnel.log"
fi
info "터널 생성 완료"

# ──────────────────────────────────────────────
# 연결 정보 출력
# ──────────────────────────────────────────────
echo ""
echo ""
printf "${G}${B}╔═══════════════════════════════════════════════╗${N}\n"
printf "${G}${B}║       Gemma 4 E4B 서버 가동 완료!             ║${N}\n"
printf "${G}${B}╚═══════════════════════════════════════════════╝${N}\n"
echo ""
printf "${B} RisuAI 설정값${N}\n"
line
printf "  ${C}%-12s${N} %s\n" "URL"      "${TUNNEL_URL}/v1"
printf "  ${C}%-12s${N} %s\n" "API Key"  "$API_KEY"
printf "  ${C}%-12s${N} %s\n" "Model ID" "$MODEL_ID"
line
echo ""
printf "${B} 서버 상태${N}\n"
line
printf "  ${C}%-12s${N} %s tokens\n"  "Context"   "$CTX_SIZE"
printf "  ${C}%-12s${N} %s\n"         "Threads"   "$THREADS"
printf "  ${C}%-12s${N} %s\n"         "KV Cache"  "q4_0 (양자화)"
printf "  ${C}%-12s${N} %s\n"         "Local"     "http://127.0.0.1:${PORT}"
line
echo ""
printf "${Y}  Ctrl+C 로 종료  |  로그: $WORK/server.log${N}\n"
echo ""

# 서버 프로세스 대기 (Ctrl+C까지 유지)
wait "$SERVER_PID" 2>/dev/null
