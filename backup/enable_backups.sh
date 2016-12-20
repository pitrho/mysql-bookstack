#!/bin/bash

BACKUP_LOG="/var/log/mysql/backup.log"

if [ -n "${CRON_TIME}" ]; then
    echo "=> Configuring cron schedule for database backups ..."

    MYSQL_HOST=${MYSQL_PORT_3306_TCP_ADDR:-${MYSQL_HOST}}
    MYSQL_PORT=${MYSQL_PORT_3306_TCP_PORT:-${MYSQL_PORT}}
    MYSQL_USER=${MYSQL_USER:-${MYSQL_ENV_MYSQL_USER}}
    MYSQL_PASS=${MYSQL_PASS:-${MYSQL_ENV_MYSQL_PASS}}
    MYSQL_DB=${MYSQL_DB:-"--all-databases"}


    [ -z "${VOLUME_DIR}" ] && { echo "=> VOLUME_DIR cannot be empty" && exit 1; }
    [ -z "${MYSQL_HOST}" ] && { echo "=> MYSQL_HOST cannot be empty" && exit 1; }
    [ -z "${MYSQL_PORT}" ] && { echo "=> MYSQL_PORT cannot be empty" && exit 1; }
    [ -z "${MYSQL_USER}" ] && { echo "=> MYSQL_USER cannot be empty" && exit 1; }
    [ -z "${MYSQL_PASS}" ] && { echo "=> MYSQL_PASS cannot be empty" && exit 1; }
    [ -z "${S3_BUCKET}" ] && { echo "=> S3_BUCKET cannot be empty" && exit 1; }
    [ -z "${AWS_ACCESS_KEY_ID}" ] && { echo "=> AWS_ACCESS_KEY_ID cannot be empty" && exit 1; }
    [ -z "${AWS_SECRET_ACCESS_KEY}" ] && { echo "=> AWS_SECRET_ACCESS_KEY cannot be empty" && exit 1; }
    [ -z "${AWS_DEFAULT_REGION}" ] && { echo "=> AWS_DEFAULT_REGION cannot be empty" && exit 1; }

    # Set environment variables to run cron job
    echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> /etc/cron.d/mysql_backup
    echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> /etc/cron.d/mysql_backup
    echo "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" >> /etc/cron.d/mysql_backup
    echo "MYSQL_HOST=${MYSQL_HOST}" >> /etc/cron.d/mysql_backup
    echo "MYSQL_PORT=${MYSQL_PORT}" >> /etc/cron.d/mysql_backup
    echo "MYSQL_USER=${MYSQL_USER}" >> /etc/cron.d/mysql_backup
    echo "MYSQL_PASS=${MYSQL_PASS}" >> /etc/cron.d/mysql_backup
    echo "MYSQL_DB=${MYSQL_DB}" >> /etc/cron.d/mysql_backup
    echo "S3_BUCKET=${S3_BUCKET}" >> /etc/cron.d/mysql_backup
    echo "MAX_BACKUPS=${MAX_BACKUPS}" >> /etc/cron.d/mysql_backup
    echo "VOLUME_DIR=${VOLUME_DIR}" >> /etc/cron.d/mysql_backup
    [ -n "${EXTRA_OPTS}" ] && { echo "EXTRA_OPTS=${EXTRA_OPTS}" >> /etc/cron.d/mysql_backup; }
    echo "${CRON_TIME} /backup_public.sh >> ${BACKUP_LOG} 2>&1" >> /etc/cron.d/mysql_backup

    echo "=> Cron scheduled for database backups on schedule ${CRON_TIME} ..."
    # start cron if it's not running
    if [ ! -f /var/run/crond.pid ]; then
        exec /usr/sbin/cron -f
    fi
fi
