-- clock_timestamp acompanha o momento efetivo da revogacao mesmo quando
-- a transacao aguardou um login concorrente liberar o bloqueio da conta.
CREATE OR REPLACE FUNCTION fn_revoga_sessoes_admin()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.senha_hash IS DISTINCT FROM NEW.senha_hash THEN
        UPDATE sessao_auth SET revogada_em = GREATEST(clock_timestamp(), criada_em)
         WHERE papel = 'admin' AND id_usuario = NEW.id_admin AND revogada_em IS NULL;
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION fn_revoga_sessoes_professor()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.senha_hash IS DISTINCT FROM NEW.senha_hash THEN
        UPDATE sessao_auth SET revogada_em = GREATEST(clock_timestamp(), criada_em)
         WHERE papel = 'professor' AND id_usuario = NEW.id_professor AND revogada_em IS NULL;
    END IF;
    RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION fn_revoga_sessoes_aluno()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.senha_hash IS DISTINCT FROM NEW.senha_hash THEN
        UPDATE sessao_auth SET revogada_em = GREATEST(clock_timestamp(), criada_em)
         WHERE papel = 'aluno' AND id_usuario = NEW.id_aluno AND revogada_em IS NULL;
    END IF;
    RETURN NEW;
END;
$$;
