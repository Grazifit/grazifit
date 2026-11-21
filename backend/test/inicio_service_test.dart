import 'package:grazifit_backend/features/inicio/inicio_repository.dart';
import 'package:grazifit_backend/features/inicio/inicio_service.dart';
import 'package:test/test.dart';

AulaDoDia _aula(int ocupadas, int maximas) => AulaDoDia(
  idAula: 1,
  horaInicio: '07:00',
  horaFim: '08:00',
  categoria: 'pilates',
  tipo: 'coletiva',
  professor: 'Ana',
  vagasOcupadas: ocupadas,
  vagasMaximas: maximas,
);

void main() {
  test('calcularOcupacao: sem aulas e 0', () {
    expect(InicioService.calcularOcupacao([]), 0);
  });

  test('calcularOcupacao: soma vagas de todas as aulas e arredonda', () {
    expect(InicioService.calcularOcupacao([_aula(5, 10), _aula(10, 10)]), 75);
    expect(InicioService.calcularOcupacao([_aula(1, 3)]), 33);
  });
}
