#!/bin/bash
set -euo pipefail

MYSQL_HOST=${MYSQL_HOST:-mysql}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_BACKUP_DATABASE=${MYSQL_BACKUP_DATABASE:---all-databases}
BACKUP_DIR=/backup/${MYSQL_HOST}
BACKUP_FILE=${BACKUP_DIR}/$(date --utc +%Y-%m-%d).sql.gpg

function cleanup() {
  # Remove backup dir
  rm "${BACKUP_DIR}" -fR
}
trap cleanup EXIT INT TERM

# Create backup dir
mkdir -p "${BACKUP_DIR}"

# Do a full dump of the database, flushing the binlogs, encrypting the result
echo Dumping data
set +e
mysqldump -h "$MYSQL_HOST" -u "${MYSQL_BACKUP_USER}" -p"${MYSQL_BACKUP_PASSWORD}" --port="${MYSQL_PORT}" --single-transaction --flush-logs --master-data=2 "$MYSQL_BACKUP_DATABASE" \
  | gpg2 -c --batch --passphrase "${MYSQL_BACKUP_ENCRYPTION_PASSPHRASE}" >"$BACKUP_FILE"
rc=$?
set -e

if [[ "$rc" != 0 ]]; then
  echo Backup failed!
  exit 1
fi

# Copy dump to remote server
echo Copying files to backup server: "$(ls "$BACKUP_DIR")"
set +e
rclone copy "${BACKUP_FILE}" "${RCLONE_TARGET}"
rc=$?
set -e

if [[ "$rc" != 0 ]]; then
  echo Upload failed!
  exit 1
fi

echo "Backup done."
