#!/bin/sh

REPOSITORY=/home/ec2-user/backtest
cd $REPOSITORY

sudo pip3 install -r requirements.txt

EC2_LOG=/home/ec2-user/deploy.log
PROJECT=flask
DATE=$(date +%Y-%m-%d-%H-%M-%S)
PORT=8301

# 현재 실행중인 서버 PID 조회
runPid=$(pgrep -f $PROJECT)

if [ -z $runPid ]; then
  echo "No servers are running" >> $EC2_LOG
fi

# 현재 실행중인 서버의 포트를 조회. 없거나 있으면 추가로 실행할 서버의 포트를 8302 함
runPortCount=$(ps -ef | grep $PROJECT | grep -v grep | grep $PORT | wc -l)
if [ $runPortCount -gt 0 ]; then
  #    echo "현재 서버는 $PORT 로 실행중입니다"
  PORT=8302
fi
echo "Server $PORT 로 시작합니다.." >> $EC2_LOG

# 새로운 서버 실행
nohup flask run --host=0.0.0.0 --port=$PORT >> $EC2_LOG 2>&1 & # EC2용

# 새롭게 실행한 서버의 health check
echo "Health check $PORT" >> $EC2_LOG

for retry in {1..10}; do
  health=$(curl -s http://localhost:$PORT/health)
  checkCount=$(echo $health | grep 'ok' | wc -l)
  if [ $checkCount -ge 1 ]; then
    echo "[$(date)] Server $PORT Started" >> $EC2_LOG

    # 초기 디플로이때에는 runpid가 null이므로 그럴때는 for문을 빠져나온다
    # 안쓰면 밑의 다음 if 문에서 unary operator expected 에러남. 널과 숫자 비교라서..
    if [ -z $runPid ]; then
      break
    fi

    # 기존 서버 Stop / Nginx 포트 변경 후 리스타트
    if [ $runPid -gt 0 ]; then
      echo "Server $runPid Stop" >> $EC2_LOG
      sudo kill -TERM $runPid
      sleep 1
      echo "Nginx Port Change" >> $EC2_LOG
      echo "set \$service_addr http://127.0.0.1:$PORT;" | sudo tee /etc/nginx/conf.d/service_addr.inc >> $EC2_LOG
      echo "Nginx reload" >> $EC2_LOG
      sudo systemctl reload nginx
    fi
    break
  else
    echo "Check - false" >> $EC2_LOG
  fi
  sleep 1
done
echo "Deploy End" >> $EC2_LOG