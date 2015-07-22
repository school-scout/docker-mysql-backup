#!/bin/bash
set -e

mysql_password=test123

function cleanup() {
  # Remove MySQL and SSH containers
  docker rm -vf $mysql_cid $ssh_cid >/dev/null 2>&1
}
trap cleanup 0

# Create MySQL container
mysql_cid=$(docker run -d -e MYSQLD_LOG_BIN=binlog -e MYSQL_ROOT_PASSWORD=$mysql_password schoolscout/custom-mysql-with-ssl:5.5)
mysql_ip=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' $mysql_cid)

# Create keypair
keyfile=$(mktemp -u)
ssh-keygen -u -N "" -f $keyfile
key=$(base64 -w0 $keyfile)
pubkey=$(base64 -w0 $keyfile.pub)

# Create SSH server
ssh_cid=$(docker run -d -e AUTHORIZED_KEYS=$pubkey schoolscout/scp-server)
ssh_ip=$(docker inspect -f '{{.NetworkSettings.IPAddress}}' $ssh_cid)

# Wait for mysql..
while ! nc -z $mysql_ip 3306; do sleep 1; done

# Start backup
if [ $1 == 'docker' ]; then
  docker run -it --rm --link $mysql_cid:mysql --volumes-from $mysql_cid \
    -e MYSQL_CONTAINER_NAME=$mysql_cid \
    -e MYSQL_BACKUP_USER=root -e MYSQL_BACKUP_PASSWORD=$mysql_password \
    -e MYSQL_BACKUP_ENCRYPTION_PASSPHRASE=test123 \
    -e MYSQL_BACKUP_SSH_ADDRESS=data@$ssh_ip: -e MYSQL_BACKUP_SSH_KEY=$key -e MYSQL_BACKUP_SSH_PORT=22 \
    schoolscout/mysql-backup
else
  docker run -it --rm \
    -e MYSQL_HOST=$mysql_ip \
    -e MYSQL_BACKUP_DATABASE=mysql \
    -e MYSQL_BACKUP_USER=root -e MYSQL_BACKUP_PASSWORD=$mysql_password \
    -e MYSQL_BACKUP_ENCRYPTION_PASSPHRASE=test123 \
    -e MYSQL_BACKUP_SSH_ADDRESS=data@$ssh_ip: -e MYSQL_BACKUP_SSH_KEY=$key -e MYSQL_BACKUP_SSH_PORT=22 \
    schoolscout/mysql-backup
fi

# Show results
echo Contents of backup directory:
docker exec $ssh_cid sh -c "find /home/data -type d | xargs ls -l"
