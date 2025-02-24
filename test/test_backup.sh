#!/bin/bash
docker run -i --rm --network local  jbergknoff/postgresql-client \
   -vON_ERROR_STOP=ON postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE <<-EOSQL
    drop table mytable;
EOSQL
docker run --rm --network local --name postgresql-backup-s3  \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD\
  postgresql-backup-s3
sleep 1
docker run -i --rm --network local  jbergknoff/postgresql-client \
   -vON_ERROR_STOP=ON postgresql://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE <<-EOSQL
    create table mytable(myint integer);
EOSQL
docker run --rm --network local --name postgresql-backup-s3  \
  -e POSTGRES_DATABASE -e POSTGRES_USER -e POSTGRES_PASSWORD -e POSTGRES_HOST -e POSTGRES_PORT \
  -e S3_ACCESS_KEY_ID -e S3_SECRET_ACCESS_KEY -e S3_ENDPOINT -e S3_BUCKET -e ENCRYPTION_PASSWORD\
  postgresql-backup-s3
docker kill $POSTGRES_HOST
docker volume rm pgdata