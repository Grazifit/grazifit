import 'package:grazifit_backend/shared/erros/tradutor_erro_banco.dart';
import 'package:shared/erros/codigo_erro.dart';
import 'package:test/test.dart';

void main() {
  group('traduzirCodigoBanco — triggers com ERRCODE proprio', () {
    test('mapeia os quatro GF da secao 7.2', () {
      final esperado = <String, CodigoErro>{
        'GF001': CodigoErro.aulaSemVagas,
        'GF002': CodigoErro.aulaInativa,
        'GF003': CodigoErro.aulaCategoriaDivergente,
        'GF004': CodigoErro.aulaProfessorDivergente,
      };

      esperado.forEach((sqlstate, codigo) {
        expect(
          traduzirCodigoBanco(sqlstate: sqlstate, nomeConstraint: null),
          codigo,
          reason: '$sqlstate deveria traduzir para ${codigo.valor}',
        );
      });
    });

    test('SQLSTATE vence o nome da constraint quando os dois vem', () {
      // trg_valida_vagas_aula e BEFORE INSERT e dispara antes de
      // uq_agendamento_aluno_aula ser avaliada (arquitetura secao 7.4):
      // aula lotada responde AULA_SEM_VAGAS, nao AGENDAMENTO_DUPLICADO.
      expect(
        traduzirCodigoBanco(
          sqlstate: 'GF001',
          nomeConstraint: 'uq_agendamento_aluno_aula',
        ),
        CodigoErro.aulaSemVagas,
      );
    });
  });

  group('traduzirCodigoBanco — violacao de constraint', () {
    test('mapeia as unicidades da secao 7.1', () {
      final esperado = <String, CodigoErro>{
        'uq_agendamento_aluno_aula': CodigoErro.agendamentoDuplicado,
        'uq_aula_professor_horario': CodigoErro.horarioConflitante,
        'uq_vinculo_aluno_ativo': CodigoErro.vinculoJaAtivo,
        'uq_avaliacao_aluno_data': CodigoErro.avaliacaoJaRegistrada,
        'uq_aluno_cpf': CodigoErro.cpfEmUso,
        'uq_aluno_email': CodigoErro.emailEmUso,
      };

      esperado.forEach((constraint, codigo) {
        expect(
          traduzirCodigoBanco(sqlstate: '23505', nomeConstraint: constraint),
          codigo,
          reason: '$constraint deveria traduzir para ${codigo.valor}',
        );
      });
    });

    test('mapeia os CHECK de dominio da secao 7.3', () {
      expect(
        traduzirCodigoBanco(sqlstate: '23514', nomeConstraint: 'dom_cpf_check'),
        CodigoErro.cpfInvalido,
      );
      expect(
        traduzirCodigoBanco(
          sqlstate: '23514',
          nomeConstraint: 'dom_email_check',
        ),
        CodigoErro.emailInvalido,
      );
    });
  });

  group('traduzirCodigoBanco — o que nao esta mapeado', () {
    test('devolve null sem constraint e sem SQLSTATE conhecido', () {
      expect(
        traduzirCodigoBanco(sqlstate: '23502', nomeConstraint: null),
        isNull,
      );
      expect(traduzirCodigoBanco(sqlstate: null, nomeConstraint: null), isNull);
    });

    test('devolve null para constraint desconhecida', () {
      expect(
        traduzirCodigoBanco(
          sqlstate: '23505',
          nomeConstraint: 'uq_inexistente',
        ),
        isNull,
      );
    });

    test('traduz o CHECK de data de nascimento', () {
      expect(
        traduzirCodigoBanco(
          sqlstate: '23514',
          nomeConstraint: 'ck_aluno_nascimento',
        ),
        CodigoErro.dataNascimentoInvalida,
      );
    });

    test('uq_professor_cpf vira CPF_EM_USO', () {
      expect(
        traduzirCodigoBanco(
          sqlstate: '23505',
          nomeConstraint: 'uq_professor_cpf',
        ),
        CodigoErro.cpfEmUso,
      );
    });

    test('FK de professor com 23503 (INSERT com professor inexistente) nao '
        'e uso', () {
      for (final constraint in <String>[
        'fk_vinculo_professor',
        'fk_cronograma_professor',
        'fk_aula_professor',
        'fk_treino_professor',
      ]) {
        expect(
          traduzirCodigoBanco(sqlstate: '23503', nomeConstraint: constraint),
          isNull,
          reason: constraint,
        );
      }
    });

    test('FK RESTRICT que aponta para aluno -> REGISTRO_EM_USO', () {
      for (final constraint in <String>[
        'fk_avaliacao_aluno',
        'fk_vinculo_aluno',
        'fk_agendamento_aluno',
        'fk_historico_aluno',
      ]) {
        expect(
          traduzirCodigoBanco(sqlstate: '23001', nomeConstraint: constraint),
          CodigoErro.registroEmUso,
          reason: constraint,
        );
      }
    });

    test('a mesma FK com 23503 (INSERT com aluno inexistente) nao e uso', () {
      // `fk_agendamento_aluno` falha com 23001 ao excluir o aluno e com 23503
      // ao agendar para um aluno que nao existe. So o primeiro e
      // REGISTRO_EM_USO.
      for (final constraint in <String>[
        'fk_avaliacao_aluno',
        'fk_vinculo_aluno',
        'fk_agendamento_aluno',
        'fk_historico_aluno',
      ]) {
        expect(
          traduzirCodigoBanco(sqlstate: '23503', nomeConstraint: constraint),
          isNull,
          reason: constraint,
        );
      }
    });

    test('23503 de INSERT com chave inexistente continua sem codigo', () {
      // Tambem e FK, mas outro significado: o endereco nao existe, nao
      // "esta em uso". Mapear por SQLSTATE daria a mensagem errada.
      expect(
        traduzirCodigoBanco(
          sqlstate: '23503',
          nomeConstraint: 'fk_vinculo_professor',
        ),
        isNull,
      );
    });

    test('LACUNA: constraints do schema ainda sem codigo no contrato', () {
      for (final constraint in <String>['uq_admin_cpf', 'uq_admin_email']) {
        expect(
          traduzirCodigoBanco(sqlstate: '23505', nomeConstraint: constraint),
          isNull,
          reason: '$constraint ganhou codigo? Atualize o tradutor e este teste',
        );
      }
    });
  });
}
