# MySQL backup on Docker

This image allows backing up MySQL Docker containers (running on the same machine) as well as external MySQL servers. It is configured via ENV variables.

Generic ENV variables needed:

* `MYSQL_HOST`: Hostname/IP of the mysql server
* `MYSQL_PORT`: Port of the mysql server. Optional, defaults to `3306`
* `MYSQL_BACKUP_USER`, `MYSQL_BACKUP_PASSWORD`: User and password for connecting to the MySQL database
* `MYSQL_BACKUP_DATABASE`: Database to backup. Optional. Backup all databases otherwise
* `MYSQL_BACKUP_ENCRYPTION_PASSPHRASE`: Password for encrypting the backup
* `RCLONE_XXX`: Options for rclone

Example:

    docker run --rm \
      -e MYSQL_HOST=external-mysql-server.example.com \
      -e MYSQL_BACKUP_DATABASE=mysql \
      -e MYSQL_BACKUP_USER=backup \
      -e MYSQL_BACKUP_PASSWORD=password \
      -e MYSQL_BACKUP_ENCRYPTION_PASSPHRASE=secret-passphrase \
      -e RCLONE_TARGET=mys3:backup \
      -e RCLONE_CONFIG_MYS3_TYPE=s3 \
      -e RCLONE_CONFIG_MYS3_ACCESS_KEY_ID=minioadmin \
      -e RCLONE_CONFIG_MYS3_SECRET_ACCESS_KEY=minioadmin \
      -e RCLONE_CONFIG_MYS3_ENDPOINT=https://my.minio.host \
      schoolscout/mysql-backup

## Privileges needed on the MySQL server

    GRANT SHOW DATABASES, SELECT, SHOW VIEW, LOCK TABLES, RELOAD, EVENT, REPLICATION CLIENT ON *.* TO backup@`172.17.%.%` IDENTIFIED BY '<PASSWORD>';
