CREATE TABLE sessao_auth (
    jti_hash    CHAR(64) PRIMARY KEY,
    papel       VARCHAR(20) NOT NULL,
    id_usuario  INTEGER NOT NULL,
    criada_em   TIMESTAMPTZ NOT NULL DEFAULT now(),
    expira_em   TIMESTAMPTZ NOT NULL,
    revogada_em TIMESTAMPTZ,
    CONSTRAINT ck_sessao_auth_jti_hash
        CHECK (jti_hash ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_sessao_auth_papel
        CHECK (papel IN ('admin', 'professor', 'aluno')),
    CONSTRAINT ck_sessao_auth_id_usuario CHECK (id_usuario > 0),
    CONSTRAINT ck_sessao_auth_expiracao CHECK (expira_em > criada_em),
    CONSTRAINT ck_sessao_auth_revogacao
        CHECK (revogada_em IS NULL OR revogada_em >= criada_em)
);

CREATE INDEX ix_sessao_auth_identidade_ativa
    ON sessao_auth (papel, id_usuario)
    WHERE revogada_em IS NULL;

CREATE INDEX ix_sessao_auth_expira_em ON sessao_auth (expira_em);

-- Cada tabela tem uma coluna de id diferente. Funcoes explicitas evitam
-- que uma troca de senha revogue sessoes de outro papel com o mesmo id.
CREATE FUNCTION fn_revoga_sessoes_admin()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.senha_hash IS DISTINCT FROM NEW.senha_hash THEN
        UPDATE sessao_auth SET revogada_em = now()
         WHERE papel = 'admin' AND id_usuario = NEW.id_admin
           AND revogada_em IS NULL;
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION fn_revoga_sessoes_professor()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.senha_hash IS DISTINCT FROM NEW.senha_hash THEN
        UPDATE sessao_auth SET revogada_em = now()
         WHERE papel = 'professor' AND id_usuario = NEW.id_professor
           AND revogada_em IS NULL;
    END IF;
    RETURN NEW;
END;
$$;

CREATE FUNCTION fn_revoga_sessoes_aluno()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.senha_hash IS DISTINCT FROM NEW.senha_hash THEN
        UPDATE sessao_auth SET revogada_em = now()
         WHERE papel = 'aluno' AND id_usuario = NEW.id_aluno
           AND revogada_em IS NULL;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_revoga_sessoes_senha
AFTER UPDATE OF senha_hash ON admin
FOR EACH ROW EXECUTE FUNCTION fn_revoga_sessoes_admin();

CREATE TRIGGER trg_professor_revoga_sessoes_senha
AFTER UPDATE OF senha_hash ON professor
FOR EACH ROW EXECUTE FUNCTION fn_revoga_sessoes_professor();

CREATE TRIGGER trg_aluno_revoga_sessoes_senha
AFTER UPDATE OF senha_hash ON aluno
FOR EACH ROW EXECUTE FUNCTION fn_revoga_sessoes_aluno();
