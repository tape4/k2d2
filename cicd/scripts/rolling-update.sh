#!/bin/bash

# idle 포트 찾기
function check_ports_idle
{
  ports=(8080 8081)
  available=()
  echo "Checking port availability..."
  for port in "${ports[@]}"
  do
      # 체크할 포트
      check_port="$port"
      echo "check port $check_port"

      # 포트 상태 확인
      ss -lnt | awk '$4 ~ /^.*:'"$check_port"'$/ {exit 1}'
      if [ $? -eq 0 ]; then
          available+=("$check_port")
      fi

  done
  echo ${available[@]}
}

# 사용중인 포트 찾기
function check_ports_in_use
{
  ports=(8080 8081)

  in_use=()
  echo "Checking port availability..."
  for port in "${ports[@]}"
  do
      # 체크할 포트
      check_port="$port"
      echo "check port $check_port"

      # 포트 상태 확인
      ss -lnt | awk '$4 ~ /^.*:'"$check_port"'$/ {exit 1}'
      if [ $? -ne 0 ]; then
          in_use+=("$check_port")
      fi

  done
  echo ${in_use[@]}
}

function switch_container()
{

  # Docker Hub 에서 새로운 이미지 받기
  source /home/ubuntu/scripts/pull-latest-images.sh

  start_new_container

  is_container_update_done="false"
  for i in {0..3}
  do
    # 새로운 컨테이너가 떴다면
    if [ "$(is_new_container_running)" == "true" ]; then
      echo "New container has been detected. Stopping old container.."
      is_container_update_done="true"
      break;
    else # 새로운 컨테이너가 아직 뜨지 않았다면 10초뒤에 다시 요청
      echo "No new container has been detected. Retrying in 10 seconds..."
    fi
    sleep 10
  done

  ## 뜬거 확인 idle 포트 도커가 떠있다면 기존 컨테이너 내리기
  if [ "$is_container_update_done" == "true" ]; then
    stop_old_container
  else # 새로운 컨테이너가 오류로 인해 뜨지 않았다면 기존 컨테이너 유지
    echo "Update failed."
    exit 1
  fi
}

# 새로운 컨테이너의 /health-check 응답 코드를 확인하는 스크립트
function is_new_container_running() {

  is_idle_running=()
  for i in {0..0}
  do
    idle_port=${idle_ports[i]}
    response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$idle_port/health-check)

    # 컨테이너가 실행 중인 경우 종료
    if [[ $response_code -ge 200 && $response_code -lt 300 ]]; then
      echo "true"
    else
      echo "false"
    fi
  done
}

function start_new_container() {
  for i in {0..0}
  do
    idle_port=${idle_ports[i]} # idle 포트
    echo "Starting container using port $idle_port..."
    docker run -d -p $idle_port:8080 --add-host host.docker.internal:host-gateway $IMAGE_NAME
  done
}

function stop_old_container() {
  if [ ${#use_ports[@]} -eq 0 ]; then
    echo "There's no running container to stop"
    return
  fi

  for i in {0..0}
  do
    use_port=${use_ports[i]} # 사용중인 포트

    # 포트로 매핑된 사용중인 컨테이너 ID 찾기
    container_id=$(docker ps --filter "publish=$use_port" --format "{{.ID}}")

    # 컨테이너가 실행 중인 경우 종료
    if [ -n "$container_id" ]; then
        echo "Stopping container $container_id using port $use_port..."
        docker stop "$container_id"
    else
        echo "No container is using port $use_port."
    fi
  done
}

use_ports=($(check_ports_in_use | tail -n 1))
idle_ports=($(check_ports_idle | tail -n 1))


switch_container


# Remove last server version image
echo "Remove last server version image"
docker rm $(docker ps -a -f status=exited -q)
docker image prune -f