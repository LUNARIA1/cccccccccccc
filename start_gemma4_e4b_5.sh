#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════╗
# ║  start_gemma4_e4b.sh  v3                                     ║
# ║  Termux 초기화 상태에서 바로 실행 가능                          ║
# ║  Galaxy Z Fold 4 (12GB RAM) + Gemma 4 E4B + RisuAI           ║
# ║                                                               ║
# ║  curl -sL <RAW_URL> -o ~/start.sh                            ║
# ║  chmod +x ~/start.sh && ~/start.sh                           ║
# ╚═══════════════════════════════════════════════════════════════╝

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#  설정
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MODEL_REPO="HauhauCS/Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-GGUF"
MODEL_FILE="Gemma-4-E4B-Uncensored-HauhauCS-Aggressive-Q4_K_M.gguf"

# ── 공식 모델을 쓰려면 위 두 줄을 주석하고 아래를 활성화 ──
# MODEL_REPO="ggml-org/gemma-4-E4B-it-GGUF"
# MODEL_FILE="gemma-4-E4B-it-Q4_K_M.gguf"

CTX_SIZE=13000         # 컨텍스트 (OOM나면 8192로 줄이세요)
THREADS=4              # CPU 스레드 (발열 시 2로)
PORT=8080

# HuggingFace 토큰 (비공개/게이트 모델 다운로드 시 필요)
# 실행 시 입력받음 — 여기에 적으면 매번 안 물어봄
HF_TOKEN="${HF_TOKEN:-}"

WORK="$HOME/gemma4"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'
C='\033[0;36m'; B='\033[1m';    N='\033[0m'

info()  { printf "${G}[✓]${N} %s\n" "$*"; }
warn()  { printf "${Y}[!]${N} %s\n" "$*"; }
fail()  { printf "${R}[✗] %s${N}\n" "$*"; exit 1; }
step()  { printf "\n${C}${B}━━ %s ━━${N}\n" "$*"; }
line()  { printf "${C}─────────────────────────────────────────────${N}\n"; }

SERVER_PID=""
TUNNEL_PID=""
API_KEY=""

