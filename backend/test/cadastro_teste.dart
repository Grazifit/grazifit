import 'package:test/test.dart';
import 'package:grazifit_backend/features/auth/validacoes.dart';

void main() {
  group('Validacoes', () {
    test('email válido retorna true', () {
      expect(Validacoes.emailValido('teste@gmail.com'), isTrue);
    });

    test('email inválido retorna false', () {
      expect(Validacoes.emailValido('email-invalido'), isFalse);
    });

    test('cpf válido retorna true', () {
      expect(Validacoes.cpfValido('11144477735'), isTrue); // CPF de teste válido
    });

    test('cpf com dígitos repetidos retorna false', () {
      expect(Validacoes.cpfValido('11111111111'), isFalse);
    });
  });
}