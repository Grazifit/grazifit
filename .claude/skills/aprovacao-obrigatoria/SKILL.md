---
name: aprovacao-obrigatoria
description: Nenhuma alteração estrutural (schema, dependências, contratos, estrutura de pastas, endpoints, decisões D1–D67, fase do roadmap) pode ser executada sem aprovação prévia explícita do usuário. Use antes de qualquer mudança que não seja escrever código dentro do escopo já aprovado.
metadata:
  source: docs/prompt-mestre.md seções 9 e 29, adaptada para o repositório de implementação
---

# Aprovação Obrigatória

**Nenhuma alteração estrutural é executada sem aprovação prévia e explícita do usuário.**

No repositório de specs isso protegia telas, fluxos e tokens. Aqui protege as fundações que já custaram nove decisões de arquitetura — **D58** a **D67** — e um schema auditado.

## Exige aprovação

- alterar `database/schema/grazi_db_init_schema.sql` — tabela, coluna, constraint, índice, view, função ou trigger
- criar migration
- acrescentar, remover ou trocar dependência em qualquer `pubspec.yaml`
- criar ou alterar endpoint
- criar ou alterar contrato de DTO em `shared/`
- alterar a estrutura de pastas do monorepo
- **antecipar fase** — cada fase do prompt de implementação é uma aprovação separada
- alterar qualquer decisão **D1**–**D67**
- criar arquivo fora do que a fase corrente autoriza
- alterar token, componente ou tela em relação ao protótipo
- alterar configuração de plataforma (`android/`, `web/`), `applicationId` ou permissões
- introduzir cache local, persistência offline ou qualquer estado fora do servidor

## Não exige aprovação

Ler, analisar, mapear, comparar, identificar inconsistência, propor solução, documentar, apresentar alternativa — e escrever código **dentro** do escopo que a fase corrente já autorizou.

## Formato antes de qualquer mudança estrutural

Apresentar nesta ordem, e só prosseguir após autorização explícita:

**O que será alterado → Motivo → Impacto → Arquivos e especificações afetados → Resultado esperado**

Quando a mudança envolver o banco, incluir o efeito sobre constraints, triggers e views existentes — o schema é autoridade acima do código (**D58**).

## A regra que costuma ser esquecida

**Uma proposta parecer óbvia não é justificativa para executá-la.** O projeto tem 67 decisões registradas precisamente para que nenhuma seja tomada dentro do código, sob pressão de prazo. Se a resposta certa parece evidente e ainda assim não está escrita em lugar nenhum, isso é **escopo novo** — e escopo novo se propõe, não se implementa.

Ver `nao-inventar` para lacuna de informação, e `fidelidade-manual-marca` para qualquer decisão de interface.
