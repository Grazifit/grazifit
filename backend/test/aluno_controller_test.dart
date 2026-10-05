import 'dart:convert';

import 'package:drift_postgres/drift_postgres.dart' show PgDate;
import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_controller.dart';
import 'package:grazifit_backend/features/pessoas/aluno/aluno_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

/// Service falso — o controller e testado sozinho, sem service, sem
/// repository, sem banco e sem servidor HTTP.
///
/// `implements` em vez de `extends` de proposito: assim nao e preciso
/// construir um `AlunoRepository`, que exigiria um `GraziDatabase`.
class _ServicoFalso implements AlunoService {
  /// A data que o controller entregou, ou nulo se ele recusou antes.
  DateTime? dataRecebida;
  bool chamado = false;

  @override
  String Function(String senha) get hash =>
      (s) => 'hash-falso';

  @override
  Future<AlunoData> criar({
    required String cpf,
    required String senha,
    required String nome,
    required DateTime dataNascimento,
    required String telefone,
    required String email,
    int? idAdminCriador,
    int? idEndereco,
    String? restricaoMedica,
    String? observacaoSaude,
  }) async {
    chamado = true;
    dataRecebida = dataNascimento;

    return AlunoData(
      idAluno: 1,
      cpf: cpf,
      senhaHash: 'hash-falso',
      nome: nome,
      dataNascimento: PgDate.fromDateTime(dataNascimento),
      telefone: telefone,
      email: email,
      status: true,
      dataCadastro: PgDate.fromDateTime(DateTime.now()),
    );
  }
}

const cpfValido = '52998224725';

/// Monta o corpo completo, trocando so o que o teste quer variar.
String _corpo({String? dataNascimento = '1995-03-20'}) {
  return jsonEncode({
    'cpf': cpfValido,
    'senha': 'senhaboa1',
    'nome': 'Aluno Teste',
    'telefone': '11999998888',
    'email': 'aluno@exemplo.com',
    'data_nascimento': ?dataNascimento,
  });
}

Future<Response> _post(AlunoController controller, String corpo) {
  return controller.router.call(
    Request(
      'POST',
      Uri.parse('http://localhost/aluno'),
      body: corpo,
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

void main() {
  late _ServicoFalso servico;
  late AlunoController controller;

  setUp(() {
    servico = _ServicoFalso();
    controller = AlunoController(servico);
  });

  group('data_nascimento — D68 aceita AAAA-MM-DD e nada mais', () {
    test('a forma do contrato passa e chega intacta ao service', () async {
      final resposta = await _post(controller, _corpo());

      expect(resposta.statusCode, 201);
      expect(servico.dataRecebida, DateTime(1995, 3, 20));
    });

    // Todas estas o `DateTime.tryParse` sozinho aceitaria. As tres ultimas
    // sao o caso perigoso: `PgDate.fromDateTime` le o dia do `DateTime` ja
    // convertido para UTC, entao um offset gravaria data diferente da
    // enviada.
    for (final bruta in const [
      '19950320',
      '1995-03-20T10:30:00',
      '1995-03-20T10:30:00Z',
      '1995-03-20 10:30:00',
      '1995-03-20T02:00:00+05:00',
      '1995-03-20T22:00:00-05:00',
    ]) {
      test('recusa "$bruta" — tem hora, fuso ou forma compacta', () async {
        final resposta = await _post(controller, _corpo(dataNascimento: bruta));

        expect(resposta.statusCode, 400);
        expect(servico.chamado, isFalse, reason: 'nao pode chegar ao service');
      });
    }

    // O regex sozinho nao pega nenhuma destas: todas casam com
    // `\d{4}-\d{2}-\d{2}`. `DateTime.tryParse` faz rollover e devolve uma
    // data valida — 2025-02-30 vira 2025-03-02. So o round-trip pega.
    for (final inexistente in const [
      '2025-02-30',
      '2025-13-01',
      '2025-04-31',
      '2025-00-10',
      '2023-02-29',
    ]) {
      test(
        'recusa "$inexistente" — data que nao existe no calendario',
        () async {
          final resposta = await _post(
            controller,
            _corpo(dataNascimento: inexistente),
          );

          expect(resposta.statusCode, 400);
          expect(
            servico.chamado,
            isFalse,
            reason: 'rollover silencioso gravaria outro dia',
          );
        },
      );
    }

    test('2024-02-29 passa — 2024 e bissexto', () async {
      final resposta = await _post(
        controller,
        _corpo(dataNascimento: '2024-02-29'),
      );

      expect(resposta.statusCode, 201);
      expect(servico.dataRecebida, DateTime(2024, 2, 29));
    });

    for (final malformada in const ['1995-3-20', '20/03/1995', 'ontem', '']) {
      test('recusa "$malformada"', () async {
        final resposta = await _post(
          controller,
          _corpo(dataNascimento: malformada),
        );

        expect(resposta.statusCode, 400);
        expect(servico.chamado, isFalse);
      });
    }
  });

  group('demais erros de forma', () {
    test('campo obrigatorio ausente', () async {
      final resposta = await _post(controller, _corpo(dataNascimento: null));

      expect(resposta.statusCode, 400);
      expect(await resposta.readAsString(), contains('data_nascimento'));
      expect(servico.chamado, isFalse);
    });

    test('JSON malformado', () async {
      final resposta = await _post(controller, '{ isto nao e json');

      expect(resposta.statusCode, 400);
      expect(await resposta.readAsString(), contains('JSON'));
      expect(servico.chamado, isFalse);
    });

    test('senha fora de 8 a 12 caracteres', () async {
      final resposta = await _post(
        controller,
        jsonEncode({
          'cpf': cpfValido,
          'senha': 'curta',
          'nome': 'Aluno Teste',
          'telefone': '11999998888',
          'email': 'aluno@exemplo.com',
          'data_nascimento': '1995-03-20',
        }),
      );

      expect(resposta.statusCode, 400);
      expect(servico.chamado, isFalse);
    });
  });

  group('resposta de sucesso', () {
    test('201 nao devolve campo clinico nem hash de senha — D21', () async {
      final resposta = await _post(
        controller,
        jsonEncode({
          'cpf': cpfValido,
          'senha': 'senhaboa1',
          'nome': 'Aluno Teste',
          'telefone': '11999998888',
          'email': 'aluno@exemplo.com',
          'data_nascimento': '1995-03-20',
          'restricao_medica': 'Hipertensao',
          'observacao_saude': 'Evitar impacto',
        }),
      );

      expect(resposta.statusCode, 201);

      final corpo =
          jsonDecode(await resposta.readAsString()) as Map<String, dynamic>;
      expect(
        corpo.keys,
        containsAll(['id_aluno', 'nome', 'email', 'telefone']),
      );
      expect(corpo.containsKey('restricao_medica'), isFalse);
      expect(corpo.containsKey('observacao_saude'), isFalse);
      expect(corpo.containsKey('senha_hash'), isFalse);
      expect(corpo.containsKey('cpf'), isFalse);
    });
  });
}
