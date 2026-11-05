import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  for (final caminhos in [
    ['docs/insomnia/GraziFit.json'],
    [
      '../docs/api/grazifit-pessoas.postman_collection.json',
      'docs/grazifit-pessoas.postman_collection.json',
    ],
  ]) {
    final caminho = caminhos.firstWhere((item) => File(item).existsSync());
    test('$caminho nao versiona credenciais ou dados de criacao', () {
      final texto = File(caminho).readAsStringSync();
      expect(() => jsonDecode(texto), returnsNormally);
      for (final literal in [
        'senha123',
        'altere-esta-senha',
        'usuario@exemplo.com',
        'admin@grazifit.com',
        'aluno@grazifit.com',
        'professor@grazifit.com',
      ]) {
        expect(texto, isNot(contains(literal)), reason: literal);
      }
      expect(texto, contains(RegExp(r'login_(email|senha)|loginEmail')));
    });
  }
}
