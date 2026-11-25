/// Formatação de datas do contrato REST (`AAAA-MM-DD`, openspec
/// formato-data-contrato-rest) para exibição. A regra de negócio sobre datas
/// (ex.: "30 dias") fica no backend.
abstract final class Datas {
  /// `2026-08-12` -> `12/08/2026`. Nulo se a entrada for nula ou inválida.
  static String? diaMesAno(String? iso) {
    final p = _partes(iso);
    return p == null ? null : '${p[2]}/${p[1]}/${p[0]}';
  }

  /// `2026-08-12` -> `12/08`.
  static String? diaMes(String? iso) {
    final p = _partes(iso);
    return p == null ? null : '${p[2]}/${p[1]}';
  }

  static List<String>? _partes(String? iso) {
    if (iso == null || iso.length < 10) return null;
    final p = iso.substring(0, 10).split('-');
    return p.length == 3 ? p : null;
  }

  static const _dias = [
    'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo',
  ];
  static const _meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho',
    'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];

  /// `2026-09-01` -> `Terça, 01 de setembro`. Formatação de exibição.
  static String? porExtenso(String? iso) {
    if (_partes(iso) == null) return null;
    final d = DateTime.tryParse(iso!.substring(0, 10));
    if (d == null) return null;
    return '${_dias[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')} '
        'de ${_meses[d.month - 1]}';
  }
}
