import 'package:shared/erros/codigo_erro.dart';

import '../../../database/database.dart' show AlunoData;
import '../../auth/validacoes.dart';
import '../../../shared/erros/aluno_exception.dart';
import 'aluno_repository.dart';

class AlunoService {
  final AlunoRepository _repository;

  /// Gera o hash da senha. Injetado na composicao (`bin/server.dart`),
  /// como no `AdminService`.
  final String Function(String senha) hash;

  AlunoService(this._repository, {required this.hash});

  Future<AlunoData> criar({
    required Identidade identidade,
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
    final cpfNormalizado = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    final emailNormalizado = email.trim().toLowerCase();

    if (!Validacoes.cpfValido(cpfNormalizado)) {
      throw const AlunoValidationException(
        CodigoErro.cpfInvalido,
        campo: 'cpf',
      );
    }

    if (!Validacoes.emailValido(emailNormalizado)) {
      throw const AlunoValidationException(
        CodigoErro.emailInvalido,
        campo: 'email',
      );
    }

    if (!_anteriorAHoje(dataNascimento)) {
      throw const AlunoValidationException(
        CodigoErro.dataNascimentoInvalida,
        campo: 'data_nascimento',
      );
    }

    if (await _repository.cpfEmUso(cpfNormalizado)) {
      throw const AlunoConflictException(CodigoErro.cpfEmUso, campo: 'cpf');
    }

    if (await _repository.emailEmUso(emailNormalizado)) {
      throw const AlunoConflictException(CodigoErro.emailEmUso, campo: 'email');
    }

    return _repository.create(
      cpf: cpfNormalizado,
      senhaHash: hash(senha),
      nome: nome.trim(),
      dataNascimento: dataNascimento,
      telefone: telefone.trim(),
      email: emailNormalizado,
      idAdminCriador: idAdminCriador,
      idEndereco: idEndereco,
      restricaoMedica: _textoOuNulo(restricaoMedica),
      observacaoSaude: _textoOuNulo(observacaoSaude),
    );
  }

  /// Espelha `ck_aluno_nascimento` — `data_nascimento < CURRENT_DATE`.
  ///
  /// Compara so a parte de data: a coluna e `DATE`, e a hora do
  /// `DateTime` recebido nao participa da constraint. Nascer hoje nao
  /// passa, porque o CHECK e `<` e nao `<=`.
  ///
  /// Divergencia conhecida: `CURRENT_DATE` e o "hoje" do fuso do servidor
  /// PostgreSQL e `DateTime.now()` e o do processo Dart.
  bool _anteriorAHoje(DateTime data) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final nascimento = DateTime(data.year, data.month, data.day);

    return nascimento.isBefore(hoje);
  }

  /// Campo clinico opcional em branco e ausencia, nao string vazia.
  ///
  /// A tela precisa distinguir "nao informado" de valor
  /// (`docs/arquitetura.md` §5.1, D21); `''` no banco nao permite isso.
  String? _textoOuNulo(String? valor) {
    final limpo = valor?.trim();
    return (limpo == null || limpo.isEmpty) ? null : limpo;
  }

  /// Id que nunca existe: nao precisa ir ao banco.
  static void _exigirIdPossivel(int idAluno) {
    if (idAluno <= 0) {
      throw const AlunoNotFoundException();
    }
  }

  Future<AlunoData> buscarAlunoPorId(int idAluno) async {
    _exigirIdPossivel(idAluno);

    final aluno = await _repository.buscarAlunoPorId(idAluno);
    if (aluno == null) {
      throw const AlunoNotFoundException();
    }
    return aluno;
  }

  /// `limit` e `offset` chegam ja validados pelo controller.
  Future<({List<AlunoData> itens, int total})> buscarAlunos({
    required int limit,
    required int offset,
  }) async {
    final itens = await _repository.buscarAlunos(limit: limit, offset: offset);
    final total = await _repository.countAlunos();
    return (itens: itens, total: total);
  }

  /// Edita nome, telefone e e-mail. Campo nulo fica como esta.
  ///
  /// A forma (tamanho, presenca) ja foi conferida pelo controller; aqui
  /// fica a regra: existencia, formato de e-mail e unicidade entre perfis
  /// (`docs/arquitetura.md` §6.3, D61). A existencia vem primeiro, para
  /// que id inexistente seja sempre 404.
  Future<AlunoData> atualizar(
    int idAluno, {
    String? nome,
    String? telefone,
    String? email,
  }) async {
    _exigirIdPossivel(idAluno);
    if (await _repository.buscarAlunoPorId(idAluno) == null) {
      throw const AlunoNotFoundException();
    }

    final emailNormalizado = email?.trim().toLowerCase();

    if (emailNormalizado != null) {
      if (!Validacoes.emailValido(emailNormalizado)) {
        throw const AlunoValidationException(
          CodigoErro.emailInvalido,
          campo: 'email',
        );
      }

      if (await _repository.emailEmUso(
        emailNormalizado,
        excetoIdAluno: idAluno,
      )) {
        throw const AlunoConflictException(
          CodigoErro.emailEmUso,
          campo: 'email',
        );
      }
    }

    final aluno = await _repository.atualizar(
      idAluno,
      nome: nome?.trim(),
      telefone: telefone?.trim(),
      email: emailNormalizado,
    );
    if (aluno == null) {
      throw const AlunoNotFoundException();
    }
    return aluno;
  }

  /// `false` inativa e preserva o historico; `true` reativa.
  Future<void> alterarStatus(int idAluno, {required bool status}) async {
    _exigirIdPossivel(idAluno);
    if (!await _repository.alterarStatus(idAluno, status: status)) {
      throw const AlunoNotFoundException();
    }
  }

  /// Exclusao real. Aluno com historico: o banco recusa e o controller
  /// responde `REGISTRO_EM_USO` — a alternativa e [alterarStatus].
  Future<void> excluir(int idAluno) async {
    _exigirIdPossivel(idAluno);
    if (!await _repository.excluir(idAluno)) {
      throw const AlunoNotFoundException();
    }
  }
}
