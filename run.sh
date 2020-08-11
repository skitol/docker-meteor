#!/bin/bash -e

# WARNING: This script is intended to be used with an image based on this image, and not directly with this image.
#          You have to adapt the script for your image. It contains example values.

# An example script to run the app in production. It uses data volumes under the $DATA_ROOT directory.
# By default /srv. It uses a MongoDB database, tozd/meteor-mongodb image which is automatically run as well.

NAME='example'
DATA_ROOT='/srv'
MONGODB_DATA="${DATA_ROOT}/${NAME}/mongodb/data"
MONGODB_LOG="${DATA_ROOT}/${NAME}/mongodb/log"

METEOR_LOG="${DATA_ROOT}/${NAME}/meteor/log"

# This file is used by both the app and tozd/meteor-mongodb images. The latter automatically creates the
# database and accounts with provided passwords. The file should look like:
#
# MONGODB_ADMIN_PWD='<pass>'
# MONGODB_CREATE_PWD='<pass>'
# MONGODB_OPLOGGER_PWD='<pass>'
#
# export MONGO_URL="mongodb://meteor:${MONGODB_CREATE_PWD}@example_mongodb/meteor"
# export MONGO_OPLOG_URL="mongodb://oplogger:${MONGODB_OPLOGGER_PWD}@example_mongodb/local?authSource=admin"
CONFIG="${DATA_ROOT}/${NAME}/run.config"

mkdir -p "$MONGODB_DATA"
mkdir -p "$MONGODB_LOG"
mkdir -p "$METEOR_LOG"

touch "$CONFIG"

if [ ! -s "$CONFIG" ]; then
  echo "Set MONGODB_CREATE_PWD, MONGODB_ADMIN_PWD, MONGODB_OPLOGGER_PWD and export MONGO_URL, MONGO_OPLOG_URL environment variables in '$CONFIG'."
  exit 1
fi

docker stop "${NAME}_mongodb" || true
sleep 1
docker rm "${NAME}_mongodb" || true
sleep 1
docker run --detach=true --restart=always --name "${NAME}_mongodb" --hostname "${NAME}_mongodb" \
 -volume "${CONFIG}:/etc/service/mongod/run.config" --volume "${MONGODB_LOG}:/var/log/mongod" --volume "${MONGODB_DATA}:/var/lib/mongodb" \
 tozd/meteor-mongodb:3.4

docker stop "${NAME}" || true
sleep 1
docker rm "${NAME}" || true
sleep 1
docker run --detach=true --restart=always --name "${NAME}" --hostname "${NAME}" \
 --env ROOT_URL=http://example.com --env MAIL_URL=smtp://example.com \
 --volume "${CONFIG}:/etc/service/meteor/run.config" --volume "${METEOR_LOG}:/var/log/meteor" \
 you/example-app
