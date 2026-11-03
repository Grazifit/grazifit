# Handoff: telas de professor (front) → integração com o backend

Para quem vai ligar estas telas ao backend. Todas são **protótipo visual**: sem rede, sem estado compartilhado, dados fictícios do mockup. Nada aqui foi inventado: cada dado aponta para a coluna do schema ou para o endpoint que existe. Onde **não existe**, está marcado como lacuna e precisa de decisão do time antes de implementar.

No código, procure por `TODO(backend)` nas telas abaixo:

```
rg "TODO\(backend\)" app/lib
```

## 1. Como a arquitetura pede a ligação

`docs/guia-desenvolvimento.md` define o caminho: `screens/ → state/ → data/ → core/network/`.

- A tela **não chama `data/` direto**. Ela lê um provider em `state/` que devolve `AsyncState` com os cinco estados (carregando, vazio, erro, sem conexão, dados).
- Hoje `app/lib/core/network/`, `core/state/` e `core/routing/` estão vazios (só `.gitkeep`), e o `pubspec.yaml` do app **não tem** Riverpod nem cliente HTTP. Adicionar dependência exige aprovação.
- As telas já recebem os dados por construtor ou por constantes no topo do arquivo. Para ligar, troque a constante/default por dados vindos do provider. O layout não deve mudar (regra de fidelidade ao mockup).
- Erros: o envelope é `{ codigo, mensagem, campo? }` (`shared/lib/erros/codigo_erro.dart`). **O texto da tela é escolhido pelo `codigo`**, nunca pela `mensagem`.

## 2. Mapa tela por tela

| Tela (arquivo) | O que é fixo hoje | De onde deve vir | Backend hoje |
|---|---|---|---|
| **Perfil do professor** (`pessoas/screens/perfil_professor_screen.dart`) | nome, e-mail, telefone, CPF, "Professora desde" | `professor.nome/email/telefone/cpf/data_cadastro` | `GET /professor/<id>` existe, mas ver L1 e L2 |
| **Editar perfil do professor** (`pessoas/screens/editar_perfil_professor_screen.dart`) | valores iniciais; botão só valida | `PATCH /professor/<id>` com `nome` e `telefone` | existe, mas ver L1, L5 e L6 |
| **Meus alunos** (`vinculos/screens/meus_alunos_screen.dart`) | lista, contador "8 alunos", busca local | `vinculo_professor_aluno` (status ativo) + última avaliação | **não existe** (L3) |
| **Detalhe do aluno** (`vinculos/screens/aluno_detalhe_screen.dart`) | saúde, "vínculo desde", contadores | `aluno.restricao_medica/observacao_saude`, `vinculo.data_inicio` | **não existe** (L3, L4) |
| **Treinos do aluno** (`treinos/screens/treinos_aluno_screen.dart`) | lista de treinos e alternância ao tocar | `treino` do aluno + `historico_treino` | **não existe** (L3, L7) |
| **Histórico de treinos** (`treinos/screens/historico_treinos_screen.dart`) | execuções e contador | `historico_treino` (30 dias) | **não existe** (L3) |
| **Alunos inativos** (`vinculos/screens/alunos_inativos_screen.dart`) | lista e "x dias sem acesso" | `aluno.data_ultimo_acesso` | **não existe** (L3) |

## 3. Navegação e parâmetros entre telas

```
Meus alunos ──(nome)──▶ Detalhe do aluno ──(nome)──▶ Treinos do aluno
     │  ▲                      │                         └─ "Montar novo treino" (tela não existe)
     │  └── chip "Meus alunos" ┤──(nome)──▶ Histórico de treinos
     ▼                         └─ "Avaliação física" (tela não existe)
Alunos inativos

Perfil do professor ──(nome, telefone, e-mail, cpf)──▶ Editar perfil do professor
```

- Hoje as telas trocam só o **nome** do aluno (`String`). Com backend, troque por **`id_aluno`** e busque os dados pelo id: nome não é chave.
- A **barra inferior** (Agenda / Alunos / Perfil) é exibida, mas **não navega** (`onSelecionar` nulo). O destino de cada aba depende do desenho de rotas (`core/routing/`, `go_router`), que é estrutural e pede aprovação.
- **Salvar em Editar perfil não atualiza o Perfil** hoje. Ao ligar, o Perfil precisa recarregar (ou o provider ser invalidado) depois do PATCH.

