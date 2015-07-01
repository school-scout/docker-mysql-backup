#!/bin/bash
set -e

BACKUP_DIR=/backup/${MYSQL_CONTAINER_NAME}
BACKUP_FILE=${BACKUP_DIR}/$(date --utc +%Y-%m-%d).sql.gpg

mkdir ${BACKUP_DIR}

# Do a full dump of the database, flushing the binlogs, encrypting the result
mysqldump -h mysql -u ${MYSQL_BACKUP_USER} -p${MYSQL_BACKUP_PASSWORD} --single-transaction --flush-logs --master-data=2 --all-databases \
  | gpg -c --batch --passphrase ${MYSQL_BACKUP_ENCRYPTION_PASSPHRASE} >$BACKUP_FILE

# Copy SSH key from ENV variable
echo $MYSQL_BACKUP_SSH_KEY | sed "s/\\$/\n/g" | sed "s/^ //g" >/root/.ssh/id_rsa
chmod 0600 /root/.ssh/id_rsa

# Copy dump to remote server
scp -r -oStrictHostKeyChecking=no $BACKUP_DIR $MYSQL_BACKUP_SSH_ADDRESS