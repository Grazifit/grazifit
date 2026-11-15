-- O executor aplica este arquivo e o registro em uma unica transacao.
LOCK TABLE admin, professor, aluno IN SHARE ROW EXCLUSIVE MODE;

CREATE TABLE identidade_email (
    email TEXT NOT NULL CONSTRAINT uq_conta_email UNIQUE,
    papel TEXT NOT NULL CHECK (papel IN ('admin', 'professor', 'aluno')),
    id_usuario INTEGER NOT NULL,
    PRIMARY KEY (papel, id_usuario)
);

-- Uma colisao existente aborta toda a migracao. Resolver os cadastros
-- com seus responsaveis antes de repetir; nunca escolher uma conta aqui.
INSERT INTO identidade_email (email, papel, id_usuario)
SELECT lower(btrim(email::text)), 'admin', id_admin FROM admin
UNION ALL
SELECT lower(btrim(email::text)), 'professor', id_professor FROM professor
UNION ALL
SELECT lower(btrim(email::text)), 'aluno', id_aluno FROM aluno;

CREATE FUNCTION fn_identidade_email() RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    id_atual INTEGER;
BEGIN
    IF TG_OP = 'DELETE' THEN
        DELETE FROM identidade_email
         WHERE papel = TG_TABLE_NAME
           AND id_usuario = (to_jsonb(OLD)->>TG_ARGV[0])::integer;
        RETURN OLD;
    END IF;
    NEW.email := lower(btrim(NEW.email::text));
    id_atual := (to_jsonb(NEW)->>TG_ARGV[0])::integer;
    IF TG_OP = 'UPDATE' THEN
        DELETE FROM identidade_email
         WHERE papel = TG_TABLE_NAME
           AND id_usuario = (to_jsonb(OLD)->>TG_ARGV[0])::integer;
    END IF;
    INSERT INTO identidade_email(email, papel, id_usuario)
    VALUES (NEW.email, TG_TABLE_NAME, id_atual);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_admin_identidade_email
BEFORE INSERT OR UPDATE OF email, id_admin OR DELETE ON admin
FOR EACH ROW EXECUTE FUNCTION fn_identidade_email('id_admin');
CREATE TRIGGER trg_professor_identidade_email
BEFORE INSERT OR UPDATE OF email, id_professor OR DELETE ON professor
FOR EACH ROW EXECUTE FUNCTION fn_identidade_email('id_professor');
CREATE TRIGGER trg_aluno_identidade_email
BEFORE INSERT OR UPDATE OF email, id_aluno OR DELETE ON aluno
FOR EACH ROW EXECUTE FUNCTION fn_identidade_email('id_aluno');

UPDATE admin SET email = lower(btrim(email::text));
UPDATE professor SET email = lower(btrim(email::text));
UPDATE aluno SET email = lower(btrim(email::text));
