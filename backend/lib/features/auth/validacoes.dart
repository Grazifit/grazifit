class Validacoes {
  static bool emailValido(String email) {
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email.trim());
  }

  static bool cpfValido(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    final digits = cpf.split('').map(int.parse).toList();
    int calcDigit(List<int> nums, int factor) {
      int sum = 0;
      for (var n in nums) {
        sum += n * factor--;
      }
      final rest = sum % 11;
      return rest < 2 ? 0 : 11 - rest;
    }

    if (calcDigit(digits.sublist(0, 9), 10) != digits[9]) return false;
    if (calcDigit(digits.sublist(0, 10), 11) != digits[10]) return false;
    return true;
  }
}