---
name: nao-inventar
description: Proibição de inventar funcionalidades, campos, regras de negócio, endpoints ou dados que não estejam no schema, na arquitetura ou nas specs do GraziFit. Use sempre que uma informação necessária não estiver nas fontes oficiais.
metadata:
  source: docs/prompt-mestre.md seção 8, adaptada para o repositório de implementação
---

# Não Inventar

É proibido, em qualquer fase da implementação:

- inventar tabela, coluna, constraint ou índice;
- inventar campo em DTO;
- inventar endpoint ou parâmetro;
- inventar regra de negócio;
- inventar permissão ou escopo de RBAC;
- inventar estado de tela, mensagem de erro ou texto de interface;
- inventar dados de usuário, médicos ou financeiros;
- presumir comportamento que não esteja documentado.

Quando a informação não estiver em `database/schema/grazi_db_init_schema.sql`, `docs/arquitetura.md`, `docs/guia-desenvolvimento.md` ou nas specs do repositório de design, **não preencha a lacuna** — mesmo que ela pareça pequena, óbvia ou trivial.

## Lacunas conhecidas onde isto morde

O schema tem ausências já mapeadas. Elas são reais e nenhuma deve ser contornada por conta própria:

- **`agendamento` não registra quem marcou presença** — e **D5** dá a marcação a professor e admin
- **`historico_treino` não registra quem confirmou a execução** — **D29** dá isso a aluno e professor
- **`avaliacao` não registra quem registrou** — **D4** e **D37** dão isso aos três perfis
- **`admin`, `treino` e `exercicio` não têm `status`** — não há como arquivar nenhum dos três

Se uma tarefa exigir qualquer uma dessas informações, **pare**. Não acrescente coluna, não infira o autor pelo token da sessão, não use `id_admin_criador` como se fosse autoria da ação.

## Protocolo de ambiguidade

1. **Identificar** com precisão o que falta ou é ambíguo.
2. **Apresentar** ao usuário, citando o arquivo e a linha onde a lacuna aparece.
3. **Indicar** as interpretações plausíveis, com o custo de cada uma.
4. **Aguardar** a decisão antes de prosseguir.

Nunca escolher uma interpretação e seguir em silêncio. Um código que roda em cima de uma suposição não declarada é pior que um código que não existe: ele parece pronto.

Ver `aprovacao-obrigatoria` para o formato da proposta, e `fidelidade-manual-marca` quando a lacuna for de interface.
