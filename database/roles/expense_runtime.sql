-- Execute as the schema owner after creating the databases, before migrations.
-- Set the LOGIN password separately with \password trocado_runtime in psql.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'trocado_runtime') THEN
        CREATE ROLE trocado_runtime LOGIN NOSUPERUSER NOBYPASSRLS NOCREATEDB NOCREATEROLE NOREPLICATION NOINHERIT;
    END IF;
END
$$;

REVOKE ALL ON DATABASE trocado FROM trocado_runtime;
REVOKE ALL ON DATABASE trocado_testing FROM trocado_runtime;
GRANT CONNECT ON DATABASE trocado TO trocado_runtime;
GRANT CONNECT ON DATABASE trocado_testing TO trocado_runtime;
