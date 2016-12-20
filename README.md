# Bookstack Backup Recovery

Base docker image to run a MySQL database server. This is a modified fork of
[pitrho/mysql](https://github.com/pitrho/docker-mysql.git).

## MySQL version

This configuration currently supports MySQL 5.5 and 5.6 on Ubuntu 14.04.

## Building the image

To create the image `pitrho/mysql`, execute the following command:

    ./build.sh

The command above creates an image for MySQL 5.6. If you wan to use MySQL 5.5,
pass the -v flag along with the version.

    ./build.sh -v 5.5

To tag the image with a different name, pass the -t flag along with the tag
name.

    ./build.sh -t pitrho/mysql-5.6

## Usage

To run the image and bind to port 3306:

        docker run -d -p 3306:3306 pitrho/mysql

The first time that you run your container, a new user `admin` with all privileges will be created in MySQL with a random password. To get the password, check the logs of the container by running:

        docker logs <CONTAINER_ID>

You will see an output like the following:

    ========================================================================
    You can now connect to this MySQL Server using:

        mysql -uadmin -p47nnf4FweaKu -h<host> -P<port>

    Please remember to change the above password as soon as possible!
    MySQL user 'root' has no password but only allows local connections.
    ========================================================================

In this case, `47nnf4FweaKu` is the password allocated to the `admin` user.

Remember that the `root` user has no password, but it's only accessible from within the container.

You can now test your deployment:

        mysql -uadmin -p

Done!

## Changing the database user and password

Instead of using the default admin user and the auto-generate password, you can
use custom values. This can be done by passing environment variables MYSQL_USER
and MYSQL_PASS.

    docker run -d -p 3306:3306 -e MYSQL_USER=user -e MYSQL_PASS=pass pitrho/mysql

## Passing extra configuration to start mysql server

To pass additional settings to `mysqld`, you can use environment variable `EXTRA_OPTS`. For example, to run mysql using lower case table name, you can do:

    docker run -d -p 3306:3306 -e EXTRA_OPTS="--lower_case_table_names=1" pitrho/mysql


## Creating a database on container creation

If you want a database to be created inside the container when you start it up
for the first time,then you can set the environment variable `ON_CREATE_DB` to
the name of the database.

    docker run -d -p 3306:3306 -e ON_CREATE_DB="newdatabase" pitrho/mysql

If this is combined with importing SQL files, those files will be imported into the created database.

## Database data and volumes

This image does not enforce any volumes on the user. Instead, it is up to the
user to decide how to create any volumes to store the data. Docker has several
ways to do this. More information can be found in the Docker
[user guide](https://docs.docker.com/userguide/dockervolumes/).

## Database backups

This image introduces a mechanism for creating and storing backups on Amazon S3.
The backups can be run manually or using an internal cron schedule.

To run the backups manually, do:

    docker run -e MYSQL_DB=dname -e AWS_ACCESS_KEY_ID=keyid -e AWS_SECRET_ACCESS_KEY=secret -e AWS_DEFAULT_REGION=region -e S3_BUCKET=path/to/bucket /backup.sh

To run the backups on a cron schedule (e.g every day at 6 am), do:

    docker run -d -p 3306:3306 -e MYSQL_DB=dname -e AWS_ACCESS_KEY_ID=keyid -e AWS_SECRET_ACCESS_KEY=secret -e AWS_DEFAULT_REGION=region -e S3_BUCKET=path/to/bucket -e CRON_TIME="0 6 * * * root"

# Backup and Restoring DB and BookStack uploads directory.

The BookStack directory backup rquires the VOLUME_DIR on the BookStack container to be available.


S3 Bucket: pitrho-backups/internal_documentation

docker exec -i [container id] /backup_recovery.sh [s3 file to restore from]

docker exec -i [container id] /backup_recovery.sh public_uploads_12162016_195747.tar.gz

# restore from the last backup made.
docker exec -i [container id] /backup_recovery.sh



*Anytime the documentation stack is started it should be loaded from a backup.

#TODO: Does the cache need to be cleared?
php artisan cache:clear
php artisan view:clear
