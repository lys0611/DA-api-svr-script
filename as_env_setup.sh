#!/bin/bash

# 실패하면 중단
set -e
set -o pipefail

LOGFILE="/home/ubuntu/as_env_setup.log"
exec &> >(tee -a "$LOGFILE")

log() {
  echo "[`date '+%Y-%m-%d %H:%M:%S'`] $1"
}

###############################################################################
# 2) filebeat / logstash 설치
###############################################################################
log "Step 2 시작: filebeat / logstash 설치 & 환경 변수 추가"

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/beats.list

sudo apt-get update
sudo apt-get install -y filebeat logstash
log "filebeat, logstash 패키지 설치 완료"

sudo systemctl enable filebeat
sudo systemctl start filebeat
sudo systemctl enable logstash
sudo systemctl start logstash
log "filebeat, logstash 서비스를 시작했습니다."

sudo chmod 777 /etc/default/logstash
log "logstash 환경변수 설정파일에 쓰기 위해 권한 부여"

sudo bash -c "cat <<EOF >> \$LOGSTASH_ENV_FILE

# === Additional Env for Pub/Sub ===
CREDENTIAL_ID=\"\$CREDENTIAL_ID\"
CREDENTIAL_SECRET=\"\$CREDENTIAL_SECRET\"
DOMAIN_ID=\"\$DOMAIN_ID\"
PROJECT_ID=\"\$PROJECT_ID\"
PUBSUB_TOPIC_NAME=\"\$PUBSUB_TOPIC_NAME\"
KAFKA_TOPIC_NAME=\"\$KAFKA_TOPIC_NAME\"
LOGSTASH_KAFKA_ENDPOINT=\"\$LOGSTASH_KAFKA_ENDPOINT\"

export CREDENTIAL_ID CREDENTIAL_SECRET DOMAIN_ID PROJECT_ID TOPIC_NAME_PUBSUB KAFKA_TOPIC_NAME MYSQL_HOST LOGSTASH_KAFKA_ENDPOINT
EOF"
log "logstash 환경 변수 추가 완료"

sudo systemctl daemon-reload
sudo systemctl restart logstash
log "logstash 재시작"

log "Step 2 완료: filebeat / logstash 설치 및 환경 변수 설정이 끝났습니다."


###############################################################################
# 3) (선택) Flask 앱 서비스(flask_app.service)에 같은 변수 쓰기
###############################################################################
log "Step 3: flask_app.service 환경변수 override 작업 진행"

SERVICE_FILE="/etc/systemd/system/flask_app.service"
OVERRIDE_DIR="/etc/systemd/system/flask_app.service.d"
OVERRIDE_FILE="$OVERRIDE_DIR/env.conf"

if [ -f "$SERVICE_FILE" ]; then
  log "flask_app.service 발견. override 설정을 진행합니다."
  sudo mkdir -p "$OVERRIDE_DIR"
  sudo bash -c "cat <<EOF > $OVERRIDE_FILE
[Service]
Environment=\"MYSQL_HOST=\$MYSQL_HOST\"
Environment=\"DOMAIN_ID=\$DOMAIN_ID\"
Environment=\"PROJECT_ID=\$PROJECT_ID\"
Environment=\"PUBSUB_TOPIC_NAME=\$PUBSUB_TOPIC_NAME\"
Environment=\"KAFKA_TOPIC_NAME=\$KAFKA_TOPIC_NAME\"
Environment=\"CREDENTIAL_ID=\$CREDENTIAL_ID\"
Environment=\"CREDENTIAL_SECRET=\$CREDENTIAL_SECRET\"
EOF"
  sudo systemctl daemon-reload
  sudo systemctl restart flask_app
  log "flask_app.service 재시작 완료"
else
  log "flask_app.service가 없어 override 스킵합니다."
fi

log "Step 3 완료"


###############################################################################
# 4) main_script.sh & setup_db.sh 다운로드, 실행
###############################################################################
log "Step 4: main_script.sh, setup_db.sh 링크 유효성 검사"

# main_script.sh
curl --output /dev/null --silent --head --fail \
  "https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/as_full_setup.sh" || {
    log "main_script.sh 다운로드 링크가 유효하지 않습니다."
    exit 1
  }

# setup_db.sh
curl --output /dev/null --silent --head --fail \
  "https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/setup_db.sh" || {
    log "setup_db.sh 다운로드 링크가 유효하지 않습니다."
    exit 1
  }

log "다운로드 링크가 모두 유효합니다. 실제 파일을 다운로드합니다."

wget -O main_script.sh \
  "https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/as_full_setup.sh"
wget -O setup_db.sh \
  "https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/setup_db.sh"

chmod +x main_script.sh
chmod +x setup_db.sh

log "main_script.sh, setup_db.sh 실행 시작"
sudo -E ./main_script.sh
sudo -E ./setup_db.sh
log "main_script.sh, setup_db.sh 실행 완료"

log "Step 4 완료"


###############################################################################
# 5) filebeat.yml & logs-to-pubsub.conf 다운로드
###############################################################################
log "Step 5: filebeat.yml, logs-to-pubsub.conf, logs-to-kafka.conf 다운로드 및 로그스태시 재시작"

sudo wget -O /etc/filebeat/filebeat.yml \
  "https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/filebeat.yml"

sudo wget -O /etc/logstash/conf.d/logs-to-pubsub.conf \
  "https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/logs-to-pubsub.conf"

sudo wget -O /etc/logstash/conf.d/logs-to-kafka.conf \
  "https://github.com/lys0611/DA-api-svr-script/raw/refs/heads/main/logs-to-kafka.conf"

sudo tee /etc/logstash/logstash.yml <<'EOF'
path.data: /var/lib/logstash
path.logs: /var/log/logstash
path.config: /etc/logstash/conf.d/logs-to-pubsub.conf
EOF

log "filebeat.yml, logs-to-pubsub.conf, logs-to-kafka.conf 다운로드 완료"

log "filebeat, logstash 서비스를 다시 시작"
sudo systemctl restart filebeat
sudo systemctl restart logstash

log "Step 5 완료"
log "as_env_setup.sh 실행 완료"
