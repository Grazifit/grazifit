# Design — D68, formato de data no contrato REST

## Onde a regra mora

A regra normativa vai em `docs/guia-desenvolvimento.md` §6 "Comunicação entre
app e backend", ao lado dos quatro bullets que já definem o contrato de fio
(REST/JSON, endpoints, erro, autorização). É o lugar documentado do contrato.

**Não vai em `docs/arquitetura.md`.** Aquele documento numera seções e a
Rastreabilidade lista "decisões novas introduzidas por **este documento**" —
D68 não é. Inserir uma seção nova ali renumeraria as seguintes sem ganho.

## Onde a validação mora

No **controller**, junto das demais checagens de forma.

A alternativa seria o service, mas a escolha aqui é deliberada: "esta string
tem a forma que o contrato exige?" é pergunta sobre a **requisição**, não sobre
o negócio. O service recebe `DateTime`, um tipo que já não admite a pergunta.
Guia §4.4 dá ao controller exatamente isso: *"forma da requisição e montagem do
DTO"*.

Isso deixa a validação num arquivo sem teste — ver Riscos.

## Como validar

Três portas em série. Nenhuma sozinha basta:

```dart
static final _formatoData = RegExp(r'^\d{4}-\d{2}-\d{2}$');

DateTime? _dataCivil(String bruto) {
  if (!_formatoData.hasMatch(bruto)) return null;   // 1
  final data = DateTime.tryParse(bruto);            // 2
  if (data == null) return null;
  return _mesmaData(data, bruto) ? data : null;     // 3
}
```

**Porta 1 — regex.** Fecha `19950320`, `1995-3-20`, qualquer coisa com `T`,
espaço, hora ou offset. Resolve os defeitos 1 e 2 da proposta.

**Porta 2 — parse.** Converte, e pega o que o regex deixou passar por acidente.

**Porta 3 — round-trip.** Indispensável, e é o motivo de este design existir em
vez de ser uma linha: **`DateTime.tryParse` faz rollover silencioso.**
`2025-02-30` casa com o regex, parseia sem erro e devolve `2025-03-02`. A única
defesa é reformatar o resultado e comparar com a string original. Se diferirem,
a data não existia.

## Alternativas descartadas

**Só regex.** Não pega rollover — `2025-02-30` passaria e gravaria 2 de março.

**Deixar o CHECK do banco barrar.** `ck_aluno_nascimento` só compara com
`CURRENT_DATE`; uma data inexistente já chegou convertida em data válida e
passa. O banco não tem como recusar o que o Dart já normalizou.

**Aceitar ISO-8601 completo e truncar no servidor.** Truncar exige decidir *em
qual fuso* truncar, e qualquer resposta a isso é arbitrária. Recusar é honesto:
o cliente sabe o dia que quis enviar; o servidor não.

**Validar no service.** Obrigaria o service a receber `String` e a conhecer
formato de transporte — `guia §4.4` proíbe.

## Risco conhecido, aceito

A validação nasce em `aluno_controller.dart`, e **não existe teste de controller
no projeto**. O `aluno_service_test.dart` cobre o service com repository falso;
nada exercita o controller. Esta change cria o primeiro, dirigindo requisições
`shelf` ao router com um service falso — sem servidor, sem banco. Sem ele, as
três portas seriam código não verificado, e o rollover é exatamente o tipo de
defeito que escapa da revisão a olho.
