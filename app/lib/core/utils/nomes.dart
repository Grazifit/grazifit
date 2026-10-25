// app/lib/core/utils/nomes.dart

/// Remove o último sobrenome: "Ana Beatriz Ramos" -> "Ana Beatriz".
/// Usado em títulos como "Histórico de Ana Beatriz".
String nomeCurto(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  if (partes.length <= 1) return nome.trim();
  return partes.sublist(0, partes.length - 1).join(' ');
}