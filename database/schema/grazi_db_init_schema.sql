BEGIN;

-- ============================================================
-- DOMINIOS
-- ============================================================

CREATE DOMAIN dom_cpf AS VARCHAR(11)
    CHECK (VALUE ~ '^\d{11}$');

CREATE DOMAIN dom_email AS VARCHAR(255)
    CHECK (VALUE ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$');

-- ============================================================
-- TABELAS BASE
-- ============================================================

CREATE TABLE endereco (
    id_endereco   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rua           VARCHAR(150) NOT NULL,
    numero        VARCHAR(10)  NOT NULL,
    complemento   VARCHAR(60),
    bairro        VARCHAR(100) NOT NULL,
    cidade        VARCHAR(100) NOT NULL,
    uf            CHAR(2)      NOT NULL,
    cep           VARCHAR(8)   NOT NULL,
    pais          VARCHAR(60)  NOT NULL DEFAULT 'Brasil',

    CONSTRAINT ck_endereco_cep CHECK (cep ~ '^\d{8}$'),
    CONSTRAINT ck_endereco_uf  CHECK (uf ~ '^[A-Z]{2}$')
);

CREATE TABLE admin (
    id_admin      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cpf           dom_cpf      NOT NULL,
    senha_hash    VARCHAR(255) NOT NULL,
    nome          VARCHAR(150) NOT NULL,
    email         dom_email    NOT NULL,
    telefone      VARCHAR(20),

    CONSTRAINT uq_admin_cpf   UNIQUE (cpf),
    CONSTRAINT uq_admin_email UNIQUE (email)
);

CREATE TABLE professor (
    id_professor        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_admin_criador    INT,
    id_endereco         INT,
    cpf                 dom_cpf      NOT NULL,
    senha_hash          VARCHAR(255) NOT NULL,
    nome                VARCHAR(150) NOT NULL,
    telefone            VARCHAR(20)  NOT NULL,
    email               dom_email    NOT NULL,
    status              BOOLEAN      NOT NULL DEFAULT TRUE,
    data_cadastro       DATE         NOT NULL DEFAULT CURRENT_DATE,
    data_ultimo_acesso  TIMESTAMPTZ,          -- nulo = nunca acessou

    CONSTRAINT uq_professor_cpf   UNIQUE (cpf),
    CONSTRAINT uq_professor_email UNIQUE (email),

    CONSTRAINT fk_professor_admin
        FOREIGN KEY (id_admin_criador) REFERENCES admin (id_admin)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_professor_endereco
        FOREIGN KEY (id_endereco) REFERENCES endereco (id_endereco)
        ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE TABLE aluno (
    id_aluno            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_admin_criador    INT,
    id_endereco         INT,
    cpf                 dom_cpf      NOT NULL,
    senha_hash          VARCHAR(255) NOT NULL,
    nome                VARCHAR(150) NOT NULL,
    data_nascimento     DATE         NOT NULL,
    telefone            VARCHAR(20)  NOT NULL,
    email               dom_email    NOT NULL,
    restricao_medica    TEXT,
    observacao_saude    TEXT,
    status              BOOLEAN      NOT NULL DEFAULT TRUE,
    data_cadastro       DATE         NOT NULL DEFAULT CURRENT_DATE,
    data_ultimo_acesso  TIMESTAMPTZ,

    CONSTRAINT uq_aluno_cpf   UNIQUE (cpf),
    CONSTRAINT uq_aluno_email UNIQUE (email),
    CONSTRAINT ck_aluno_nascimento CHECK (data_nascimento < CURRENT_DATE),

    CONSTRAINT fk_aluno_admin
        FOREIGN KEY (id_admin_criador) REFERENCES admin (id_admin)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_aluno_endereco
        FOREIGN KEY (id_endereco) REFERENCES endereco (id_endereco)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- NOTA: peso/altura/imc foram REMOVIDOS de ALUNO.
-- Sao dado historico e vivem em AVALIACAO. A medida atual do aluno
-- e lida pela view vw_aluno_medida_atual (no fim deste script).

-- ============================================================
-- AVALIACAO FISICA
-- ============================================================

CREATE TABLE avaliacao (
    id_avaliacao     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_aluno         INT          NOT NULL,
    data_avaliacao   DATE         NOT NULL DEFAULT CURRENT_DATE,
    peso             NUMERIC(5,2) NOT NULL,   -- kg
    altura           NUMERIC(3,2) NOT NULL,   -- metros
    imc              NUMERIC(5,2)
                     GENERATED ALWAYS AS (peso / (altura * altura)) STORED,
    observacao       TEXT,

    CONSTRAINT ck_avaliacao_peso   CHECK (peso   > 0 AND peso   < 500),
    CONSTRAINT ck_avaliacao_altura CHECK (altura > 0 AND altura < 3),
    CONSTRAINT uq_avaliacao_aluno_data UNIQUE (id_aluno, data_avaliacao),

    CONSTRAINT fk_avaliacao_aluno
        FOREIGN KEY (id_aluno) REFERENCES aluno (id_aluno)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
-- VINCULO PROFESSOR x ALUNO
-- ============================================================

CREATE TABLE vinculo_professor_aluno (
    id_vinculo    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_professor  INT     NOT NULL,
    id_aluno      INT     NOT NULL,
    data_inicio   DATE    NOT NULL DEFAULT CURRENT_DATE,
    data_fim      DATE,
    status        BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT ck_vinculo_periodo
        CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    -- vinculo inativo precisa ter data de encerramento
    CONSTRAINT ck_vinculo_encerramento
        CHECK (status = TRUE OR data_fim IS NOT NULL),

    CONSTRAINT fk_vinculo_professor
        FOREIGN KEY (id_professor) REFERENCES professor (id_professor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_vinculo_aluno
        FOREIGN KEY (id_aluno) REFERENCES aluno (id_aluno)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Garante no maximo UM vinculo ativo por aluno
CREATE UNIQUE INDEX uq_vinculo_aluno_ativo
    ON vinculo_professor_aluno (id_aluno)
    WHERE status = TRUE;

-- ============================================================
-- CRONOGRAMA (padrao de recorrencia)
-- ============================================================

CREATE TABLE cronograma (
    id_cronograma     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_admin_criador  INT,
    id_professor      INT         NOT NULL,
    categoria         VARCHAR(40) NOT NULL,
    hora_inicio       TIME        NOT NULL,
    hora_fim          TIME        NOT NULL,
    data_inicio       DATE        NOT NULL,
    data_fim          DATE,                    -- nulo = sem prazo definido
    vagas_maxima      INT         NOT NULL,
    status            BOOLEAN     NOT NULL DEFAULT TRUE,

    CONSTRAINT ck_cronograma_categoria
        CHECK (categoria IN ('musculacao','funcional','pilates','crossfit','danca','spinning')),
    CONSTRAINT ck_cronograma_horario CHECK (hora_fim > hora_inicio),
    CONSTRAINT ck_cronograma_periodo
        CHECK (data_fim IS NULL OR data_fim >= data_inicio),
    CONSTRAINT ck_cronograma_vagas CHECK (vagas_maxima > 0),

    CONSTRAINT fk_cronograma_admin
        FOREIGN KEY (id_admin_criador) REFERENCES admin (id_admin)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_cronograma_professor
        FOREIGN KEY (id_professor) REFERENCES professor (id_professor)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Normalizacao de DIAS_AULA (antes era VARCHAR "SEG,QUA,SEX" - violava 1FN)
-- dia_semana segue ISO/PostgreSQL: 0=domingo ... 6=sabado
CREATE TABLE cronograma_dia (
    id_cronograma  INT      NOT NULL,
    dia_semana     SMALLINT NOT NULL,

    PRIMARY KEY (id_cronograma, dia_semana),
    CONSTRAINT ck_cronograma_dia CHECK (dia_semana BETWEEN 0 AND 6),

    CONSTRAINT fk_cronograma_dia_cronograma
        FOREIGN KEY (id_cronograma) REFERENCES cronograma (id_cronograma)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ============================================================
-- AULA (instancia concreta)
-- ============================================================

CREATE TABLE aula (
    id_aula                 INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_admin_criador        INT,
    id_professor            INT         NOT NULL,
    id_cronograma           INT,                     -- nulo = aula avulsa
    data                    DATE        NOT NULL,
    hora_inicio             TIME        NOT NULL,
    hora_fim                TIME        NOT NULL,
    tipo                    VARCHAR(20) NOT NULL,
    categoria               VARCHAR(40) NOT NULL,
    vagas_maxima            INT         NOT NULL,
    status                  BOOLEAN     NOT NULL DEFAULT TRUE,
    id_professor_cancelou   INT,
    id_admin_cancelou       INT,
    data_cancelamento       TIMESTAMPTZ,

    CONSTRAINT ck_aula_tipo
        CHECK (tipo IN ('coletiva','individual','experimental')),
    CONSTRAINT ck_aula_categoria
        CHECK (categoria IN ('musculacao','funcional','pilates','crossfit','danca','spinning')),
    CONSTRAINT ck_aula_horario CHECK (hora_fim > hora_inicio),
    CONSTRAINT ck_aula_vagas   CHECK (vagas_maxima > 0),

    -- D13: cronograma e sempre em grupo; personal so por aula avulsa.
    CONSTRAINT ck_aula_cronograma_tipo
        CHECK (id_cronograma IS NULL OR tipo = 'coletiva'),

    -- D11: personal comporta de 1 a 3 alunos.
    CONSTRAINT ck_aula_personal_vagas
        CHECK (tipo <> 'individual' OR vagas_maxima BETWEEN 1 AND 3),

    -- Cancelamento coerente: ou nada preenchido, ou data + exatamente um responsavel
    CONSTRAINT ck_aula_cancelamento CHECK (
        (id_professor_cancelou IS NULL
         AND id_admin_cancelou IS NULL
         AND data_cancelamento IS NULL)
        OR
        (data_cancelamento IS NOT NULL
         AND (id_professor_cancelou IS NULL) <> (id_admin_cancelou IS NULL))
    ),
    -- Aula cancelada obrigatoriamente tem status FALSE
    CONSTRAINT ck_aula_status_cancelada
        CHECK (data_cancelamento IS NULL OR status = FALSE),

    -- Impede duas aulas do mesmo professor no mesmo horario
    CONSTRAINT uq_aula_professor_horario
        UNIQUE (id_professor, data, hora_inicio),

    CONSTRAINT fk_aula_admin
        FOREIGN KEY (id_admin_criador) REFERENCES admin (id_admin)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_aula_professor
        FOREIGN KEY (id_professor) REFERENCES professor (id_professor)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_aula_cronograma
        FOREIGN KEY (id_cronograma) REFERENCES cronograma (id_cronograma)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_aula_professor_cancelou
        FOREIGN KEY (id_professor_cancelou) REFERENCES professor (id_professor)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_aula_admin_cancelou
        FOREIGN KEY (id_admin_cancelou) REFERENCES admin (id_admin)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- ============================================================
-- AGENDAMENTO
-- ============================================================

CREATE TABLE agendamento (
    id_agendamento     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_aluno           INT         NOT NULL,
    id_aula            INT         NOT NULL,
    data_agendamento   DATE        NOT NULL DEFAULT CURRENT_DATE,
    status             VARCHAR(15) NOT NULL DEFAULT 'agendado',
    data_presenca      TIMESTAMPTZ,
    data_cancelamento  TIMESTAMPTZ,

    CONSTRAINT ck_agendamento_status
        CHECK (status IN ('agendado','presente','faltou','cancelado')),
    -- Coerencia entre status e as datas
    CONSTRAINT ck_agendamento_presenca
        CHECK ((status = 'presente') = (data_presenca IS NOT NULL)),
    CONSTRAINT ck_agendamento_cancelamento
        CHECK ((status = 'cancelado') = (data_cancelamento IS NOT NULL)),

    CONSTRAINT uq_agendamento_aluno_aula UNIQUE (id_aluno, id_aula),

    CONSTRAINT fk_agendamento_aluno
        FOREIGN KEY (id_aluno) REFERENCES aluno (id_aluno)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_agendamento_aula
        FOREIGN KEY (id_aula) REFERENCES aula (id_aula)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
-- EXERCICIO / TREINO
-- ============================================================

CREATE TABLE exercicio (
    id_exercicio      INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_admin_criador  INT          NOT NULL,
    nome              VARCHAR(120) NOT NULL,
    instrucoes        TEXT         NOT NULL,
    descricao         TEXT,
    dificuldade       VARCHAR(15)  NOT NULL DEFAULT 'iniciante',

    CONSTRAINT ck_exercicio_dificuldade
        CHECK (dificuldade IN ('iniciante','intermediario','avancado')),
    CONSTRAINT uq_exercicio_nome UNIQUE (nome),

    CONSTRAINT fk_exercicio_admin
        FOREIGN KEY (id_admin_criador) REFERENCES admin (id_admin)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- TREINO:
--   id_admin preenchido                  -> treino livre / padrao do sistema
--   id_professor + id_aluno preenchidos  -> treino personalizado
CREATE TABLE treino (
    id_treino     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_admin      INT,
    id_aluno      INT,
    id_professor  INT,
    nome          VARCHAR(120) NOT NULL,
    tipo          VARCHAR(20)  NOT NULL,

    CONSTRAINT ck_treino_tipo
        CHECK (tipo IN ('forca','hipertrofia','resistencia','cardio','mobilidade')),
    CONSTRAINT ck_treino_origem CHECK (
        (id_admin IS NOT NULL AND id_aluno IS NULL     AND id_professor IS NULL)
        OR
        (id_admin IS NULL     AND id_aluno IS NOT NULL AND id_professor IS NOT NULL)
    ),

    CONSTRAINT fk_treino_admin
        FOREIGN KEY (id_admin) REFERENCES admin (id_admin)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_treino_aluno
        FOREIGN KEY (id_aluno) REFERENCES aluno (id_aluno)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_treino_professor
        FOREIGN KEY (id_professor) REFERENCES professor (id_professor)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE treino_exercicio (
    id_treino_exercicio INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_treino           INT         NOT NULL,
    id_exercicio        INT         NOT NULL,
    ordem               INT         NOT NULL,
    series              INT         NOT NULL,
    repeticoes          INT         NOT NULL,
    carga               VARCHAR(30) NOT NULL,

    CONSTRAINT ck_treino_exercicio_series     CHECK (series     > 0),
    CONSTRAINT ck_treino_exercicio_repeticoes CHECK (repeticoes > 0),
    CONSTRAINT ck_treino_exercicio_ordem      CHECK (ordem      > 0),
    CONSTRAINT uq_treino_exercicio_ordem UNIQUE (id_treino, ordem),

    CONSTRAINT fk_treino_exercicio_treino
        FOREIGN KEY (id_treino) REFERENCES treino (id_treino)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_treino_exercicio_exercicio
        FOREIGN KEY (id_exercicio) REFERENCES exercicio (id_exercicio)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE historico_treino (
    id_historico     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_treino        INT     NOT NULL,
    id_aluno         INT     NOT NULL,
    data_execucao    DATE    NOT NULL DEFAULT CURRENT_DATE,
    status           BOOLEAN NOT NULL DEFAULT TRUE,
    observacao       TEXT,

    CONSTRAINT ck_historico_data CHECK (data_execucao <= CURRENT_DATE),

    CONSTRAINT fk_historico_treino
        FOREIGN KEY (id_treino) REFERENCES treino (id_treino)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_historico_aluno
        FOREIGN KEY (id_aluno) REFERENCES aluno (id_aluno)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ============================================================
-- INDICES
-- O PostgreSQL NAO cria indice automatico para FK.
-- ============================================================

CREATE INDEX idx_professor_admin        ON professor (id_admin_criador);
CREATE INDEX idx_professor_endereco     ON professor (id_endereco);
-- D23: painel de inativos, corte de 30 dias. Nulo = nunca acessou.
CREATE INDEX idx_professor_ultimo_acesso ON professor (data_ultimo_acesso);

CREATE INDEX idx_aluno_admin            ON aluno (id_admin_criador);
CREATE INDEX idx_aluno_endereco         ON aluno (id_endereco);
CREATE INDEX idx_aluno_nome             ON aluno (nome);
-- D23: painel de inativos, corte de 30 dias. Nulo = nunca acessou.
CREATE INDEX idx_aluno_ultimo_acesso    ON aluno (data_ultimo_acesso);

CREATE INDEX idx_avaliacao_aluno_data   ON avaliacao (id_aluno, data_avaliacao DESC);

CREATE INDEX idx_vinculo_professor      ON vinculo_professor_aluno (id_professor);
CREATE INDEX idx_vinculo_aluno          ON vinculo_professor_aluno (id_aluno);

CREATE INDEX idx_cronograma_professor   ON cronograma (id_professor);
CREATE INDEX idx_cronograma_admin       ON cronograma (id_admin_criador);

CREATE INDEX idx_aula_professor         ON aula (id_professor);
CREATE INDEX idx_aula_cronograma        ON aula (id_cronograma);
CREATE INDEX idx_aula_admin             ON aula (id_admin_criador);
-- Query mais frequente do sistema: agenda do dia / da semana
CREATE INDEX idx_aula_data_status       ON aula (data, status);

CREATE INDEX idx_agendamento_aula       ON agendamento (id_aula);
CREATE INDEX idx_agendamento_aluno      ON agendamento (id_aluno);
CREATE INDEX idx_agendamento_status     ON agendamento (status);

CREATE INDEX idx_exercicio_admin        ON exercicio (id_admin_criador);

CREATE INDEX idx_treino_aluno           ON treino (id_aluno);
CREATE INDEX idx_treino_professor       ON treino (id_professor);
CREATE INDEX idx_treino_admin           ON treino (id_admin);

CREATE INDEX idx_treino_exercicio_trn   ON treino_exercicio (id_treino);
CREATE INDEX idx_treino_exercicio_ex    ON treino_exercicio (id_exercicio);

CREATE INDEX idx_historico_treino       ON historico_treino (id_treino);
CREATE INDEX idx_historico_aluno_data   ON historico_treino (id_aluno, data_execucao DESC);

-- ============================================================
-- CONTROLE DE VAGAS (concorrencia)
-- Sem isso, duas requisicoes simultaneas furam o limite de vagas.
-- O FOR UPDATE serializa o acesso a linha da aula.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_valida_vagas_aula()
RETURNS TRIGGER AS $$
DECLARE
    v_vagas     INT;
    v_ocupadas  INT;
    v_status    BOOLEAN;
BEGIN
    -- so valida quando o agendamento ocupa vaga
    IF NEW.status IN ('cancelado','faltou') THEN
        RETURN NEW;
    END IF;

    SELECT vagas_maxima, status
      INTO v_vagas, v_status
      FROM aula
     WHERE id_aula = NEW.id_aula
     FOR UPDATE;                       -- lock pessimista na aula

    IF v_status = FALSE THEN
        RAISE EXCEPTION 'Aula % esta cancelada/inativa.', NEW.id_aula
            USING ERRCODE = 'GF002';
    END IF;

    SELECT COUNT(*)
      INTO v_ocupadas
      FROM agendamento
     WHERE id_aula = NEW.id_aula
       AND status NOT IN ('cancelado','faltou')
       AND (TG_OP = 'INSERT' OR id_agendamento <> NEW.id_agendamento);

    IF v_ocupadas >= v_vagas THEN
        RAISE EXCEPTION
            'Aula % sem vagas disponiveis (% de %).',
            NEW.id_aula, v_ocupadas, v_vagas
            USING ERRCODE = 'GF001';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_vagas_aula
    BEFORE INSERT OR UPDATE OF id_aula, status ON agendamento
    FOR EACH ROW EXECUTE FUNCTION fn_valida_vagas_aula();

-- ============================================================
-- CONSISTENCIA AULA x CRONOGRAMA
-- Aula gerada por cronograma deve herdar categoria e professor.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_valida_aula_cronograma()
RETURNS TRIGGER AS $$
DECLARE
    v_categoria  VARCHAR(40);
    v_professor  INT;
BEGIN
    IF NEW.id_cronograma IS NULL THEN
        RETURN NEW;                    -- aula avulsa
    END IF;

    SELECT categoria, id_professor
      INTO v_categoria, v_professor
      FROM cronograma
     WHERE id_cronograma = NEW.id_cronograma;

    IF NEW.categoria <> v_categoria THEN
        RAISE EXCEPTION
            'Categoria da aula (%) difere do cronograma (%).',
            NEW.categoria, v_categoria
            USING ERRCODE = 'GF003';
    END IF;

    IF NEW.id_professor <> v_professor THEN
        RAISE EXCEPTION
            'Professor da aula (%) difere do cronograma (%).',
            NEW.id_professor, v_professor
            USING ERRCODE = 'GF004';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_valida_aula_cronograma
    BEFORE INSERT OR UPDATE OF id_cronograma, categoria, id_professor ON aula
    FOR EACH ROW EXECUTE FUNCTION fn_valida_aula_cronograma();

-- ============================================================
-- VIEWS DE APOIO
-- ============================================================

-- Medida fisica atual do aluno (substitui peso/altura/imc em ALUNO)
CREATE OR REPLACE VIEW vw_aluno_medida_atual AS
SELECT DISTINCT ON (a.id_aluno)
       a.id_aluno,
       a.nome,
       av.data_avaliacao,
       av.peso,
       av.altura,
       av.imc
  FROM aluno a
  LEFT JOIN avaliacao av ON av.id_aluno = a.id_aluno
 ORDER BY a.id_aluno, av.data_avaliacao DESC;

-- Ocupacao das aulas
CREATE OR REPLACE VIEW vw_aula_ocupacao AS
SELECT au.id_aula,
       au.data,
       au.hora_inicio,
       au.categoria,
       au.vagas_maxima,
       COUNT(ag.id_agendamento) FILTER (
           WHERE ag.status NOT IN ('cancelado','faltou')
       ) AS vagas_ocupadas,
       au.vagas_maxima - COUNT(ag.id_agendamento) FILTER (
           WHERE ag.status NOT IN ('cancelado','faltou')
       ) AS vagas_livres
  FROM aula au
  LEFT JOIN agendamento ag ON ag.id_aula = au.id_aula
 WHERE au.status = TRUE
 GROUP BY au.id_aula;

-- ============================================================
-- COMENTARIOS (dicionario de dados)
-- ============================================================

COMMENT ON COLUMN avaliacao.peso   IS 'Peso em quilogramas.';
COMMENT ON COLUMN avaliacao.altura IS 'Altura em METROS. Ex.: 1.78';
COMMENT ON COLUMN avaliacao.imc    IS 'Coluna gerada: peso / altura^2.';
COMMENT ON COLUMN cronograma_dia.dia_semana
    IS 'Dia da semana. 0=domingo, 1=segunda ... 6=sabado.';
COMMENT ON COLUMN aula.id_cronograma
    IS 'Nulo = aula avulsa. Preenchido = gerada a partir de recorrencia.';
COMMENT ON CONSTRAINT ck_aula_cronograma_tipo ON aula
    IS 'D13: aula gerada por cronograma e sempre coletiva.';
COMMENT ON CONSTRAINT ck_aula_personal_vagas ON aula
    IS 'D11: aula individual (personal) comporta de 1 a 3 alunos.';
COMMENT ON TABLE  treino
    IS 'id_admin = treino padrao do sistema. id_professor+id_aluno = personalizado.';

COMMIT;
