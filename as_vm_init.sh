#!/bin/bash

###############################################################################
# as_vm_init.sh
#   1) MySQL, 도메인, Kafka 등 각종 환경 변수를 ~/.bashrc에 등록
#   2) as_env_setup.sh 스크립트를 깃허브에서 다운로드 → 실행
###############################################################################

# 1. 환경 변수 설정
MYSQL_HOST="{MySQL 엔드포인트}"
DOMAIN_ID="{조직 ID}"
PROJECT_ID="{프로젝트 ID}"
CREDENTIAL_ID="{액세스 키 ID}"
CREDENTIAL_SECRET="{보안 액세스 키}"
LOGSTASH_KAFKA_ENDPOINT="{Kafka 클러스터 부트스트랩 서버}"

PUBSUB_TOPIC_NAME="log-topic"
KAFKA_TOPIC_NAME="nginx-topic"
LOGSTASH_ENV_FILE="/etc/default/logstash"

# 깃허브에서 받을 스크립트 URL
ENV_SETUP_SCRIPT_URL="https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/as_env_setup.sh"

echo "kakaocloud: 1. ~/.bashrc에 환경 변수를 설정합니다."

# (1) 등록할 환경 변수를 하나의 문자열로 구성
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

# (2) 스크립트 내에서 즉시 반영
eval "$BASHRC_EXPORT"

# (3) .bashrc에 중복이 없을 경우에만 추가
if ! grep -q "MYSQL_HOST" /home/ubuntu/.bashrc; then
  echo "$BASHRC_EXPORT" >> /home/ubuntu/.bashrc
fi

# (4) .bashrc 다시 로드
source /home/ubuntu/.bashrc
echo "kakaocloud: ~/.bashrc에 환경 변수를 추가 완료."

# 2. as_env_setup.sh 스크립트 다운로드 및 실행
echo "kakaocloud: 2. as_env_setup.sh 스크립트를 다운로드합니다."

# (1) 다운로드 링크가 유효한지 검사
curl --output /dev/null --silent --head --fail "$ENV_SETUP_SCRIPT_URL" || {
  echo "kakaocloud: as_env_setup.sh 다운로드 링크가 유효하지 않습니다."
  exit 1
}

echo "kakaocloud: 스크립트 다운로드 링크가 유효합니다. 스크립트를 다운로드합니다."
wget -O as_env_setup.sh "$ENV_SETUP_SCRIPT_URL"
chmod +x as_env_setup.sh

echo "kakaocloud: as_env_setup.sh 실행을 시작합니다."
sudo -E ./as_env_setup.sh

echo "kakaocloud: 모든 작업 완료"
