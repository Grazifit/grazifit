class ExcecaoValidacao implements Exception {
  final String message;
  ExcecaoValidacao(this.message);

  @override
  String toString() => message;
}