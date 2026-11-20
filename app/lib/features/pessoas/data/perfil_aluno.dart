/// Dados do perfil do aluno, como as telas de perfil esperam receber.
///
/// ATENÇÃO: as chaves usadas no `fromJson` (nome, desde, email, telefone, cpf,
/// nascimento, restricaoMedica, observacoesSaude) são uma suposição. Ajuste
/// para os nomes reais que o backend devolve.
///
/// As datas [desde] e [nascimento] são texto já no formato dd/MM/aaaa, que é o
/// que a tela mostra e o que o campo de edição usa. Se o backend enviar ISO
/// 8601, converta no `fromJson`.
class PerfilAluno {
  final String nome;

  /// Data de entrada do aluno, ex.: "12/03/2025".
  final String desde;
  final String email;
  final String telefone;
  final String cpf;

  /// Data de nascimento, ex.: "14/07/1996".
  final String nascimento;

  /// Informados pelo próprio aluno no primeiro acesso. Nulos se não informados.
  final String? restricaoMedica;
  final String? observacoesSaude;

  const PerfilAluno({
    required this.nome,
    required this.desde,
    required this.email,
    required this.telefone,
    required this.cpf,
    required this.nascimento,
    this.restricaoMedica,
    this.observacoesSaude,
  });

  factory PerfilAluno.fromJson(Map<String, dynamic> json) {
    return PerfilAluno(
      nome: json['nome'] as String,
      desde: json['desde'] as String,
      email: json['email'] as String,
      telefone: json['telefone'] as String,
      cpf: json['cpf'] as String,
      nascimento: json['nascimento'] as String,
      restricaoMedica: json['restricaoMedica'] as String?,
      observacoesSaude: json['observacoesSaude'] as String?,
    );
  }
}
