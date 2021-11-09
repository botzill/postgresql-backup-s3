#!/bin/sh
set -e
set -o pipefail
. env.sh

echo "-----"
echo "Restoring dump of ${POSTGRES_DATABASE} database from ${POSTGRES_HOST}..."

if [ "${RESTORE}" = "**None**" ]; then
  echo "Restore not set"
  exit 2
elif [ "${RESTORE}" = "latest" ]; then
  echo "Restoring latest"
  res=$(aws $AWS_ARGS s3 ls s3://$S3_BUCKET/$S3_PREFIX/ 2>&1)
  echo $res | grep -v " PRE " | sort | head -1 | cut -d " " -f 4
  echo "$res" | grep -v " PRE " | sort | head -1 | cut -d " " -f 4
  echo "$res"
  SRC_FILE=$(echo $res | grep -v " PRE " | sort | head -1 | cut -d " " -f 4 2>&1)

  echo "Restoring: $SRC_FILE"
else
  echo "Restoring ${RESTORE}"
  SRC_FILE=${RESTORE}
fi

DEST_FILE=$SRC_FILE

# shellcheck disable=SC2086
aws $AWS_ARGS s3 cp s3://$S3_BUCKET/$S3_PREFIX/$SRC_FILE $DEST_FILE  || exit 2
if [ "${ENCRYPTION_PASSWORD}" = "**None**" ]; then
  echo "File not encrypted"
else
  DEST_FILE="restore.sql.gz"
  openssl aes-256-cbc -iter 1000 -d -in $SRC_FILE -out $DEST_FILE -k $ENCRYPTION_PASSWORD || exit 2
  rm $SRC_FILE
  SRC_FILE=$DEST_FILE
fi

if [ "${POSTGRES_DATABASE}" == "all" ]; then
  echo "Can't restore all"
  exit 2
else
  if [ -f "$SRC_FILE" ]; then
    echo "Restoring with pg_restore $POSTGRES_HOST_OPTS -1 -f $SRC_FILE"
    pg_restore $POSTGRES_HOST_OPTS --create --clean -d $POSTGRES_DATABASE -1 -e --no-owner --no-privileges $SRC_FILE
  else
    echo "No file to restore from"; exit 2;
  fi
fi

echo "SQL restore finished"
echo "-----"
exit 0