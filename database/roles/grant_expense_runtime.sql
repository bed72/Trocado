-- Execute as the schema owner in each database after migrations.
GRANT USAGE ON SCHEMA public TO trocado_runtime;
REVOKE CREATE ON SCHEMA public FROM trocado_runtime;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE users, personal_access_tokens, expenses TO trocado_runtime;
GRANT USAGE, SELECT ON SEQUENCE users_id_seq, personal_access_tokens_id_seq, expenses_id_seq TO trocado_runtime;
REVOKE TRUNCATE, REFERENCES, TRIGGER ON TABLE users, personal_access_tokens, expenses FROM trocado_runtime;
