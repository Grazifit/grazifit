import 'package:shared/dtos/aula_rotulos.dart';
import 'package:test/test.dart';

void main() {
  test('categorias conhecidas devolvem o rótulo da tabela', () {
    expect(rotuloCategoriaAula('musculacao'), 'Musculação');
    expect(rotuloCategoriaAula('funcional'), 'Funcional');
    expect(rotuloCategoriaAula('pilates'), 'Pilates');
    expect(rotuloCategoriaAula('crossfit'), 'Crossfit');
    expect(rotuloCategoriaAula('danca'), 'Dança');
    expect(rotuloCategoriaAula('spinning'), 'Spinning');
  });

  test('tipos conhecidos devolvem o rótulo da tabela', () {
    expect(rotuloTipoAula('coletiva'), 'Em grupo');
    expect(rotuloTipoAula('individual'), 'Personal');
    expect(rotuloTipoAula('experimental'), 'Experimental');
  });

  test('código desconhecido devolve o próprio código', () {
    expect(rotuloCategoriaAula('yoga'), 'yoga');
    expect(rotuloTipoAula('online'), 'online');
    expect(rotuloCategoriaAula(''), '');
  });
}
