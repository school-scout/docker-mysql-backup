#!/bin/bash
set -e

MYSQL_HOST=${MYSQL_HOST:-mysql}
BACKUP_DIR=/backup/${MYSQL_CONTAINER_NAME:-$MYSQL_HOST}
BACKUP_FILE=${BACKUP_DIR}/$(date --utc +%Y-%m-%d).sql.gpg

mkdir ${BACKUP_DIR}

# Do a full dump of the database, flushing the binlogs, encrypting the result
echo Dumping data
mysqldump -h $MYSQL_HOST -u ${MYSQL_BACKUP_USER} -p${MYSQL_BACKUP_PASSWORD} --single-transaction --flush-logs --master-data=2 --all-databases \
  | gpg2 -c --batch --passphrase ${MYSQL_BACKUP_ENCRYPTION_PASSPHRASE} >$BACKUP_FILE

# Copy SSH key from ENV variable
echo $MYSQL_BACKUP_SSH_KEY | base64 -d >/root/.ssh/id_rsa
chmod 0600 /root/.ssh/id_rsa

# Copy dump to remote server
echo Copying files to backup server: $(ls $BACKUP_DIR)
scp -r -P ${MYSQL_BACKUP_SSH_PORT:=22} -oStrictHostKeyChecking=no $BACKUP_DIR $MYSQL_BACKUP_SSH_ADDRESS

echo "Backup done."
