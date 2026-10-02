import 'package:shared/erros/codigo_erro.dart';

import '../../../database/database.dart' show AlunoData;
import '../../auth/criptografia.dart';
import '../../auth/validacoes.dart';
import 'aluno_exception.dart';
import 'aluno_repository.dart';

class AlunoService {
  final AlunoRepository _repository;

  final String Function(String senha) hash;

  AlunoService(this._repository, {this.hash = hashPassword});

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
  /// A coluna e anulavel e a DoD da S2 exige que a tela **declare a
  /// ausencia** (D21, arquitetura secao 5.1). `''` gravado no banco nao e
  /// ausencia — e um dado vazio que a tela nao sabe distinguir.
  String? _textoOuNulo(String? valor) {
    final limpo = valor?.trim();
    return (limpo == null || limpo.isEmpty) ? null : limpo;
  }
}
