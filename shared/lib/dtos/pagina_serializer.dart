/// Uma pagina de qualquer colecao (`docs/guia-desenvolvimento.md` §6,
/// "Listas").
///
/// Recebe os itens ja serializados pelo DTO da entidade, pelo mesmo motivo
/// de `aluno_serializer.dart`: esta pasta nao importa nada do projeto.
///
/// `total` e o tamanho da colecao inteira, nao da pagina: e com ele que o
/// app sabe se existe proxima pagina (`offset + itens.length < total`).
Map<String, dynamic> paginaToJson({
  required List<Map<String, dynamic>> itens,
  required int limit,
  required int offset,
  required int total,
}) {
  return {'itens': itens, 'limit': limit, 'offset': offset, 'total': total};
}
