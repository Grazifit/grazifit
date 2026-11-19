import 'package:shared/dtos/aula_agendado_serializer.dart';
import 'package:shared/dtos/aula_serializer.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> json({
    bool status = true,
    DateTime? dataCancelamento,
    int? idProfessorCancelou,
    int? idAdminCancelou,
    int vagasOcupadas = 0,
  }) => aulaToJson(
    idAula: 7,
    idProfessor: 10,
    idCronograma: null,
    data: DateTime(2026, 6, 20),
    horaInicio: const Duration(hours: 7, minutes: 5),
    horaFim: const Duration(hours: 8),
    tipo: 'coletiva',
    categoria: 'pilates',
    vagasMaxima: 10,
    status: status,
    dataCancelamento: dataCancelamento,
    idProfessorCancelou: idProfessorCancelou,
    idAdminCancelou: idAdminCancelou,
    vagasOcupadas: vagasOcupadas,
  );

  test('aula ativa: data_cancelamento e cancelado_por nulos', () {
    final j = json();
    expect(j['data_cancelamento'], isNull);
    expect(j['cancelado_por'], isNull);
    expect(j.containsKey('data_cancelamento'), isTrue);
    expect(j.containsKey('cancelado_por'), isTrue);
  });

  test('cancelado_por vem do responsavel; ids nao sao expostos', () {
    final instante = DateTime.utc(2026, 6, 10, 15, 30);
    final porAdmin = json(
      status: false,
      dataCancelamento: instante,
      idAdminCancelou: 1,
    );
    final porProfessor = json(
      status: false,
      dataCancelamento: instante,
      idProfessorCancelou: 10,
    );

    expect(porAdmin['cancelado_por'], 'admin');
    expect(porProfessor['cancelado_por'], 'professor');
    for (final j in [porAdmin, porProfessor]) {
      expect(j.keys, isNot(contains('id_admin_cancelou')));
      expect(j.keys, isNot(contains('id_professor_cancelou')));
    }
  });

  test('data_cancelamento sai em UTC ISO-8601, qualquer que seja o fuso', () {
    final local = DateTime.parse('2026-06-10T12:30:00-03:00').toLocal();
    final j = json(status: false, dataCancelamento: local, idAdminCancelou: 1);
    expect(j['data_cancelamento'], '2026-06-10T15:30:00.000Z');
  });

  test('vagas_livres = vagas_maxima - vagas_ocupadas', () {
    expect(json(), containsPair('vagas_ocupadas', 0));
    expect(json(), containsPair('vagas_livres', 10));
    final j = json(vagasOcupadas: 7);
    expect(j['vagas_ocupadas'], 7);
    expect(j['vagas_livres'], 3);
    expect(json(vagasOcupadas: 10)['vagas_livres'], 0);
  });

  test('agendado da aula: so as quatro chaves, sem dado pessoal', () {
    final j = aulaAgendadoToJson(
      idAgendamento: 3,
      idAluno: 40,
      nomeAluno: 'Ana',
      status: 'presente',
    );
    expect(j, {
      'id_agendamento': 3,
      'id_aluno': 40,
      'nome_aluno': 'Ana',
      'status': 'presente',
    });
  });
}
