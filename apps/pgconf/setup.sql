
-- Function used to create roles at startup when we don't yet know if the database is new
-- or if it's being restored from backup. This will update the passwords for existing users.
CREATE OR REPLACE FUNCTION create_or_update_role_with_password(rolename TEXT, rolepassword TEXT) RETURNS VOID AS
$$
BEGIN
  IF NOT EXISTS (SELECT * FROM pg_roles WHERE rolname = rolename) THEN
    EXECUTE 'CREATE USER "' || rolename || '" WITH PASSWORD ''' || rolepassword || '''';
    RAISE NOTICE 'CREATE USER "%" WITH PASSWORD ''%''', rolename, rolepassword;
  ELSE
    EXECUTE 'ALTER USER "' || rolename || '" WITH PASSWORD ''' || rolepassword || '''';
    RAISE NOTICE 'ALTER USER "%" WITH PASSWORD ''%''', rolename, rolepassword;
  END IF;
END;
$$
LANGUAGE plpgsql;

-- change passwords of admin users
SELECT create_or_update_role_with_password('postgres', 'PG_ROOT_PASSWORD');
SELECT create_or_update_role_with_password('PG_PRIMARY_USER', 'PG_PRIMARY_PASSWORD');
SELECT create_or_update_role_with_password('PG_USER', 'PG_PASSWORD');
ALTER USER "PG_PRIMARY_USER" WITH REPLICATION;

-- Function used to parse CSV list of strings
CREATE OR REPLACE FUNCTION create_or_update_credentials(user_list text[], password_list text[]) RETURNS VOID AS
$$
BEGIN
  FOR i IN 1 .. array_upper(user_list, 1)
  LOOP
    PERFORM create_or_update_role_with_password(user_list[i], password_list[i]);
  END LOOP;
END;
$$
LANGUAGE plpgsql;

-- create database
CREATE DATABASE PG_DATABASE WITH OWNER = PG_USER ENCODING = 'UTF8' TABLESPACE = pg_default LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8' CONNECTION LIMIT = -1 TEMPLATE template0;
\c PG_DATABASE

-- enable required extensions
create extension pgcrypto;
create extension pg_stat_statements;
create extension pgaudit;

grant all privileges on database PG_DATABASE to PG_USER;
grant all on all tables in schema public to PG_USER;

