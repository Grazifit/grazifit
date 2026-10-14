import 'dart:convert';

import 'package:grazifit_backend/database/database.dart';
import 'package:grazifit_backend/features/pessoas/professor/professor_controller.dart';
import 'package:grazifit_backend/features/pessoas/professor/professor_service.dart';
import 'package:grazifit_backend/shared/erros/professor_exception.dart';
import 'package:grazifit_backend/shared/autorizacao/identidade.dart';
import 'package:grazifit_backend/shared/middleware/identidade_middleware.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

class _ServicoFalso implements ProfessorService {
  ProfessorData? registro;
  Object? erro;

  Future<T> _responder<T>(T Function() acao) async {
    if (erro case final falha?) throw falha;
    return acao();
  }

  @override
  Future<ProfessorData> criar({
    required Identidade identidade,
    required String cpf,
    required String senha,
    required String nome,
    required String telefone,
    required String email,
  }) => _responder(
    () => registro = ProfessorData(
      idProfessor: 1,
      idAdminCriador: identidade.id,
      cpf: cpf,
      senhaHash: 'hash-nao-publico',
      nome: nome,
      telefone: telefone,
      email: email,
      status: true,
    ),
  );

  @override
  Future<ProfessorData> buscarPorId(Identidade identidade, int idProfessor) =>
      _responder(() {
        if (registro?.idProfessor != idProfessor) {
          throw const ProfessorNotFoundException();
        }
        return registro!;
      });

  @override
  Future<ProfessorData> atualizar({
    required Identidade identidade,
    required int idProfessor,
    String? nome,
    String? email,
    String? telefone,
    String? senha,
    bool? status,
  }) => _responder(() {
    final anterior = registro;
    if (anterior == null || anterior.idProfessor != idProfessor) {
      throw const ProfessorNotFoundException();
    }
    return registro = ProfessorData(
      idProfessor: anterior.idProfessor,
      cpf: anterior.cpf,
      senhaHash: senha == null ? anterior.senhaHash : 'hash-alterado',
      nome: nome ?? anterior.nome,
      telefone: telefone ?? anterior.telefone,
      email: email ?? anterior.email,
      status: status ?? anterior.status,
    );
  });

  @override
  Future<void> deletar(Identidade identidade, int idProfessor) =>
      _responder(() {
        if (registro?.idProfessor != idProfessor) {
          throw const ProfessorNotFoundException();
        }
        registro = null;
      });
}

Future<Response> _requisitar(
  ProfessorController controller,
  String metodo,
  String caminho, {
  Object? corpo,
  Identidade? identidade = const Identidade(id: 7, papel: Papel.admin),
}) => controller.router.call(
  Request(
    metodo,
    Uri.parse('http://localhost$caminho'),
    body: corpo == null ? null : jsonEncode(corpo),
    headers: {'Content-Type': 'application/json'},
    context: {chaveIdentidadeContexto: ?identidade},
  ),
);

void main() {
  late _ServicoFalso service;
  late ProfessorController controller;

  setUp(() {
    service = _ServicoFalso();
    controller = ProfessorController(service);
  });

  test('CRUD HTTP retorna 201, 200, 200 e 204 sem expor senha', () async {
    final criacao = await _requisitar(
      controller,
      'POST',
      '/professor',
      corpo: {
        'cpf': '52998224725',
        'senha': 'senha123',
        'nome': 'Professor Teste',
        'telefone': '11999998888',
        'email': 'professor@exemplo.com',
      },
    );
    expect(criacao.statusCode, 201);
    final criado =
        jsonDecode(await criacao.readAsString()) as Map<String, dynamic>;
    expect(criado['id_professor'], 1);
    expect(criado, isNot(contains('senha')));
    expect(criado, isNot(contains('senha_hash')));

    final busca = await _requisitar(controller, 'GET', '/professor/1');
    expect(busca.statusCode, 200);

    final atualizacao = await _requisitar(
      controller,
      'PATCH',
      '/professor/1',
      corpo: {'nome': 'Nome Atualizado', 'status': false},
    );
    expect(atualizacao.statusCode, 200);
    final atualizado =
        jsonDecode(await atualizacao.readAsString()) as Map<String, dynamic>;
    expect(atualizado['nome'], 'Nome Atualizado');
    expect(atualizado['status'], isFalse);

    final exclusao = await _requisitar(controller, 'DELETE', '/professor/1');
    expect(exclusao.statusCode, 204);
  });

  test('valida forma do POST, PATCH e id antes de chamar o service', () async {
    expect(
      (await _requisitar(
        controller,
        'POST',
        '/professor',
        corpo: {},
      )).statusCode,
      400,
    );
    expect(
      (await _requisitar(
        controller,
        'PATCH',
        '/professor/1',
        corpo: {'status': 'sim'},
      )).statusCode,
      400,
    );
    expect(
      (await _requisitar(controller, 'GET', '/professor/abc')).statusCode,
      400,
    );
  });

  test('traduz excecoes de dominio para 400, 409 e 404', () async {
    service.erro = const ProfessorValidationException(
      CodigoErro.cpfInvalido,
      campo: 'cpf',
    );
    final invalido = await _requisitar(
      controller,
      'POST',
      '/professor',
      corpo: {
        'cpf': '123',
        'senha': 'senha123',
        'nome': 'Professor',
        'telefone': '11999998888',
        'email': 'professor@exemplo.com',
      },
    );
    expect(invalido.statusCode, 400);

    service.erro = const ProfessorConflictException(
      CodigoErro.emailEmUso,
      campo: 'email',
    );
    expect(
      (await _requisitar(controller, 'GET', '/professor/1')).statusCode,
      409,
    );

    service.erro = const ProfessorNotFoundException();
    final ausente = await _requisitar(controller, 'DELETE', '/professor/1');
    expect(ausente.statusCode, 404);
    final json =
        jsonDecode(await ausente.readAsString()) as Map<String, dynamic>;
    expect(json['codigo'], 'PROFESSOR_NAO_ENCONTRADO');
  });

  test('rejeita requisicao sem identidade', () async {
    final resposta = await _requisitar(
      controller,
      'GET',
      '/professor/1',
      identidade: null,
    );
    expect(resposta.statusCode, 401);
  });
}
