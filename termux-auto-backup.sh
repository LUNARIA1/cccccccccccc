#!/bin/bash

# --- 색상 설정 ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  PocketRisu 자동 백업 설정 스크립트   ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo -e "${YELLOW}※ 주의: 이 스크립트는 사전에 rclone config 설정이 완료되어 있어야 합니다.${NC}"
echo -e "${YELLOW}※ rclone 원격 이름은 'gdrive'로 가정합니다.${NC}\n"

BACKUP_SCRIPT_PATH="$HOME/backup_risu_cron.sh"

# 기존에 설정된 백업이 있는지 확인하고 안내
if [ -f "$BACKUP_SCRIPT_PATH" ]; then
    echo -e "${YELLOW}[안내] 이미 백업이 설정되어 있습니다.${NC}"
    echo -e "새로운 주기를 선택하시면 기존 설정은 자동으로 덮어씌워집니다.\n"
fi

# 1단계: 백업 주기 선택 받기 (0번 삭제 옵션 추가)
echo "원하시는 작업을 선택해주세요:"
echo -e "${RED}0) ❌ 자동 백업 완전히 중지 및 삭제${NC}"
echo "1) 1시간마다 백업"
echo "2) 3시간마다 백업"
echo "3) 6시간마다 백업"
echo "4) 12시간마다 백업"
echo "5) 24시간마다 백업 (매일 자정)"
echo "---------------------------------------"

# curl | bash 환경에서 키보드 입력을 강제로 받기 위해 </dev/tty 유지
read -p "번호를 입력하세요 (0-5): " INTERVAL_CHOICE </dev/tty

# 0번 선택 시 백업 삭제 로직
if [ "$INTERVAL_CHOICE" == "0" ]; then
    echo -e "\n▶ 기존 백업 설정을 삭제합니다..."
    
    # 크론탭에서 제거
    CRON_TMP_FILE="$TMPDIR/mycron"
    crontab -l 2>/dev/null | grep -v "backup_risu_cron.sh" > "$CRON_TMP_FILE"
    crontab "$CRON_TMP_FILE"
    rm "$CRON_TMP_FILE"
    
    # 스크립트 파일 삭제
    rm -f "$BACKUP_SCRIPT_PATH"
    
    echo -e "${RED}자동 백업 스케줄이 완전히 해제되었습니다.${NC}"
    exit 0
fi

# 주기 설정 로직
case $INTERVAL_CHOICE in
    1) CRON_TIME="0 * * * *" ; STR_TIME="1시간" ;;
    2) CRON_TIME="0 */3 * * *" ; STR_TIME="3시간" ;;
    3) CRON_TIME="0 */6 * * *" ; STR_TIME="6시간" ;;
    4) CRON_TIME="0 */12 * * *" ; STR_TIME="12시간" ;;
    5) CRON_TIME="0 0 * * *" ; STR_TIME="24시간" ;;
    *) echo -e "\n잘못된 입력입니다. 기본값인 3시간으로 설정합니다." ; CRON_TIME="0 */3 * * *" ; STR_TIME="3시간" ;;
esac

echo -e "\n▶ [${STR_TIME}] 주기로 설정을 시작합니다...\n"

# 2단계: 실제 실행될 백업 스크립트(payload) 생성
cat << 'EOF' > "$BACKUP_SCRIPT_PATH"
#!/bin/bash

# [핵심 해결책] Termux의 환경 변수와 경로를 강제로 불러오기
source /data/data/com.termux/files/usr/etc/profile
export PATH=/data/data/com.termux/files/usr/bin:$PATH
export HOME=/data/data/com.termux/files/home

# 경로 및 변수 설정
SOURCE_DIR="$HOME/PocketRisu/save"
BACKUP_TEMP_DIR="$HOME/risu_tmp_backups"
TIMESTAMP=$(date +"%Y%m%d-%H%M")
BACKUP_FILE="save-${TIMESTAMP}.tar.gz"
RCLONE_REMOTE="gdrive:PocketRisu_Backups" 

# 소스 폴더 존재 여부 확인
if [ ! -d "$SOURCE_DIR" ]; then
    echo "[$(date +"%Y-%m-%d %H:%M")] 오류: PocketRisu/save 폴더가 없습니다." >> "$HOME/backup_log.txt"
    exit 1
fi

# 압축 진행
mkdir -p "$BACKUP_TEMP_DIR"

# [안전장치] tar 압축이 '완벽하게 성공'했을 때만 업로드 진행
if tar -czf "$BACKUP_TEMP_DIR/$BACKUP_FILE" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"; then
    rclone copy "$BACKUP_TEMP_DIR/$BACKUP_FILE" "$RCLONE_REMOTE"
    
    if [ $? -eq 0 ]; then
        echo "[${TIMESTAMP}] 백업 및 업로드 성공 (${BACKUP_FILE})" >> "$HOME/backup_log.txt"
    else
        echo "[${TIMESTAMP}] 구글 드라이브 업로드 실패" >> "$HOME/backup_log.txt"
    fi
else
    # 압축 실패 시 0바이트 파일을 업로드하지 않고 중단
    echo "[${TIMESTAMP}] tar 압축 실패 (0바이트 방지)" >> "$HOME/backup_log.txt"
fi

# 임시 파일 삭제
rm -f "$BACKUP_TEMP_DIR/$BACKUP_FILE"
EOF

# 스크립트에 실행 권한 부여
chmod +x "$BACKUP_SCRIPT_PATH"
echo "- 백업 쉘 스크립트 덮어쓰기 완료: $BACKUP_SCRIPT_PATH"

# 3단계: 크론탭(Crontab) 등록
CRON_TMP_FILE="$TMPDIR/mycron"
crontab -l 2>/dev/null | grep -v "backup_risu_cron.sh" > "$CRON_TMP_FILE"
echo "$CRON_TIME $BACKUP_SCRIPT_PATH" >> "$CRON_TMP_FILE"
crontab "$CRON_TMP_FILE"
rm "$CRON_TMP_FILE"

echo "- 스케줄러(Crontab) 갱신 완료"

# 4단계: 스케줄러 데몬(crond) 실행 상태 확인 및 구동
if ! pgrep -x "crond" > /dev/null
then
    crond
    echo "- 백그라운드 스케줄러(crond) 구동 완료"
else
    echo "- 스케줄러(crond)가 이미 실행 중입니다."
fi

echo -e "\n${GREEN}=== 모든 설정이 완료되었습니다! ===${NC}"
echo -e "이제 ${YELLOW}${STR_TIME}${NC}마다 백업이 구글 드라이브로 전송됩니다."
echo -e "성공 여부 기록은 ${YELLOW}~/backup_log.txt${NC} 에서 확인하실 수 있습니다."
echo -e "※ Termux 알림창에서 'Acquire WakeLock'을 켜두시는 것을 잊지 마세요!"