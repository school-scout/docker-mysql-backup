#!/usr/bin/env bash
set -euo pipefail

IMAGE=schoolscout/mysql-backup:0.2.0
MYSQL_PASSWORD=test123

function cleanup() {
  # Remove MySQL and SSH containers
  docker rm -vf "$mysql_cid" "$minio_cid" >/dev/null 2>&1
  rm test-output/* -f
}
trap cleanup 0

# Create MySQL container
mysql_cid=$(docker run -d -e MYSQL_ROOT_PASSWORD=$MYSQL_PASSWORD mariadb:10.7.8 --log-bin)
mysql_ip=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' "$mysql_cid")

# Create minio server
minio_cid=$(docker run -d quay.io/minio/minio server /data)

# Wait for mysql..
while ! nc -z "$mysql_ip" 3306; do sleep 1; done

# Start backup
docker run -it --rm \
  --link "$mysql_cid":mysql \
  --link "$minio_cid":minio \
  -e MYSQL_HOST=mysql \
  -e MYSQL_BACKUP_DATABASE=mysql \
  -e MYSQL_BACKUP_USER=root -e MYSQL_BACKUP_PASSWORD="$MYSQL_PASSWORD" \
  -e MYSQL_BACKUP_ENCRYPTION_PASSPHRASE="$MYSQL_PASSWORD" \
  -e RCLONE_CONFIG_MYS3_TYPE=s3 \
  -e RCLONE_CONFIG_MYS3_ACCESS_KEY_ID=minioadmin \
  -e RCLONE_CONFIG_MYS3_SECRET_ACCESS_KEY=minioadmin \
  -e RCLONE_CONFIG_MYS3_ENDPOINT=http://minio:9000 \
  -e RCLONE_TARGET=mys3:backup \
  "$IMAGE"

# Show results
backup_file="$(date --utc +%Y-%m-%d).sql.gpg"
docker run --rm --name minio-client \
  --link "$minio_cid":minio \
  -v "$PWD/test-output:/test-output" \
  -e MINIO_SERVER_HOST="minio" \
  -e MINIO_SERVER_ACCESS_KEY="minioadmin" \
  -e MINIO_SERVER_SECRET_KEY="minioadmin" \
  bitnami/minio-client \
  cp "minio/backup/$backup_file" /test-output/test.sql.gpg

echo Backup file:
ls -l test-output

gpg2 -d --batch --passphrase "$MYSQL_PASSWORD" -o test-output/test.sql test-output/test.sql.gpg

echo Head of dump:
head test-output/test.sql

echo Tail of dump:
tail test-output/test.sql
