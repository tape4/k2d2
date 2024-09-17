#/bin/sh

DIR=$( pwd )
TARGET_DIR="/etc/nginx"
TARGET="nginx.conf"

echo $DIR/$TARGET

docker build -t nginx-healthcheck-module .
docker run -d -v $DIR/$TARGET:$TARGET_DIR/$TARGET:ro --network host nginx-healthcheck-module 
# docker run -d -p 51821:80 -v $DIR/$TARGET:$TARGET_DIR/$TARGET:ro --network host nginx-healthcheck-module 
# docker run -d -p 51821:80 -v $DIR/$TARGET:$TARGET_DIR/$TARGET:ro --add-host host.docker.internal:host-gateway nginx-healthcheck-module 
# echo "docker run -d -p 80:80 -v $DIR/$TARGET:$TARGET_DIR/$TARGET nginx-healthcheck-module"