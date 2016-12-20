#!/bin/bash
# Recover backup for BookStack

aws=/usr/bin/aws


if [ -z $1 ]; then
  echo "Restoring from last backup."
  # old version of aws does not support --recursive
  #KEY=`$aws s3 ls $S3_BUCKET --recursive | sort | tail -n 1 | awk '{print $4}'`
  KEY=`$aws s3 ls s3://$S3_BUCKET/ | tail -n 1 | awk '{print $4}'`
else
  echo "Restoring from $1 backup."
  KEY=$1
fi

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

# begin recovery

TMP_DIR="`mktemp -d /tmp/bak.XXXXXXXX`"

echo $TMP_DIR

#KEY=`$aws s3 ls $S3_BUCKET --recursive | sort | tail -n 1 | awk '{print $4}'`
$aws s3 cp s3://$S3_BUCKET/$KEY $TMP_DIR/

if [ "$?" -ne 0 ]; then
  echo "Data restore failed."
  exit 1
fi

cd $TMP_DIR
tar -xzf *.tar.gz

rm *.tar.gz

gunzip tmp/*.sql.gz

echo "Restoring ${MYSQL_DB}"
mysql -h${MYSQL_HOST} -u${MYSQL_USER} -p${MYSQL_PASS} ${MYSQL_DB} < tmp/*.sql

# remove the db extraction dir
rm -rf tmp/

# clean this directory
#cd $VOLUME_DIR
#rm -rf *

cp -r * $VOLUME_DIR

chown -R www-data: $VOLUME_DIR

rm -rf $TMP_DIR

echo "Backup recovery completed."
