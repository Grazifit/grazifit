---
name: fidelidade-manual-marca
description: O protótipo do Figma e as specs de tela são a fonte executável da interface do GraziFit; o manual de marca é a fonte de cor, tipografia e logotipo. Implementar é reproduzir a moldura, não reinterpretá-la. Use sempre que estiver escrevendo, revisando ou decidindo qualquer coisa de UI.
metadata:
  source: docs/prompt-mestre.md seção 17, adaptada para o repositório de implementação
---

# Fidelidade ao Protótipo e ao Manual de Marca

No repositório de specs esta skill governava **decisões** visuais. Aqui ela governa **execução**: o desenho já foi feito, aprovado e auditado. Implementar não é decidir de novo.

## Ordem de autoridade visual

1. **Figma — protótipo navegável** (página 08): 60 molduras, 169 conexões, 24 de 24 fluxos
2. **Specs de tela** (`05-screens`): responsabilidade declarada de cada tela e seus estados
3. **Componentes** (`04-components`): 21 conjuntos, 92+ variantes
4. **Tokens** (`03-foundations`): 48 variáveis, 8 estilos de texto, 3 elevações
5. **Manual de marca**: cor, tipografia, logotipo, aplicações

O que está mais acima vence. Nenhum nível autoriza extrapolar o manual de marca.

## A regra que não se negocia

**A tela implementada tem de ser reconhecível como a moldura aprovada.** Diferença visível entre o que roda e o que está no Figma é **defeito**, não interpretação — e se corrige no código, nunca "corrigindo" a moldura.

Preferência estética não vence moldura aprovada. Não vence por ser mais moderna, mais limpa, mais acessível na sua opinião, nem porque uma biblioteca de componentes sugere outra coisa. As 60 molduras já passaram por auditoria de acessibilidade, responsividade, marca e RBAC.

## Tokens não se recriam

Nenhum valor de cor, espaçamento, raio, sombra ou tamanho de fonte é escrito à mão no código. Tudo vem dos tokens de foundations. Um literal de cor no código é sinal de que o token certo não foi encontrado — procure o token, não invente o valor.

## Componente antes de tela

Antes de escrever um widget novo, procure entre os 21 conjuntos. Uma tela que parece precisar de algo inédito quase sempre precisa de uma **variante** de um conjunto existente. Componente novo é alteração estrutural: exige aprovação (ver `aprovacao-obrigatoria`).

## Estados fazem parte da moldura

Loading, vazio, erro, sem conexão e dados são especificados, não decorativos. RNF-04 vale para todas as telas que carregam dados. Uma tela entregue sem os cinco estados está incompleta, mesmo que o caminho feliz esteja perfeito.

## Quando o protótipo não cobre

Acontece: microinteração, transição, um estado não desenhado. Nesse caso **pare e pergunte** — ver `nao-inventar`. Não preencha a lacuna por conta própria, mesmo que pareça pequena e óbvia. A lacuna pode ser intencional, e o histórico do projeto registra 57 decisões justamente para que ninguém precise adivinhar.
