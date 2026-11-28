/// Rótulos de tela para os códigos de categoria e tipo de aula.
///
/// Sem imports: lido pelo app e pelo backend.

const Map<String, String> rotulosCategoriaAula = {
  'musculacao': 'Musculação',
  'funcional': 'Funcional',
  'pilates': 'Pilates',
  'crossfit': 'Crossfit',
  'danca': 'Dança',
  'spinning': 'Spinning',
};

const Map<String, String> rotulosTipoAula = {
  'coletiva': 'Em grupo',
  'individual': 'Personal',
  'experimental': 'Experimental',
};

/// Código desconhecido volta como está.
String rotuloCategoriaAula(String codigo) =>
    rotulosCategoriaAula[codigo] ?? codigo;

/// Código desconhecido volta como está.
String rotuloTipoAula(String codigo) => rotulosTipoAula[codigo] ?? codigo;
