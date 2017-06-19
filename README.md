# MySQL backup on Docker

This image allows backing up MySQL Docker containers (running on the same machine) as well as external MySQL servers. It is configured via ENV variables.

Generic ENV variables needed:

* `MYSQL_BACKUP_USER`, `MYSQL_BACKUP_PASSWORD`: User and password for connecting to the MySQL database
* `MYSQL_BACKUP_DATABASE`: Database to backup. Optional. Backup all databases otherwise
* `MYSQL_BACKUP_SSH_ADDRESS`, `MYSQL_BACKUP_SSH_PORT`, `MYSQL_BACKUP_SSH_KEY`: SSH Credentials for the target server where backups will be stored. The key must be base64 encoded (see below).
* `MYSQL_BACKUP_ENCRYPTION_PASSPHRASE`: Password for encrypting the backup

## Backing up a mysql docker container

Replace `MYSQL_CONTAINER_NAME` with the name of the target MySQL container. Example:

    MYSQL_CONTAINER_NAME=mysql-server
    MYSQL_BACKUP_SSH_KEY=$(base64 -w0 id_rsa)

    docker run --rm \
      --link ${MYSQL_CONTAINER_NAME}:mysql \
      -e MYSQL_BACKUP_USER=backup -e MYSQL_BACKUP_PASSWORD=password \
      -e MYSQL_BACKUP_SSH_ADDRESS=data@backup: -e MYSQL_BACKUP_SSH_PORT=22 -e MYSQL_BACKUP_SSH_KEY=$MYSQL_BACKUP_SSH_KEY \
      -e MYSQL_BACKUP_ENCRYPTION_PASSPHRASE=secret-passphrase \
      schoolscout/mysql-backup

## Backing up an external MySQL server

You need to additionally set the following ENV variables:

* `MYSQL_HOST`: hostname/IP of the external MySQL server

Example:

    MYSQL_BACKUP_SSH_KEY=$(base64 -w0 id_rsa)

    docker run --rm \
      -e MYSQL_HOST=external-mysql-server.example.com \
      -e MYSQL_BACKUP_USER=backup -e MYSQL_BACKUP_PASSWORD=password \
      -e MYSQL_BACKUP_SSH_ADDRESS=data@backup: -e MYSQL_BACKUP_SSH_PORT=22 -e MYSQL_BACKUP_SSH_KEY=$MYSQL_BACKUP_SSH_KEY \
      -e MYSQL_BACKUP_ENCRYPTION_PASSPHRASE=secret-passphrase \
      schoolscout/mysql-backup

## Privileges needed on the MySQL server

    GRANT SHOW DATABASES, SELECT, SHOW VIEW, LOCK TABLES, RELOAD, EVENT, REPLICATION CLIENT ON *.* TO backup@`172.17.%.%` IDENTIFIED BY '<PASSWORD>';
