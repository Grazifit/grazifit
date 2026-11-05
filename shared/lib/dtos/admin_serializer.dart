/// Admin como o proprio admin o enxerga.
///
/// Recebe valores soltos pelo mesmo motivo de `aluno_serializer.dart`: esta
/// pasta nao importa nada do projeto, e o import relativo para
/// `backend/lib/database/` que existia aqui nao compilava.
Map<String, dynamic> adminToPublicJson({
  required int idAdmin,
  required String nome,
  required String email,
  String? telefone,
}) {
  return {
    'id_admin': idAdmin,
    'nome': nome,
    'email': email,
    'telefone': telefone,
  };
}
