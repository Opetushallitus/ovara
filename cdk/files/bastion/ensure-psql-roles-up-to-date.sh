#!/usr/bin/env bash

set -uo pipefail

if [ $# -lt 1 ]; then
  echo ""
  echo ""
  echo "Usage:"
  echo "$0 <dbname> <master-password> <app-password> <readonly-password>"
  exit 1
fi
host=$1
db=$2
master_pw=$3
app_pw=$4
readonly_pw=$5

echo "Creating database $db if it does not exists"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname postgres --command "create database $db";
echo ""
echo "Ensure user 'app' exists; this command fails when it does already exist."
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "create role app;"
echo ""
echo "Ensure user 'app' has the correct password and permissions."
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "alter role app with login password '$app_pw';"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant all privileges on database $db to app;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant all privileges on all tables in schema public to app;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant all privileges on all sequences in schema public to app;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant all privileges on schema public to app;"
echo ""
echo "Ensure user 'readonly' exists; this command fails when it does already exist."
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "create role readonlyrole;"
echo ""
echo "Ensure user 'readonly' has the correct password and permissions."
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant usage on schema public to readonlyrole;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant select on all tables in schema public to readonlyrole;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant select on all sequences in schema public to readonlyrole;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "alter default privileges in schema public grant select on tables to readonlyrole;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "alter default privileges in schema public grant select on sequences to readonlyrole;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "create user readonly with password '$readonly_pw';"
echo ""
echo "Ensure role 'oph_group' exists; this command fails when it does already exist."
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "create role oph_group;"
echo ""
echo "Ensure 'oph_group' has the correct password, and 'app' and 'oph' both belong to it."
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "alter role oph_group with login password '$master_pw';"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant oph to oph_group;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant app to oph_group;"
echo ""
echo "Ensure the 'app' user owns the database and everything in it."
PGPASSWORD=$master_pw psql -h $host --user oph_group --dbname $db --command "reassign owned by oph to app;"
echo ""
echo "Ensure user 'oph' still has permissions to everything now owned by 'app'."
PGPASSWORD=$master_pw psql -h $host --user oph_group --dbname $db --command "grant all privileges on database $db to oph;"
PGPASSWORD=$master_pw psql -h $host --user oph_group --dbname $db --command "grant all privileges on all tables in schema public to oph;"
PGPASSWORD=$master_pw psql -h $host --user oph_group --dbname $db --command "grant all privileges on all sequences in schema public to oph;"
PGPASSWORD=$master_pw psql -h $host --user oph_group --dbname $db --command "grant all privileges on schema public to oph;"
echo ""
echo "Role 'oph_group' is not needed anymore, drop it."
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "drop role oph_group;"
echo ""
echo "Creating user insert_raw_user nad role insert_raw_role (for IAM authentication)"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "create schema raw;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "create role insert_raw_role;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant usage on schema raw to insert_raw_role;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant select on all sequences in schema raw to insert_raw_role;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant select on all tables in schema raw to insert_raw_role;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant insert on all tables in schema raw to insert_raw_role;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "create user insert_raw_user;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant rds_iam to insert_raw_user;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant insert_raw_role to insert_raw_user;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant truncate on all tables in schema raw to insert_raw_role;"
echo "Creating AWS S3 extension"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "create extension aws_s3 cascade;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant usage on schema aws_s3 to app;"
PGPASSWORD=$master_pw psql -h $host --user oph --dbname $db --command "grant execute on all functions in schema aws_s3 to app;"
echo ""
echo "Creating session tables for ovara-virkailija"
PGPASSWORD=$app_pw psql -h $host --user app --dbname $db --command "CREATE SCHEMA IF NOT EXISTS OVARA_VIRKAILIJA_SESSION;"
PGPASSWORD=$app_pw psql -h $host --user app --dbname $db --command "CREATE UNLOGGED TABLE IF NOT EXISTS OVARA_VIRKAILIJA_SESSION.VIRKAILIJA_SESSION (
    PRIMARY_ID CHAR(36) NOT NULL,
    SESSION_ID CHAR(36) NOT NULL,
    CREATION_TIME BIGINT NOT NULL,
    LAST_ACCESS_TIME BIGINT NOT NULL,
    MAX_INACTIVE_INTERVAL INT NOT NULL,
    EXPIRY_TIME BIGINT NOT NULL,
    PRINCIPAL_NAME VARCHAR(100),
    CONSTRAINT VIRKAILIJA_SESSION_PK PRIMARY KEY (PRIMARY_ID)
);"
PGPASSWORD=$app_pw psql -h $host --user app --dbname $db --command "CREATE UNIQUE INDEX IF NOT EXISTS VIRKAILIJA_SESSION_IX1 ON OVARA_VIRKAILIJA_SESSION.VIRKAILIJA_SESSION (SESSION_ID);"
PGPASSWORD=$app_pw psql -h $host --user app --dbname $db --command "CREATE INDEX IF NOT EXISTS VIRKAILIJA_SESSION_IX2 ON OVARA_VIRKAILIJA_SESSION.VIRKAILIJA_SESSION (EXPIRY_TIME);"
PGPASSWORD=$app_pw psql -h $host --user app --dbname $db --command "CREATE INDEX IF NOT EXISTS VIRKAILIJA_SESSION_IX3 ON OVARA_VIRKAILIJA_SESSION.VIRKAILIJA_SESSION (PRINCIPAL_NAME);"
PGPASSWORD=$app_pw psql -h $host --user app --dbname $db --command "CREATE UNLOGGED TABLE IF NOT EXISTS OVARA_VIRKAILIJA_SESSION.VIRKAILIJA_SESSION_ATTRIBUTES (
    SESSION_PRIMARY_ID CHAR(36) NOT NULL,
    ATTRIBUTE_NAME VARCHAR(200) NOT NULL,
    ATTRIBUTE_BYTES BYTEA NOT NULL,
    CONSTRAINT VIRKAILIJA_SESSION_ATTRIBUTES_PK PRIMARY KEY (SESSION_PRIMARY_ID, ATTRIBUTE_NAME),
    CONSTRAINT VIRKAILIJA_SESSION_ATTRIBUTES_FK FOREIGN KEY (SESSION_PRIMARY_ID) REFERENCES OVARA_VIRKAILIJA_SESSION.VIRKAILIJA_SESSION(PRIMARY_ID) ON DELETE CASCADE
);"
PGPASSWORD=$app_pw psql -h $host --user app --dbname $db --command "CREATE UNLOGGED TABLE IF NOT EXISTS OVARA_VIRKAILIJA_SESSION.VIRKAILIJA_CAS_CLIENT_SESSION (
    MAPPED_TICKET_ID VARCHAR PRIMARY KEY,
    VIRKAILIJA_SESSION_ID CHAR(36) NOT NULL UNIQUE,
    CONSTRAINT VIRKAILIJA_CAS_CLIENT_SESSION_FK FOREIGN KEY (VIRKAILIJA_SESSION_ID) REFERENCES OVARA_VIRKAILIJA_SESSION.VIRKAILIJA_SESSION(SESSION_ID) ON DELETE CASCADE
);"
PGPASSWORD=$app_pw psql -h $host --user app --dbname $db --command "CREATE UNIQUE INDEX IF NOT EXISTS VIRKAILIJA_CAS_CLIENT_SESSION_IX1 ON OVARA_VIRKAILIJA_SESSION.VIRKAILIJA_CAS_CLIENT_SESSION (MAPPED_TICKET_ID);"
echo ""
echo "DONE!"
