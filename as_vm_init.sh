#!/bin/bash

# 스크립트가 실패하면 중단
set -e
# 파이프라인 중 하나라도 실패하면 전체 실패
set -o pipefail

LOGFILE="/home/ubuntu/as_vm_init.log"
# 표준 출력 + 에러를 동시에 로그 파일에 기록
exec &> >(tee -a "$LOGFILE")

# 로그 함수
log() {
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] $1"
}

#############################################################
# 1. 환경 변수 설정
#############################################################
MYSQL_HOST="{MySQL 엔드포인트}"
DOMAIN_ID="{조직 ID}"
PROJECT_ID="{프로젝트 ID}"
CREDENTIAL_ID="{액세스 키 ID}"
CREDENTIAL_SECRET="{보안 액세스 키}"
LOGSTASH_KAFKA_ENDPOINT="{Kafka 클러스터 부트스트랩 서버}"

PUBSUB_TOPIC_NAME="log-topic"
KAFKA_TOPIC_NAME="nginx-topic"
LOGSTASH_ENV_FILE="/etc/default/logstash"

ENV_SETUP_SCRIPT_URL="https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/as_env_setup.sh"

log "Step 1: ~/.bashrc에 환경 변수를 설정합니다."

BASHRC_EXPORT=$(cat <<EOF
export MYSQL_HOST="$MYSQL_HOST"
export DOMAIN_ID="$DOMAIN_ID"
export PROJECT_ID="$PROJECT_ID"
export PUBSUB_TOPIC_NAME="$PUBSUB_TOPIC_NAME"
export KAFKA_TOPIC_NAME="$KAFKA_TOPIC_NAME"
export CREDENTIAL_ID="$CREDENTIAL_ID"
export CREDENTIAL_SECRET="$CREDENTIAL_SECRET"
export LOGSTASH_KAFKA_ENDPOINT="$LOGSTASH_KAFKA_ENDPOINT"
EOF
)

eval "$BASHRC_EXPORT"

if ! grep -q "MYSQL_HOST" /home/ubuntu/.bashrc; then
  log "기존 .bashrc에 환경 변수가 없으므로 추가합니다."
  echo "$BASHRC_EXPORT" >> /home/ubuntu/.bashrc
fi

source /home/ubuntu/.bashrc
log "Step 1 완료: ~/.bashrc에 환경 변수를 추가했습니다."


#############################################################
# 2. as_env_setup.sh 스크립트 다운로드 및 실행
#############################################################
log "Step 2: as_env_setup.sh 스크립트를 다운로드합니다."

curl --output /dev/null --silent --head --fail "$ENV_SETUP_SCRIPT_URL" || {
  log "as_env_setup.sh 다운로드 링크가 유효하지 않습니다."
  exit 1
}

log "다운로드 링크가 유효함을 확인했습니다. 스크립트를 가져옵니다."
wget -O as_env_setup.sh "$ENV_SETUP_SCRIPT_URL"
chmod +x as_env_setup.sh

log "as_env_setup.sh 실행을 시작합니다."
sudo -E ./as_env_setup.sh
log "as_env_setup.sh 실행이 완료되었습니다."

log "모든 작업이 완료되었습니다."
