#!/bin/bash

# 스크립트 내에서 하나라도 실패하면 즉시 종료
set -e
# 파이프라인(파이프 연산자 |) 중 하나라도 실패해도 전체를 실패로 간주
set -o pipefail

echo "kakaocloud: 1. Defining environment variables in as_vm_init.sh (in-memory only)"

# 1) 메모리에 환경 변수만 등록
export MYSQL_HOST="{MySQL 엔드포인트}"
export DOMAIN_ID="{조직 ID}"
export PROJECT_ID="{프로젝트 ID}"
export CREDENTIAL_ID="{액세스 키 ID}"
export CREDENTIAL_SECRET="{보안 액세스 키}"
export LOGSTASH_KAFKA_ENDPOINT="{Kafka 클러스터 부트스트랩 서버}"

export PUBSUB_TOPIC_NAME="log-topic"
export KAFKA_TOPIC_NAME="nginx-topic"
export LOGSTASH_ENV_FILE="/etc/default/logstash"

echo "kakaocloud: Environment variables have been exported to memory."

###############################################################################
# 2) as_env_setup.sh 다운로드 & 실행
###############################################################################
ENV_SETUP_SCRIPT_URL="https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/as_env_setup.sh"

echo "kakaocloud: 2. Checking the validity of as_env_setup.sh download link"
curl --output /dev/null --silent --head --fail "$ENV_SETUP_SCRIPT_URL" \
  || { echo "kakaocloud: as_env_setup.sh 링크가 유효하지 않습니다."; exit 1; }
echo "kakaocloud: as_env_setup.sh download link is valid"

echo "kakaocloud: Downloading as_env_setup.sh"
wget -O as_env_setup.sh "$ENV_SETUP_SCRIPT_URL" \
  || { echo "kakaocloud: Failed to download as_env_setup.sh"; exit 1; }

chmod +x as_env_setup.sh \
  || { echo "kakaocloud: Failed to chmod as_env_setup.sh"; exit 1; }
echo "kakaocloud: as_env_setup.sh is ready to run"

echo "kakaocloud: Executing as_env_setup.sh"
sudo -E ./as_env_setup.sh \
  || { echo "kakaocloud: as_env_setup.sh execution failed"; exit 1; }

echo "kakaocloud: All steps in as_vm_init.sh have finished"