## 4. Lacunas e decisões para o time (não resolvidas no código)

**L1. Professor não consegue ler nem editar o próprio perfil.**
`ProfessorService.buscarPorId` e `atualizar` chamam `exigirAdmin(identidade)`. O mockup mostra o professor editando nome e telefone. Precisa de decisão de RBAC (matriz em `docs/arquitetura.md`, teste automatizado). Qualquer mudança é aprovação obrigatória.

**L2. O DTO público de professor não traz `cpf` nem `data_cadastro`.**
`shared/lib/dtos/professor_serializer.dart` devolve só `id_professor, nome, email, telefone, status`. A tela de Perfil mostra CPF e "Professora desde". Pelo guia, é **um DTO por perfil**: precisa de um DTO da visão do próprio professor. Observação: o schema (`database/schema/grazi_db_init_schema.sql`) tem `professor.data_cadastro` e `data_ultimo_acesso`, mas a classe Drift `professor_tables.dart` que li não declara essas colunas nem `id_endereco`. Vale conferir se ela está desatualizada em relação ao SQL (o schema é a autoridade, D58).

**L3. Não existe backend para vínculos, treinos, avaliações, agendamentos.**
Em `backend/lib/features/` essas pastas só têm `README.md`. O único endpoint de aluno é o do admin (`GET /aluno?limit&offset`, não filtra por professor). Essas cinco telas dependem das fatias dessas features.

**L4. DTO de aluno para o professor.**
`alunoToPublicJson` é "aluno como o admin o enxerga" (sem saúde). O Detalhe do aluno precisa de `restricao_medica` e `observacao_saude`. Dado clínico vazado para o perfil errado é tratado como incidente de LGPD (`docs/arquitetura.md`), então precisa de DTO próprio e teste de RBAC.

**L5. Telefone: com máscara ou só dígitos?**
A tela usa a máscara `(45) 90000-0001` (15 caracteres). O backend aceita até 20 e **não normaliza** o telefone (o CPF ele normaliza). O helper do mockup diz "Somente números". Definir o formato enviado e o exibido.

**L6. Forma dos erros de validação no backend.**
Erros de forma (campo ausente, tamanho) voltam como `{ "erro": "..." }` (`_erroDeForma`), não no envelope `{ codigo, mensagem, campo }`. Os códigos `CAMPO_OBRIGATORIO` e `CAMPO_INVALIDO` existem no enum mas o controller de professor não os usa. A tela precisa tratar os dois formatos ou o backend padronizar.

**L7. Quem confirmou a execução do treino.**
`historico_treino` não registra quem confirmou (lacuna já mapeada em `.claude/skills/nao-inventar`, D29). A tela de Treinos do aluno deixa o professor confirmar a execução. Não contornar: levar ao time.

**L8. Regra de senha divergente (vale para o Cadastro de professor).**
O app (`Validadores.senha`) exige 8+ caracteres, 1 maiúscula e 1 especial, sem limite máximo. O backend exige de 8 a 12. Uma senha de 13+ passa no app e é recusada no servidor.

## 5. O que cada tela precisa implementar ao ligar

Todas as telas que carregam dado precisam dos cinco estados (RNF-04): **carregando, vazio, erro, sem conexão, dados**. O protótipo só tem o "dados" e, em Meus alunos e Inativos, um texto de vazio ("Nenhum aluno encontrado") para a busca. Os textos dos outros estados **não estão no mockup**: não inventar, pedir ao design/time.

## 6. Checklist de integração

- [ ] Resolver L1 e L2 antes de ligar Perfil e Editar perfil do professor.
- [ ] Trocar `nome` por `id_aluno` na navegação entre as telas de aluno.
- [ ] Criar `data/` + `state/` da feature (sem chamar `data/` direto da tela).
- [ ] Cobrir os cinco estados em cada tela.
- [ ] Tratar o envelope de erro pelo `codigo` (e o formato `{erro}`, L6).
- [ ] Ligar a barra inferior após a decisão de rotas.
- [ ] Rodar `flutter analyze` e abrir cada tela pelo menu dev (`lib/dev/menu_dev_screen.dart`).
- [ ] Manter `database/schema/grazi_db_init_schema.sql` intocado, salvo migration aprovada.
