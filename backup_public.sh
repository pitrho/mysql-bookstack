#!/bin/bash
# Added ability to backup volume with the db

if [ "${MYSQL_ENV_MYSQL_PASS}" == "**Random**" ]; then
    unset MYSQL_ENV_MYSQL_PASS
fi

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


DEFAULT_MAX_BACKUPS=30
MAX_BACKUPS=${MAX_BACKUPS:-${DEFAULT_MAX_BACKUPS}}
BACKUP_PREFIX=$( [ "$MYSQL_DB" = "--all-databases" ] && echo "all" || echo $MYSQL_DB )
BACKUP_NAME="${BACKUP_PREFIX}_`date +"%m%d%Y_%H%M%S"`.sql.gz"
BACKUP_PATH="/tmp/${BACKUP_NAME}"

echo "=> Backup started ..."

# First, make sure the that the S3_BUCKET path exists
#
count=`/usr/bin/aws s3 ls s3://$S3_BUCKET | wc -l`

if [[ $count -eq 0 ]]; then
  echo "Path $S3_BUCKET not found."
  exit 1
fi

# Create the database backup locally
mysqldump -h${MYSQL_HOST} -P${MYSQL_PORT} -u${MYSQL_USER} -p${MYSQL_PASS} ${EXTRA_OPTS} ${MYSQL_DB} | gzip -9 > ${BACKUP_PATH}
if [ "$?" -ne 0 ]; then
    echo "   Backup failed"
    rm -rf $BACKUP_PATH
    exit 1
fi

echo "=> Volume Backup started ..."
vol_count=`mount|grep "$VOLUME_DIR"|wc -l`

if [[ $vol_count -eq 0 ]]; then
  echo "No Volume directory to backup."
else
  echo "Backing up $VOLUME_DIR"
  DATA_BACKUP=public_uploads_`date +"%m%d%Y_%H%M%S"`.tar.gz
  tar -czf $DATA_BACKUP -C $VOLUME_DIR . ${BACKUP_PATH}
  if [ "$?" -ne 0 ]; then
    echo "Private uploads backup failed." 
    exit 1
  fi
fi

# Copy the backup to the S3 bucket
echo "Copying $DATA_BACKUP to S3 ..."
S3_FILE_PATH="s3://$S3_BUCKET/$DATA_BACKUP"
/usr/bin/aws s3 cp $DATA_BACKUP $S3_FILE_PATH

# Clean up
rm -rf $DATA_BACKUP

echo "Removing old databse backup files ..."
files=($(aws s3 ls s3://$S3_BUCKET | awk '{print $4}'))
count=${#files[@]}
diff=`expr $count - $MAX_BACKUPS`
if [[ $diff -gt 0 ]]; then
  while [[ $diff -gt 0 ]]; do
    i=`expr $diff - 1`
    file=${files[$i]}
    /usr/bin/aws s3 rm s3://$S3_BUCKET/$file
    let diff=diff-1
  done
fi

echo "=> Backup completed"