cleanup() {
    echo ""
    warn "종료 중..."
    [ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null
    [ -n "$TUNNEL_PID" ] && kill "$TUNNEL_PID" 2>/dev/null
    command -v termux-wake-unlock &>/dev/null && termux-wake-unlock 2>/dev/null
    exit 0
}
trap cleanup INT TERM EXIT

mkdir -p "$WORK"

# ──────────────────────────────────────────────
# 1. Termux 패키지 전체 세팅 (ICU 깨짐 방지 포함)
# ──────────────────────────────────────────────
step "1/6 Termux 패키지 세팅"

yes | pkg update 2>/dev/null
yes | pkg upgrade 2>/dev/null

pkg install -y \
    git cmake make clang curl \
    libicu libxml2 \
    2>/dev/null

# cmake 동작 확인
if ! cmake --version > /dev/null 2>&1; then
    warn "cmake 깨짐, 강제 재설치..."
    pkg install -y --reinstall libicu libxml2 cmake 2>/dev/null
    cmake --version > /dev/null 2>&1 || fail "cmake 설치 실패. Termux 앱 재설치 후 재시도"
fi

info "패키지 준비 완료"

# 슬립 방지
if command -v termux-wake-lock &>/dev/null; then
    termux-wake-lock 2>/dev/null && info "화면 꺼짐 방지 활성화"
else
    warn "Termux:API 앱 미설치 → 화면 꺼지면 작업 중단될 수 있음"
fi

# 저장공간 확인
AVAIL_MB=$(df "$HOME" 2>/dev/null | awk 'NR==2{print int($4/1024)}')
if [ -n "$AVAIL_MB" ] && [ "$AVAIL_MB" -lt 7000 ]; then
    warn "저장공간 부족 가능 (${AVAIL_MB}MB 남음, 7GB+ 권장)"
fi

# ──────────────────────────────────────────────
# 2. llama.cpp 소스 빌드
# ──────────────────────────────────────────────
step "2/6 llama.cpp 빌드"
LLAMA_DIR="$WORK/llama.cpp"
SERVER_BIN="$LLAMA_DIR/build/bin/llama-server"

if [ -x "$SERVER_BIN" ]; then
    info "llama-server 이미 빌드됨 → 스킵"
else
    if [ -d "$LLAMA_DIR/.git" ]; then
        info "기존 소스 사용"
    else
        rm -rf "$LLAMA_DIR"
        info "llama.cpp 클론 중..."
        git clone --depth 1 https://github.com/ggml-org/llama.cpp "$LLAMA_DIR"
    fi

    cd "$LLAMA_DIR"
    info "빌드 중... (첫 실행 시 3~5분 소요)"

    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        2>&1 | tail -2

    cmake --build build --config Release -j"$(nproc)" --target llama-server \
        2>&1 | tail -5

    [ -x "$SERVER_BIN" ] || fail "빌드 실패. 확인: cd $LLAMA_DIR && cmake --build build 2>&1 | tail -30"
    info "빌드 완료"
    cd "$HOME"
fi

# ──────────────────────────────────────────────
# 3. 모델 다운로드
# ──────────────────────────────────────────────
step "3/6 모델 다운로드"
MODEL_DIR="$WORK/models"
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"
mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_PATH" ]; then
    SIZE_MB=$(du -m "$MODEL_PATH" | cut -f1)
    if [ "$SIZE_MB" -lt 100 ]; then
        warn "파일이 너무 작음 (${SIZE_MB}MB), 재다운로드"
        rm -f "$MODEL_PATH"
    else
        info "모델 존재 (${SIZE_MB}MB) → 스킵"
    fi
fi

if [ ! -f "$MODEL_PATH" ]; then
    MODEL_URL="https://huggingface.co/${MODEL_REPO}/resolve/main/${MODEL_FILE}"

    # HF 토큰 확인 — 없으면 물어봄
    if [ -z "$HF_TOKEN" ]; then
        echo ""
        warn "비공개 모델은 HuggingFace 토큰이 필요합니다"
        warn "발급: https://huggingface.co/settings/tokens (Read 권한)"
        echo ""
        printf "  HF Token (hf_...): "
        read -r HF_TOKEN
        echo ""
    fi

    HF_AUTH=()
    if [ -n "$HF_TOKEN" ]; then
        HF_AUTH=(-H "Authorization: Bearer $HF_TOKEN")
        info "HuggingFace 토큰 적용됨"
    fi

    info "다운로드: $MODEL_FILE"
    warn "~5.3GB — Wi-Fi 권장"
    echo ""
    curl -L -C - --progress-bar "${HF_AUTH[@]}" -o "$MODEL_PATH" "$MODEL_URL" \
        || fail "다운로드 실패. URL 확인: $MODEL_URL"

    # 다운로드 검증 (에러 페이지가 저장됐을 수 있음)
    DL_SIZE=$(du -m "$MODEL_PATH" 2>/dev/null | cut -f1)
    if [ -z "$DL_SIZE" ] || [ "$DL_SIZE" -lt 100 ]; then
        DL_CONTENT=$(head -c 100 "$MODEL_PATH" 2>/dev/null)
        rm -f "$MODEL_PATH"
        fail "다운로드 실패 (파일이 너무 작음). 응답: $DL_CONTENT"
    fi

    info "다운로드 완료"
fi

# ──────────────────────────────────────────────
# 4. cloudflared 설치
# ──────────────────────────────────────────────
step "4/6 Cloudflare 터널 준비"
CF_BIN="$WORK/cloudflared"

if [ -x "$CF_BIN" ]; then
    info "cloudflared 이미 설치됨"
else
    info "cloudflared 다운로드 중..."
    curl -L --progress-bar \
        -o "$CF_BIN" \
        "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    chmod +x "$CF_BIN"
    info "설치 완료"
fi

# ──────────────────────────────────────────────
# 5. llama-server 시작
# ──────────────────────────────────────────────
step "5/6 서버 시작"

API_KEY="sk-$(head -c 30 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)"

pkill -f "llama-server" 2>/dev/null || true
pkill -f "cloudflared" 2>/dev/null || true
sleep 1

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

info "모델 로딩 중... (1~3분)"
READY=0
for _ in $(seq 1 180); do
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
        echo ""
        warn "서버 비정상 종료. 로그:"
        tail -20 "$WORK/server.log" 2>/dev/null
        fail "llama-server 크래시"
    fi
    if curl -sf "http://127.0.0.1:${PORT}/health" 2>/dev/null | grep -q 'ok\|status'; then
        READY=1; break
    fi
    printf "."
    sleep 2
done
echo ""
[ "$READY" -ne 1 ] && fail "서버 타임아웃. cat $WORK/server.log 로 확인"
info "서버 준비 완료"

MODEL_ID=$(curl -sf -H "Authorization: Bearer $API_KEY" \
    "http://127.0.0.1:$PORT/v1/models" 2>/dev/null \
    | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
    | sed 's/.*"id"[[:space:]]*:[[:space:]]*"//;s/"//') || true
[ -z "$MODEL_ID" ] && MODEL_ID="$MODEL_FILE"

# ──────────────────────────────────────────────
# 6. Cloudflare 터널
# ──────────────────────────────────────────────
step "6/6 Cloudflare 터널"

info "터널 생성 중..."
"$CF_BIN" tunnel --url "http://127.0.0.1:$PORT" \
    > "$WORK/tunnel.log" 2>&1 &
TUNNEL_PID=$!

TUNNEL_URL=""
for _ in $(seq 1 30); do
    TUNNEL_URL=$(grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' "$WORK/tunnel.log" 2>/dev/null | head -1)
    [ -n "$TUNNEL_URL" ] && break
    sleep 2
done
[ -z "$TUNNEL_URL" ] && fail "터널 실패. cat $WORK/tunnel.log 로 확인"
info "터널 생성 완료"

# ──────────────────────────────────────────────
# 완료
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
printf "  ${C}%-12s${N} %s\n"         "KV Cache"  "q4_0"
printf "  ${C}%-12s${N} %s\n"         "Local"     "http://127.0.0.1:${PORT}"
line
echo ""
printf "${Y}  Ctrl+C 로 종료${N}\n"
echo ""

wait "$SERVER_PID" 2>/dev/null
