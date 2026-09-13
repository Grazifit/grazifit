class ValidationException implements Exception{
  final String message;
  ValidationException(this.message);
}
class ConflictException implements Exception{
  final String message;
  ConflictException(this.message);
}